part of '../main.dart';

class VendorArenaNavigation {
  const VendorArenaNavigation._();

  static AppArena get arena => AppArena.vendor;

  static AppArena get backTarget => AppArena.dashboard;

  static bool get shouldHideShellHeader => true;

  static bool get shouldAutoHideBottomBar => false;
}
