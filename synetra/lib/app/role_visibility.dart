part of '../main.dart';

class AppRoleVisibility {
  const AppRoleVisibility._();

  static bool canSeeAdminArena(AppViewerRole role) => role.isAdmin;

  static bool canManageAdminArena(AppViewerRole role) => role.isAdmin;

  static List<AppArena> visibleArenas(AppViewerRole role) => [
    AppArena.dashboard,
    if (canSeeAdminArena(role)) AppArena.admin,
    AppArena.association,
    AppArena.member,
    AppArena.vendor,
    AppArena.events,
    AppArena.profile,
  ];

  static List<MemberArenaSection> visibleMemberSections(AppViewerRole role) =>
      MemberArenaNavigation.visibleSections(role);

  static List<AssociationArenaSection> visibleAssociationSections(
    AppViewerRole role,
  ) => AssociationArenaNavigation.visibleSections(role);

  static List<EventsArenaSection> visibleEventSections(AppViewerRole role) =>
      EventsArenaNavigation.visibleSections(role);

  static String shellRoleTitle(AppViewerRole role) =>
      role.isAdmin ? 'Synetra Admin' : 'Synetra Member';

  static String shellRoleSubtitle(AppViewerRole role) =>
      role.isAdmin ? 'Admin access' : 'Member access';
}
