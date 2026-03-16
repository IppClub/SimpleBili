import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/auth_provider.dart';
import '../features/auth/login_page.dart';
import '../features/feed/feed_page.dart';
import '../features/search/search_page.dart';
import '../features/player/player_page.dart';
import '../features/up/up_space_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const FeedPage(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchPage(),
      ),
      GoRoute(
        path: '/up/:mid',
        builder: (context, state) {
          final mid = state.pathParameters['mid']!;
          return UpSpacePage(mid: mid);
        },
      ),
      GoRoute(
        path: '/player/:bvid',
        builder: (context, state) {
          final bvid = state.pathParameters['bvid']!;
          return PlayerPage(bvid: bvid);
        },
      ),
    ],
    redirect: (context, state) {
      final isAuth = authState.status == AuthStatus.authenticated;
      final isGoingToLogin = state.uri.path == '/login';

      if (!isAuth && !isGoingToLogin) {
        return '/login';
      }
      if (isAuth && isGoingToLogin) {
        return '/';
      }
      return null;
    },
  );
});
