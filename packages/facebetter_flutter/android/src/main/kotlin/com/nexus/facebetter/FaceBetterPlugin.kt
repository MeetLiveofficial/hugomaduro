package com.nexus.facebetter

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * MethodChannel `krimson/facebetter` + PlatformView `facebetter_preview`.
 *
 * El preview real (como https://demo.facebetter.net/) es el PlatformView GL.
 */
class FaceBetterPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    companion object {
        private const val TAG = "FaceBetterPlugin"
        const val CHANNEL = "krimson/facebetter"
        const val VIEW_TYPE = "facebetter_preview"
    }

    private lateinit var channel: MethodChannel
    private var context: Context? = null
    private var activity: Activity? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
        binding.platformViewRegistry.registerViewFactory(
            VIEW_TYPE,
            FaceBetterViewFactory(binding.binaryMessenger),
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        context = null
        FaceBetterSession.active?.dispose()
        FaceBetterSession.active = null
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
            "isAvailable" -> result.success(true)
            "setBeauty" -> {
                val host = FaceBetterSession.active
                if (host == null) {
                    result.success(null)
                    return
                }
                fun num(key: String): Float =
                    (call.argument<Number>(key))?.toFloat() ?: 0f
                host.setBeauty(
                    smooth = num("smooth"),
                    whiten = num("whiten"),
                    rosy = num("rosy"),
                    sharpen = num("sharpen"),
                    slim = num("slimFace"),
                    eye = num("bigEye"),
                    enabled = call.argument<Boolean>("enabled") ?: true,
                )
                result.success(null)
            }
            "stop" -> {
                Thread({
                    try {
                        FaceBetterSession.active?.dispose()
                    } catch (e: Exception) {
                        Log.e(TAG, "stop failed", e)
                    }
                    FaceBetterSession.active = null
                    Handler(android.os.Looper.getMainLooper()).post {
                        result.success(null)
                    }
                }, "facebetter-stop").start()
            }
            // start ya no usa Texture; el PlatformView se crea desde Dart.
            "start" -> result.success(1)
            else -> result.notImplemented()
        }
    }
}
