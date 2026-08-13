part of '../../main.dart';

class AppSessionState {
  const AppSessionState({
    required this.isAuthenticated,
    required this.username,
    required this.viewerRole,
    required this.authToken,
    required this.refreshToken,
    required this.sessionId,
  });

  const AppSessionState.signedOut()
    : isAuthenticated = false,
      username = '',
      viewerRole = AppViewerRole.viewOnly,
      authToken = '',
      refreshToken = '',
      sessionId = '';

  final bool isAuthenticated;
  final String username;
  final AppViewerRole viewerRole;
  final String authToken;
  final String refreshToken;
  final String sessionId;

  AppSessionState copyWith({
    bool? isAuthenticated,
    String? username,
    AppViewerRole? viewerRole,
    String? authToken,
    String? refreshToken,
    String? sessionId,
  }) {
    return AppSessionState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      username: username ?? this.username,
      viewerRole: viewerRole ?? this.viewerRole,
      authToken: authToken ?? this.authToken,
      refreshToken: refreshToken ?? this.refreshToken,
      sessionId: sessionId ?? this.sessionId,
    );
  }

  bool get hasAuthToken => authToken.trim().isNotEmpty;
  bool get hasRefreshToken => refreshToken.trim().isNotEmpty;

  static Future<AppSessionState> loadFromStorage(
    SharedPreferences preferences,
    FlutterSecureStorage secureStorage,
  ) async {
    final isAuthenticated =
        preferences.getBool(_SessionStorageKeys.isAuthenticated) ?? false;
    if (!isAuthenticated) {
      return const AppSessionState.signedOut();
    }

    final username = preferences.getString(_SessionStorageKeys.username) ?? '';
    final viewerRoleName =
        preferences.getString(_SessionStorageKeys.viewerRole) ??
        AppViewerRole.viewOnly.name;
    final viewerRole = AppViewerRole.values.firstWhere(
      (role) => role.name == viewerRoleName,
      orElse: () => AppViewerRole.viewOnly,
    );
    final authToken =
        await secureStorage.read(key: _SessionStorageKeys.authToken) ?? '';
    final refreshToken =
        await secureStorage.read(key: _SessionStorageKeys.refreshToken) ?? '';
    final sessionId =
        await secureStorage.read(key: _SessionStorageKeys.sessionId) ?? '';

    if (authToken.trim().isEmpty && refreshToken.trim().isEmpty) {
      return const AppSessionState.signedOut();
    }

    return AppSessionState(
      isAuthenticated: true,
      username: username,
      viewerRole: viewerRole,
      authToken: authToken,
      refreshToken: refreshToken,
      sessionId: sessionId,
    );
  }
}

class TenantContext {
  const TenantContext({
    required this.associationId,
    required this.associationName,
    required this.city,
    required this.state,
  });

  factory TenantContext.fromProfile(AssociationProfileData profile) {
    return TenantContext(
      associationId: profile.id,
      associationName: profile.name,
      city: profile.city,
      state: profile.state,
    );
  }

  final String associationId;
  final String associationName;
  final String city;
  final String state;

  String get locationLabel =>
      [city, state].where((part) => part.trim().isNotEmpty).join(', ');
}

class AppLockState {
  const AppLockState({
    required this.biometricEnabled,
    required this.hasPin,
    required this.isUnlocked,
  });

  const AppLockState.unconfigured()
    : biometricEnabled = false,
      hasPin = false,
      isUnlocked = true;

  final bool biometricEnabled;
  final bool hasPin;
  final bool isUnlocked;

  bool get requiresUnlock => biometricEnabled || hasPin;

  AppLockState copyWith({
    bool? biometricEnabled,
    bool? hasPin,
    bool? isUnlocked,
  }) {
    return AppLockState(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      hasPin: hasPin ?? this.hasPin,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }

  static Future<AppLockState> loadFromStorage(
    SharedPreferences preferences,
    FlutterSecureStorage secureStorage, {
    required bool hasActiveSession,
  }) async {
    final biometricEnabled =
        preferences.getBool(_AppLockStorageKeys.biometricEnabled) ?? false;
    final storedPin = await secureStorage.read(key: _AppLockStorageKeys.pin);
    final hasPin = (storedPin ?? '').trim().isNotEmpty;
    final requiresUnlock = biometricEnabled || hasPin;

    return AppLockState(
      biometricEnabled: biometricEnabled,
      hasPin: hasPin,
      isUnlocked: !hasActiveSession || !requiresUnlock,
    );
  }
}

class SessionController extends Notifier<AppSessionState> {
  @override
  AppSessionState build() => ref.watch(initialSessionStateProvider);

  void signIn(AuthSession authSession) {
    _applySession(authSession, unlockSession: true);
  }

  Future<void> signInAndWarm(AuthSession authSession) async {
    ref.read(startupWarmupProvider.notifier).state = true;
    try {
      _applySession(authSession, unlockSession: true);
      await _warmAuthenticatedStartup(ref, authSession.viewerRole);
    } finally {
      ref.read(startupWarmupProvider.notifier).state = false;
    }
  }

