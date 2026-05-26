part of '../main.dart';

@immutable
class AppShellNavigationState {
  const AppShellNavigationState({
    required this.isDrawerOpen,
    required this.selectedArena,
    required this.memberArenaSection,
    required this.adminArenaSection,
    required this.associationArenaSection,
    required this.eventsArenaSection,
  });

  const AppShellNavigationState.initial()
    : isDrawerOpen = false,
      selectedArena = AppArena.dashboard,
      memberArenaSection = MemberArenaSection.media,
      adminArenaSection = AdminArenaSection.appAccess,
      associationArenaSection = AssociationArenaSection.profile,
      eventsArenaSection = EventsArenaSection.master;

  final bool isDrawerOpen;
  final AppArena selectedArena;
  final MemberArenaSection memberArenaSection;
  final AdminArenaSection adminArenaSection;
  final AssociationArenaSection associationArenaSection;
  final EventsArenaSection eventsArenaSection;

  AppShellNavigationState copyWith({
    bool? isDrawerOpen,
    AppArena? selectedArena,
    MemberArenaSection? memberArenaSection,
    AdminArenaSection? adminArenaSection,
    AssociationArenaSection? associationArenaSection,
    EventsArenaSection? eventsArenaSection,
  }) {
    return AppShellNavigationState(
      isDrawerOpen: isDrawerOpen ?? this.isDrawerOpen,
      selectedArena: selectedArena ?? this.selectedArena,
      memberArenaSection: memberArenaSection ?? this.memberArenaSection,
      adminArenaSection: adminArenaSection ?? this.adminArenaSection,
      associationArenaSection:
          associationArenaSection ?? this.associationArenaSection,
      eventsArenaSection: eventsArenaSection ?? this.eventsArenaSection,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is AppShellNavigationState &&
        other.isDrawerOpen == isDrawerOpen &&
        other.selectedArena == selectedArena &&
        other.memberArenaSection == memberArenaSection &&
        other.adminArenaSection == adminArenaSection &&
        other.associationArenaSection == associationArenaSection &&
        other.eventsArenaSection == eventsArenaSection;
  }

  @override
  int get hashCode => Object.hash(
    isDrawerOpen,
    selectedArena,
    memberArenaSection,
    adminArenaSection,
    associationArenaSection,
    eventsArenaSection,
  );
}

class ShellNavigationController extends ChangeNotifier {
  AppShellNavigationState _state = const AppShellNavigationState.initial();
  final List<AppShellNavigationState> _history = [];

  AppShellNavigationState get state => _state;

  bool arenaHasNestedMenu(AppViewerRole viewerRole, AppArena arena) {
    return (AppRoleVisibility.canSeeAdminArena(viewerRole) &&
            arena == AppArena.admin) ||
        arena == AppArena.association ||
        arena == AppArena.member ||
        arena == AppArena.events;
  }

  bool needsNormalization(AppViewerRole viewerRole) {
    if (viewerRole.isAdmin) {
      return false;
    }

    return _state.selectedArena == AppArena.admin ||
        (_state.selectedArena == AppArena.member &&
            MemberArenaNavigation.normalizeSection(
                  viewerRole,
                  _state.memberArenaSection,
                ) !=
                _state.memberArenaSection) ||
        (_state.selectedArena == AppArena.association &&
            AssociationArenaNavigation.normalizeSection(
                  viewerRole,
                  _state.associationArenaSection,
                ) !=
                _state.associationArenaSection) ||
        (_state.selectedArena == AppArena.events &&
            EventsArenaNavigation.normalizeSection(
                  viewerRole,
                  _state.eventsArenaSection,
                ) !=
                _state.eventsArenaSection);
  }

  void normalizeForRole(AppViewerRole viewerRole) {
    if (viewerRole.isAdmin) {
      return;
    }

    var nextState = _state;

    if (nextState.selectedArena == AppArena.admin) {
      nextState = nextState.copyWith(
        selectedArena: AppArena.member,
        isDrawerOpen: false,
      );
    }

    if (nextState.selectedArena == AppArena.member) {
      nextState = nextState.copyWith(
        memberArenaSection: MemberArenaNavigation.normalizeSection(
          viewerRole,
          nextState.memberArenaSection,
        ),
      );
    }

    if (nextState.selectedArena == AppArena.association) {
      nextState = nextState.copyWith(
        associationArenaSection: AssociationArenaNavigation.normalizeSection(
          viewerRole,
          nextState.associationArenaSection,
        ),
      );
    }

    if (nextState.selectedArena == AppArena.events) {
      nextState = nextState.copyWith(
        eventsArenaSection: EventsArenaNavigation.normalizeSection(
          viewerRole,
          nextState.eventsArenaSection,
        ),
      );
    }

    _setState(nextState);
  }

  void toggleDrawer() {
    _setState(_state.copyWith(isDrawerOpen: !_state.isDrawerOpen));
  }

