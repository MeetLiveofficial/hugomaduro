import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/model/chat/message_data.dart';
import 'package:krimson/screen/chat_screen/chat_screen_controller.dart';
import 'package:krimson/screen/chat_screen/widget/chat_media_helpers.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';

/// Used by chat_screen_controller for waveform sample width.
const double wavesWidth = 200;

class ChatAudioMessage extends StatelessWidget {
  final MessageData message;
  final ChatScreenController controller;

  const ChatAudioMessage({
    super.key,
    required this.message,
    required this.controller,
  });

  List<double> _parseWaveData() {
    final raw = message.waveData?.trim();
    if (raw == null || raw.isEmpty) return const [];
    return raw
        .split(',')
        .map((e) => double.tryParse(e.trim()) ?? 0.0)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isMe = message.userId == controller.myUser?.id;
    final waves = _parseWaveData();
    final accent = themeAccentSolid(context);

    return ChatBubble(
      isMe: isMe,
      child: Obx(() {
        final pv = controller.playerValue.value;
        final msgId = message.id ?? 0;
        final isThis = pv.id == msgId;
        final isPlaying = isThis && pv.state == PlayerState.playing;

        return InkWell(
          onTap: () => controller.toggleAudioPlayback(message),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                if (isThis && waves.isNotEmpty)
                  AudioFileWaveforms(
                    size: const Size(wavesWidth * 0.72, 34),
                    playerController: controller.playerController,
                    waveformData: waves,
                    waveformType: WaveformType.fitWidth,
                    playerWaveStyle: playerWaveStyle,
                    enableSeekGesture: false,
                  )
                else if (waves.isNotEmpty)
                  SizedBox(
                    width: wavesWidth * 0.72,
                    height: 34,
                    child: CustomPaint(
                      painter: _StaticWavePainter(
                        waves,
                        isThis ? accent : textLightGrey(context),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: wavesWidth * 0.55,
                    child: Text(
                      'Voice message',
                      style: TextStyleCustom.outFitRegular400(
                        color: textDarkGrey(context),
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _StaticWavePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _StaticWavePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final count = data.length.clamp(1, 80);
    final step = size.width / count;
    final mid = size.height / 2;
    final sampleStep = (data.length / count).ceil().clamp(1, data.length);
    for (var i = 0; i < count; i++) {
      final idx = (i * sampleStep).clamp(0, data.length - 1);
      final amp = data[idx].abs();
      final h = (amp > 1 ? (amp / 100).clamp(0.08, 1.0) : amp.clamp(0.08, 1.0)) *
          mid;
      final x = i * step + step / 2;
      canvas.drawLine(Offset(x, mid - h), Offset(x, mid + h), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StaticWavePainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.color != color;
}
