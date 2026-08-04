import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:krimson/common/manager/logger.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/user_service.dart';
import 'package:krimson/model/user_model/user_model.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:url_launcher/url_launcher.dart';

/// Verificación de identidad (una sola vez) antes de solicitar un retiro.
class KycVerificationScreen extends StatefulWidget {
  const KycVerificationScreen({super.key, this.user});

  final User? user;

  @override
  State<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends State<KycVerificationScreen> {
  bool _loading = false;
  bool _polling = false;
  String? _error;
  String? _verificationUrl;
  String _statusLabel = 'none';
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _statusLabel = widget.user?.kycStatus ?? 'none';
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSession());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _startSession() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lang = SessionManager.instance.getLang();
      final data = await UserService.instance.startKyc(
        language: lang.isEmpty ? null : lang,
      );
      if (data['already_approved'] == true) {
        await _finishSuccess();
        return;
      }
      final url = data['url']?.toString();
      if (url == null || url.isEmpty) {
        throw Exception('Missing verification URL');
      }
      setState(() {
        _verificationUrl = url;
        _statusLabel = data['kyc_status']?.toString() ?? 'pending';
      });
      await _openUrl(url);
      _startPolling();
    } catch (e) {
      Loggers.error('startKyc: $e');
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(
      uri,
      mode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
      webOnlyWindowName: kIsWeb ? '_blank' : null,
    );
    if (!ok && mounted) {
      setState(() => _error = 'Could not open verification page');
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    setState(() => _polling = true);
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      try {
        final user = await UserService.instance.fetchUserDetails(
          userId: SessionManager.instance.getUserID(),
        );
        if (user == null || !mounted) return;
        setState(() => _statusLabel = user.kycStatus ?? _statusLabel);
        if (user.isKycApproved) {
          _pollTimer?.cancel();
          await _finishSuccess(user);
          return;
        }
        final st = (user.kycStatus ?? '').toLowerCase();
        if (st == 'declined' || st == 'expired') {
          _pollTimer?.cancel();
          setState(() {
            _polling = false;
            _error = st == 'declined'
                ? 'Verification declined. Please try again with a valid ID.'
                : 'Verification expired. Please start again.';
          });
        }
      } catch (e) {
        Loggers.error('KYC poll: $e');
      }
    });
  }

  Future<void> _finishSuccess([User? user]) async {
    final u = user ?? SessionManager.instance.getUser() ?? widget.user;
    if (u != null) SessionManager.instance.setUser(u);
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back(result: true);
      return;
    }
    Get.back(result: true);
  }

  Future<void> _checkNow() async {
    setState(() => _loading = true);
    try {
      final user = await UserService.instance.fetchUserDetails(
        userId: SessionManager.instance.getUserID(),
      );
      if (user != null && user.isKycApproved) {
        await _finishSuccess(user);
        return;
      }
      setState(() {
        _statusLabel = user?.kycStatus ?? _statusLabel;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorRes.bgVoid,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: ColorRes.whitePure),
          onPressed: () => Get.back(result: false),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Identity verification',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ColorRes.whitePure,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'To request a withdrawal, verify your identity once with your ID and a selfie.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ColorRes.whitePure.withValues(alpha: 0.75),
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const Spacer(),
              if (_loading)
                const Center(
                  child: CircularProgressIndicator(color: ColorRes.accentRose),
                )
              else ...[
                if (_error != null) ...[
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: ColorRes.coralRed, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Status: $_statusLabel'
                  '${_polling ? ' · waiting…' : ''}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ColorRes.whitePure.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _verificationUrl == null
                      ? _startSession
                      : () => _openUrl(_verificationUrl!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorRes.accentRose,
                    foregroundColor: ColorRes.whitePure,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _verificationUrl == null
                        ? 'Start verification'
                        : 'Open verification again',
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _checkNow,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorRes.whitePure,
                    side: BorderSide(
                      color: ColorRes.whitePure.withValues(alpha: 0.35),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('I already finished — check status'),
                ),
                if (_verificationUrl != null) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _startSession,
                    child: Text(
                      'Create a new session',
                      style: TextStyle(
                        color: ColorRes.whitePure.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
