package com.nexus.gpupixel

import android.content.Context
import android.graphics.Bitmap
import android.graphics.ImageFormat
import android.graphics.Matrix
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
import android.os.Build
import android.util.Log
import android.util.Size
import android.view.Surface
import android.view.WindowManager
import com.pixpark.gpupixel.FaceDetector
import com.pixpark.gpupixel.GPUPixel
import com.pixpark.gpupixel.GPUPixelFilter
import com.pixpark.gpupixel.GPUPixelSinkRawData
import com.pixpark.gpupixel.GPUPixelSourceRawData
import java.nio.ByteBuffer
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Pipeline estabilizado anti-SIGSEGV:
 *
 *  Camera2 thread  →  copia YUV→RGBA, cierra Image
 *        ↓ post
 *  GL thread       →  FaceDetector + GPUPixel.ProcessData + draw Texture
 *
 * Init / Process / Destroy SOLO en el hilo GL.
 * Camera2 NUNCA llama ProcessData directamente.
 */
class GpuPixelEngine(private val context: Context) {
    companion object {
        private const val TAG = "GpuPixelEngine"
    }

    private data class RgbaPacket(
        val rgba: ByteArray,
        val width: Int,
        val height: Int,
        val front: Boolean,
        val rotDegrees: Int,
    )

    private var source: GPUPixelSourceRawData? = null
    private var beauty: GPUPixelFilter? = null
    private var reshape: GPUPixelFilter? = null
    private var sink: GPUPixelSinkRawData? = null
    private var detector: FaceDetector? = null

    private var cameraDevice: CameraDevice? = null
    private var captureSession: CameraCaptureSession? = null
    private var imageReader: ImageReader? = null
    private var previewSurface: Surface? = null

    private var glThread: HandlerThread? = null
    private var glHandler: Handler? = null
    private var camThread: HandlerThread? = null
    private var camHandler: Handler? = null

    /** true solo tras Init + Create exitosos en hilo GL. */
    @Volatile
    private var glReady = false

    /** Camera2 puede entregar frames. */
    @Volatile
    private var acceptFrames = false

    @Volatile
    private var stopping = false

    @Volatile
    private var released = false

    private val glBusy = AtomicBoolean(false)
    private var cameraClosedLatch: CountDownLatch? = null

    @Volatile
    private var smooth = 0.55f
    @Volatile
    private var whiten = 0.25f
    @Volatile
    private var slimFace = 0f
    @Volatile
    private var bigEye = 0f

    private fun ensureGlThread() {
        if (glThread?.isAlive == true && glHandler != null) return
        glThread = HandlerThread("gpupixel-gl").also { it.start() }
        glHandler = Handler(glThread!!.looper)
    }

    /**
     * Init asíncrono en hilo GL. No abre cámara.
     * [onDone] se invoca en el hilo GL (el caller debe re-dispatch si hace falta).
     */
    fun initAsync(onDone: (ok: Boolean, error: String?) -> Unit) {
        if (released) {
            onDone(false, "engine released")
            return
        }
        ensureGlThread()
        glHandler!!.post {
            try {
                if (released) {
                    onDone(false, "engine released")
                    return@post
                }
                if (glReady && source != null) {
                    onDone(true, null)
                    return@post
                }
                Log.i(TAG, "GL init begin")
                GPUPixel.Init(context.applicationContext)

                val src = GPUPixelSourceRawData.Create()
                    ?: throw IllegalStateException("SourceRawData.Create null")
                val beau = GPUPixelFilter.Create(GPUPixelFilter.BEAUTY_FACE_FILTER)
                    ?: throw IllegalStateException("BeautyFace.Create null")
                val resh = GPUPixelFilter.Create(GPUPixelFilter.FACE_RESHAPE_FILTER)
                    ?: throw IllegalStateException("FaceReshape.Create null")
                val snk = GPUPixelSinkRawData.Create()
                    ?: throw IllegalStateException("SinkRawData.Create null")
                val det = FaceDetector.Create()
                    ?: throw IllegalStateException("FaceDetector.Create null")

                src.AddSink(beau)
                beau.AddSink(resh)
                resh.AddSink(snk)

                source = src
                beauty = beau
                reshape = resh
                sink = snk
                detector = det

                applyBeautyInternal()
                glReady = true
                Log.i(TAG, "GL pipeline READY")
                onDone(true, null)
            } catch (t: Throwable) {
                Log.e(TAG, "GL init failed", t)
                glReady = false
                destroyFiltersOnGlThread()
                onDone(false, t.message ?: t.javaClass.simpleName)
            }
        }
    }

    fun setBeauty(smooth: Float, whiten: Float, slim: Float, eye: Float) {
        this.smooth = smooth
        this.whiten = whiten
        this.slimFace = slim
        this.bigEye = eye
        val h = glHandler
        if (h != null && glReady) {
            h.post { if (glReady && !released) applyBeautyInternal() }
        }
    }

