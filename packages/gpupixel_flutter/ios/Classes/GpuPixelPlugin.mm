#import <Flutter/Flutter.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreVideo/CoreVideo.h>
#include <cstring>
#include <vector>

#if __has_include(<gpupixel/gpupixel.h>)
#import <gpupixel/gpupixel.h>
#define KRIMSON_GPUPIXEL 1
#else
#define KRIMSON_GPUPIXEL 0
#endif

@interface GpuPixelFlutterTexture : NSObject <FlutterTexture>
@property(nonatomic, assign) CVPixelBufferRef latest;
@end

@implementation GpuPixelFlutterTexture
- (CVPixelBufferRef)copyPixelBuffer {
  if (!_latest) return NULL;
  CVPixelBufferRetain(_latest);
  return _latest;
}
- (void)dealloc {
  if (_latest) {
    CFRelease(_latest);
    _latest = NULL;
  }
}
@end

@interface GpuPixelEngine : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate>
@property(nonatomic, strong) GpuPixelFlutterTexture *texture;
@property(nonatomic, weak) NSObject<FlutterTextureRegistry> *registry;
@property(nonatomic, assign) int64_t textureId;
- (BOOL)start:(NSError **)error;
- (void)setSmooth:(float)s whiten:(float)w slim:(float)slim eye:(float)eye;
- (void)stop;
@end

@implementation GpuPixelEngine {
  AVCaptureSession *_session;
  float _smooth, _whiten, _slim, _eye;
  BOOL _busy;
#if KRIMSON_GPUPIXEL
  std::shared_ptr<gpupixel::SourceRawData> _source;
  std::shared_ptr<gpupixel::BeautyFaceFilter> _beauty;
  std::shared_ptr<gpupixel::FaceReshapeFilter> _reshape;
  std::shared_ptr<gpupixel::SinkRawData> _sink;
  std::shared_ptr<gpupixel::FaceDetector> _detector;
#endif
}

- (instancetype)init {
  self = [super init];
  if (self) {
    _smooth = 0.55f;
    _whiten = 0.25f;
    _slim = 0;
    _eye = 0;
    _busy = NO;
    _texture = [[GpuPixelFlutterTexture alloc] init];
  }
  return self;
}

- (void)ensurePipeline {
#if KRIMSON_GPUPIXEL
  if (_source) return;
  NSString *fw = [[NSBundle mainBundle].privateFrameworksPath
      stringByAppendingPathComponent:@"gpupixel.framework"];
  if ([[NSFileManager defaultManager] fileExistsAtPath:fw]) {
    gpupixel::GPUPixel::SetResourcePath(fw.UTF8String);
  }
  _source = gpupixel::SourceRawData::Create();
  _beauty = gpupixel::BeautyFaceFilter::Create();
  _reshape = gpupixel::FaceReshapeFilter::Create();
  _sink = gpupixel::SinkRawData::Create();
  _detector = gpupixel::FaceDetector::Create();
  _source->AddSink(_beauty)->AddSink(_reshape)->AddSink(_sink);
  [self applyBeauty];
#endif
}

- (void)applyBeauty {
#if KRIMSON_GPUPIXEL
  if (_beauty) {
    _beauty->SetBlurAlpha(_smooth);
    _beauty->SetWhite(_whiten);
  }
  if (_reshape) {
    _reshape->SetFaceSlimLevel(_slim);
    _reshape->SetEyeZoomLevel(_eye);
  }
#endif
}

- (void)setSmooth:(float)s whiten:(float)w slim:(float)slim eye:(float)eye {
  _smooth = s;
  _whiten = w;
  _slim = slim;
  _eye = eye;
  [self applyBeauty];
}

- (BOOL)start:(NSError **)error {
#if !KRIMSON_GPUPIXEL
  if (error) {
    *error = [NSError errorWithDomain:@"gpupixel" code:1
                             userInfo:@{NSLocalizedDescriptionKey : @"GPUPixel missing"}];
  }
  return NO;
#else
  [self ensurePipeline];
  _session = [[AVCaptureSession alloc] init];
  _session.sessionPreset = AVCaptureSessionPreset1280x720;

  AVCaptureDevice *device =
      [AVCaptureDevice defaultDeviceWithDeviceType:AVCaptureDeviceTypeBuiltInWideAngleCamera
                                         mediaType:AVMediaTypeVideo
                                          position:AVCaptureDevicePositionFront];
  if (!device) {
    if (error) {
      *error = [NSError errorWithDomain:@"gpupixel" code:2
                               userInfo:@{NSLocalizedDescriptionKey : @"No camera"}];
    }
    return NO;
  }
  NSError *err = nil;
  AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&err];
  if (err) {
    if (error) *error = err;
    return NO;
  }
  if ([_session canAddInput:input]) [_session addInput:input];

  AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
  output.videoSettings =
      @{(id)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};
  output.alwaysDiscardsLateVideoFrames = YES;
  dispatch_queue_t q = dispatch_queue_create("gpupixel.cam", DISPATCH_QUEUE_SERIAL);
  [output setSampleBufferDelegate:self queue:q];
  if ([_session canAddOutput:output]) [_session addOutput:output];

  AVCaptureConnection *conn = [output connectionWithMediaType:AVMediaTypeVideo];
  if ([conn isVideoOrientationSupported]) {
    conn.videoOrientation = AVCaptureVideoOrientationPortrait;
  }
  if ([conn isVideoMirroringSupported]) {
    conn.videoMirrored = YES;
  }

  dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
    [self->_session startRunning];
  });
  return YES;
#endif
}

