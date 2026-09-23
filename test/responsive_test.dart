import 'package:dino/core/ui/responsive/app_responsive.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('classifies viewport widths without gaps', () {
    expect(AppResponsive.screenSize(0), AppScreenSize.compact);
    expect(AppResponsive.screenSize(599.9), AppScreenSize.compact);
    expect(AppResponsive.screenSize(600), AppScreenSize.medium);
    expect(AppResponsive.screenSize(839.9), AppScreenSize.medium);
    expect(AppResponsive.screenSize(840), AppScreenSize.expanded);
  });
}
