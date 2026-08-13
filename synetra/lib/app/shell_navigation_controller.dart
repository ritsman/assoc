part of '../main.dart';

@immutable
class AppShellNavigationState {
  const AppShellNavigationState({
    required this.isDrawerOpen,
    required this.selectedArena,
    required this.memberArenaSection,
    required this.vendorArenaSection,
    required this.adminArenaSection,
    required this.associationArenaSection,
    required this.eventsArenaSection,
  });

  const AppShellNavigationState.initial()
    : isDrawerOpen = false,
      selectedArena = AppArena.dashboard,
      memberArenaSection = MemberArenaSection.media,
      vendorArenaSection = VendorArenaSection.category,
      adminArenaSection = AdminArenaSection.appAccess,
      associationArenaSection = AssociationArenaSection.profile,
      eventsArenaSection = EventsArenaSection.master;

  final bool isDrawerOpen;
  final AppArena selectedArena;
  final MemberArenaSection memberArenaSection;
  final VendorArenaSection vendorArenaSection;
  final AdminArenaSection adminArenaSection;
  final AssociationArenaSection associationArenaSection;
  final EventsArenaSection eventsArenaSection;

  AppShellNavigationState copyWith({
    bool? isDrawerOpen,
    AppArena? selectedArena,
    MemberArenaSection? memberArenaSection,
    VendorArenaSection? vendorArenaSection,
    AdminArenaSection? adminArenaSection,
    AssociationArenaSection? associationArenaSection,
    EventsArenaSection? eventsArenaSection,
  }) {
    return AppShellNavigationState(
      isDrawerOpen: isDrawerOpen ?? this.isDrawerOpen,
      selectedArena: selectedArena ?? this.selectedArena,
      memberArenaSection: memberArenaSection ?? this.memberArenaSection,
      vendorArenaSection: vendorArenaSection ?? this.vendorArenaSection,
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
        other.vendorArenaSection == vendorArenaSection &&
        other.adminArenaSection == adminArenaSection &&
        other.associationArenaSection == associationArenaSection &&
        other.eventsArenaSection == eventsArenaSection;
  }

  @override
  int get hashCode => Object.hash(
    isDrawerOpen,
    selectedArena,
    memberArenaSection,
    vendorArenaSection,
    adminArenaSection,
    associationArenaSection,
    eventsArenaSection,
  );
}

class ShellNavigationController extends ChangeNotifier {
  AppShellNavigationState _state = const AppShellNavigationState.initial();
  final List<AppShellNavigationState> _history = [];

  AppShellNavigationState get state => _state;

  bool get _isAtInitialLandingState =>
      _history.isEmpty &&
      _state.selectedArena == AppArena.dashboard &&
      _state.memberArenaSection == MemberArenaSection.media &&
      _state.vendorArenaSection == VendorArenaSection.category &&
      _state.adminArenaSection == AdminArenaSection.appAccess &&
      _state.associationArenaSection == AssociationArenaSection.profile &&
      _state.eventsArenaSection == EventsArenaSection.master;

  bool arenaHasNestedMenu(
    AppViewerRole viewerRole,
    AppArena arena, {
    bool disableAdminFunctionsFromApp = false,
  }) {
    return (AppRoleVisibility.canSeeAdminArena(
              viewerRole,
              disableAdminFunctionsFromApp: disableAdminFunctionsFromApp,
            ) &&
            arena == AppArena.admin) ||
        arena == AppArena.association ||
        arena == AppArena.member ||
        (AppRoleVisibility.canSeeVendorArena(viewerRole) &&
            arena == AppArena.vendor) ||
        arena == AppArena.events;
  }

