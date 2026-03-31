import 'package:riverpod/riverpod.dart';
import '../../core/bili_client.dart';

final favoriteServiceProvider = Provider<FavoriteService>((ref) {
  return FavoriteService(ref.read(biliClientProvider));
});

class FavoriteService {
  final BiliClient _client;

  FavoriteService(this._client);

  /// 获取用户创建的收藏夹列表
  Future<List<dynamic>> getFavoriteList() async {
    // 先获取自己的 mid
    final navRes = await _client.dio.get('/x/web-interface/nav');
    if (navRes.data['code'] != 0) {
      throw Exception(navRes.data['message']);
    }
    final mid = navRes.data['data']['mid'];

    final res = await _client.dio.get(
      '/x/v3/fav/folder/created/list-all',
      queryParameters: {'up_mid': mid, 'jsonp': 'jsonp'},
    );
    if (res.data['code'] == 0) {
      return res.data['data']?['list'] ?? [];
    } else {
      throw Exception(res.data['message']);
    }
  }

  /// 获取收藏夹内的视频列表
  Future<Map<String, dynamic>> getFavoriteVideos(
    int mediaId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final res = await _client.dio.get(
      '/x/v3/fav/resource/list',
      queryParameters: {
        'media_id': mediaId,
        'pn': page,
        'ps': pageSize,
        'platform': 'web',
      },
    );
    if (res.data['code'] == 0) {
      return res.data['data'] ?? {};
    } else {
      throw Exception(res.data['message']);
    }
  }
}
