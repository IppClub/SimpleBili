import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'auth_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _sessdataController = TextEditingController();
  final _biliJctController = TextEditingController();
  final _dedeUserIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      final method = _tabController.index == 0
          ? LoginMethod.qrcode
          : LoginMethod.cookie;
      if (ref.read(authProvider).loginMethod != method) {
        ref.read(authProvider.notifier).setLoginMethod(method);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _sessdataController.dispose();
    _biliJctController.dispose();
    _dedeUserIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Sync tab controller if state changes from elsewhere
    ref.listen(authProvider, (previous, next) {
      if (next.loginMethod.index != _tabController.index) {
        _tabController.animateTo(next.loginMethod.index);
      }
    });

    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'SimpleBi',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFB7299),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Welcome back', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'QR Login'),
                  Tab(text: 'Cookie Login'),
                ],
                indicatorColor: const Color(0xFFFB7299),
                labelColor: const Color(0xFFFB7299),
                unselectedLabelColor: Colors.grey,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 300,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildQrLogin(authState),
                    _buildCookieLogin(authState),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQrLogin(AuthState state) {
    if (state.status == AuthStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.qrcodeUrl == null) {
      return Center(
        child: ElevatedButton(
          onPressed: () => ref.read(authProvider.notifier).startQrLogin(),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFB7299),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: const Text('Generate QR Code'),
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: QrImageView(
            data: state.qrcodeUrl!,
            version: QrVersions.auto,
            size: 180.0,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          state.status == AuthStatus.waitingConfirm
              ? 'Please confirm on your phone'
              : 'Scan with Bilibili App',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        if (state.status == AuthStatus.qrcodeExpired) ...[
          const SizedBox(height: 8),
          const Text('QR Code Expired', style: TextStyle(color: Colors.red)),
          TextButton(
            onPressed: () => ref.read(authProvider.notifier).startQrLogin(),
            child: const Text('Refresh'),
          ),
        ],
      ],
    );
  }

  Widget _buildCookieLogin(AuthState state) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildTextField(
            _sessdataController,
            'SESSDATA',
            'e.g. 12345678,abcd...',
          ),
          const SizedBox(height: 12),
          _buildTextField(_biliJctController, 'bili_jct', 'e.g. 98765432...'),
          const SizedBox(height: 12),
          _buildTextField(_dedeUserIdController, 'DedeUserID', 'e.g. 18273645'),
          const SizedBox(height: 24),
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                state.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.status == AuthStatus.loading
                  ? null
                  : () {
                      ref
                          .read(authProvider.notifier)
                          .loginWithCookie(
                            sessdata: _sessdataController.text.trim(),
                            biliJct: _biliJctController.text.trim(),
                            dedeUserId: _dedeUserIdController.text.trim(),
                          );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFB7299),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: state.status == AuthStatus.loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Login'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        labelStyle: const TextStyle(fontSize: 14),
        hintStyle: TextStyle(fontSize: 12, color: Colors.grey.withOpacity(0.6)),
      ),
    );
  }
}
