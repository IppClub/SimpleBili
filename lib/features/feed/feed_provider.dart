import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'feed_service.dart';

class FeedState {
  final bool isLoading;
  final String? error;
  final List<dynamic> items;
  final String offset;
  final bool hasMore;

  FeedState({
    this.isLoading = false,
    this.error,
    this.items = const [],
    this.offset = '',
    this.hasMore = true,
  });

  FeedState copyWith({
    bool? isLoading,
    String? error,
    List<dynamic>? items,
    String? offset,
    bool? hasMore,
    bool clearError = false,
  }) {
    return FeedState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      items: items ?? this.items,
      offset: offset ?? this.offset,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class FeedNotifier extends StateNotifier<FeedState> {
  final FeedService _service;

  FeedNotifier(this._service) : super(FeedState()) {
    refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true, items: []);
    try {
      final data = await _service.getVideoFeed(offset: '');
      state = state.copyWith(
        isLoading: false,
        items: data['items'] ?? [],
        offset: data['offset'] ?? '',
        hasMore: data['has_more'] ?? false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    try {
      final data = await _service.getVideoFeed(offset: state.offset);
      state = state.copyWith(
        isLoading: false,
        items: [...state.items, ...(data['items'] ?? [])],
        offset: data['offset'] ?? '',
        hasMore: data['has_more'] ?? false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final feedProvider = StateNotifierProvider<FeedNotifier, FeedState>((ref) {
  return FeedNotifier(ref.read(feedServiceProvider));
});
