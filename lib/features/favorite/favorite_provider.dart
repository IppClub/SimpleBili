import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'favorite_service.dart';

// ── 收藏夹列表 ──

class FavoriteListState {
  final bool isLoading;
  final String? error;
  final List<dynamic> folders;

  FavoriteListState({
    this.isLoading = false,
    this.error,
    this.folders = const [],
  });

  FavoriteListState copyWith({
    bool? isLoading,
    String? error,
    List<dynamic>? folders,
    bool clearError = false,
  }) {
    return FavoriteListState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      folders: folders ?? this.folders,
    );
  }
}

class FavoriteListNotifier extends StateNotifier<FavoriteListState> {
  final FavoriteService _service;

  FavoriteListNotifier(this._service) : super(FavoriteListState()) {
    load();
  }

  Future<void> load() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final folders = await _service.getFavoriteList();
      if (!mounted) return;
      state = state.copyWith(isLoading: false, folders: folders);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final favoriteListProvider =
    StateNotifierProvider<FavoriteListNotifier, FavoriteListState>((ref) {
      return FavoriteListNotifier(ref.read(favoriteServiceProvider));
    });

// ── 收藏夹内视频列表 ──

class FavoriteDetailState {
  final bool isLoading;
  final String? error;
  final List<dynamic> videos;
  final int page;
  final bool hasMore;
  final Map<String, dynamic>? info;

  FavoriteDetailState({
    this.isLoading = false,
    this.error,
    this.videos = const [],
    this.page = 1,
    this.hasMore = true,
    this.info,
  });

  FavoriteDetailState copyWith({
    bool? isLoading,
    String? error,
    List<dynamic>? videos,
    int? page,
    bool? hasMore,
    Map<String, dynamic>? info,
    bool clearError = false,
  }) {
    return FavoriteDetailState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      videos: videos ?? this.videos,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      info: info ?? this.info,
    );
  }
}

class FavoriteDetailNotifier extends StateNotifier<FavoriteDetailState> {
  final FavoriteService _service;
  final int mediaId;

  FavoriteDetailNotifier(this._service, this.mediaId)
    : super(FavoriteDetailState()) {
    load();
  }

  Future<void> load() async {
    if (!mounted) return;
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      page: 1,
      videos: [],
    );
    try {
      final data = await _service.getFavoriteVideos(mediaId, page: 1);
      if (!mounted) return;
      final medias = data['medias'] as List? ?? [];
      final hasMore = data['has_more'] ?? false;
      state = state.copyWith(
        isLoading: false,
        videos: medias,
        info: data['info'],
        page: 1,
        hasMore: hasMore,
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
      final data = await _service.getFavoriteVideos(mediaId, page: nextPage);
      if (!mounted) return;
      final medias = data['medias'] as List? ?? [];
      state = state.copyWith(
        isLoading: false,
        videos: [...state.videos, ...medias],
        page: nextPage,
        hasMore: data['has_more'] ?? false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final favoriteDetailProvider =
    StateNotifierProvider.family<
      FavoriteDetailNotifier,
      FavoriteDetailState,
      int
    >((ref, mediaId) {
      return FavoriteDetailNotifier(ref.read(favoriteServiceProvider), mediaId);
    });
