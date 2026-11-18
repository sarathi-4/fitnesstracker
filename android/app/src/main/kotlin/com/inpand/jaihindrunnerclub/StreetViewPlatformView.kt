package com.inpand.jaihindrunnerclub

import android.app.Activity
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.view.View
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import com.google.android.gms.maps.StreetViewPanorama
import com.google.android.gms.maps.StreetViewPanoramaView
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.StreetViewPanoramaCamera
import com.google.android.gms.maps.model.StreetViewSource
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class StreetViewPlatformViewFactory(
    private val activity: Activity,
    private val lifecycle: Lifecycle,
    private val messenger: BinaryMessenger
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val creationParams = args as? Map<String, Any?> ?: emptyMap()
        return StreetViewPlatformView(activity, lifecycle, messenger, viewId, creationParams)
    }
}

class StreetViewPlatformView(
    private val activity: Activity,
    private val lifecycle: Lifecycle,
    messenger: BinaryMessenger,
    viewId: Int,
    creationParams: Map<String, Any?>
) : PlatformView, MethodChannel.MethodCallHandler, DefaultLifecycleObserver {

    private val streetView: StreetViewPanoramaView = StreetViewPanoramaView(activity)
    private val channel = MethodChannel(messenger, "com.inpand.jaihindrunnerclub/street_view_$viewId")
    private val mainHandler = Handler(Looper.getMainLooper())
    private var panorama: StreetViewPanorama? = null
    private var isDisposed = false

    private var pendingLat: Double = (creationParams["lat"] as? Number)?.toDouble() ?: 10.6726
    private var pendingLng: Double = (creationParams["lng"] as? Number)?.toDouble() ?: 78.1189
    private var pendingBearing: Float = (creationParams["bearing"] as? Number)?.toFloat() ?: 0f
    private var pendingRadius: Int = (creationParams["radius"] as? Number)?.toInt() ?: 250

    init {
        channel.setMethodCallHandler(this)
        try {
            streetView.onCreate(null)
            streetView.onStart()
            streetView.onResume()
        } catch (_: Exception) {
        }
        lifecycle.addObserver(this)

        streetView.getStreetViewPanoramaAsync { pano ->
            if (isDisposed) return@getStreetViewPanoramaAsync
            panorama = pano

            pano.isUserNavigationEnabled = true
            pano.isPanningGesturesEnabled = true
            pano.isZoomGesturesEnabled = true
            pano.isStreetNamesEnabled = true

            pano.setOnStreetViewPanoramaChangeListener { location ->
                if (isDisposed) return@setOnStreetViewPanoramaChangeListener
                val isAvailable = location != null && location.panoId != null
                val payload = HashMap<String, Any?>()
                payload["available"] = isAvailable
                if (isAvailable && location != null) {
                    payload["lat"] = location.position.latitude
                    payload["lng"] = location.position.longitude
                    payload["panoId"] = location.panoId
                }
                mainHandler.post {
                    if (!isDisposed) {
                        channel.invokeMethod("onAvailabilityChanged", payload)
                    }
                }
            }

            pano.setOnStreetViewPanoramaCameraChangeListener { camera ->
                if (isDisposed) return@setOnStreetViewPanoramaCameraChangeListener
                mainHandler.post {
                    if (!isDisposed) {
                        channel.invokeMethod(
                            "onCameraBearingChanged",
                            mapOf("bearing" to camera.bearing.toDouble())
                        )
                    }
                }
            }

            applyPosition(pendingLat, pendingLng, pendingBearing, pendingRadius)
        }
    }

    private fun applyPosition(lat: Double, lng: Double, bearing: Float?, radius: Int) {
        val pano = panorama ?: return
        try {
            pano.setPosition(LatLng(lat, lng), radius, StreetViewSource.OUTDOOR)
            if (bearing != null) {
                val currentCam = pano.panoramaCamera
                val updatedCam = StreetViewPanoramaCamera.Builder(currentCam)
                    .bearing(bearing)
                    .tilt(0f)
                    .build()
                pano.animateTo(updatedCam, 500L)
            }
        } catch (_: Exception) {
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (isDisposed) {
            result.success(null)
            return
        }
        when (call.method) {
            "updatePosition" -> {
                val lat = (call.argument<Number>("lat"))?.toDouble()
                val lng = (call.argument<Number>("lng"))?.toDouble()
                val bearing = (call.argument<Number>("bearing"))?.toFloat()
                val radius = (call.argument<Number>("radius"))?.toInt() ?: 250
                if (lat != null && lng != null) {
                    pendingLat = lat
                    pendingLng = lng
                    if (bearing != null) pendingBearing = bearing
                    pendingRadius = radius
                    applyPosition(lat, lng, bearing, radius)
                }
                result.success(null)
            }
            "setBearing" -> {
                val bearing = (call.argument<Number>("bearing"))?.toFloat() ?: 0f
                panorama?.let { pano ->
                    val cam = StreetViewPanoramaCamera.Builder(pano.panoramaCamera)
                        .bearing(bearing)
                        .tilt(0f)
                        .build()
                    pano.animateTo(cam, 450L)
                }
                result.success(null)
            }
            "zoomIn" -> {
                panorama?.let { pano ->
                    val nextZoom = (pano.panoramaCamera.zoom + 0.6f).coerceAtMost(3.0f)
                    val cam = StreetViewPanoramaCamera.Builder(pano.panoramaCamera)
                        .zoom(nextZoom)
                        .build()
                    pano.animateTo(cam, 300L)
                }
                result.success(null)
            }
            "zoomOut" -> {
                panorama?.let { pano ->
                    val nextZoom = (pano.panoramaCamera.zoom - 0.6f).coerceAtLeast(0.0f)
                    val cam = StreetViewPanoramaCamera.Builder(pano.panoramaCamera)
                        .zoom(nextZoom)
                        .build()
                    pano.animateTo(cam, 300L)
                }
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    override fun getView(): View = streetView

    override fun onStart(owner: LifecycleOwner) {
        if (!isDisposed) {
            try { streetView.onStart() } catch (_: Exception) {}
        }
    }

    override fun onResume(owner: LifecycleOwner) {
        if (!isDisposed) {
            try { streetView.onResume() } catch (_: Exception) {}
        }
    }

    override fun onPause(owner: LifecycleOwner) {
        if (!isDisposed) {
            try { streetView.onPause() } catch (_: Exception) {}
        }
    }

    override fun onStop(owner: LifecycleOwner) {
        if (!isDisposed) {
            try { streetView.onStop() } catch (_: Exception) {}
        }
    }

    override fun dispose() {
        if (isDisposed) return
        isDisposed = true
        lifecycle.removeObserver(this)
        channel.setMethodCallHandler(null)
        try {
            streetView.onPause()
            streetView.onStop()
            streetView.onDestroy()
        } catch (_: Exception) {
        }
    }
}
