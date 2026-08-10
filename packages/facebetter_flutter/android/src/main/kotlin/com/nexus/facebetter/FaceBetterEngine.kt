package com.nexus.facebetter

import android.content.Context
import android.graphics.Bitmap
import android.graphics.ImageFormat
import android.graphics.RectF
import android.graphics.SurfaceTexture
import android.hardware.camera2.CameraCaptureSession
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraDevice
import android.hardware.camera2.CameraManager
import android.hardware.camera2.CaptureRequest
import android.media.Image
import android.media.ImageReader
import android.os.Handler
import android.os.HandlerThread
import android.util.Log
import android.util.Size
import android.view.Surface
import com.pixpark.facebetter.BeautyEffectEngine
import com.pixpark.facebetter.BeautyParams.BasicParam
import com.pixpark.facebetter.BeautyParams.ReshapeParam
import com.pixpark.facebetter.ImageFrame
import java.nio.ByteBuffer
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Camera2 (YUV) → FaceBetter processImage → Flutter Texture (Surface).
 */
class FaceBetterEngine(private val context: Context) {
    companion object {
        private const val TAG = "FaceBetterEngine"
    }

    private var beauty: BeautyEffectEngine? = null

    private var cameraDevice: CameraDevice? = null
    private var captureSession: CameraCaptureSession? = null
    private var imageReader: ImageReader? = null
    private var previewSurface: Surface? = null

    private var camThread: HandlerThread? = null
    private var camHandler: Handler? = null
    private val processing = AtomicBoolean(false)

    @Volatile
    private var stopping = false
    @Volatile
    private var released = false
    private var cameraClosedLatch: CountDownLatch? = null

    @Volatile
    private var smooth = 0.55f
    @Volatile
    private var whiten = 0.35f
    @Volatile
    private var rosy = 0.15f
    @Volatile
    private var sharpen = 0.2f
    @Volatile
    private var slimFace = 0f
    @Volatile
    private var bigEye = 0f
    @Volatile
    private var beautyEnabled = true

    private var frontFacing = true

    fun init(appId: String, appKey: String) {
        if (beauty != null) return
        val log = BeautyEffectEngine.LogConfig()
        log.consoleEnabled = true
        log.fileEnabled = false
        log.level = BeautyEffectEngine.LogLevel.INFO
        BeautyEffectEngine.setLogConfig(log)

        val config = BeautyEffectEngine.EngineConfig()
        config.appId = appId
        config.appKey = appKey
        beauty = BeautyEffectEngine(context, config)
        applyBeautyInternal()
        Log.i(TAG, "BeautyEffectEngine ready")
    }

    fun setBeauty(
        smooth: Float,
        whiten: Float,
        rosy: Float,
        sharpen: Float,
        slim: Float,
        eye: Float,
        enabled: Boolean,
    ) {
        this.smooth = smooth
        this.whiten = whiten
        this.rosy = rosy
        this.sharpen = sharpen
        this.slimFace = slim
        this.bigEye = eye
        this.beautyEnabled = enabled
        applyBeautyInternal()
    }

    private fun applyBeautyInternal() {
        val eng = beauty ?: return
        if (!beautyEnabled) {
            eng.setBeautyParam(BasicParam.SMOOTHING, 0f)
            eng.setBeautyParam(BasicParam.WHITENING, 0f)
            eng.setBeautyParam(BasicParam.ROSINESS, 0f)
            eng.setBeautyParam(BasicParam.SHARPENING, 0f)
            eng.setBeautyParam(ReshapeParam.FACE_THIN, 0f)
            eng.setBeautyParam(ReshapeParam.EYE_SIZE, 0f)
            return
        }
        eng.setBeautyParam(BasicParam.SMOOTHING, smooth.coerceIn(0f, 1f))
        eng.setBeautyParam(BasicParam.WHITENING, whiten.coerceIn(0f, 1f))
        eng.setBeautyParam(BasicParam.ROSINESS, rosy.coerceIn(0f, 1f))
        eng.setBeautyParam(BasicParam.SHARPENING, sharpen.coerceIn(0f, 1f))
        eng.setBeautyParam(ReshapeParam.FACE_THIN, slimFace.coerceIn(0f, 1f))
        eng.setBeautyParam(ReshapeParam.EYE_SIZE, bigEye.coerceIn(0f, 1f))
    }

