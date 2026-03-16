import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'up_service.dart';

class UpSpaceState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? info;
  final Map<String, dynamic>? stat;
  final List<dynamic> videos;
  final int page;
  final bool hasMore;

  UpSpaceState({
    this.isLoading = false,
    this.error,
    this.info,
    this.stat,
    this.videos = const [],
    this.page = 1,
    this.hasMore = true,
  });

  UpSpaceState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? info,
    Map<String, dynamic>? stat,
    List<dynamic>? videos,
    int? page,
    bool? hasMore,
  }) {
    return UpSpaceState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      info: info ?? this.info,
      stat: stat ?? this.stat,
      videos: videos ?? this.videos,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class UpNotifier extends StateNotifier<UpSpaceState> {
  final UpService _service;
  final String mid;

  UpNotifier(this._service, this.mid) : super(UpSpaceState()) {
    loadData();
  }

  Future<void> loadData() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, error: null, page: 1, hasMore: true);
    try {
      final info = await _service.getUpInfo(mid);
      final stat = await _service.getUpStat(mid);
      final videos = await _service.getUpVideos(mid, page: 1);

      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        info: info,
        stat: stat,
        videos: videos,
        page: 1,
        hasMore: videos.isNotEmpty,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore || !mounted) return;

    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.page + 1;
      final newVideos = await _service.getUpVideos(mid, page: nextPage);

      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        videos: [...state.videos, ...newVideos],
        page: nextPage,
        hasMore: newVideos.isNotEmpty,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final upProvider = StateNotifierProvider.family<UpNotifier, UpSpaceState, String>((ref, mid) {
  return UpNotifier(ref.read(upServiceProvider), mid);
});
