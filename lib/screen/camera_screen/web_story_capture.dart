import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:krimson/common/functions/media_picker_helper.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/post_service.dart';
import 'package:krimson/common/service/utils/params.dart';
import 'package:krimson/common/widget/custom_back_button.dart';
import 'package:krimson/screen/face_filters/services/face_camera_service.dart';
import 'package:krimson/screen/face_filters/widgets/web_camera_preview.dart';
import 'package:krimson/screen/feed_screen/feed_screen_controller.dart';
import 'package:krimson/screen/profile_screen/profile_screen_controller.dart';
import 'package:krimson/utilities/app_res.dart';
import 'package:krimson/utilities/asset_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';

/// Historia en el navegador: cámara (getUserMedia) o foto de la galería.
class WebStoryCapture extends StatefulWidget {
  const WebStoryCapture({super.key});

  @override
  State<WebStoryCapture> createState() => _WebStoryCaptureState();
}

class _WebStoryCaptureState extends State<WebStoryCapture> {
  final FaceCameraService _camera = FaceCameraService();
  Uint8List? _preview;
  bool _starting = true;
  bool _busy = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    _startCamera();
  }

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  Future<void> _startCamera() async {
    setState(() {
      _starting = true;
      _cameraError = null;
    });
    final ok = await _camera.initialize();
    if (!mounted) return;
    setState(() {
      _starting = false;
      _cameraError = ok
          ? null
          : 'No se pudo encender la cámara. Permite el acceso en el navegador o sube una foto.';
    });
  }

  Future<void> _pickGallery() async {
    final file =
        await MediaPickerHelper.shared.pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted || bytes.isEmpty) return;
    setState(() => _preview = bytes);
  }

  Future<void> _capture() async {
    final file = await _camera.takePicture();
    if (file == null) {
      _toast('No se pudo tomar la foto. Revisa el permiso de la cámara.');
      return;
    }
    final bytes = await file.readAsBytes();
    if (!mounted || bytes.isEmpty) return;
    setState(() => _preview = bytes);
  }

  Future<void> _publish() async {
    final bytes = _preview;
    if (bytes == null || _busy) return;
    setState(() => _busy = true);
    try {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      final upload = XFile.fromData(
        bytes,
        name: 'story_$stamp.jpg',
        mimeType: 'image/jpeg',
      );
      final response = await PostService.instance.createStory(
        files: {
          Params.content: [upload],
        },
        param: {
          Params.type: 0,
          Params.duration: AppRes.storyImageAndTextDuration,
        },
      );
      if (response.status == true && response.data != null) {
        final story = response.data!;
        story.user = SessionManager.instance.getUser();
        if (Get.isRegistered<FeedScreenController>()) {
          Get.find<FeedScreenController>().onAddStory(story);
        }
        if (Get.isRegistered<ProfileScreenController>(
            tag: ProfileScreenController.tag)) {
          Get.find<ProfileScreenController>(tag: ProfileScreenController.tag)
              .onAddStory(story);
        }
        Get.back();
        _toast('Historia publicada');
        return;
      }
      _toast(response.message ?? 'No se pudo publicar la historia');
    } catch (e) {
      _toast('No se pudo publicar la historia');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String message) {
    Get.snackbar(
      'Story',
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewType = _camera.webViewType;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_preview != null)
            Image.memory(_preview!, fit: BoxFit.cover)
          else if (viewType != null && viewType.isNotEmpty)
            WebCameraPreview(viewType: viewType)
          else
            const ColoredBox(color: Colors.black),
          if (_starting)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: CustomBackButton(
                    padding: const EdgeInsets.all(15),
                    color: Colors.white,
                    onTap: _preview != null
                        ? () => setState(() => _preview = null)
                        : null,
                  ),
                ),
                if (_cameraError != null && _preview == null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Text(
                      _cameraError!,
                      textAlign: TextAlign.center,
                      style: TextStyleCustom.outFitRegular400(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                const Spacer(),
                if (_preview == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _GalleryButton(onTap: _busy ? null : _pickGallery),
                        _Shutter(onTap: _busy || _starting ? null : _capture),
                        const SizedBox(width: 52, height: 52),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _busy
                                ? null
                                : () => setState(() => _preview = null),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Colors.white),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Repetir'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _busy ? null : _publish,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFFF4D9A),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(_busy ? 'Publicando…' : 'Publicar'),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryButton extends StatelessWidget {
  const _GalleryButton({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(AssetRes.icUploadGallery, fit: BoxFit.cover),
      ),
    );
  }
}

class _Shutter extends StatelessWidget {
  const _Shutter({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: Center(
          child: Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