    fun startCamera(surfaceTexture: SurfaceTexture, preferFront: Boolean = true) {
        stopCamera()
        released = false
        stopping = false
        frontFacing = preferFront

        camThread = HandlerThread("facebetter-cam").also { it.start() }
        camHandler = Handler(camThread!!.looper)

        surfaceTexture.setDefaultBufferSize(720, 1280)
        previewSurface = Surface(surfaceTexture)

        val manager = context.getSystemService(Context.CAMERA_SERVICE) as CameraManager
        val cameraId = pickCameraId(manager, preferFront)
            ?: throw IllegalStateException("No camera")

        val characteristics = manager.getCameraCharacteristics(cameraId)
        val map = characteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP)
            ?: throw IllegalStateException("No stream config")
        val yuvSize = chooseSize(map.getOutputSizes(ImageFormat.YUV_420_888))

        imageReader = ImageReader.newInstance(
            yuvSize.width,
            yuvSize.height,
            ImageFormat.YUV_420_888,
            2
        )
        imageReader!!.setOnImageAvailableListener({ reader ->
            if (stopping || released) {
                try {
                    reader.acquireLatestImage()?.close()
                } catch (_: Exception) {
                }
                return@setOnImageAvailableListener
            }
            val image = reader.acquireLatestImage() ?: return@setOnImageAvailableListener
            if (!processing.compareAndSet(false, true)) {
                image.close()
                return@setOnImageAvailableListener
            }
            try {
                if (!stopping && !released) {
                    processImage(image, characteristics)
                }
            } catch (t: Throwable) {
                Log.e(TAG, "process frame", t)
            } finally {
                image.close()
                processing.set(false)
            }
        }, camHandler)

