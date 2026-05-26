part of '../main.dart';

class EventsArenaNavigation {
  const EventsArenaNavigation._();

  static EventsArenaSection defaultSection(AppViewerRole role) =>
      role.isAdmin ? EventsArenaSection.master : EventsArenaSection.event;

  static List<EventsArenaSection> visibleSections(AppViewerRole role) =>
      role.isAdmin ? EventsArenaSection.values : [EventsArenaSection.event];

  static EventsArenaSection normalizeSection(
    AppViewerRole role,
    EventsArenaSection section,
  ) {
    if (!role.isAdmin && section != EventsArenaSection.event) {
      return EventsArenaSection.event;
    }
    return section;
  }

  static EventsArenaSection? backTarget(
    AppViewerRole role,
    EventsArenaSection current,
  ) {
    final root = defaultSection(role);
    return current == root ? null : root;
  }

  static bool get shouldHideShellHeader => true;

  static bool get shouldAutoHideBottomBar => false;
}
