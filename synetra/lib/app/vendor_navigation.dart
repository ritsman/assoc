part of '../main.dart';

class VendorArenaNavigation {
  const VendorArenaNavigation._();

  static VendorArenaSection defaultSection(AppViewerRole role) =>
      VendorArenaSection.vendor;

  static List<VendorArenaSection> visibleSections(AppViewerRole role) =>
      role.isAdmin
          ? VendorArenaSection.values
          : const [VendorArenaSection.vendor];

  static VendorArenaSection normalizeSection(
    AppViewerRole role,
    VendorArenaSection section,
  ) {
    if (!role.isAdmin && section != VendorArenaSection.vendor) {
      return VendorArenaSection.vendor;
    }
    return section;
  }

  static VendorArenaSection? backTarget(
    AppViewerRole role,
    VendorArenaSection current,
  ) {
    final root = defaultSection(role);
    return current == root ? null : root;
  }

  static AppArena get arena => AppArena.vendor;

  static bool get shouldHideShellHeader => true;

  static bool get shouldAutoHideBottomBar => true;
}
