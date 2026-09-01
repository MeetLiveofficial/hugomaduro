import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/model/user_model/user_model.dart';

/// True cuando el error indica token inválido/ausente (401 de sesión Laravel).
bool isSessionAuthFailure(Object error) {
  final msg = error.toString().toLowerCase();
  return msg.contains('401') ||
      msg.contains('unauthorized error') ||
      msg.contains('invalid token') ||
      msg.contains('token not provided');
}

bool hasStoredSession() {
  if (!SessionManager.instance.isLogin() ||
      !SessionManager.instance.hasAuthToken) {
    return false;
  }
  final id = SessionManager.instance.getUser()?.id;
  return id != null && id > 0;
}

/// Refresca el perfil remoto; en fallos de red devuelve el usuario en caché.
/// Lanza si el token ya no es válido.
Future<User?> refreshSessionUser({
  Duration timeout = const Duration(seconds: 15),
}) async {
  if (!hasStoredSession()) return null;
  final cached = SessionManager.instance.getUser()!;
  try {
    final fresh = await UserService.instance
        .fetchUserDetails(userId: cached.id!.toInt())
        .timeout(timeout);
    return fresh ?? cached;
  } catch (e) {
    if (isSessionAuthFailure(e)) rethrow;
    return cached;
  }
}
