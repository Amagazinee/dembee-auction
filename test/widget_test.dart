import 'package:flutter_test/flutter_test.dart';

import 'package:dembee_app/core/constants/app_constants.dart';

void main() {
  test('App constants are configured', () {
    expect(AppConstants.appName, 'Дэмбээ');
    expect(AppConstants.bidIncrements, [1, 2, 3, 4, 5]);
  });
}
