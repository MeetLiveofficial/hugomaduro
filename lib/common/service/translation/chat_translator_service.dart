/// Traducción on-device de chat.
///
/// - Móvil (Android/iOS): Google ML Kit via [chat_translator_service_io.dart]
/// - Web / desktop sin ML Kit: no-op via [chat_translator_service_stub.dart]
library;

export 'chat_translator_service_stub.dart'
    if (dart.library.io) 'chat_translator_service_io.dart';
