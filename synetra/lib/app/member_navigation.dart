part of '../main.dart';

class MemberArenaNavigation {
  const MemberArenaNavigation._();

  static MemberArenaSection defaultSection(AppViewerRole role) =>
      role.isVendor
          ? MemberArenaSection.primaryMembers
          : MemberArenaSection.media;

  static List<MemberArenaSection> visibleSections(AppViewerRole role) => [
    if (role.isAdmin || role.isMember) MemberArenaSection.media,
    MemberArenaSection.primaryMembers,
    MemberArenaSection.associateMembers,
    MemberArenaSection.temporaryVisitors,
    if (role.isAdmin) MemberArenaSection.master,
  ];

  static MemberArenaSection normalizeSection(
    AppViewerRole role,
    MemberArenaSection section,
  ) {
    if (section == MemberArenaSection.allMembers ||
        section == MemberArenaSection.directory ||
        section == MemberArenaSection.committeeMembers ||
        (role.isVendor && section == MemberArenaSection.media)) {
      return MemberArenaSection.primaryMembers;
    }
    if (!role.isAdmin && section == MemberArenaSection.master) {
      return MemberArenaSection.primaryMembers;
    }
    return section;
  }

  static MemberArenaSection? backTarget(
    AppViewerRole role,
    MemberArenaSection current,
  ) {
    final root = defaultSection(role);
    return current == root ? null : root;
  }

  static bool shouldHideShellHeader(MemberArenaSection section) => true;

  static bool shouldAutoHideBottomBar(MemberArenaSection section) => true;
}