    private fun applyBeautyInternal() {
        try {
            beauty?.SetProperty("skin_smoothing", smooth)
            beauty?.SetProperty("whiteness", whiten)
            reshape?.SetProperty("thin_face", slimFace)
            reshape?.SetProperty("big_eye", bigEye)
        } catch (t: Throwable) {
            Log.w(TAG, "setBeauty props: ${t.message}")
        }
    }

    /**
     * Abre Camera2 solo si [glReady]. Los frames se copian en cam thread
     * y se procesan en GL thread.
     */
    fun startCamera(surfaceTexture: SurfaceTexture, preferFront: Boolean = true) {
        check(glReady) { "GPUPixel GL not ready — call initAsync first" }
        check(!released) { "engine released" }

        stopCameraInternal(joinCamThread = true)

        stopping = false
        acceptFrames = true

        camThread = HandlerThread("gpupixel-cam").also { it.start() }
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

        val sensorOrientation =
            characteristics.get(CameraCharacteristics.SENSOR_ORIENTATION) ?: 90
        val facing = characteristics.get(CameraCharacteristics.LENS_FACING)
        val front = facing == CameraCharacteristics.LENS_FACING_FRONT
        // Fórmula Camera2: frontal (sensor + display) % 360; trasera (sensor - display).
        // El mapa 90→270 / 270→90 dejaba el selfie de cabeza en móviles reales.
        val rotDegrees = computePreviewRotation(sensorOrientation, front)

        imageReader!!.setOnImageAvailableListener({ reader ->
            if (!acceptFrames || !glReady || stopping || released) {
                try {
                    reader.acquireLatestImage()?.close()
                } catch (_: Exception) {
                }
                return@setOnImageAvailableListener
            }
            val image = reader.acquireLatestImage() ?: return@setOnImageAvailableListener
            // Drop si GL sigue ocupado (evita cola / UAF).
            if (!glBusy.compareAndSet(false, true)) {
                image.close()
                return@setOnImageAvailableListener
            }
            var packet: RgbaPacket? = null
            try {
                packet = copyFrameToPacket(image, front, rotDegrees)
            } catch (t: Throwable) {
                Log.e(TAG, "copy frame", t)
                glBusy.set(false)
            } finally {
                try {
                    image.close()
                } catch (_: Exception) {
                }
            }
            val p = packet
            if (p == null) {
                glBusy.set(false)
                return@setOnImageAvailableListener
            }
            val gh = glHandler
            if (gh == null || !glReady || released || !acceptFrames) {
                glBusy.set(false)
                return@setOnImageAvailableListener
            }
            gh.post {
                try {
                    if (glReady && acceptFrames && !released && !stopping) {
                        processPacket(p)
                    }
                } catch (t: Throwable) {
                    Log.e(TAG, "process packet", t)
                } finally {
                    glBusy.set(false)
                }
            }
        }, camHandler)

        manager.openCamera(cameraId, object : CameraDevice.StateCallback() {
            override fun onOpened(camera: CameraDevice) {
                if (stopping || released || !acceptFrames) {
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
                                if (stopping || released || !acceptFrames) {
                                    try {
                                        session.close()
                                    } catch (_: Exception) {
                                    }
                                    return
                                }
                                captureSession = session
                                try {
                                    val req =
                                        camera.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW)
                                    req.addTarget(reader.surface)
                                    req.set(
                                        CaptureRequest.CONTROL_AF_MODE,
                                        CaptureRequest.CONTROL_AF_MODE_CONTINUOUS_PICTURE
                                    )
                                    session.setRepeatingRequest(req.build(), null, camHandler)
                                    Log.i(TAG, "camera preview repeating")
                                } catch (e: Exception) {
                                    Log.e(TAG, "setRepeatingRequest", e)
                                }
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

    /** Copia YUV→RGBA en cam thread; [image] debe cerrarse después. */
    private fun copyFrameToPacket(image: Image, front: Boolean, rotDegrees: Int): RgbaPacket? {
        val rgba = GPUPixel.YUV_420_888toRGBA(image) ?: return null
        return RgbaPacket(
            rgba = rgba,
            width = image.width,
            height = image.height,
            front = front,
            rotDegrees = rotDegrees,
        )
    }

    /** Solo hilo GL. */
    private fun processPacket(packet: RgbaPacket) {
        val src = source ?: return
        val snk = sink ?: return
        val det = detector ?: return
        val surface = previewSurface ?: return
        if (!glReady || released) return

        var rgba = packet.rgba
        var w = packet.width
        var h = packet.height
        val rot = packet.rotDegrees
        if (rot != 0) {
            rgba = GPUPixel.rotateRgbaImage(rgba, w, h, rot) ?: return
            if (rot == 90 || rot == 270) {
                val t = w
                w = h
                h = t
            }
        }

        try {
            val landmarks = det.detect(
                rgba,
                w,
                h,
                w * 4,
                FaceDetector.GPUPIXEL_MODE_FMT_VIDEO,
                FaceDetector.GPUPIXEL_FRAME_TYPE_RGBA
            )
            if (landmarks != null && landmarks.isNotEmpty()) {
                reshape?.SetProperty("face_landmark", landmarks)
            }
        } catch (t: Throwable) {
            Log.w(TAG, "detect: ${t.message}")
        }

        try {
            src.ProcessData(
                rgba,
                w,
                h,
                w * 4,
                GPUPixelSourceRawData.FRAME_TYPE_RGBA
            )
        } catch (t: Throwable) {
            Log.e(TAG, "ProcessData", t)
            return
        }

        val out = try {
            snk.GetRgbaBuffer()
        } catch (t: Throwable) {
            Log.e(TAG, "GetRgbaBuffer", t)
            null
        } ?: return

        val bw = snk.GetWidth()
        val bh = snk.GetHeight()
        if (bw <= 0 || bh <= 0 || out.size < bw * bh * 4) return

        val bitmap = Bitmap.createBitmap(bw, bh, Bitmap.Config.ARGB_8888)
        bitmap.copyPixelsFromBuffer(ByteBuffer.wrap(out))

        val drawBmp = if (packet.front) {
            val m = Matrix().apply { preScale(-1f, 1f) }
            Bitmap.createBitmap(bitmap, 0, 0, bitmap.width, bitmap.height, m, false).also {
                bitmap.recycle()
            }
        } else {
            bitmap
        }

        try {
            // Software canvas es más compatible con SurfaceTexture de Flutter.
            val canvas = try {
                surface.lockCanvas(null)
            } catch (_: Exception) {
                try {
                    surface.lockHardwareCanvas()
                } catch (e2: Exception) {
                    Log.w(TAG, "lockCanvas: ${e2.message}")
                    null
                }
            } ?: return

            try {
                canvas.drawColor(android.graphics.Color.BLACK)
                val scale = maxOf(
                    canvas.width.toFloat() / drawBmp.width,
                    canvas.height.toFloat() / drawBmp.height
                )
                val dw = drawBmp.width * scale
                val dh = drawBmp.height * scale
                val left = (canvas.width - dw) / 2f
                val top = (canvas.height - dh) / 2f
                canvas.drawBitmap(drawBmp, null, RectF(left, top, left + dw, top + dh), null)
            } finally {
                try {
                    surface.unlockCanvasAndPost(canvas)
                } catch (_: Exception) {
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "draw texture: ${e.message}")
        } finally {
            drawBmp.recycle()
        }
    }

    @Suppress("DEPRECATION")
    private fun currentDisplayRotation(): Int {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                context.display?.rotation ?: Surface.ROTATION_0
            } else {
                val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
                wm.defaultDisplay.rotation
            }
        } catch (_: Exception) {
            Surface.ROTATION_0
        }
    }

    private fun computePreviewRotation(sensorOrientation: Int, front: Boolean): Int {
        val deviceDegrees = when (currentDisplayRotation()) {
            Surface.ROTATION_0 -> 0
            Surface.ROTATION_90 -> 90
            Surface.ROTATION_180 -> 180
            Surface.ROTATION_270 -> 270
            else -> 0
        }
        return if (front) {
            (sensorOrientation + deviceDegrees) % 360
        } else {
            (sensorOrientation - deviceDegrees + 360) % 360
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

    private fun stopCameraInternal(joinCamThread: Boolean) {
        acceptFrames = false
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

        val drainDeadline = System.nanoTime() + 800_000_000L
        while (glBusy.get() && System.nanoTime() < drainDeadline) {
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

        if (joinCamThread) {
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
    }

    private fun destroyFiltersOnGlThread() {
        try {
            beauty?.Destroy()
        } catch (_: Exception) {
        }
        try {
            reshape?.Destroy()
        } catch (_: Exception) {
        }
        try {
            sink?.Destroy()
        } catch (_: Exception) {
        }
        try {
            source?.Destroy()
        } catch (_: Exception) {
        }
        try {
            detector?.destroy()
        } catch (_: Exception) {
        }
        beauty = null
        reshape = null
        sink = null
        source = null
        detector = null
        glReady = false
    }

    @Synchronized
    fun release() {
        if (released) return
        released = true
        acceptFrames = false
        stopping = true
        stopCameraInternal(joinCamThread = true)

        val done = CountDownLatch(1)
        val h = glHandler
        if (h != null) {
            h.post {
                try {
                    destroyFiltersOnGlThread()
                } finally {
                    done.countDown()
                }
            }
            try {
                done.await(3, TimeUnit.SECONDS)
            } catch (_: InterruptedException) {
            }
        } else {
            destroyFiltersOnGlThread()
        }

        val gt = glThread
        glHandler = null
        glThread = null
        if (gt != null) {
            gt.quitSafely()
            try {
                gt.join(1000)
            } catch (_: InterruptedException) {
            }
        }
        Log.i(TAG, "pipeline released")
    }
}
