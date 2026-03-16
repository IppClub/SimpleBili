import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'video_service.dart';

class VideoPlayerState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? videoInfo;
  final Map<String, dynamic>? playUrlInfo;
  final double speed;
  final int currentQuality;
  final List<Map<String, dynamic>> availableQualities;
  final bool isFavoriting;

  VideoPlayerState({
    this.isLoading = false,
    this.error,
    this.videoInfo,
    this.playUrlInfo,
    this.speed = 1.0,
    this.currentQuality = 80, // Default to 1080P
    this.availableQualities = const [
      {'qn': 116, 'desc': '1080P 60FPS'},
      {'qn': 80, 'desc': '1080P'},
      {'qn': 64, 'desc': '720P'},
      {'qn': 32, 'desc': '480P'},
      {'qn': 16, 'desc': '360P'},
    ],
    this.isFavoriting = false,
  });

  VideoPlayerState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? videoInfo,
    Map<String, dynamic>? playUrlInfo,
    double? speed,
    int? currentQuality,
    List<Map<String, dynamic>>? availableQualities,
    bool? isFavoriting,
    bool clearError = false,
  }) {
    return VideoPlayerState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      videoInfo: videoInfo ?? this.videoInfo,
      playUrlInfo: playUrlInfo ?? this.playUrlInfo,
      speed: speed ?? this.speed,
      currentQuality: currentQuality ?? this.currentQuality,
      availableQualities: availableQualities ?? this.availableQualities,
      isFavoriting: isFavoriting ?? this.isFavoriting,
    );
  }
}

class PlayerNotifier extends StateNotifier<VideoPlayerState> {
  final VideoService _service;
  final String _bvid;

  PlayerNotifier(this._service, this._bvid) : super(VideoPlayerState());

  Future<void> loadVideo() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final info = await _service.getVideoInfo(_bvid);
      final cid = info['cid'];
      final playInfo = await _service.getPlayUrl(
        _bvid,
        cid,
        qn: state.currentQuality,
      );

      state = state.copyWith(
        isLoading: false,
        videoInfo: info,
        playUrlInfo: playInfo,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addToFavorite({
    required int aid,
    required List<int> folderIds,
  }) async {
    if (state.isFavoriting) return;
    state = state.copyWith(isFavoriting: true);
    try {
      await _service.addToFavorite(aid: aid, folderIds: folderIds);
      final info = await _service.getVideoInfo(_bvid);
      state = state.copyWith(videoInfo: info, isFavoriting: false);
    } catch (e) {
      state = state.copyWith(isFavoriting: false, error: 'Favorite failed: $e');
    }
  }

  Future<void> changeQuality(int qn) async {
    if (state.currentQuality == qn) return;
    state = state.copyWith(currentQuality: qn, isLoading: true);
    try {
      final cid = state.videoInfo!['cid'];
      final playInfo = await _service.getPlayUrl(_bvid, cid, qn: qn);
      state = state.copyWith(isLoading: false, playUrlInfo: playInfo);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Change quality failed: $e',
      );
    }
  }

  void setSpeed(double speed) {
    state = state.copyWith(speed: speed);
  }
}

final playerProvider =
    StateNotifierProvider.family<PlayerNotifier, VideoPlayerState, String>((
      ref,
      bvid,
    ) {
      return PlayerNotifier(ref.read(videoServiceProvider), bvid)..loadVideo();
    });
