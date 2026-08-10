# gpupixel_flutter

Puente Flutter ↔ [GPUPixel](https://gpupixel.pixpark.net/) para Krimson.

## Pipeline nativo

```
Camera → SourceRawData → BeautyFaceFilter → FaceReshapeFilter → SinkRawData
                                                              ↓
                                                    Flutter Texture (preview)
```

- **Canal:** `krimson/gpupixel` — solo lifecycle + floats (`smooth`, `whiten`, `slimFace`, `bigEye`).
- **Frames:** nunca cruzan Dart (evita latencia / drop de FPS).

## Plataformas

| | Android | iOS |
|---|---|---|
| Lib | `android/libs/gpupixel-release.aar` (v1.3.1) | `ios/Frameworks/gpupixel.framework` |
| Preview | Camera2 → Texture | AVCapture → FlutterTexture |
| Props | `skin_smoothing`, `whiteness`, `thin_face`, `big_eye` | SetBlurAlpha / SetWhite / Slim / Eye |

## Uso Dart

```dart
final gpu = GpuPixelController();
await gpu.checkAvailable();
await gpu.start();
await gpu.setSmooth(0.7);
// Widget: GpuPixelPreview(controller: gpu)
await gpu.stop();
```

## LiveKit

En LIVE la cámara la posee LiveKit. GPUPixel se usa en **pre-live** con looks Soft/Natural/Beauty/… mapeados a los 4 floats. Para publicar frames filtrados hace falta un `ExternalVideoTrack` / capturer nativo (pendiente).

Referencias:
- Docs: https://gpupixel.pixpark.net/guide/intro
- Demo comercial: https://www.facebetter.net/

## Actualizar libs

```bash
# Android
curl -L -o gpupixel_android.zip \
  https://github.com/pixpark/gpupixel/releases/download/v1.3.1/gpupixel_android.zip
# Extraer gpupixel-release.aar → android/libs/

# iOS
curl -L -o gpupixel_ios_arm64.zip \
  https://github.com/pixpark/gpupixel/releases/download/v1.3.1/gpupixel_ios_arm64.zip
# Extraer gpupixel.framework → ios/Frameworks/
```
