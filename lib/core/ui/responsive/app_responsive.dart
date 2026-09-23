enum AppScreenSize { compact, medium, expanded }

abstract final class AppResponsive {
  static const compactWidth = 600.0;
  static const mediumWidth = 840.0;
  static const compactHeight = 480.0;
  static const maxMapWidth = 720.0;
  static const maxContentWidth = 1200.0;

  static AppScreenSize screenSize(double width) => switch (width) {
    < compactWidth => AppScreenSize.compact,
    < mediumWidth => AppScreenSize.medium,
    _ => AppScreenSize.expanded,
  };
}
