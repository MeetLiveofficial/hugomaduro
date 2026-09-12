import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;
import 'package:krimson/common/extensions/string_extension.dart';
import 'package:krimson/common/manager/app_role.dart';
import 'package:krimson/common/manager/session_manager.dart';
import 'package:krimson/common/service/api/common_service.dart';
import 'package:krimson/common/widget/custom_app_bar.dart';
import 'package:krimson/common/widget/loader_widget.dart';
import 'package:krimson/common/widget/text_button_custom.dart';
import 'package:krimson/languages/languages_keys.dart';
import 'package:krimson/utilities/app_platform.dart';
import 'package:krimson/utilities/client_colors.dart';
import 'package:krimson/utilities/color_res.dart';
import 'package:krimson/utilities/const_res.dart';
import 'package:krimson/utilities/text_style_custom.dart';
import 'package:krimson/utilities/theme_res.dart';
import 'package:webview_flutter_plus/webview_flutter_plus.dart';

enum TermAndPrivacyType { privacyPolicy, termAndCondition }

class TermAndPrivacyScreen extends StatefulWidget {
  final TermAndPrivacyType type;

  const TermAndPrivacyScreen({super.key, required this.type});

  @override
  State<TermAndPrivacyScreen> createState() => _TermAndPrivacyScreenState();
}

class _TermAndPrivacyScreenState extends State<TermAndPrivacyScreen> {
  bool _loading = true;
  String _html = '';
  WebViewControllerPlus? _webController;

  bool get _isPrivacy => widget.type == TermAndPrivacyType.privacyPolicy;

  String get _title =>
      _isPrivacy ? LKey.privacyPolicy.tr : LKey.termsOfUse.tr;

  String get _publicUrl =>
      _isPrivacy ? '${baseURL}privacidad' : '${baseURL}terminos';

