import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'up_provider.dart';
import '../../shared/video_card.dart';

class UpSpacePage extends ConsumerStatefulWidget {
  final String mid;

  const UpSpacePage({super.key, required this.mid});

  @override
  ConsumerState<UpSpacePage> createState() => _UpSpacePageState();
}

class _UpSpacePageState extends ConsumerState<UpSpacePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 400) {
      ref.read(upProvider(widget.mid).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final upState = ref.watch(upProvider(widget.mid));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(upProvider(widget.mid).notifier).loadData(),
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildAppBar(context, upState),
            if (upState.isLoading && upState.info == null)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
            if (upState.error != null && upState.info == null)
              SliverFillRemaining(
                child: Center(child: Text('Error: ${upState.error}')),
              ),
            if (upState.info != null) ...[
              _buildHeader(upState),
              _buildVideoList(context, upState),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, UpSpaceState state) {
    return SliverAppBar(pinned: true, title: Text(state.info?['name'] ?? ''));
  }

  Widget _buildHeader(UpSpaceState state) {
    final info = state.info!;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 38,
                backgroundImage: NetworkImage(info['face'] ?? ''),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    info['sign'] ?? 'No signature',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoList(BuildContext context, UpSpaceState state) {
    return SliverPadding(
      padding: const EdgeInsets.all(8),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 300,
          childAspectRatio: 1.1,
          crossAxisSpacing: 8,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          if (index == state.videos.length) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFB7299)));
          }
          final video = state.videos[index];
          return VideoCard(
            title: video['title'] ?? '',
            cover: video['pic'] ?? '',
            author: state.info?['name'] ?? '',
            viewCount: video['play']?.toString() ?? '0',
            duration: video['length'] ?? '',
            onTap: () => context.push('/player/${video['bvid']}'),
          );
        }, childCount: state.videos.length + (state.hasMore ? 1 : 0)),
      ),
    );
  }
}
