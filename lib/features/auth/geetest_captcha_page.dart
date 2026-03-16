import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class GeetestResult {
  final String validate;
  final String seccode;
  final String challenge;

  GeetestResult({
    required this.validate,
    required this.seccode,
    required this.challenge,
  });

  Map<String, String> toMap() {
    return {
      'validate': validate,
      'seccode': seccode,
      'challenge': challenge,
    };
  }
}

class GeetestCaptchaPage extends StatefulWidget {
  final String gt;
  final String challenge;

  const GeetestCaptchaPage({
    super.key,
    required this.gt,
    required this.challenge,
  });

  @override
  State<GeetestCaptchaPage> createState() => _GeetestCaptchaPageState();
}

class _GeetestCaptchaPageState extends State<GeetestCaptchaPage> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;

  @override
  Widget build(BuildContext context) {
    final String htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Captcha</title>
    <script src="https://static.geetest.com/static/tools/gt.js"></script>
    <style>
        body { margin: 0; display: flex; justify-content: center; align-items: center; height: 100vh; background: #121212; }
    </style>
</head>
<body>
    <div id="captcha"></div>
    <script>
        initGeetest({
            gt: "${widget.gt}",
            challenge: "${widget.challenge}",
            offline: false,
            new_captcha: true,
            product: "embed",
            width: "100%"
        }, function (captchaObj) {
            captchaObj.appendTo('#captcha');
            captchaObj.onSuccess(function () {
                var result = captchaObj.getValidate();
                window.flutter_inappwebview.callHandler('onSuccess', result);
            });
            captchaObj.onError(function (error) {
                window.flutter_inappwebview.callHandler('onError', error.message);
            });
        });
    </script>
</body>
</html>
''';

    return Scaffold(
      appBar: AppBar(
        title: const Text('验证码校验'),
        backgroundColor: const Color(0xFF121212),
      ),
      body: InAppWebView(
        key: webViewKey,
        initialData: InAppWebViewInitialData(data: htmlContent),
        onWebViewCreated: (controller) {
          webViewController = controller;
          controller.addJavaScriptHandler(
            handlerName: 'onSuccess',
            callback: (args) {
              final result = args[0];
              Navigator.of(context).pop(GeetestResult(
                validate: result['geetest_validate'],
                seccode: result['geetest_seccode'],
                challenge: result['geetest_challenge'],
              ));
            },
          );
          controller.addJavaScriptHandler(
            handlerName: 'onError',
            callback: (args) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('验证失败: \${args[0]}')),
              );
            },
          );
        },
      ),
    );
  }
}