  bool needsNormalization(
    AppViewerRole viewerRole, {
    bool disableAdminFunctionsFromApp = false,
  }) {
    if (viewerRole.isAdmin) {
      return disableAdminFunctionsFromApp &&
          _state.selectedArena == AppArena.admin;
    }

    if (_isAtInitialLandingState &&
        _state.selectedArena !=
            AppRoleVisibility.preferredHomeArena(viewerRole)) {
      return true;
    }

    return !AppRoleVisibility.visibleArenas(
          viewerRole,
          disableAdminFunctionsFromApp: disableAdminFunctionsFromApp,
        ).contains(_state.selectedArena) ||
        _state.selectedArena == AppArena.admin ||
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

  void normalizeForRole(
    AppViewerRole viewerRole, {
    bool disableAdminFunctionsFromApp = false,
  }) {
    if (viewerRole.isAdmin && !disableAdminFunctionsFromApp) {
      return;
    }

    var nextState = _state;
    final preferredHome = AppRoleVisibility.preferredHomeArena(viewerRole);

    if (_isAtInitialLandingState &&
        nextState.selectedArena == AppArena.dashboard) {
      nextState = nextState.copyWith(
        selectedArena: preferredHome,
        memberArenaSection: MemberArenaNavigation.defaultSection(viewerRole),
        vendorArenaSection: VendorArenaNavigation.defaultSection(viewerRole),
        associationArenaSection: AssociationArenaNavigation.defaultSection(
          viewerRole,
        ),
        eventsArenaSection: EventsArenaNavigation.defaultSection(viewerRole),
        isDrawerOpen: false,
      );
    }

    if (!AppRoleVisibility.visibleArenas(
      viewerRole,
      disableAdminFunctionsFromApp: disableAdminFunctionsFromApp,
    ).contains(nextState.selectedArena)) {
      nextState = nextState.copyWith(
        selectedArena: preferredHome,
        isDrawerOpen: false,
      );
    }

    if (nextState.selectedArena == AppArena.admin &&
        !AppRoleVisibility.canSeeAdminArena(
          viewerRole,
          disableAdminFunctionsFromApp: disableAdminFunctionsFromApp,
        )) {
      nextState = nextState.copyWith(
        selectedArena: preferredHome,
        isDrawerOpen: false,
      );
    }

    if (nextState.selectedArena == AppArena.member &&
        AppRoleVisibility.canSeeMemberArena(viewerRole)) {
      nextState = nextState.copyWith(
        memberArenaSection: MemberArenaNavigation.normalizeSection(
          viewerRole,
          nextState.memberArenaSection,
        ),
      );
    }

    if (nextState.selectedArena == AppArena.association &&
        AppRoleVisibility.canSeeAssociationArena(viewerRole)) {
      nextState = nextState.copyWith(
        associationArenaSection: AssociationArenaNavigation.normalizeSection(
          viewerRole,
          nextState.associationArenaSection,
        ),
      );
    }

    if (nextState.selectedArena == AppArena.vendor &&
        AppRoleVisibility.canSeeVendorArena(viewerRole)) {
      nextState = nextState.copyWith(
        vendorArenaSection: VendorArenaNavigation.normalizeSection(
          viewerRole,
          nextState.vendorArenaSection,
        ),
      );
    }

    if (nextState.selectedArena == AppArena.events &&
        AppRoleVisibility.canSeeEventsArena(viewerRole)) {
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

  void selectArena(
    AppViewerRole viewerRole,
    AppArena arena, {
    bool disableAdminFunctionsFromApp = false,
  }) {
    if (!AppRoleVisibility.visibleArenas(
      viewerRole,
      disableAdminFunctionsFromApp: disableAdminFunctionsFromApp,
    ).contains(arena)) {
      return;
    }

    _navigateTo(
      _state.copyWith(
        selectedArena: arena,
        isDrawerOpen:
            arenaHasNestedMenu(
                  viewerRole,
                  arena,
                  disableAdminFunctionsFromApp: disableAdminFunctionsFromApp,
                )
                ? _state.isDrawerOpen
                : false,
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

  void selectAdminSection(
    AppViewerRole viewerRole,
    AdminArenaSection section, {
    bool disableAdminFunctionsFromApp = false,
  }) {
    if (!AppRoleVisibility.canManageAdminArena(
      viewerRole,
      disableAdminFunctionsFromApp: disableAdminFunctionsFromApp,
    )) {
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

  void selectVendorSection(
    AppViewerRole viewerRole,
    VendorArenaSection section,
  ) {
    final nextSection = VendorArenaNavigation.normalizeSection(
      viewerRole,
      section,
    );

    _navigateTo(
      _state.copyWith(
        selectedArena: AppArena.vendor,
        vendorArenaSection: nextSection,
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
        _setState(_state.copyWith(associationArenaSection: backSection));
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
