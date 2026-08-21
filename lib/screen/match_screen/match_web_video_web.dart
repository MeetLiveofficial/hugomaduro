import 'dart:html' as html;

/// El &lt;video&gt; de LiveKit en Web se pinta encima del canvas; sin esto
/// tapa botones. pointer-events:none deja los toques a Flutter.
void passThroughMatchVideoClicks() {
  for (final node in html.document.querySelectorAll('video')) {
    final el = node as html.Element;
    el.style.pointerEvents = 'none';
    el.style.objectFit = 'cover';
    el.style.width = '100%';
    el.style.height = '100%';
    // Miniatura (~110×160) por encima del video grande (HtmlElementView).
    final pip = el.offsetWidth > 0 && el.offsetWidth <= 170;
    _raisePlatformView(el, pip ? '40' : '1');
  }
}

void _raisePlatformView(html.Element video, String z) {
  video.style.zIndex = z;
  html.Element? p = video.parent;
  var hops = 0;
  while (p != null && hops < 8) {
    final tag = p.tagName.toLowerCase();
    if (tag.contains('flt-platform-view') || tag.contains('flt-semantics')) {
      p.style.zIndex = z;
      p.style.position = 'relative';
      if (z == '40') p.style.overflow = 'hidden';
      break;
    }
    p = p.parent;
    hops++;
  }
}
