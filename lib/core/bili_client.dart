import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod/riverpod.dart';

final biliClientProvider = Provider<BiliClient>((ref) {
  return BiliClient();
});

class BiliClient {
  late Dio _dio;
  String _cookie = '';
  bool _isInitialized = false;

  BiliClient() {
    _dio = Dio(BaseOptions(
      baseUrl: 'https://api.bilibili.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
        'Referer': 'https://www.bilibili.com',
        'Origin': 'https://www.bilibili.com',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (!_isInitialized) {
          await init();
        }
        if (_cookie.isNotEmpty) {
          options.headers['Cookie'] = _cookie;
        }
        return handler.next(options);
      },
    ));
  }

  Dio get dio => _dio;
  String get cookie => _cookie;

  Future<void> init() async {
    if (_isInitialized) return;
    final prefs = await SharedPreferences.getInstance();
    _cookie = prefs.getString('bili_cookie') ?? '';
    _isInitialized = true;
  }

  Future<void> saveCookie(String cookie) async {
    _cookie = cookie;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bili_cookie', cookie);
    _isInitialized = true;
  }

  Future<void> clearCookie() async {
    _cookie = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bili_cookie');
  }

  String? wbiImgKey;
  String? wbiSubKey;

  Future<void> fetchWbiKeys() async {
    if (wbiImgKey != null && wbiSubKey != null) return;
    
    try {
      final res = await _dio.get('/x/web-interface/nav');
      if (res.data['code'] == 0) {
        final wbiImg = res.data['data']['wbi_img'];
        final imgUrl = wbiImg['img_url'] as String;
        final subUrl = wbiImg['sub_url'] as String;
        
        wbiImgKey = imgUrl.split('/').last.split('.').first;
        wbiSubKey = subUrl.split('/').last.split('.').first;
      }
    } catch (e) {
      print('Fetch WBI keys failed: $e');
    }
  }
}