  void selectArena(AppViewerRole viewerRole, AppArena arena) {
    if (!AppRoleVisibility.canSeeAdminArena(viewerRole) &&
        arena == AppArena.admin) {
      return;
    }

    _navigateTo(
      _state.copyWith(
        selectedArena: arena,
        isDrawerOpen:
            arenaHasNestedMenu(viewerRole, arena) ? _state.isDrawerOpen : false,
      ),
    );
  }

  void selectMemberSection(
    AppViewerRole viewerRole,
    MemberArenaSection section,
  ) {
    final nextSection = MemberArenaNavigation.normalizeSection(
      viewerRole,
      section,
    );

    _navigateTo(
      _state.copyWith(
        selectedArena: AppArena.member,
        memberArenaSection: nextSection,
        isDrawerOpen: false,
      ),
    );
  }

  void selectAdminSection(AppViewerRole viewerRole, AdminArenaSection section) {
    if (!AppRoleVisibility.canManageAdminArena(viewerRole)) {
      return;
    }

    _navigateTo(
      _state.copyWith(
        selectedArena: AppArena.admin,
        adminArenaSection: section,
        isDrawerOpen: false,
      ),
    );
  }

  void selectAssociationSection(
    AppViewerRole viewerRole,
    AssociationArenaSection section,
  ) {
    final nextSection = AssociationArenaNavigation.normalizeSection(
      viewerRole,
      section,
    );

    _navigateTo(
      _state.copyWith(
        selectedArena: AppArena.association,
        associationArenaSection: nextSection,
        isDrawerOpen: false,
      ),
    );
  }

  void selectEventsSection(
    AppViewerRole viewerRole,
    EventsArenaSection section,
  ) {
    final nextSection = EventsArenaNavigation.normalizeSection(
      viewerRole,
      section,
    );

    _navigateTo(
      _state.copyWith(
        selectedArena: AppArena.events,
        eventsArenaSection: nextSection,
        isDrawerOpen: false,
      ),
    );
  }

  void openProfile() {
    _navigateTo(
      _state.copyWith(selectedArena: AppArena.profile, isDrawerOpen: false),
    );
  }

  void openTimeline() {
    _navigateTo(
      _state.copyWith(selectedArena: AppArena.timeline, isDrawerOpen: false),
    );
  }

  bool handleBackNavigation(AppViewerRole viewerRole) {
    if (_state.isDrawerOpen) {
      _setState(_state.copyWith(isDrawerOpen: false));
      return false;
    }

    if (_history.isNotEmpty) {
      final previousState = _history.removeLast();
      _setState(previousState.copyWith(isDrawerOpen: false));
      return false;
    }

    if (_state.selectedArena == AppArena.timeline) {
      _setState(_state.copyWith(selectedArena: AppArena.dashboard));
      return false;
    }

    if (_state.selectedArena == AppArena.profile ||
        _state.selectedArena == AppArena.vendor) {
      _setState(_state.copyWith(selectedArena: AppArena.dashboard));
      return false;
    }

    if (_state.selectedArena == AppArena.admin) {
      if (_state.adminArenaSection != AdminArenaSection.appAccess) {
        _setState(
          _state.copyWith(adminArenaSection: AdminArenaSection.appAccess),
        );
        return false;
      }
      _setState(_state.copyWith(selectedArena: AppArena.dashboard));
      return false;
    }

    if (_state.selectedArena == AppArena.association) {
      final backSection = AssociationArenaNavigation.backTarget(
        viewerRole,
        _state.associationArenaSection,
      );
      if (backSection != null) {
        _setState(
          _state.copyWith(
            associationArenaSection: backSection,
          ),
        );
        return false;
      }
      _setState(_state.copyWith(selectedArena: AppArena.dashboard));
      return false;
    }

    if (_state.selectedArena == AppArena.member) {
      final backSection = MemberArenaNavigation.backTarget(
        viewerRole,
        _state.memberArenaSection,
      );
      if (backSection != null) {
        _setState(_state.copyWith(memberArenaSection: backSection));
        return false;
      }
      _setState(_state.copyWith(selectedArena: AppArena.dashboard));
      return false;
    }

    if (_state.selectedArena == AppArena.events) {
      final backSection = EventsArenaNavigation.backTarget(
        viewerRole,
        _state.eventsArenaSection,
      );
      if (backSection != null) {
        _setState(_state.copyWith(eventsArenaSection: backSection));
        return false;
      }
      _setState(_state.copyWith(selectedArena: AppArena.dashboard));
      return false;
    }

    return true;
  }

  void _navigateTo(AppShellNavigationState nextState) {
    if (_state != nextState) {
      _history.add(_state);
    }
    _setState(nextState);
  }

  void _setState(AppShellNavigationState nextState) {
    if (_state == nextState) {
      return;
    }
    _state = nextState;
    notifyListeners();
  }
}
