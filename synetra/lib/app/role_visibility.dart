part of '../main.dart';

class AppRoleVisibility {
  const AppRoleVisibility._();

  static bool canSeeAdminArena(AppViewerRole role) => role.isAdmin;

  static bool canManageAdminArena(AppViewerRole role) => role.isAdmin;

  static bool canSeeMemberArena(AppViewerRole role) =>
      role.isAdmin || role.isVendor;

  static bool canSeeVendorArena(AppViewerRole role) =>
      role.isAdmin || role.isMember || role.isVendor;

  static bool canSeeAssociationArena(AppViewerRole role) =>
      role.isAdmin || role.isMember || role.isVendor;

  static bool canSeeEventsArena(AppViewerRole role) =>
      role.isAdmin || role.isMember || role.isVendor;

  static List<AppArena> visibleArenas(AppViewerRole role) => [
    AppArena.dashboard,
    if (canSeeAdminArena(role)) AppArena.admin,
    if (canSeeAssociationArena(role)) AppArena.association,
    if (canSeeMemberArena(role)) AppArena.member,
    if (canSeeVendorArena(role)) AppArena.vendor,
    if (canSeeEventsArena(role)) AppArena.events,
    AppArena.profile,
  ];

  static List<MemberArenaSection> visibleMemberSections(AppViewerRole role) =>
      MemberArenaNavigation.visibleSections(role);

  static List<AssociationArenaSection> visibleAssociationSections(
    AppViewerRole role,
  ) => AssociationArenaNavigation.visibleSections(role);

  static List<EventsArenaSection> visibleEventSections(AppViewerRole role) =>
      EventsArenaNavigation.visibleSections(role);

  static String shellRoleTitle(AppViewerRole role) => switch (role) {
    AppViewerRole.admin => 'Synetra Admin',
    AppViewerRole.member => 'Synetra Member',
    AppViewerRole.vendor => 'Synetra Vendor',
    AppViewerRole.viewOnly => 'Synetra Viewer',
  };

  static String shellRoleSubtitle(AppViewerRole role) => switch (role) {
    AppViewerRole.admin => 'Admin access',
    AppViewerRole.member => 'Member access',
    AppViewerRole.vendor => 'Vendor access',
    AppViewerRole.viewOnly => 'Viewer access',
  };
}
