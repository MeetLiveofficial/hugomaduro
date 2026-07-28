const String baseURL = 'https://meetlive.online/';
const String apiURL = '${baseURL}api/';
const String apiKey = 'retry123';

/// WebSocket del servidor LiveKit auto-alojado.
const String liveKitWsUrl = 'wss://live.meetlive.online';

/// Firebase Auth / Firestore (legado). Chat y Live van por Laravel.
const bool useFirebase = false;

/// ESTRICTO: sin compartir perfil/contenido ni descargas a galería/externo.
const bool allowContentSharing = false;
const bool allowContentDownload = false;

// If you change this topic you also change backend .env file
String notificationTopic = "krimson";

String revenueCatAndroidApiKey = "______"; // revenueCat android api
String revenueCatAppleApiKey = "________"; // revenueCat apple api
