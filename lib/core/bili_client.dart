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
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api.bilibili.com',
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36',
          'Referer': 'https://www.bilibili.com',
          'Origin': 'https://www.bilibili.com',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!_isInitialized) {
            await init();
          }
          if (_cookie.isNotEmpty) {
            options.headers['Cookie'] = _cookie;
          }
          return handler.next(options);
        },
        onResponse: (response, handler) async {
          // Auto-update cookies from set-cookie headers
          final setCookies = response.headers['set-cookie'];
          if (setCookies != null && setCookies.isNotEmpty) {
            await _mergeCookies(setCookies);
          }
          return handler.next(response);
        },
      ),
    );
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

  /// Merge new set-cookie values into the existing cookie string.
  Future<void> _mergeCookies(List<String> setCookies) async {
    // Parse existing cookies into a map
    final cookieMap = <String, String>{};
    for (final part in _cookie.split(';')) {
      final trimmed = part.trim();
      final idx = trimmed.indexOf('=');
      if (idx > 0) {
        cookieMap[trimmed.substring(0, idx).trim()] = trimmed
            .substring(idx + 1)
            .trim();
      }
    }
    // Merge new cookies (each set-cookie header: "key=value; path=...; ...")
    bool changed = false;
    for (final raw in setCookies) {
      final pair = raw.split(';').first.trim();
      final idx = pair.indexOf('=');
      if (idx > 0) {
        final key = pair.substring(0, idx).trim();
        final value = pair.substring(idx + 1).trim();
        if (cookieMap[key] != value) {
          cookieMap[key] = value;
          changed = true;
        }
      }
    }
    if (changed) {
      final newCookie = cookieMap.entries
          .map((e) => '${e.key}=${e.value}')
          .join('; ');
      await saveCookie(newCookie);
    }
  }

  /// Check if the current cookie is still valid.
  Future<bool> checkCookieValid() async {
    if (_cookie.isEmpty) return false;
    try {
      final res = await _dio.get('/x/web-interface/nav');
      return res.data['code'] == 0 && res.data['data']['isLogin'] == true;
    } catch (_) {
      return false;
    }
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
