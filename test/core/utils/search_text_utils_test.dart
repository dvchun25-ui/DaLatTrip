import 'package:flutter_test/flutter_test.dart';

import 'package:dalattrip/core/utils/search_text_utils.dart';

void main() {
  group('SearchTextUtils.normalize', () {
    test('bỏ dấu tiếng Việt và khoảng trắng thừa', () {
      expect(
        SearchTextUtils.normalize('  Đặng Văn Chúng  '),
        'dang van chung',
      );
    });

    test('chuẩn hóa dấu câu thành khoảng trắng', () {
      expect(SearchTextUtils.normalize('Đà-Lạt.Trip'), 'da lat trip');
    });
  });
}
