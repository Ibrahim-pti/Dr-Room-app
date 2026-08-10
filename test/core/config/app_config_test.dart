import 'package:flutter_test/flutter_test.dart';
import 'package:dr_room/core/config/app_config.dart';

void main() {
  group('AppConfig', () {
    test('defaults to dev when no ENV is defined and this is not a release',
        () {
      expect(AppConfig.environment, Environment.dev);
      expect(AppConfig.isProd, isFalse);
    });

    test('baseUrl and storageUrl hang off the same origin', () {
      expect(AppConfig.baseUrl, endsWith('/api'));
      expect(AppConfig.storageUrl, endsWith('/storage'));

      final apiOrigin =
          AppConfig.baseUrl.substring(0, AppConfig.baseUrl.length - '/api'.length);
      final storageOrigin = AppConfig.storageUrl
          .substring(0, AppConfig.storageUrl.length - '/storage'.length);
      expect(apiOrigin, storageOrigin);
    });

    test('requests are bounded by a timeout', () {
      expect(AppConfig.requestTimeout, greaterThan(Duration.zero));
      expect(AppConfig.requestTimeout, lessThanOrEqualTo(const Duration(minutes: 1)));
    });
  });
}
