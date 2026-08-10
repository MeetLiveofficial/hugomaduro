package com.nexus.facebetter

import android.content.Context
import android.view.View
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class FaceBetterViewFactory(
    private val messenger: BinaryMessenger,
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val map = args as? Map<*, *>
        val appId = map?.get("appId") as? String ?: ""
        val appKey = map?.get("appKey") as? String ?: ""
        return FaceBetterPlatformView(context, messenger, viewId, appId, appKey)
    }
}

class FaceBetterPlatformView(
    context: Context,
    messenger: BinaryMessenger,
    viewId: Int,
    appId: String,
    appKey: String,
) : PlatformView {
    private val host = FaceBetterHostView(context, appId, appKey)
    private val channel = MethodChannel(messenger, "krimson/facebetter/view_$viewId")

    init {
        FaceBetterSession.active = host
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "setBeauty" -> {
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
                else -> result.notImplemented()
            }
        }
    }

    override fun getView(): View = host

    override fun dispose() {
        channel.setMethodCallHandler(null)
        if (FaceBetterSession.active === host) {
            FaceBetterSession.active = null
        }
        host.dispose()
    }
}

object FaceBetterSession {
    @JvmField
    var active: FaceBetterHostView? = null
}
