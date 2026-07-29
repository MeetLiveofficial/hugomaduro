/// Face filters (MediaPipe + CustomPainter + LiveKit bridge).
///
/// ```
/// lib/screen/face_filters/
/// ├── models/          FaceFilterId, FaceMeshFrame, landmarks
/// ├── services/
/// │   ├── face_camera_service*.dart      camera ImageStream
/// │   ├── face_mesh_engine*.dart         mediapipe_face_mesh
/// │   ├── face_filter_pipeline.dart      throttle + wiring
/// │   ├── face_filter_catalog_store.dart sync API + cache
/// │   └── livekit_face_filter_bridge.dart LiveKit integration
/// └── widgets/         preview, overlay, painter, carousel
/// ```
library;

export 'models/face_filter_effect.dart';
export 'models/face_mesh_frame.dart';
export 'services/face_camera_service.dart';
export 'services/face_filter_catalog_store.dart';
export 'services/face_filter_pipeline.dart';
export 'services/face_mesh_engine.dart';
export 'services/livekit_face_filter_bridge.dart';
export 'widgets/beauty_camera_preview.dart';
export 'widgets/face_camera_preview_stack.dart';
export 'widgets/face_filter_carousel.dart';
export 'widgets/face_filter_overlay.dart';
export 'widgets/face_filter_painter.dart';
