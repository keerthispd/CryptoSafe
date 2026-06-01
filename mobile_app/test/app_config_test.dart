import 'package:flutter_test/flutter_test.dart';

import 'package:cryptosafe_mobile/src/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('normalizeBaseUrl trims trailing slash', () {
      expect(AppConfig.normalizeBaseUrl('http://10.0.2.2:5000/'), 'http://10.0.2.2:5000');
    });

    test('normalizeBaseUrl falls back to default when empty', () {
      expect(AppConfig.normalizeBaseUrl(''), AppConfig.defaultBaseUrl());
    });
  });
}