  void syncSession(AuthSession authSession) {
    _applySession(authSession, unlockSession: false);
  }

  void _applySession(AuthSession authSession, {required bool unlockSession}) {
    state = AppSessionState(
      isAuthenticated: true,
      username: authSession.email,
      viewerRole: authSession.viewerRole,
      authToken: authSession.authToken,
      refreshToken:
          authSession.refreshToken.trim().isNotEmpty
              ? authSession.refreshToken
              : state.refreshToken,
      sessionId: authSession.sessionId,
    );
    if (unlockSession) {
      ref.read(appLockProvider.notifier).unlockForActiveSession();
    }
    unawaited(_persistState());
  }

  void setViewerRole(AppViewerRole viewerRole) {
    state = state.copyWith(viewerRole: viewerRole);
    unawaited(_persistState());
  }

  void signOut() {
    state = const AppSessionState.signedOut();
    ref.read(appLockProvider.notifier).resetForSignedOutState();
    unawaited(_persistState());
  }

  Future<bool> restoreSession() async {
    if (!state.hasRefreshToken) {
      signOut();
      return false;
    }

    try {
      if (!state.hasAuthToken) {
        final refreshedToken = await refreshAccessToken();
        return refreshedToken != null;
      }

      final authSession =
          await ref.read(apiClientProvider).fetchCurrentSession();
      syncSession(authSession);
      return true;
    } catch (_) {
      final refreshedToken = await refreshAccessToken();
      return refreshedToken != null;
    }
  }

  Future<String?> refreshAccessToken() async {
    if (!state.hasRefreshToken) {
      signOut();
      return null;
    }

    try {
      final authSession = await SynetraApiClient().refreshSession(
        refreshToken: state.refreshToken,
      );
      syncSession(authSession);
      return authSession.authToken;
    } catch (_) {
      signOut();
      return null;
    }
  }

  Future<void> _persistState() async {
    final preferences = ref.read(sharedPreferencesProvider);
    final secureStorage = ref.read(secureStorageProvider);
    await preferences.setBool(
      _SessionStorageKeys.isAuthenticated,
      state.isAuthenticated,
    );
    await preferences.setString(_SessionStorageKeys.username, state.username);
    await preferences.setString(
      _SessionStorageKeys.viewerRole,
      state.viewerRole.name,
    );
    if (state.isAuthenticated && state.authToken.trim().isNotEmpty) {
      await secureStorage.write(
        key: _SessionStorageKeys.authToken,
        value: state.authToken,
      );
      await secureStorage.write(
        key: _SessionStorageKeys.refreshToken,
        value: state.refreshToken,
      );
      await secureStorage.write(
        key: _SessionStorageKeys.sessionId,
        value: state.sessionId,
      );
      return;
    }

    await secureStorage.delete(key: _SessionStorageKeys.authToken);
    await secureStorage.delete(key: _SessionStorageKeys.refreshToken);
    await secureStorage.delete(key: _SessionStorageKeys.sessionId);
  }
}

class _SessionStorageKeys {
  const _SessionStorageKeys._();

  static const isAuthenticated = 'session.isAuthenticated';
  static const username = 'session.username';
  static const viewerRole = 'session.viewerRole';
  static const authToken = 'session.authToken';
  static const refreshToken = 'session.refreshToken';
  static const sessionId = 'session.sessionId';
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences has not been initialized.');
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  throw UnimplementedError('FlutterSecureStorage has not been initialized.');
});

final localAuthenticationProvider = Provider<LocalAuthentication>((ref) {
  throw UnimplementedError('LocalAuthentication has not been initialized.');
});

final initialSessionStateProvider = Provider<AppSessionState>((ref) {
  return const AppSessionState.signedOut();
});

final initialAppLockStateProvider = Provider<AppLockState>((ref) {
  return const AppLockState.unconfigured();
});

final apiClientProvider = Provider<SynetraApiClient>((ref) {
  final authToken = ref.watch(
    sessionProvider.select((session) => session.authToken),
  );
  return SynetraApiClient(
    authToken: authToken,
    refreshAuthToken:
        () => ref.read(sessionProvider.notifier).refreshAccessToken(),
  );
});

final sessionProvider = NotifierProvider<SessionController, AppSessionState>(
  SessionController.new,
);

class AppLockController extends Notifier<AppLockState> {
  @override
  AppLockState build() => ref.watch(initialAppLockStateProvider);

  Future<bool> enableBiometrics() async {
    final localAuth = ref.read(localAuthenticationProvider);
    final canUseBiometrics =
        await localAuth.canCheckBiometrics ||
        await localAuth.isDeviceSupported();
    if (!canUseBiometrics) {
      return false;
    }
    state = state.copyWith(biometricEnabled: true);
    await _persist();
    return true;
  }

  Future<void> disableBiometrics() async {
    state = state.copyWith(biometricEnabled: false);
    await _persist();
  }

  Future<void> setPin(String pin) async {
    final secureStorage = ref.read(secureStorageProvider);
    await secureStorage.write(key: _AppLockStorageKeys.pin, value: pin);
    state = state.copyWith(hasPin: true);
    await _persist();
  }

