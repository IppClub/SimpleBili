import 'package:riverpod/riverpod.dart';
import '../../core/bili_client.dart';
import '../../core/wbi_sign.dart';

final upServiceProvider = Provider<UpService>((ref) {
  return UpService(ref.read(biliClientProvider));
});

class UpService {
  final BiliClient _client;

  UpService(this._client);

  Future<Map<String, dynamic>> getUpInfo(String mid) async {
    await _client.fetchWbiKeys();
    final params = {'mid': mid};
    final signedParams = WbiSign.sign(params, _client.wbiImgKey!, _client.wbiSubKey!);

    try {
      final res = await _client.dio.get(
        '/x/space/wbi/acc/info',
        queryParameters: signedParams,
      );
      if (res.data['code'] == 0) {
        return res.data['data'];
      } else {
        throw Exception(res.data['message']);
      }
    } catch (e) {
      print('Get UP info failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUpStat(String mid) async {
    try {
      final res = await _client.dio.get(
        '/x/space/upstat',
        queryParameters: {'mid': mid},
      );
      if (res.data['code'] == 0) {
        return res.data['data'];
      } else {
        throw Exception(res.data['message']);
      }
    } catch (e) {
      print('Get UP stat failed: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> getUpVideos(String mid, {int page = 1, int pageSize = 30}) async {
    await _client.fetchWbiKeys();
    final params = {
      'mid': mid,
      'pn': page.toString(),
      'ps': pageSize.toString(),
      'order': 'pubdate',
    };
    final signedParams = WbiSign.sign(params, _client.wbiImgKey!, _client.wbiSubKey!);

    try {
      final res = await _client.dio.get(
        '/x/space/wbi/arc/search',
        queryParameters: signedParams,
      );
      if (res.data['code'] == 0) {
        return res.data['data']['list']['vlist'] ?? [];
      } else {
        throw Exception(res.data['message']);
      }
    } catch (e) {
      print('Get UP videos failed: $e');
      rethrow;
    }
  }
}
