part of '../main.dart';

class AssociationArenaNavigation {
  const AssociationArenaNavigation._();

  static AssociationArenaSection defaultSection(AppViewerRole role) =>
      AssociationArenaSection.profile;

  static List<AssociationArenaSection> visibleSections(AppViewerRole role) =>
      AssociationArenaSection.values
          .where((section) => section != AssociationArenaSection.master)
          .toList();

  static AssociationArenaSection normalizeSection(
    AppViewerRole role,
    AssociationArenaSection section,
  ) {
    if (section == AssociationArenaSection.master) {
      return AssociationArenaSection.profile;
    }
    return section;
  }

  static AssociationArenaSection? backTarget(
    AppViewerRole role,
    AssociationArenaSection current,
  ) {
    final root = defaultSection(role);
    return current == root ? null : root;
  }

  static bool usesBreadcrumbInsteadOfHero(AssociationArenaSection section) {
    return section == AssociationArenaSection.gallery ||
        section == AssociationArenaSection.circulars;
  }

  static bool shouldHideShellHeader(AssociationArenaSection section) {
    return section == AssociationArenaSection.profile ||
        section == AssociationArenaSection.aboutUs ||
        section == AssociationArenaSection.master ||
        section == AssociationArenaSection.managementCommittee;
  }

  static bool shouldAutoHideBottomBar(AssociationArenaSection section) {
    return shouldHideShellHeader(section) ||
        usesBreadcrumbInsteadOfHero(section);
  }
}
