import 'package:riverpod/riverpod.dart';
import '../../core/bili_client.dart';
import '../../core/wbi_sign.dart';

final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService(ref.read(biliClientProvider));
});

class SearchService {
  final BiliClient _client;

  SearchService(this._client);

  Future<Map<String, dynamic>> searchVideo(String keyword, int page) async {
    await _client.fetchWbiKeys();

    if (_client.wbiImgKey == null || _client.wbiSubKey == null) {
      throw Exception('WBI keys not available');
    }

    final Map<String, dynamic> params = {
      'keyword': keyword,
      'search_type': 'video',
      'page': page.toString(),
    };

    final signedParams = WbiSign.sign(params, _client.wbiImgKey!, _client.wbiSubKey!);

    try {
      final res = await _client.dio.get(
        '/x/web-interface/wbi/search/type',
        queryParameters: signedParams,
      );
      if (res.data['code'] == 0) {
        return res.data['data'];
      } else {
        throw Exception(res.data['message']);
      }
    } catch (e) {
      print('Search failed: $e');
      rethrow;
    }
  }
}
