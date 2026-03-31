import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/auth_provider.dart';
import 'feed_provider.dart';
import '../../shared/dynamic_card.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  final ScrollController _scrollController = ScrollController();

  int _statValue(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is Map) {
      final candidates = [
        value['count'],
        value['value'],
        value['num'],
        value['num_str'],
        value['total'],
      ];
      for (final candidate in candidates) {
        final parsed = _statValue(candidate);
        if (parsed != 0) return parsed;
      }
    }
    return 0;
  }

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
      ref.read(feedProvider.notifier).fetchMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dynamic Feed'),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_outline),
            tooltip: '我的收藏',
            onPressed: () => context.push('/favorite'),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('退出登录'),
                  content: const Text('确定要退出登录吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        '确认退出',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                ref.read(authProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(feedProvider.notifier).refresh(),
        child: _buildBody(feedState),
      ),
    );
  }

  Widget _buildBody(FeedState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Failed to load: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(feedProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // Switched from GridView to ListView for native-like dynamic feed
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.items.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.items.length) {
          return const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final item = state.items[index];
        // debugPrint('DYNAMIC_ITEM: ${item}');
        final modules = item['modules'] ?? {};
        final moduleDynamic = modules['module_dynamic'] ?? {};
        final moduleAuthor = modules['module_author'] ?? {};

        final major = moduleDynamic['major'] ?? {};
        final archive = major['archive'] ?? {};

        // Data extraction
        final title = archive['title'] ?? 'No Title';
        final cover = archive['cover'] ?? '';
        final authorName = moduleAuthor['name'] ?? 'Unknown';
        final authorFace = moduleAuthor['face'] ?? '';
        final publishTime = moduleAuthor['pub_time'] ?? '';
        final viewCount =
            archive['stat']?['play'] ?? archive['stat']?['view'] ?? '0';
        final danmaku = archive['stat']?['danmaku'] ?? '0';
        final durationText = archive['duration_text'] ?? '';
        final bvid = archive['bvid'] ?? '';
        final mid = moduleAuthor['mid']?.toString() ?? '';

        final moduleStat = modules['module_stat'] ?? {};
        final likeCount = _statValue(
          moduleStat['like'] ??
              moduleStat['like_count'] ??
              moduleStat['thumb_up'] ??
              archive['stat']?['like'] ??
              archive['stat']?['like_count'],
        ).toString();
        final commentCount = _statValue(
          moduleStat['reply'] ??
              moduleStat['comment'] ??
              moduleStat['comment_count'] ??
              moduleStat['reply_count'] ??
              archive['stat']?['reply'] ??
              archive['stat']?['comment'] ??
              archive['stat']?['reply_count'],
        ).toString();
        final forwardCount = _statValue(
          moduleStat['forward'] ??
              moduleStat['share'] ??
              moduleStat['share_count'],
        ).toString();
        final dynamicId = item['id_str'] ?? '';
        final shareUrl = dynamicId.isNotEmpty
            ? 'https://t.bilibili.com/$dynamicId'
            : 'https://www.bilibili.com/video/$bvid';

        return DynamicCard(
          authorName: authorName,
          authorFace: authorFace,
          publishTime: publishTime,
          title: title,
          cover: cover,
          viewCount: viewCount.toString(),
          danmakuCount: danmaku.toString(),
          duration: durationText,
          likeCount: likeCount,
          commentCount: commentCount,
          forwardCount: forwardCount,
          shareUrl: shareUrl,
          onAuthorTap: () {
            if (mid.isNotEmpty) {
              context.push('/up/$mid');
            }
          },
          onTap: () {
            if (bvid.isNotEmpty) {
              context.push('/player/$bvid');
            }
          },
        );
      },
    );
  }
}