  Future<void> clearPin() async {
    final secureStorage = ref.read(secureStorageProvider);
    await secureStorage.delete(key: _AppLockStorageKeys.pin);
    state = state.copyWith(hasPin: false);
    await _persist();
  }

  Future<bool> verifyPin(String pin) async {
    final secureStorage = ref.read(secureStorageProvider);
    final savedPin =
        await secureStorage.read(key: _AppLockStorageKeys.pin) ?? '';
    if (savedPin == pin && pin.isNotEmpty) {
      state = state.copyWith(isUnlocked: true);
      return true;
    }
    return false;
  }

  Future<bool> unlockWithBiometrics() async {
    final localAuth = ref.read(localAuthenticationProvider);
    final didAuthenticate = await localAuth.authenticate(
      localizedReason: 'Unlock NIMA',
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
      ),
    );
    if (didAuthenticate) {
      state = state.copyWith(isUnlocked: true);
    }
    return didAuthenticate;
  }

  void unlockForActiveSession() {
    state = state.copyWith(isUnlocked: true);
  }

  void lockForCurrentSession() {
    if (state.requiresUnlock) {
      state = state.copyWith(isUnlocked: false);
    }
  }

  void resetForSignedOutState() {
    state = state.copyWith(isUnlocked: true);
  }

  Future<void> _persist() async {
    final preferences = ref.read(sharedPreferencesProvider);
    await preferences.setBool(
      _AppLockStorageKeys.biometricEnabled,
      state.biometricEnabled,
    );
  }
}

class _AppLockStorageKeys {
  const _AppLockStorageKeys._();

  static const biometricEnabled = 'appLock.biometricEnabled';
  static const pin = 'appLock.pin';
}

final appLockProvider = NotifierProvider<AppLockController, AppLockState>(
  AppLockController.new,
);

final startupWarmupProvider = StateProvider<bool>((ref) => false);

final sessionRestoreProvider = FutureProvider<bool>((ref) async {
  final restored = await ref.read(sessionProvider.notifier).restoreSession();
  if (!restored) {
    return false;
  }

  final session = ref.read(sessionProvider);
  if (!session.isAuthenticated) {
    return false;
  }

  await _warmAuthenticatedStartup(ref, session.viewerRole);
  return true;
});

final associationProfileProvider = FutureProvider<AssociationProfileData>(
  (ref) => ref.watch(apiClientProvider).fetchAssociationProfile(),
);

final associationAboutProvider = FutureProvider<AssociationAboutData>(
  (ref) => ref.watch(apiClientProvider).fetchAssociationAbout(),
);

final associationCircularLibraryProvider =
    FutureProvider<AssociationCircularLibraryData>(
      (ref) => ref.watch(apiClientProvider).fetchAssociationCircularLibrary(),
    );

final memberDirectoryProvider = FutureProvider<List<MemberDirectoryItem>>(
  (ref) => ref.watch(apiClientProvider).fetchMembers(),
);

final memberArenaDataProvider =
    FutureProvider.family<MemberArenaData, AppViewerRole>(
      (ref, viewerRole) => ref
          .watch(apiClientProvider)
          .loadMemberArenaData(viewerRole: viewerRole),
    );

final adminArenaDataProvider = FutureProvider<AdminArenaData>(
  (ref) => ref.watch(apiClientProvider).loadAdminArenaData(),
);

final appAccessProvider = FutureProvider<AdminAppAccessSettings>(
  (ref) => ref.watch(apiClientProvider).fetchAppAccess(),
);

final eventsArenaDataProvider = FutureProvider<EventsArenaData>(
  (ref) => ref.watch(apiClientProvider).loadEventsArenaData(),
);

final dashboardDataProvider = FutureProvider<DashboardData>(
  (ref) => ref.watch(apiClientProvider).loadDashboardData(),
);

final sessionReportProvider = FutureProvider<SessionReportData>(
  (ref) => ref.watch(apiClientProvider).fetchSessionReport(),
);

final vendorDirectoryProvider = FutureProvider<List<DashboardVendorItem>>(
  (ref) => ref.watch(apiClientProvider).fetchVendors(),
);

final vendorTaxonomyProvider = FutureProvider<List<VendorTaxonomyCategoryItem>>(
  (ref) => ref.watch(apiClientProvider).fetchVendorTaxonomy(),
);

final tenantProvider = FutureProvider<TenantContext>((ref) async {
  final profile = await ref.watch(associationProfileProvider.future);
  return TenantContext.fromProfile(profile);
});

Future<void> _warmAuthenticatedStartup(
  Ref ref,
  AppViewerRole viewerRole,
) async {
  final warmupTasks = <Future<void>>[
    ref.read(associationProfileProvider.future).then((_) {}),
    ref.read(tenantProvider.future).then((_) {}),
  ];

  if (AppRoleVisibility.preferredHomeArena(viewerRole) == AppArena.dashboard) {
    warmupTasks.add(ref.read(dashboardDataProvider.future).then((_) {}));
  }

  await Future.wait(
    warmupTasks.map((task) => task.catchError((_) {})),
    eagerError: false,
  );
}
