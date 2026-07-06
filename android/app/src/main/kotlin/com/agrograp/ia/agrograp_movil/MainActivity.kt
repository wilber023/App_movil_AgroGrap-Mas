package com.agrograp.ia.agrograp_movil

import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// FlutterFragmentActivity (en vez de FlutterActivity): requerido por
// `local_auth` para poder mostrar el prompt biométrico nativo (MASVS-AUTH).
class MainActivity : FlutterFragmentActivity() {
    private val securityChannel = "agrograph.mas/security"

    // MASVS-STORAGE (prevención de fuga de datos sensibles): expone
    // FLAG_SECURE para bloquear capturas de pantalla/grabación en las
    // pantallas de login/registro desde el lado Dart (ver
    // core/security/screen_security.dart).
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, securityChannel)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "enableSecureScreen" -> {
                        window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    "disableSecureScreen" -> {
                        window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
