import 'dart:html' as html;

/// El &lt;video&gt; / HtmlElementView de LiveKit en Web se pinta encima del
/// canvas de Flutter y se come los toques (mic, colgar, gift, etc.).
/// `pointer-events: none` en el video **y** en el host del platform-view
/// deja los clics al canvas de Flutter.
///
/// No tocar todos los `flt-semantics`: Flutter Web los usa para hit-testing.
void passThroughMatchVideoClicks() {
  for (final node in html.document.querySelectorAll('video')) {
    final el = node as html.Element;
    el.style.pointerEvents = 'none';
    el.style.setProperty('object-fit', 'cover', 'important');
    el.style.setProperty('object-position', 'center center', 'important');
    // Miniatura (~110×160) por encima del video grande (HtmlElementView).
    final pip = el.offsetWidth > 0 && el.offsetWidth <= 170;
    if (!pip) {
      el.style.setProperty('width', '100%', 'important');
      el.style.setProperty('height', '100%', 'important');
      el.style.setProperty('min-width', '100%', 'important');
      el.style.setProperty('min-height', '100%', 'important');
    }
    _raisePlatformView(el, pip ? '40' : '1', fill: !pip);
  }
}

void _raisePlatformView(html.Element video, String z, {required bool fill}) {
  video.style.zIndex = z;
  html.Element? p = video.parent;
  var hops = 0;
  while (p != null && hops < 16) {
    final tag = p.tagName.toLowerCase();
    final isHost = tag.contains('flt-platform-view') ||
        tag.contains('flt-platform-view-slot');
    if (fill) {
      p.style.setProperty('width', '100%', 'important');
      p.style.setProperty('height', '100%', 'important');
      p.style.overflow = 'hidden';
    }
    if (isHost) {
      p.style.zIndex = z;
      p.style.position = 'relative';
      // Crítico: el host captura clics aunque el <video> ya tenga none.
      // Sin ClipRect en Web el video desborda sobre la barra de controles.
      p.style.pointerEvents = 'none';
      p.style.overflow = 'hidden';
      break;
    }
    p = p.parent;
    hops++;
  }
}
