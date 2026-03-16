import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'search_service.dart';

class SearchState {
  final bool isLoading;
  final String? error;
  final List<dynamic> items;
  final int page;
  final bool hasMore;
  final String keyword;

  SearchState({
    this.isLoading = false,
    this.error,
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.keyword = '',
  });

  SearchState copyWith({
    bool? isLoading,
    String? error,
    List<dynamic>? items,
    int? page,
    bool? hasMore,
    String? keyword,
    bool clearError = false,
  }) {
    return SearchState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      keyword: keyword ?? this.keyword,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  final SearchService _service;

  SearchNotifier(this._service) : super(SearchState());

  Future<void> search(String keyword) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      items: [],
      keyword: keyword,
      page: 1,
    );
    try {
      final data = await _service.searchVideo(keyword, 1);
      final List<dynamic> results = data['result'] ?? [];
      final int numPages = data['numPages'] ?? 0;

      state = state.copyWith(
        isLoading: false,
        items: results,
        hasMore: 1 < numPages,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    final nextPage = state.page + 1;
    try {
      final data = await _service.searchVideo(state.keyword, nextPage);
      final List<dynamic> results = data['result'] ?? [];
      final int numPages = data['numPages'] ?? 0;

      state = state.copyWith(
        isLoading: false,
        items: [...state.items, ...results],
        page: nextPage,
        hasMore: nextPage < numPages,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref.read(searchServiceProvider));
});
