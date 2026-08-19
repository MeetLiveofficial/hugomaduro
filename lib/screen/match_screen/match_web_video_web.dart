import 'dart:html' as html;

/// El &lt;video&gt; de LiveKit en Web se pinta encima del canvas; sin esto
/// tapa botones. pointer-events:none deja los toques a Flutter.
void passThroughMatchVideoClicks() {
  for (final node in html.document.querySelectorAll('video')) {
    final el = node as html.Element;
    el.style.pointerEvents = 'none';
    el.style.objectFit = 'cover';
  }
}