        manager.openCamera(cameraId, object : CameraDevice.StateCallback() {
            override fun onOpened(camera: CameraDevice) {
                if (stopping || released) {
                    try {
                        camera.close()
                    } catch (_: Exception) {
                    }
                    return
                }
                cameraDevice = camera
                try {
                    val reader = imageReader ?: run {
                        camera.close()
                        return
                    }
                    camera.createCaptureSession(
                        listOf(reader.surface),
                        object : CameraCaptureSession.StateCallback() {
                            override fun onConfigured(session: CameraCaptureSession) {
                                if (stopping || released) {
                                    try {
                                        session.close()
                                    } catch (_: Exception) {
                                    }
                                    return
                                }
                                captureSession = session
                                val req = camera.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW)
                                req.addTarget(reader.surface)
                                req.set(
                                    CaptureRequest.CONTROL_AF_MODE,
                                    CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE
                                )
                                session.setRepeatingRequest(req.build(), null, camHandler)
                            }

                            override fun onConfigureFailed(session: CameraCaptureSession) {
                                Log.e(TAG, "capture session configure failed")
                            }
                        },
                        camHandler
                    )
                } catch (e: Exception) {
                    Log.e(TAG, "createCaptureSession", e)
                }
            }

            override fun onDisconnected(camera: CameraDevice) {
                try {
                    camera.close()
                } catch (_: Exception) {
                }
                if (cameraDevice === camera) cameraDevice = null
                cameraClosedLatch?.countDown()
            }

            override fun onError(camera: CameraDevice, error: Int) {
                Log.e(TAG, "camera error $error")
                try {
                    camera.close()
                } catch (_: Exception) {
                }
                if (cameraDevice === camera) cameraDevice = null
                cameraClosedLatch?.countDown()
            }

            override fun onClosed(camera: CameraDevice) {
                if (cameraDevice === camera) cameraDevice = null
                cameraClosedLatch?.countDown()
            }
        }, camHandler)
    }

    private fun processImage(image: Image, characteristics: CameraCharacteristics) {
        if (stopping || released) return
        val eng = beauty ?: return
        val surface = previewSurface ?: return

        val planes = image.planes
        if (planes.size < 3) return

        val yBuffer = planes[0].buffer
        val uBuffer = planes[1].buffer
        val vBuffer = planes[2].buffer
        val yStride = planes[0].rowStride
        val uStride = planes[1].rowStride
        val vStride = planes[2].rowStride
        val uPixelStride = planes[1].pixelStride
        val width = image.width
        val height = image.height

        var input: ImageFrame? = null
        var output: ImageFrame? = null
        var rgba: ImageFrame? = null
        try {
            input = ImageFrame.createWithAndroid420(
                width,
                height,
                yBuffer,
                yStride,
                uBuffer,
                uStride,
                vBuffer,
                vStride,
                uPixelStride
            ) ?: return

            val facing = characteristics.get(CameraCharacteristics.LENS_FACING)
            val front = facing == CameraCharacteristics.LENS_FACING_FRONT
            // AAR 1.2.0 no expone mirror(); rotate + flip en canvas.
            if (front) {
                input.rotate(ImageFrame.Rotation.ROTATION_270)
            } else {
                input.rotate(ImageFrame.Rotation.ROTATION_90)
            }
            input.type = ImageFrame.FrameType.VIDEO

            output = eng.processImage(input)
            if (output == null || !output.isValid) {
                Log.w(TAG, "processImage returned null")
                return
            }

            rgba = output.convert(ImageFrame.Format.RGBA) ?: output
            val bw = rgba.width
            val bh = rgba.height
            val data: ByteBuffer = rgba.data ?: return
            if (bw <= 0 || bh <= 0) return

            data.rewind()
            val raw = Bitmap.createBitmap(bw, bh, Bitmap.Config.ARGB_8888)
            raw.copyPixelsFromBuffer(data)
            val bitmap = if (front) {
                val m = android.graphics.Matrix().apply { preScale(-1f, 1f) }
                Bitmap.createBitmap(raw, 0, 0, raw.width, raw.height, m, false).also {
                    raw.recycle()
                }
            } else {
                raw
            }

            try {
                val canvas = surface.lockHardwareCanvas()
                canvas.drawColor(android.graphics.Color.BLACK)
                val scale = maxOf(
                    canvas.width.toFloat() / bitmap.width,
                    canvas.height.toFloat() / bitmap.height
                )
                val dw = bitmap.width * scale
                val dh = bitmap.height * scale
                val left = (canvas.width - dw) / 2f
                val top = (canvas.height - dh) / 2f
                canvas.drawBitmap(
                    bitmap,
                    null,
                    RectF(left, top, left + dw, top + dh),
                    null
                )
                surface.unlockCanvasAndPost(canvas)
            } catch (e: Exception) {
                Log.w(TAG, "draw texture: ${e.message}")
            } finally {
                bitmap.recycle()
            }
        } finally {
            try {
                rgba?.takeIf { it !== output }?.release()
            } catch (_: Exception) {
            }
            try {
                output?.release()
            } catch (_: Exception) {
            }
            try {
                input?.release()
            } catch (_: Exception) {
            }
        }
    }

    private fun pickCameraId(manager: CameraManager, preferFront: Boolean): String? {
        var fallback: String? = null
        for (id in manager.cameraIdList) {
            val facing = manager.getCameraCharacteristics(id)
                .get(CameraCharacteristics.LENS_FACING)
            if (preferFront && facing == CameraCharacteristics.LENS_FACING_FRONT) return id
            if (!preferFront && facing == CameraCharacteristics.LENS_FACING_BACK) return id
            if (fallback == null) fallback = id
        }
        return fallback
    }

    private fun chooseSize(sizes: Array<Size>): Size {
        val target = sizes
            .filter { it.width * it.height <= 1280 * 720 }
            .maxByOrNull { it.width * it.height }
        return target ?: sizes.minBy { it.width * it.height }
    }

    @Synchronized
    fun stopCamera() {
        stopping = true
        try {
            imageReader?.setOnImageAvailableListener(null, null)
        } catch (_: Exception) {
        }
        try {
            captureSession?.stopRepeating()
        } catch (_: Exception) {
        }
        try {
            captureSession?.abortCaptures()
        } catch (_: Exception) {
        }
        try {
            captureSession?.close()
        } catch (_: Exception) {
        }
        captureSession = null

        val drainDeadline = System.nanoTime() + 500_000_000L
        while (processing.get() && System.nanoTime() < drainDeadline) {
            try {
                Thread.sleep(10)
            } catch (_: InterruptedException) {
                break
            }
        }

        val latch = CountDownLatch(1)
        cameraClosedLatch = latch
        val device = cameraDevice
        cameraDevice = null
        if (device != null) {
            try {
                device.close()
            } catch (_: Exception) {
                latch.countDown()
            }
            try {
                latch.await(2, TimeUnit.SECONDS)
            } catch (_: InterruptedException) {
            }
        } else {
            latch.countDown()
        }
        cameraClosedLatch = null

        try {
            imageReader?.close()
        } catch (_: Exception) {
        }
        imageReader = null
        try {
            previewSurface?.release()
        } catch (_: Exception) {
        }
        previewSurface = null

        val thread = camThread
        camHandler = null
        camThread = null
        if (thread != null) {
            thread.quitSafely()
            try {
                thread.join(1000)
            } catch (_: InterruptedException) {
            }
        }
    }

    @Synchronized
    fun release() {
        if (released) return
        released = true
        stopping = true
        stopCamera()
        try {
            beauty?.release()
        } catch (_: Exception) {
        }
        beauty = null
        Log.i(TAG, "pipeline released")
    }
}
