import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'search_provider.dart';
import '../../shared/video_card.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(searchProvider.notifier).loadMore();
    }
  }

  void _performSearch() {
    final text = _searchController.text.trim();
    if (text.isNotEmpty) {
      ref.read(searchProvider.notifier).search(text);
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Search videos...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white54),
          ),
          style: const TextStyle(color: Colors.white),
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _performSearch(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _performSearch),
        ],
      ),
      body: _buildBody(searchState),
    );
  }

  Widget _buildBody(SearchState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFB7299)),
      );
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(child: Text('Search failed: ${state.error}'));
    }

    if (!state.isLoading && state.items.isEmpty && state.keyword.isNotEmpty) {
      return const Center(child: Text('No videos found'));
    }

    if (state.items.isEmpty) {
      return const Center(child: Text('Enter keywords to search'));
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        childAspectRatio: 1.1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 12,
      ),
      itemCount: state.items.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.items.length) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFB7299)),
          );
        }

        final item = state.items[index];
        final String title =
            (item['title'] as String?)?.replaceAll(RegExp(r'<[^>]*>'), '') ??
            'No Title';
        final cover = item['pic']?.startsWith('http') == true
            ? item['pic']
            : 'https:${item['pic'] ?? ''}';
        final author = item['author'] ?? 'Unknown';
        final viewCount = item['play']?.toString() ?? '0';
        final durationText = item['duration'] ?? '';
        final bvid = item['bvid'] ?? '';

        // Extract date if possible
        String? date;
        if (item['pubdate'] != null) {
          final dt = DateTime.fromMillisecondsSinceEpoch(
            item['pubdate'] * 1000,
          );
          date = '${dt.month}-${dt.day}';
        }

        return VideoCard(
          title: title,
          cover: cover!,
          author: author,
          viewCount: (viewCount.length > 4)
              ? '${(int.parse(viewCount) / 10000).toStringAsFixed(1)}万'
              : viewCount,
          duration: durationText,
          date: date,
          onTap: () {
            context.push('/player/$bvid');
          },
        );
      },
    );
  }
}
