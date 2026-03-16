import 'package:riverpod/riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/bili_client.dart';
import '../../core/wbi_sign.dart';

final videoServiceProvider = Provider<VideoService>((ref) {
  return VideoService(ref.read(biliClientProvider));
});

class VideoService {
  final BiliClient _client;

  VideoService(this._client);

  Future<Map<String, dynamic>> getVideoInfo(String bvid) async {
    try {
      final res = await _client.dio.get(
        '/x/web-interface/view',
        queryParameters: {'bvid': bvid},
      );
      if (res.data['code'] == 0) {
        return res.data['data'];
      } else {
        throw Exception(res.data['message']);
      }
    } catch (e) {
      print('Get video info failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPlayUrl(
    String bvid,
    int cid, {
    int qn = 80,
  }) async {
    await _client.fetchWbiKeys();

    if (_client.wbiImgKey == null || _client.wbiSubKey == null) {
      throw Exception('WBI keys not available');
    }

    // Use fnval: 1 to get combined stream (FLV/MP4) which includes audio.
    // DASH (fnval: 16) separates audio and video into different URLs.
    final Map<String, dynamic> params = {
      'bvid': bvid,
      'cid': cid.toString(),
      'qn': qn.toString(),
      'fnval': '1',
      'fnver': '0',
      'fourk': '1',
    };

    final signedParams = WbiSign.sign(
      params,
      _client.wbiImgKey!,
      _client.wbiSubKey!,
    );

    try {
      final res = await _client.dio.get(
        '/x/player/wbi/playurl',
        queryParameters: signedParams,
      );
      if (res.data['code'] == 0) {
        return res.data['data'];
      } else {
        throw Exception(res.data['message']);
      }
    } catch (e) {
      print('Get play URL failed: $e');
      rethrow;
    }
  }

  Future<int?> getCurrentUserMid() async {
    try {
      final res = await _client.dio.get('/x/web-interface/nav');
      if (res.data['code'] == 0) {
        final data = res.data['data'] ?? {};
        return data['mid'] as int?;
      }
    } catch (e) {
      print('Get user mid failed: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getFavoriteFolders(int mid) async {
    try {
      final res = await _client.dio.get(
        '/x/v3/fav/folder/created/list-all',
        queryParameters: {'up_mid': mid.toString(), 'type': '2'},
      );
      if (res.data['code'] == 0) {
        final data = res.data['data'] ?? {};
        final list = data['list'] as List<dynamic>? ?? [];
        return list.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      print('Get favorite folders failed: $e');
    }
    return [];
  }

  Future<void> addToFavorite({
    required int aid,
    required List<int> folderIds,
  }) async {
    final csrf = _getCookieValue('bili_jct');
    if (csrf == null || csrf.isEmpty) {
      throw Exception('Missing bili_jct in cookie');
    }
    if (folderIds.isEmpty) {
      return;
    }

    try {
      final res = await _client.dio.post(
        '/x/v3/fav/resource/deal',
        data: {
          'rid': aid.toString(),
          'type': '2',
          'add_media_ids': folderIds.join(','),
          'del_media_ids': '',
          'csrf': csrf,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      if (res.data['code'] != 0) {
        throw Exception(res.data['message'] ?? 'Favorite failed');
      }
    } catch (e) {
      print('Add to favorite failed: $e');
      rethrow;
    }
  }

  String? _getCookieValue(String key) {
    final cookie = _client.cookie;
    if (cookie.isEmpty) return null;
    final match = RegExp(
      '(?:^|; )' + RegExp.escape(key) + '=([^;]*)',
    ).firstMatch(cookie);
    return match?.group(1);
  }
}
