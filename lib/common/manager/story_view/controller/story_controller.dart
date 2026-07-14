import 'dart:async';

enum PlaybackState { play, pause, next, previous, playFromStart }

/// Minimal BehaviorSubject-like notifier compatible with story_image / story_view.
class PlaybackNotifier {
  PlaybackState value;
  final StreamController<PlaybackState> _controller =
      StreamController<PlaybackState>.broadcast();

  PlaybackNotifier([this.value = PlaybackState.play]);

  PlaybackNotifier get stream => this;

  StreamSubscription<PlaybackState> listen(
    void Function(PlaybackState event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return _controller.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  void add(PlaybackState state) {
    value = state;
    if (!_controller.isClosed) {
      _controller.add(state);
    }
  }

  Future<void> close() => _controller.close();
}

class StoryController {
  final PlaybackNotifier playbackNotifier = PlaybackNotifier();

  void play() => playbackNotifier.add(PlaybackState.play);

  void pause() => playbackNotifier.add(PlaybackState.pause);

  void next() => playbackNotifier.add(PlaybackState.next);

  void previous() => playbackNotifier.add(PlaybackState.previous);

  void playFromStart() => playbackNotifier.add(PlaybackState.playFromStart);

  void dispose() {
    playbackNotifier.close();
  }
}
