package com.nexus.gpupixel

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.view.TextureRegistry

/**
 * MethodChannel `krimson/gpupixel`
 *
 * start: Init GL (async) → Ready → Camera2 → textureId
 * Frames nunca cruzan el canal.
 */
class GpuPixelPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    companion object {
        private const val TAG = "GpuPixelPlugin"
        const val CHANNEL = "krimson/gpupixel"
    }

    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var activity: Activity? = null
    private var textures: TextureRegistry? = null
    private var textureEntry: TextureRegistry.SurfaceTextureEntry? = null
    private var engine: GpuPixelEngine? = null
    private val mainHandler = Handler(Looper.getMainLooper())
    @Volatile
    private var starting = false

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        textures = binding.textureRegistry
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        releaseEngine()
        context = null
        textures = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isAvailable" -> {
                try {
                    Class.forName("com.pixpark.gpupixel.GPUPixel")
                    result.success(true)
                } catch (e: Throwable) {
                    Log.e(TAG, "GPUPixel not loadable", e)
                    result.success(false)
                }
            }
            "start" -> start(call, result)
            "setBeauty" -> setBeauty(call, result)
            "stop" -> {
                Thread({
                    try {
                        releaseEngine()
                    } catch (e: Exception) {
                        Log.e(TAG, "stop failed", e)
                    }
                    mainHandler.post { result.success(null) }
                }, "gpupixel-stop").start()
            }
            else -> result.notImplemented()
        }
    }

    private fun start(call: MethodCall, result: Result) {
        val ctx = context
        val registry = textures
        if (ctx == null || registry == null) {
            result.error("NO_CONTEXT", "Plugin not attached", null)
            return
        }
        if (starting) {
            result.error("BUSY", "GPUPixel start already in progress", null)
            return
        }
        starting = true
        val front = call.argument<Boolean>("frontCamera") ?: true

        // Trabajo pesado fuera del main; texture registry se toca en main.
        Thread({
            try {
                releaseEngine()

                val entryLatch = CountDownLatchBox()
                var entry: TextureRegistry.SurfaceTextureEntry? = null
                var entryError: Exception? = null
                mainHandler.post {
                    try {
                        entry = registry.createSurfaceTexture()
                        textureEntry = entry
                    } catch (e: Exception) {
                        entryError = e
                    }
                    entryLatch.countDown()
                }
                entryLatch.await(5)
                val tex = entry
                if (tex == null) {
                    starting = false
                    mainHandler.post {
                        result.error(
                            "TEXTURE",
                            entryError?.message ?: "createSurfaceTexture failed",
                            null
                        )
                    }
                    return@Thread
                }

                val eng = GpuPixelEngine(ctx)
                engine = eng

                val initLatch = CountDownLatchBox()
                var initOk = false
                var initErr: String? = null
                eng.initAsync { ok, err ->
                    initOk = ok
                    initErr = err
                    initLatch.countDown()
                }
                initLatch.await(8)

                if (!initOk) {
                    releaseEngine()
                    starting = false
                    mainHandler.post {
                        result.error("INIT_FAILED", initErr ?: "GPUPixel Init failed", null)
                    }
                    return@Thread
                }

                try {
                    eng.startCamera(tex.surfaceTexture(), front)
                } catch (e: Exception) {
                    Log.e(TAG, "startCamera failed", e)
                    releaseEngine()
                    starting = false
                    mainHandler.post {
                        result.error("CAMERA", e.message, null)
                    }
                    return@Thread
                }

                // Pequeña pausa: primer frame / openCamera async.
                try {
                    Thread.sleep(120)
                } catch (_: InterruptedException) {
                }

                starting = false
                val id = tex.id().toInt()
                Log.i(TAG, "start OK textureId=$id")
                mainHandler.post { result.success(id) }
            } catch (e: SecurityException) {
                releaseEngine()
                starting = false
                mainHandler.post {
                    result.error("PERMISSION", "Camera permission required", e.message)
                }
            } catch (e: Exception) {
                Log.e(TAG, "start failed", e)
                releaseEngine()
                starting = false
                mainHandler.post {
                    result.error("START_FAILED", e.message, null)
                }
            }
        }, "gpupixel-start").start()
    }

    private fun setBeauty(call: MethodCall, result: Result) {
        val eng = engine
        if (eng == null) {
            result.success(null)
            return
        }
        fun num(key: String): Float =
            (call.argument<Number>(key))?.toFloat() ?: 0f

        eng.setBeauty(
            smooth = num("smooth"),
            whiten = num("whiten"),
            slim = num("slimFace"),
            eye = num("bigEye"),
        )
        result.success(null)
    }

    private fun releaseEngine() {
        try {
            engine?.release()
        } catch (_: Exception) {
        }
        engine = null
        try {
            mainHandler.post {
                try {
                    textureEntry?.release()
                } catch (_: Exception) {
                }
                textureEntry = null
            }
            // Si ya estamos en background tras stop, esperar un poco a release texture.
            Thread.sleep(50)
        } catch (_: Exception) {
            try {
                textureEntry?.release()
            } catch (_: Exception) {
            }
            textureEntry = null
        }
    }

    /** Latch simple sin importar java.util en cada call site. */
    private class CountDownLatchBox {
        private val latch = java.util.concurrent.CountDownLatch(1)
        fun countDown() = latch.countDown()
        fun await(seconds: Long) {
            try {
                latch.await(seconds, java.util.concurrent.TimeUnit.SECONDS)
            } catch (_: InterruptedException) {
            }
        }
    }
}
