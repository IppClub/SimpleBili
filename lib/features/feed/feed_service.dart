import 'package:riverpod/riverpod.dart';
import '../../core/bili_client.dart';

final feedServiceProvider = Provider<FeedService>((ref) {
  return FeedService(ref.read(biliClientProvider));
});

class FeedService {
  final BiliClient _client;

  FeedService(this._client);

  Future<Map<String, dynamic>> getVideoFeed({String offset = ''}) async {
    try {
      final res = await _client.dio.get(
        '/x/polymer/web-dynamic/v1/feed/all',
        queryParameters: {
          'type': 'video',
          'offset': offset,
          'timezone_offset': '-480',
        },
      );
      if (res.data['code'] == 0) {
        return res.data['data'];
      } else {
        throw Exception(res.data['message']);
      }
    } catch (e) {
      print('Fetch feed failed: $e');
      rethrow;
    }
  }
}
