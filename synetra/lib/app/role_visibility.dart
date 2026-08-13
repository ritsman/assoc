part of '../main.dart';

class AppRoleVisibility {
  const AppRoleVisibility._();

  static bool canSeeAdminArena(
    AppViewerRole role, {
    bool disableAdminFunctionsFromApp = false,
  }) => role.isAdmin && !disableAdminFunctionsFromApp;

  static bool canManageAdminArena(
    AppViewerRole role, {
    bool disableAdminFunctionsFromApp = false,
  }) => role.isAdmin && !disableAdminFunctionsFromApp;

  static bool canSeeMemberArena(AppViewerRole role) =>
      role.isAdmin || role.isVendor;

  static bool canSeeVendorArena(AppViewerRole role) =>
      role.isAdmin || role.isMember;

  static bool canSeeAssociationArena(AppViewerRole role) =>
      role.isAdmin || role.isMember || role.isVendor;

  static bool canSeeEventsArena(AppViewerRole role) =>
      role.isAdmin || role.isMember || role.isVendor;

  static AppArena preferredHomeArena(AppViewerRole role) => AppArena.dashboard;

  static List<AppArena> visibleArenas(
    AppViewerRole role, {
    bool disableAdminFunctionsFromApp = false,
  }) => [
    AppArena.dashboard,
    if (canSeeAdminArena(
      role,
      disableAdminFunctionsFromApp: disableAdminFunctionsFromApp,
    ))
      AppArena.admin,
    if (canSeeAssociationArena(role)) AppArena.association,
    if (canSeeMemberArena(role)) AppArena.member,
    if (canSeeVendorArena(role)) AppArena.vendor,
    if (canSeeEventsArena(role)) AppArena.events,
    AppArena.timeline,
    AppArena.profile,
  ];

  static List<MemberArenaSection> visibleMemberSections(AppViewerRole role) =>
      MemberArenaNavigation.visibleSections(role);

  static List<AssociationArenaSection> visibleAssociationSections(
    AppViewerRole role,
  ) => AssociationArenaNavigation.visibleSections(role);

  static List<VendorArenaSection> visibleVendorSections(AppViewerRole role) =>
      VendorArenaNavigation.visibleSections(role);

  static List<EventsArenaSection> visibleEventSections(AppViewerRole role) =>
      EventsArenaNavigation.visibleSections(role);

  static String shellRoleTitle(AppViewerRole role) => switch (role) {
    AppViewerRole.admin => 'NIMA Admin',
    AppViewerRole.member => 'NIMA Member',
    AppViewerRole.vendor => 'NIMA Vendor',
    AppViewerRole.viewOnly => 'NIMA Viewer',
  };

  static String shellRoleSubtitle(AppViewerRole role) => switch (role) {
    AppViewerRole.admin => 'Admin access',
    AppViewerRole.member => 'Member access',
    AppViewerRole.vendor => 'Vendor access',
    AppViewerRole.viewOnly => 'Viewer access',
  };
}