- (void)stop {
  [_session stopRunning];
  _session = nil;
  if (_registry && _textureId != 0) {
    [_registry unregisterTexture:_textureId];
  }
  _textureId = 0;
#if KRIMSON_GPUPIXEL
  _source.reset();
  _beauty.reset();
  _reshape.reset();
  _sink.reset();
  _detector.reset();
#endif
}

#if KRIMSON_GPUPIXEL
- (void)captureOutput:(AVCaptureOutput *)output
    didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
           fromConnection:(AVCaptureConnection *)connection {
  if (_busy) return;
  _busy = YES;

  CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
  if (!pixelBuffer) {
    _busy = NO;
    return;
  }

  CVPixelBufferLockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);
  uint8_t *base = (uint8_t *)CVPixelBufferGetBaseAddress(pixelBuffer);
  int width = (int)CVPixelBufferGetWidth(pixelBuffer);
  int height = (int)CVPixelBufferGetHeight(pixelBuffer);
  size_t stride = CVPixelBufferGetBytesPerRow(pixelBuffer);

  std::vector<uint8_t> bgra((size_t)width * height * 4);
  if ((int)stride == width * 4) {
    memcpy(bgra.data(), base, bgra.size());
  } else {
    for (int y = 0; y < height; y++) {
      memcpy(bgra.data() + y * width * 4, base + y * stride, (size_t)width * 4);
    }
  }
  CVPixelBufferUnlockBaseAddress(pixelBuffer, kCVPixelBufferLock_ReadOnly);

  auto landmarks = _detector->Detect(
      bgra.data(), width, height, width * 4,
      GPUPIXEL_MODE_FMT_VIDEO, GPUPIXEL_FRAME_TYPE_BGRA);
  if (!landmarks.empty()) {
    _reshape->SetFaceLandmarks(landmarks);
  }
  _source->ProcessData(bgra.data(), width, height, width * 4, GPUPIXEL_FRAME_TYPE_BGRA);

  const uint8_t *out = _sink->GetRgbaBuffer();
  int ow = _sink->GetWidth();
  int oh = _sink->GetHeight();
  if (!out || ow <= 0 || oh <= 0) {
    _busy = NO;
    return;
  }

  NSDictionary *attrs = @{
    (id)kCVPixelBufferCGImageCompatibilityKey : @YES,
    (id)kCVPixelBufferCGBitmapContextCompatibilityKey : @YES,
    (id)kCVPixelBufferIOSurfacePropertiesKey : @{},
  };
  CVPixelBufferRef outBuf = NULL;
  CVPixelBufferCreate(kCFAllocatorDefault, ow, oh, kCVPixelFormatType_32BGRA,
                      (__bridge CFDictionaryRef)attrs, &outBuf);
  if (!outBuf) {
    _busy = NO;
    return;
  }
  CVPixelBufferLockBaseAddress(outBuf, 0);
  uint8_t *dst = (uint8_t *)CVPixelBufferGetBaseAddress(outBuf);
  size_t dstStride = CVPixelBufferGetBytesPerRow(outBuf);
  for (int y = 0; y < oh; y++) {
    for (int x = 0; x < ow; x++) {
      const uint8_t *s = out + (y * ow + x) * 4;
      uint8_t *d = dst + y * dstStride + x * 4;
      d[0] = s[2];
      d[1] = s[1];
      d[2] = s[0];
      d[3] = s[3];
    }
  }
  CVPixelBufferUnlockBaseAddress(outBuf, 0);

  if (_texture.latest) CFRelease(_texture.latest);
  _texture.latest = outBuf;
  [_registry textureFrameAvailable:_textureId];
  _busy = NO;
}
#endif

@end

@interface GpuPixelPlugin : NSObject <FlutterPlugin>
@end

@implementation GpuPixelPlugin {
  FlutterMethodChannel *_channel;
  NSObject<FlutterTextureRegistry> *_textures;
  GpuPixelEngine *_engine;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:@"krimson/gpupixel"
                                  binaryMessenger:[registrar messenger]];
  GpuPixelPlugin *instance = [[GpuPixelPlugin alloc] init];
  instance->_textures = [registrar textures];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result {
  if ([@"isAvailable" isEqualToString:call.method]) {
#if KRIMSON_GPUPIXEL
    result(@YES);
#else
    result(@NO);
#endif
    return;
  }
  if ([@"start" isEqualToString:call.method]) {
#if KRIMSON_GPUPIXEL
    [_engine stop];
    _engine = [[GpuPixelEngine alloc] init];
    _engine.registry = _textures;
    int64_t texId = [_textures registerTexture:_engine.texture];
    _engine.textureId = texId;
    NSError *err = nil;
    if (![_engine start:&err]) {
      result([FlutterError errorWithCode:@"START_FAILED"
                                 message:err.localizedDescription
                                 details:nil]);
      return;
    }
    result(@(texId));
#else
    result([FlutterError errorWithCode:@"UNAVAILABLE"
                               message:@"GPUPixel not linked"
                               details:nil]);
#endif
    return;
  }
  if ([@"setBeauty" isEqualToString:call.method]) {
    NSDictionary *args = call.arguments;
    [_engine setSmooth:[args[@"smooth"] floatValue]
                whiten:[args[@"whiten"] floatValue]
                  slim:[args[@"slimFace"] floatValue]
                   eye:[args[@"bigEye"] floatValue]];
    result(nil);
    return;
  }
  if ([@"stop" isEqualToString:call.method]) {
    [_engine stop];
    _engine = nil;
    result(nil);
    return;
  }
  result(FlutterMethodNotImplemented);
}

@end
