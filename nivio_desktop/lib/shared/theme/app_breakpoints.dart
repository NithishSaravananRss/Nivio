/// Desktop breakpoint and layout size tokens.
abstract final class AppBreakpoints {
  static const double compact = 1024;
  static const double standard = 1200;
  static const double large = 1600;
  static const double ultraWide = 1920;
  static const double compactShell = 720;
  static const double sidebarExpandedWidth = 240;
  static const double sidebarCollapsedWidth = 72;
  static const double topbarHeight = 64;
  static const double contentMaxWidth = 1680;
  static const double settingsMaxWidth = 1200;
  static const double scrollbarWidth = 10;
  static const double posterRatio = 2 / 3;
  static const double landscapeRatio = 16 / 9;
  static const double heroRatio = 21 / 9;

  static bool isCompact(double width) => width < standard;
  static bool isStandard(double width) => width >= standard && width < large;
  static bool isLarge(double width) => width >= large && width < ultraWide;
  static bool isUltraWide(double width) => width >= ultraWide;
}