  bool get _hasHtml {
    final plain = html_parser.parse(_html).body?.text.trim() ?? '';
    return plain.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await CommonService.instance.fetchGlobalSettings();
    } catch (_) {}
    if (!mounted) return;
    final settings = SessionManager.instance.getSettings();
    _html = (_isPrivacy
                ? settings?.privacyPolicy
                : settings?.termsOfUses)
            ?.trim() ??
        '';
    _initWebView();
    setState(() => _loading = false);
  }

  void _initWebView() {
    if (!AppPlatform.isMobile) return;
    final client = AppRole.isClient();
    final controller = WebViewControllerPlus()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(
          client ? ClientColors.bg : ColorRes.bgLightGrey)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final url = request.url;
            if (url.startsWith('data:') ||
                url == 'about:blank' ||
                url.startsWith('https://meetlive.online/') ||
                url.startsWith(baseURL)) {
              return NavigationDecision.navigate;
            }
            url.lunchUrlWithHttps;
            return NavigationDecision.prevent;
          },
        ),
      );
    if (_hasHtml) {
      controller.loadHtmlString(_wrapHtml(_html, client: client));
    } else {
      controller.loadRequest(Uri.parse(_publicUrl));
    }
    _webController = controller;
  }

  String _wrapHtml(String body, {required bool client}) {
    final bg = client ? '#2A2A32' : '#FFD6EC';
    final fg = client ? '#FFFFFF' : '#1A1A1F';
    final link = client ? '#27D3F5' : '#E24AB7';
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    html, body { margin: 0; padding: 0; background: $bg; color: $fg; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      font-size: 16px; line-height: 1.55; padding: 16px 18px 40px;
    }
    h1 { font-size: 22px; margin: 0 0 12px; }
    h2 { font-size: 18px; margin: 20px 0 8px; }
    h3 { font-size: 16px; margin: 16px 0 8px; }
    p { margin: 0 0 12px; }
    a { color: $link; }
    img { max-width: 100%; height: auto; }
    ul, ol { padding-left: 1.25em; }
  </style>
</head>
<body>$body</body>
</html>
''';
  }

  Future<void> _openPublicUrl() async {
    await _publicUrl.lunchUrlWithHttps;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppRole.isClient() ? ClientColors.bg : null,
      body: Column(
        children: [
          CustomAppBar(
            title: _title,
            rowWidget: IconButton(
              onPressed: _openPublicUrl,
              tooltip: _title,
              icon: const Icon(Icons.open_in_new,
                  color: ColorRes.whitePure, size: 20),
            ),
          ),
          Expanded(child: _buildBody(context)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) return const LoaderWidget();

    if (AppPlatform.isMobile && _webController != null) {
      return WebViewWidget(controller: _webController!);
    }

    if (_hasHtml) {
      return _LegalHtmlView(html: _html);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _title,
            style: TextStyleCustom.unboundedSemiBold600(
                color: textDarkGrey(context), fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          TextButtonCustom(
            title: _title,
            onTap: _openPublicUrl,
          ),
        ],
      ),
    );
  }
}

class _LegalHtmlView extends StatelessWidget {
  final String html;

  const _LegalHtmlView({required this.html});

  @override
  Widget build(BuildContext context) {
    final body = html_parser.parse(html).body;
    final children = <Widget>[];
    if (body != null) {
      for (final node in body.nodes) {
        children.addAll(_blockWidgets(context, node));
      }
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: children,
    );
  }

  List<Widget> _blockWidgets(BuildContext context, html_dom.Node node) {
    if (node is html_dom.Text) {
      final text = node.text.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (text.isEmpty) return const [];
      return [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(text,
              style: TextStyleCustom.outFitRegular400(
                  color: textDarkGrey(context), fontSize: 15)),
        ),
      ];
    }
    if (node is! html_dom.Element) return const [];

    final tag = node.localName?.toLowerCase();
    switch (tag) {
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
        final size = tag == 'h1' ? 22.0 : (tag == 'h2' ? 18.0 : 16.0);
        return [
          Padding(
            padding: EdgeInsets.only(top: tag == 'h1' ? 0 : 16, bottom: 8),
            child: Text(
              node.text.trim(),
              style: TextStyleCustom.outFitSemiBold600(
                  color: textDarkGrey(context), fontSize: size),
            ),
          ),
        ];
      case 'p':
      case 'div':
      case 'section':
      case 'article':
        final hasBlock = node.children.any((c) {
          final t = c.localName?.toLowerCase();
          return t == 'p' ||
              t == 'div' ||
              t == 'ul' ||
              t == 'ol' ||
              t == 'h1' ||
              t == 'h2' ||
              t == 'h3' ||
              t == 'h4' ||
              t == 'section';
        });
        if (hasBlock) {
          return [
            for (final child in node.nodes)
              ..._blockWidgets(context, child),
          ];
        }
        final spans = _inlineSpans(context, node);
        if (spans.isEmpty) return const [];
        return [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text.rich(TextSpan(children: spans)),
          ),
        ];
      case 'ul':
      case 'ol':
        return [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < node.children.length; i++)
                  if (node.children[i].localName?.toLowerCase() == 'li')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tag == 'ol' ? '${i + 1}. ' : '• ',
                            style: TextStyleCustom.outFitRegular400(
                                color: textDarkGrey(context), fontSize: 15),
                          ),
                          Expanded(
                            child: Text.rich(TextSpan(
                                children: _inlineSpans(
                                    context, node.children[i]))),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
        ];
      case 'br':
        return [const SizedBox(height: 8)];
      case 'hr':
        return [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: textLightGrey(context).withValues(alpha: 0.4)),
          ),
        ];
      default:
        if (node.children.isEmpty) {
          final spans = _inlineSpans(context, node);
          if (spans.isEmpty) return const [];
          return [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text.rich(TextSpan(children: spans)),
            ),
          ];
        }
        return [
          for (final child in node.nodes) ..._blockWidgets(context, child),
        ];
    }
  }

  List<InlineSpan> _inlineSpans(
      BuildContext context, html_dom.Node node) {
    final color = textDarkGrey(context);
    final accent = themeAccentSolid(context);
    return _collectSpans(node, context,
        base: TextStyleCustom.outFitRegular400(color: color, fontSize: 15),
        accent: accent);
  }

  List<InlineSpan> _collectSpans(
    html_dom.Node node,
    BuildContext context, {
    required TextStyle base,
    required Color accent,
    bool bold = false,
    bool italic = false,
    bool underline = false,
    String? href,
  }) {
    if (node is html_dom.Text) {
      final text = node.text.replaceAll(RegExp(r'[ \t\r\n]+'), ' ');
      if (text.isEmpty) return const [];
      final style = base.copyWith(
        fontWeight: bold ? FontWeight.w600 : base.fontWeight,
        fontStyle: italic ? FontStyle.italic : base.fontStyle,
        decoration: underline || href != null
            ? TextDecoration.underline
            : base.decoration,
        color: href != null ? accent : base.color,
      );
      if (href != null) {
        return [
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: GestureDetector(
              onTap: () => href.lunchUrlWithHttps,
              child: Text(text, style: style),
            ),
          ),
        ];
      }
      return [TextSpan(text: text, style: style)];
    }
    if (node is! html_dom.Element) return const [];
    final tag = node.localName?.toLowerCase();
    if (tag == 'br') return const [TextSpan(text: '\n')];
    final nextBold = bold || tag == 'strong' || tag == 'b';
    final nextItalic = italic || tag == 'em' || tag == 'i';
    final nextUnderline = underline || tag == 'u';
    final nextHref = tag == 'a' ? (node.attributes['href'] ?? href) : href;
    return [
      for (final child in node.nodes)
        ..._collectSpans(child, context,
            base: base,
            accent: accent,
            bold: nextBold,
            italic: nextItalic,
            underline: nextUnderline,
            href: nextHref),
    ];
  }
}
