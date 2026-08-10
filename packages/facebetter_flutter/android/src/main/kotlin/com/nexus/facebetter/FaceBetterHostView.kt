package com.nexus.facebetter

import android.content.Context
import android.util.Log
import android.view.ViewGroup
import android.widget.FrameLayout
import com.pixpark.facebetter.BeautyEffectEngine
import com.pixpark.facebetter.BeautyParams.BasicParam
import com.pixpark.facebetter.BeautyParams.ReshapeParam
import com.pixpark.facebetter.ImageFrame

/**
 * Host nativo igual al [demo FaceBetter](https://demo.facebetter.net/):
 * Camera2 → ImageFrame → processImage (GL thread) → GLSurfaceView I420.
 */
class FaceBetterHostView(
    context: Context,
    private val appId: String,
    private val appKey: String,
) : FrameLayout(context), GLI420Renderer.FrameProvider {

    companion object {
        private const val TAG = "FaceBetterHostView"
    }

    private val renderer: GLI420Renderer = GLI420Renderer(context)
    private var camera: CameraHandler? = null
    private var beauty: BeautyEffectEngine? = null

    private val frameLock = Any()
    private var latestFrame: ImageFrame? = null

    init {
        layoutParams = LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.MATCH_PARENT,
        )
        renderer.setFrameProvider(this)
        addView(
            renderer,
            LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            ),
        )
        initEngine()
        startCamera()
    }

    private fun initEngine() {
        val log = BeautyEffectEngine.LogConfig()
        log.consoleEnabled = true
        log.fileEnabled = false
        log.level = BeautyEffectEngine.LogLevel.INFO
        BeautyEffectEngine.setLogConfig(log)

        val config = BeautyEffectEngine.EngineConfig()
        config.appId = appId
        config.appKey = appKey
        beauty = BeautyEffectEngine(context, config)
        setBeauty(0.55f, 0.35f, 0.15f, 0.2f, 0.15f, 0.1f, true)
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
        val eng = beauty ?: return
        if (!enabled) {
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
        eng.setBeautyParam(ReshapeParam.FACE_THIN, slim.coerceIn(0f, 1f))
        eng.setBeautyParam(ReshapeParam.EYE_SIZE, eye.coerceIn(0f, 1f))
    }

    private fun startCamera() {
        val cam = CameraHandler(context)
        camera = cam
        cam.setFrameCallback(CameraHandler.FrameCallback { image, _ ->
            try {
                val planes = image.planes
                if (planes.size < 3) return@FrameCallback
                val input = ImageFrame.createWithAndroid420(
                    image.width,
                    image.height,
                    planes[0].buffer,
                    planes[0].rowStride,
                    planes[1].buffer,
                    planes[1].rowStride,
                    planes[2].buffer,
                    planes[2].rowStride,
                    planes[1].pixelStride,
                ) ?: return@FrameCallback

                if (cam.isFrontFacing) {
                    input.rotate(ImageFrame.Rotation.ROTATION_270)
                } else {
                    input.rotate(ImageFrame.Rotation.ROTATION_90)
                }
                input.type = ImageFrame.FrameType.VIDEO

                synchronized(frameLock) {
                    latestFrame?.release()
                    latestFrame = input
                }
                renderer.requestRender()
            } catch (t: Throwable) {
                Log.e(TAG, "onFrame", t)
            }
        })
        cam.startCamera()
    }

    override fun getCurrentFrame(): ImageFrame? {
        synchronized(frameLock) {
            val eng = beauty ?: return null
            val input = latestFrame ?: return null
            return try {
                eng.processImage(input)
            } catch (t: Throwable) {
                Log.e(TAG, "processImage", t)
                null
            }
        }
    }

    override fun releaseFrame(frame: ImageFrame?) {
        try {
            frame?.release()
        } catch (_: Exception) {
        }
    }

    fun dispose() {
        try {
            camera?.stopCamera()
        } catch (_: Exception) {
        }
        camera = null
        synchronized(frameLock) {
            try {
                latestFrame?.release()
            } catch (_: Exception) {
            }
            latestFrame = null
        }
        try {
            beauty?.release()
        } catch (_: Exception) {
        }
        beauty = null
        try {
            renderer.setRenderingEnabled(false)
        } catch (_: Exception) {
        }
    }
}
