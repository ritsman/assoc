part of '../main.dart';

const _nimaBrandRed = Color(0xFFEB1C24);
const _nimaBrandRedDark = Color(0xFFCB1720);
const _nimaInk = Color(0xFF1E1E1E);
const _nimaMuted = Color(0xFF666666);
const _nimaSoftSurface = Color(0xFFFFF7F7);

enum AppViewerRole { admin, member, vendor, viewOnly }

extension AppViewerRoleLabel on AppViewerRole {
  String get label => switch (this) {
    AppViewerRole.admin => 'Admin',
    AppViewerRole.member => 'Member',
    AppViewerRole.vendor => 'Vendor',
    AppViewerRole.viewOnly => 'View only',
  };

  bool get isAdmin => this == AppViewerRole.admin;
  bool get isMember => this == AppViewerRole.member;
  bool get isVendor => this == AppViewerRole.vendor;
}

enum AppArena {
  dashboard,
  admin,
  association,
  member,
  vendor,
  events,
  profile,
  timeline,
}

extension AppArenaLabel on AppArena {
  String get label => switch (this) {
    AppArena.dashboard => 'Dashboard',
    AppArena.admin => 'Admin Arena',
    AppArena.association => 'Association Arena',
    AppArena.member => 'Member Arena',
    AppArena.vendor => 'Vendor Arena',
    AppArena.events => 'Events Arena',
    AppArena.profile => 'Profile',
    AppArena.timeline => 'Timeline',
  };
}

enum MemberArenaSection {
  media,
  directory,
  allMembers,
  primaryMembers,
  associateMembers,
  temporaryVisitors,
  committeeMembers,
  master,
}

extension MemberArenaSectionLabel on MemberArenaSection {
  String get label => switch (this) {
    MemberArenaSection.media => 'Media',
    MemberArenaSection.directory => 'Directory',
    MemberArenaSection.allMembers => 'All Members',
    MemberArenaSection.primaryMembers => 'Primary Members',
    MemberArenaSection.associateMembers => 'Associate Members',
    MemberArenaSection.temporaryVisitors => 'Guest',
    MemberArenaSection.committeeMembers => 'Committee Members',
    MemberArenaSection.master => 'Master',
  };
}

enum AdminArenaSection {
  appAccess,
  memberAccess,
  vendorAccess,
  bannerAccess,
  timelineAccess,
  eventAccess,
}

extension AdminArenaSectionLabel on AdminArenaSection {
  String get label => switch (this) {
    AdminArenaSection.appAccess => 'App Access',
    AdminArenaSection.memberAccess => 'Member Access',
    AdminArenaSection.vendorAccess => 'Vendor Access',
    AdminArenaSection.bannerAccess => 'Banner Access',
    AdminArenaSection.timelineAccess => 'Timeline Access',
    AdminArenaSection.eventAccess => 'Event Access',
  };
}

enum AssociationArenaSection {
  profile,
  aboutUs,
  finance,
  managementCommittee,
  circulars,
  gallery,
  master,
}

extension AssociationArenaSectionLabel on AssociationArenaSection {
  String get label => switch (this) {
    AssociationArenaSection.profile => 'Profile',
    AssociationArenaSection.aboutUs => 'About Us',
    AssociationArenaSection.finance => 'Finance',
    AssociationArenaSection.managementCommittee => 'Committee',
    AssociationArenaSection.circulars => 'Circulars',
    AssociationArenaSection.gallery => 'Gallery',
    AssociationArenaSection.master => 'Master',
  };
}

enum EventsArenaSection { master, createNewEvent, typeOfEvent, event }

extension EventsArenaSectionLabel on EventsArenaSection {
  String get label => switch (this) {
    EventsArenaSection.master => 'Master',
    EventsArenaSection.createNewEvent => 'Create New Event',
    EventsArenaSection.typeOfEvent => 'Type of Event',
    EventsArenaSection.event => 'Event',
  };
}

class SynetraApp extends StatelessWidget {
  const SynetraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NIMA',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _nimaBrandRed,
          brightness: Brightness.light,
        ).copyWith(
          primary: _nimaBrandRed,
          secondary: _nimaBrandRedDark,
          surface: Colors.white,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Color(0xFF171717),
            height: 1.1,
          ),
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF171717),
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF171717),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF4B5563),
          ),
          bodyMedium: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
      ),
      home: const SynetraLaunchScreen(),
    );
  }
}

class SynetraLaunchScreen extends ConsumerStatefulWidget {
  const SynetraLaunchScreen({super.key});

  @override
  ConsumerState<SynetraLaunchScreen> createState() =>
      _SynetraLaunchScreenState();
}

class _SynetraLaunchScreenState extends ConsumerState<SynetraLaunchScreen> {
  bool _showLogin = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 1800), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _showLogin = true;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final isAuthenticated = session.isAuthenticated;
    final sessionRestoreAsync = ref.watch(sessionRestoreProvider);
    final appLock = ref.watch(appLockProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child:
          !_showLogin || sessionRestoreAsync.isLoading
              ? const _SynetraSplashExperience()
              : isAuthenticated && appLock.requiresUnlock && !appLock.isUnlocked
              ? const _SynetraLoginScreen(forceUnlock: true)
              : isAuthenticated
              ? const SynetraAdminShell()
              : const _SynetraLoginScreen(),
    );
  }
}

class _SynetraSplashExperience extends StatelessWidget {
  const _SynetraSplashExperience();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(height: 28, color: _nimaBrandRed),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 24, 28, 18),
                child: Column(
                  children: [
                    const Spacer(flex: 2),
                    const _NimaBrandLockup(wordmarkWidth: 260),
                    const SizedBox(height: 56),
                    const _NimaLoadingDots(),
                    const Spacer(flex: 3),
                    const _NimaPoweredByFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SynetraLoginScreen extends ConsumerStatefulWidget {
  const _SynetraLoginScreen({this.forceUnlock = false});

  final bool forceUnlock;

  @override
  ConsumerState<_SynetraLoginScreen> createState() =>
      _SynetraLoginScreenState();
}

class _SynetraLoginScreenState extends ConsumerState<_SynetraLoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  bool _showPassword = false;
  bool _isSubmitting = false;
  bool _isUnlocking = false;
  bool _didAttemptBiometric = false;
  String? _errorText;

  bool get _showUnlockFlow {
    final session = ref.read(sessionProvider);
    final appLock = ref.read(appLockProvider);
    return widget.forceUnlock ||
        (session.isAuthenticated &&
            appLock.requiresUnlock &&
            !appLock.isUnlocked);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appLock = ref.read(appLockProvider);
    if (_showUnlockFlow && appLock.biometricEnabled && !_didAttemptBiometric) {
      _didAttemptBiometric = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _unlockWithBiometrics();
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _errorText = 'Enter your username and password to continue.';
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      final authSession = await ref
          .read(apiClientProvider)
          .authenticate(username: username, password: password);

      if (!mounted) {
        return;
      }

      ref.read(sessionProvider.notifier).signIn(authSession);
    } catch (error) {
      setState(() {
        _errorText = _friendlyAuthError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _friendlyAuthError(Object error) {
    final message = error.toString();
    if (message.contains('403')) {
      return 'This member account is not approved for login yet.';
    }
    if (message.contains('401')) {
      return 'Invalid username or password.';
    }
    return 'Sign in failed. Check the backend connection and try again.';
  }

  Future<void> _unlockWithBiometrics() async {
    setState(() {
      _isUnlocking = true;
      _errorText = null;
    });
    try {
      final unlocked =
          await ref.read(appLockProvider.notifier).unlockWithBiometrics();
      if (!unlocked && mounted) {
        setState(() {
          _errorText = 'Biometric verification was cancelled or unavailable.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorText = 'Biometric unlock is not available on this device.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUnlocking = false;
        });
      }
    }
  }

  Future<void> _unlockWithPin() async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) {
      setState(() {
        _errorText = 'Enter your app PIN to continue.';
      });
      return;
    }

    setState(() {
      _isUnlocking = true;
      _errorText = null;
    });
    final isValid = await ref.read(appLockProvider.notifier).verifyPin(pin);
    if (!mounted) {
      return;
    }
    setState(() {
      _isUnlocking = false;
      _errorText = isValid ? null : 'That PIN is incorrect. Please try again.';
    });
    if (isValid) {
      _pinController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final appLock = ref.watch(appLockProvider);
    final showUnlockFlow =
        widget.forceUnlock ||
        (session.isAuthenticated &&
            appLock.requiresUnlock &&
            !appLock.isUnlocked);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Container(height: 24, color: _nimaBrandRed),
            Expanded(
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, _nimaSoftSurface],
                  ),
                ),
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Column(
                        children: [
                          const _NimaBrandLockup(wordmarkWidth: 240),
                          const SizedBox(height: 28),
                          _NimaEntryCard(
                            child:
                                showUnlockFlow
                                    ? _buildUnlockPanel(
                                      context,
                                      session: session,
                                      appLock: appLock,
                                    )
                                    : _buildLoginPanel(context),
                          ),
                          const SizedBox(height: 24),
                          const _NimaPoweredByFooter(compact: true),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnlockPanel(
    BuildContext context, {
    required AppSessionState session,
    required AppLockState appLock,
  }) {
    final resumeLabel =
        session.username.trim().isEmpty
            ? 'Resume your ${session.viewerRole.label.toLowerCase()} session securely.'
            : 'Continue as ${session.username.trim()} without signing in again.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick unlock',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: _nimaInk,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          resumeLabel,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: _nimaMuted, height: 1.55),
        ),
        if (appLock.biometricEnabled) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: _nimaFilledButtonStyle(),
              onPressed: _isUnlocking ? null : _unlockWithBiometrics,
              icon: const Icon(Icons.fingerprint_rounded),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Unlock with biometrics'),
              ),
            ),
          ),
        ],
        if (appLock.hasPin) ...[
          const SizedBox(height: 18),
          TextField(
            controller: _pinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 6,
            onSubmitted: (_) => _unlockWithPin(),
            decoration: _nimaInputDecoration(
              labelText: 'Enter PIN',
              prefixIcon: Icons.pin_outlined,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: _nimaOutlinedButtonStyle(),
              onPressed: _isUnlocking ? null : _unlockWithPin,
              icon: const Icon(Icons.lock_open_rounded),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Enter PIN'),
              ),
            ),
          ),
        ],
        if (_errorText != null) ...[
          const SizedBox(height: 16),
          Text(
            _errorText!,
            style: const TextStyle(
              color: Color(0xFFDC2626),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 20),
        TextButton(
          onPressed: () {
            ref.read(sessionProvider.notifier).signOut();
          },
          style: TextButton.styleFrom(foregroundColor: _nimaBrandRedDark),
          child: const Text('Use another account'),
        ),
      ],
    );
  }

  Widget _buildLoginPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Member login',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: _nimaInk,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Sign in with your registered backend credentials to access the correct admin, member, or vendor view for your account.',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: _nimaMuted, height: 1.55),
        ),
        const SizedBox(height: 22),
        TextField(
          controller: _usernameController,
          keyboardType: TextInputType.emailAddress,
          decoration: _nimaInputDecoration(
            labelText: 'Username',
            prefixIcon: Icons.person_outline_rounded,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: !_showPassword,
          onSubmitted: (_) => _submit(),
          decoration: _nimaInputDecoration(
            labelText: 'Password',
            prefixIcon: Icons.lock_outline_rounded,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _showPassword = !_showPassword;
                });
              },
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
              ),
            ),
          ),
        ),
        if (_errorText != null) ...[
          const SizedBox(height: 14),
          Text(
            _errorText!,
            style: const TextStyle(
              color: Color(0xFFDC2626),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: _nimaFilledButtonStyle(),
            onPressed: _isSubmitting ? null : _submit,
            icon: const Icon(Icons.login_rounded),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(_isSubmitting ? 'Signing in...' : 'Login'),
            ),
          ),
        ),
      ],
    );
  }
}

class _LocalProfileDraft {
  const _LocalProfileDraft({
    required this.displayName,
    required this.email,
    required this.aboutMe,
    this.avatarBytes,
    this.avatarFileName = '',
  });

  final String displayName;
  final String email;
  final String aboutMe;
  final Uint8List? avatarBytes;
  final String avatarFileName;

  _LocalProfileDraft copyWith({
    String? displayName,
    String? email,
    String? aboutMe,
    Uint8List? avatarBytes,
    bool clearAvatar = false,
    String? avatarFileName,
  }) {
    return _LocalProfileDraft(
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      aboutMe: aboutMe ?? this.aboutMe,
      avatarBytes: clearAvatar ? null : avatarBytes ?? this.avatarBytes,
      avatarFileName: clearAvatar ? '' : avatarFileName ?? this.avatarFileName,
    );
  }
}

class SynetraAdminShell extends ConsumerStatefulWidget {
  const SynetraAdminShell({super.key});

  @override
  ConsumerState<SynetraAdminShell> createState() => _SynetraAdminShellState();
}

class _SynetraAdminShellState extends ConsumerState<SynetraAdminShell> {
  late final ShellNavigationController _navigationController;
  _LocalProfileDraft? _profileDraft;
  DateTime? _lastExitRequestAt;

  @override
  void initState() {
    super.initState();
    _navigationController =
        ShellNavigationController()..addListener(_handleNavigationChanged);
    Future<void>.microtask(() => ref.read(tenantProvider.future));
  }

  @override
  void dispose() {
    _navigationController
      ..removeListener(_handleNavigationChanged)
      ..dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _profileDraft ??= _buildInitialProfileDraft();
  }

  _LocalProfileDraft _buildInitialProfileDraft() {
    final session = ref.read(sessionProvider);
    final username = session.username.trim();
    final viewerRole = session.viewerRole;
    final displayName = _displayNameFromUsername(username, viewerRole);
    return _LocalProfileDraft(
      displayName: displayName,
      email: username,
      aboutMe:
          viewerRole.isAdmin
              ? 'Managing association operations, member access, and event coordination in this review build.'
              : viewerRole.isVendor
              ? 'Vendor partner keeping profile details, catalogue information, and association updates current in this review build.'
              : 'Association member exploring updates, directory details, and upcoming events in this review build.',
    );
  }

  void _handleNavigationChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewerRole = ref.watch(
      sessionProvider.select((session) => session.viewerRole),
    );
    final navigation = _navigationController.state;
    if (_navigationController.needsNormalization(viewerRole)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _navigationController.normalizeForRole(viewerRole);
      });
    }
    final slideX = navigation.isDrawerOpen ? 260.0 : 0.0;
    final slideY = navigation.isDrawerOpen ? 88.0 : 0.0;
    final scale = navigation.isDrawerOpen ? 0.84 : 1.0;
    final radius = navigation.isDrawerOpen ? 36.0 : 0.0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          return;
        }
        final shouldExit = _navigationController.handleBackNavigation(
          viewerRole,
        );
        if (!shouldExit) {
          _lastExitRequestAt = null;
          return;
        }

        final now = DateTime.now();
        final shouldExitApp =
            _lastExitRequestAt != null &&
            now.difference(_lastExitRequestAt!) <= const Duration(seconds: 2);
        if (shouldExitApp) {
          await SystemNavigator.pop();
          return;
        }

        _lastExitRequestAt = now;
        if (context.mounted) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(
                content: Text('Press back again to exit the app.'),
                duration: Duration(seconds: 2),
              ),
            );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF130F27),
        body: Stack(
          children: [
            SafeArea(
              child: _AdminDrawer(
                viewerRole: viewerRole,
                username: _profileDraft?.email ?? '',
                profileDraft: _profileDraft ?? _buildInitialProfileDraft(),
                selectedArena: navigation.selectedArena,
                selectedMemberSection: navigation.memberArenaSection,
                selectedAdminSection: navigation.adminArenaSection,
                selectedAssociationSection: navigation.associationArenaSection,
                selectedEventsSection: navigation.eventsArenaSection,
                onArenaSelected:
                    (arena) =>
                        _navigationController.selectArena(viewerRole, arena),
                onMemberSectionSelected:
                    (section) => _navigationController.selectMemberSection(
                      viewerRole,
                      section,
                    ),
                onAdminSectionSelected:
                    (section) => _navigationController.selectAdminSection(
                      viewerRole,
                      section,
                    ),
                onAssociationSectionSelected:
                    (section) => _navigationController.selectAssociationSection(
                      viewerRole,
                      section,
                    ),
                onEventsSectionSelected:
                    (section) => _navigationController.selectEventsSection(
                      viewerRole,
                      section,
                    ),
                onProfileSelected: _navigationController.openProfile,
                onSignOut: () {
                  unawaited(
                    ref.read(apiClientProvider).logout().catchError((_) {}),
                  );
                  ref.read(sessionProvider.notifier).signOut();
                },
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeInOutCubic,
              left: slideX,
              right: -slideX,
              top: slideY,
              bottom: -slideY,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOutCubic,
                scale: scale,
                alignment: Alignment.centerLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow:
                        navigation.isDrawerOpen
                            ? const [
                              BoxShadow(
                                color: Color(0x40000000),
                                blurRadius: 40,
                                offset: Offset(-8, 20),
                              ),
                            ]
                            : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: Stack(
                      children: [
                        _AdminDashboardView(
                          selectedArena: navigation.selectedArena,
                          memberArenaSection: navigation.memberArenaSection,
                          adminArenaSection: navigation.adminArenaSection,
                          associationArenaSection:
                              navigation.associationArenaSection,
                          eventsArenaSection: navigation.eventsArenaSection,
                          dashboardAssociationName:
                              ref
                                  .watch(tenantProvider)
                                  .valueOrNull
                                  ?.associationName ??
                              '',
                          profileDraft:
                              _profileDraft ?? _buildInitialProfileDraft(),
                          viewerRole: viewerRole,
                          isDrawerOpen: navigation.isDrawerOpen,
                          onMenuPressed: _navigationController.toggleDrawer,
                          onArenaSelected:
                              (arena) => _navigationController.selectArena(
                                viewerRole,
                                arena,
                              ),
                          onTimelinePressed: _navigationController.openTimeline,
                          onMemberSectionSelected:
                              (section) => _navigationController
                                  .selectMemberSection(viewerRole, section),
                          onAdminSectionSelected:
                              (section) => _navigationController
                                  .selectAdminSection(viewerRole, section),
                          onAssociationSectionSelected:
                              (section) => _navigationController
                                  .selectAssociationSection(
                                    viewerRole,
                                    section,
                                  ),
                          onProfileSaved: (draft) {
                            setState(() {
                              _profileDraft = draft;
                            });
                          },
                        ),
                        if (navigation.isDrawerOpen)
                          Positioned.fill(
                            child: GestureDetector(
                              onTap: _navigationController.toggleDrawer,
                              child: Container(color: const Color(0x33000000)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminDashboardView extends StatefulWidget {
  const _AdminDashboardView({
    required this.selectedArena,
    required this.memberArenaSection,
    required this.adminArenaSection,
    required this.associationArenaSection,
    required this.eventsArenaSection,
    required this.dashboardAssociationName,
    required this.profileDraft,
    required this.viewerRole,
    required this.isDrawerOpen,
    required this.onMenuPressed,
    required this.onArenaSelected,
    required this.onTimelinePressed,
    required this.onMemberSectionSelected,
    required this.onAdminSectionSelected,
    required this.onAssociationSectionSelected,
    required this.onProfileSaved,
  });

  final AppArena selectedArena;
  final MemberArenaSection memberArenaSection;
  final AdminArenaSection adminArenaSection;
  final AssociationArenaSection associationArenaSection;
  final EventsArenaSection eventsArenaSection;
  final String dashboardAssociationName;
  final _LocalProfileDraft profileDraft;
  final AppViewerRole viewerRole;
  final bool isDrawerOpen;
  final VoidCallback onMenuPressed;
  final ValueChanged<AppArena> onArenaSelected;
  final VoidCallback onTimelinePressed;
  final ValueChanged<MemberArenaSection> onMemberSectionSelected;
  final ValueChanged<AdminArenaSection> onAdminSectionSelected;
  final ValueChanged<AssociationArenaSection> onAssociationSectionSelected;
  final ValueChanged<_LocalProfileDraft> onProfileSaved;

  @override
  State<_AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<_AdminDashboardView> {
  bool _isBottomBarVisible = true;

  bool get _shouldAutoHideBottomBar =>
      widget.selectedArena == AppArena.dashboard ||
      widget.selectedArena == AppArena.timeline ||
      (widget.selectedArena == AppArena.association &&
          AssociationArenaNavigation.shouldAutoHideBottomBar(
            widget.associationArenaSection,
          )) ||
      (widget.selectedArena == AppArena.member &&
          MemberArenaNavigation.shouldAutoHideBottomBar(
            widget.memberArenaSection,
          )) ||
      (widget.selectedArena == AppArena.admin &&
          _isImmersiveAdminSection(widget.adminArenaSection));

  bool _isImmersiveAdminSection(AdminArenaSection section) => true;

  bool _handleScrollNotification(ScrollNotification notification) {
    if (!_shouldAutoHideBottomBar) {
      if (!_isBottomBarVisible) {
        setState(() {
          _isBottomBarVisible = true;
        });
      }
      return false;
    }

    if (notification.metrics.pixels <= 12) {
      if (!_isBottomBarVisible) {
        setState(() {
          _isBottomBarVisible = true;
        });
      }
      return false;
    }

    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse &&
          _isBottomBarVisible) {
        setState(() {
          _isBottomBarVisible = false;
        });
      } else if (notification.direction == ScrollDirection.forward &&
          !_isBottomBarVisible) {
        setState(() {
          _isBottomBarVisible = true;
        });
      }
    }

    return false;
  }

  @override
  void didUpdateWidget(covariant _AdminDashboardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_shouldAutoHideBottomBar && !_isBottomBarVisible) {
      setState(() {
        _isBottomBarVisible = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAssociationImmersiveSection =
        widget.selectedArena == AppArena.association &&
        AssociationArenaNavigation.usesBreadcrumbInsteadOfHero(
          widget.associationArenaSection,
        );
    final shouldHideArenaHeader =
        (widget.selectedArena == AppArena.association &&
            AssociationArenaNavigation.shouldHideShellHeader(
              widget.associationArenaSection,
            )) ||
        widget.selectedArena == AppArena.timeline ||
        (widget.selectedArena == AppArena.vendor &&
            VendorArenaNavigation.shouldHideShellHeader) ||
        (widget.selectedArena == AppArena.events &&
            EventsArenaNavigation.shouldHideShellHeader) ||
        widget.selectedArena == AppArena.profile ||
        (widget.selectedArena == AppArena.member &&
            MemberArenaNavigation.shouldHideShellHeader(
              widget.memberArenaSection,
            )) ||
        (widget.selectedArena == AppArena.admin &&
            _isImmersiveAdminSection(widget.adminArenaSection));
    final topBarOnLightSurface =
        isAssociationImmersiveSection || shouldHideArenaHeader;
    final associationBreadcrumbLabel =
        widget.associationArenaSection == AssociationArenaSection.circulars
            ? 'Circulars'
            : 'Gallery';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: _handleScrollNotification,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 78, 20, 16),
                      child: Column(
                        children: [
                          if (isAssociationImmersiveSection) ...[
                            Align(
                              alignment: Alignment.centerLeft,
                              child: RichText(
                                text: TextSpan(
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Association Arena'),
                                    TextSpan(
                                      text: ' / ',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: const Color(0xFFD1D5DB),
                                          ),
                                    ),
                                    TextSpan(
                                      text: associationBreadcrumbLabel,
                                      style: const TextStyle(
                                        color: Color(0xFF171717),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ] else if (!shouldHideArenaHeader) ...[
                            if (widget.selectedArena != AppArena.dashboard) ...[
                              _HeroSection(
                                selectedArena: widget.selectedArena,
                                selectedMemberSection:
                                    widget.memberArenaSection,
                                selectedAdminSection: widget.adminArenaSection,
                                selectedAssociationSection:
                                    widget.associationArenaSection,
                                selectedEventsSection:
                                    widget.eventsArenaSection,
                                dashboardAssociationName:
                                    widget.dashboardAssociationName,
                                viewerRole: widget.viewerRole,
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Text(
                                    widget.selectedArena.label,
                                    style: theme.textTheme.headlineSmall,
                                  ),
                                  const Spacer(),
                                  Text(
                                    widget.selectedArena == AppArena.member
                                        ? widget.memberArenaSection.label
                                        : widget.selectedArena == AppArena.admin
                                        ? widget.adminArenaSection.label
                                        : widget.selectedArena ==
                                            AppArena.association
                                        ? widget.associationArenaSection.label
                                        : widget.selectedArena ==
                                            AppArena.events
                                        ? widget.eventsArenaSection.label
                                        : widget.selectedArena ==
                                            AppArena.timeline
                                        ? 'Live feed'
                                        : 'Hello World',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: const Color(0xFF7C3AED),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  widget.selectedArena == AppArena.member
                                      ? 'Member feed and directory now read from the backend.'
                                      : widget.selectedArena == AppArena.events
                                      ? widget.viewerRole.isAdmin
                                          ? 'Event master, type manager, timeline, and creation flow now run from the backend.'
                                          : 'Live events now load from the backend in a member-friendly timeline view.'
                                      : widget.selectedArena ==
                                          AppArena.timeline
                                      ? 'Timeline opens as a dedicated social-style feed backed by approved live posts.'
                                      : widget.viewerRole.isAdmin
                                      ? '${widget.selectedArena.label} arena is currently active for the admin view.'
                                      : '${widget.selectedArena.label} arena is currently active.',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (widget.selectedArena == AppArena.member)
                                _QuickStatsRow(
                                  selectedArena: widget.viewerRole.label,
                                  stat1Value: 'Live',
                                  stat2Value: widget.memberArenaSection.label,
                                  stat3Value:
                                      widget.viewerRole.isAdmin
                                          ? 'All posts'
                                          : 'Approved',
                                )
                              else if (widget.selectedArena == AppArena.admin)
                                const _QuickStatsRow(
                                  selectedArena: 'Admin',
                                  stat1Value: 'Members',
                                  stat2Value: 'Content',
                                  stat3Value: 'Events',
                                )
                              else if (widget.selectedArena ==
                                  AppArena.association)
                                _QuickStatsRow(
                                  selectedArena: 'Association',
                                  stat1Value: 'Live',
                                  stat2Value:
                                      widget.associationArenaSection.label,
                                  stat3Value: 'Profile',
                                )
                              else if (widget.selectedArena == AppArena.events)
                                _QuickStatsRow(
                                  selectedArena: 'Events',
                                  stat1Value: 'Live',
                                  stat2Value: widget.eventsArenaSection.label,
                                  stat3Value: 'Timeline',
                                )
                              else if (widget.selectedArena ==
                                  AppArena.timeline)
                                const _QuickStatsRow(
                                  selectedArena: 'Timeline',
                                  stat1Value: 'Live',
                                  stat2Value: 'Approved',
                                  stat3Value: 'Feed',
                                )
                              else
                                _QuickStatsRow(
                                  selectedArena: widget.selectedArena.label,
                                  stat1Value: '12',
                                  stat2Value: '₹2.4L',
                                  stat3Value: '05',
                                ),
                              const SizedBox(height: 24),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    sliver: SliverList.list(
                      children: [
                        if (widget.selectedArena == AppArena.member)
                          MemberArenaPanel(
                            viewerRole: widget.viewerRole,
                            section: widget.memberArenaSection,
                            onSectionSelected: widget.onMemberSectionSelected,
                          )
                        else if (widget.selectedArena == AppArena.admin)
                          AdminArenaPanel(
                            section: widget.adminArenaSection,
                            onSectionSelected: widget.onAdminSectionSelected,
                          )
                        else if (widget.selectedArena == AppArena.association)
                          AssociationArenaPanel(
                            viewerRole: widget.viewerRole,
                            section: widget.associationArenaSection,
                            onSectionSelected:
                                widget.onAssociationSectionSelected,
                          )
                        else if (widget.selectedArena == AppArena.events)
                          EventsArenaPanel(
                            viewerRole: widget.viewerRole,
                            section: widget.eventsArenaSection,
                          )
                        else if (widget.selectedArena == AppArena.dashboard)
                          DashboardPanel(
                            onOpenAssociationGallery:
                                () => widget.onAssociationSectionSelected(
                                  AssociationArenaSection.gallery,
                                ),
                            onOpenAssociationProfile:
                                () => widget.onAssociationSectionSelected(
                                  AssociationArenaSection.profile,
                                ),
                            onOpenAssociationCirculars:
                                () => widget.onAssociationSectionSelected(
                                  AssociationArenaSection.circulars,
                                ),
                            onOpenMemberArena:
                                () => widget.onMemberSectionSelected(
                                  MemberArenaSection.allMembers,
                                ),
                            onOpenVendorArena:
                                () => widget.onArenaSelected(AppArena.vendor),
                            onOpenEventsArena:
                                () => widget.onArenaSelected(AppArena.events),
                            onOpenTimeline: widget.onTimelinePressed,
                            onOpenProfile:
                                () => widget.onArenaSelected(AppArena.profile),
                            onOpenAdminArena:
                                () => widget.onAdminSectionSelected(
                                  AdminArenaSection.appAccess,
                                ),
                            viewerRole: widget.viewerRole,
                          )
                        else if (widget.selectedArena == AppArena.timeline)
                          const TimelinePanel()
                        else if (widget.selectedArena == AppArena.vendor)
                          VendorArenaPanel(
                            viewerRole: widget.viewerRole,
                            onOpenProfile:
                                () => widget.onArenaSelected(AppArena.profile),
                          )
                        else if (widget.selectedArena == AppArena.profile)
                          _ProfileArenaView(
                            viewerRole: widget.viewerRole,
                            profileDraft: widget.profileDraft,
                            onSaved: widget.onProfileSaved,
                          )
                        else
                          const _PlaceholderArenaContent(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 20,
              right: 20,
              top: 14,
              child: _DashboardTopBar(
                isOnLightSurface: topBarOnLightSurface,
                isDrawerOpen: widget.isDrawerOpen,
                onMenuPressed: widget.onMenuPressed,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          _shouldAutoHideBottomBar && !_isBottomBarVisible
              ? null
              : _AdminBottomBar(
                viewerRole: widget.viewerRole,
                selectedArena: widget.selectedArena,
                onArenaSelected: widget.onArenaSelected,
                onTimelinePressed: widget.onTimelinePressed,
              ),
    );
  }
}

class _DashboardTopBar extends StatelessWidget {
  const _DashboardTopBar({
    required this.isOnLightSurface,
    required this.isDrawerOpen,
    required this.onMenuPressed,
  });

  final bool isOnLightSurface;
  final bool isDrawerOpen;
  final VoidCallback onMenuPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TopBarIconButton(
          icon: isDrawerOpen ? Icons.close_rounded : Icons.menu_rounded,
          onTap: onMenuPressed,
          isOnLightSurface: isOnLightSurface,
        ),
        const Spacer(),
        _TopBarIconButton(
          icon: Icons.search_rounded,
          onTap: () {},
          isOnLightSurface: isOnLightSurface,
        ),
        const SizedBox(width: 10),
        _TopBarIconButton(
          icon: Icons.notifications_none_rounded,
          onTap: () {},
          isOnLightSurface: isOnLightSurface,
        ),
      ],
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer({
    required this.viewerRole,
    required this.username,
    required this.profileDraft,
    required this.selectedArena,
    required this.selectedMemberSection,
    required this.selectedAdminSection,
    required this.selectedAssociationSection,
    required this.selectedEventsSection,
    required this.onArenaSelected,
    required this.onMemberSectionSelected,
    required this.onAdminSectionSelected,
    required this.onAssociationSectionSelected,
    required this.onEventsSectionSelected,
    required this.onProfileSelected,
    required this.onSignOut,
  });

  final AppViewerRole viewerRole;
  final String username;
  final _LocalProfileDraft profileDraft;
  final AppArena selectedArena;
  final MemberArenaSection selectedMemberSection;
  final AdminArenaSection selectedAdminSection;
  final AssociationArenaSection selectedAssociationSection;
  final EventsArenaSection selectedEventsSection;
  final ValueChanged<AppArena> onArenaSelected;
  final ValueChanged<MemberArenaSection> onMemberSectionSelected;
  final ValueChanged<AdminArenaSection> onAdminSectionSelected;
  final ValueChanged<AssociationArenaSection> onAssociationSectionSelected;
  final ValueChanged<EventsArenaSection> onEventsSectionSelected;
  final VoidCallback onProfileSelected;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final displayEmail = username.trim();
    final displayName =
        profileDraft.displayName.trim().isEmpty
            ? _displayNameFromUsername(displayEmail, viewerRole)
            : profileDraft.displayName.trim();
    final items =
        AppRoleVisibility.visibleArenas(viewerRole)
            .map(
              (arena) => (
                arena,
                switch (arena) {
                  AppArena.dashboard => Icons.dashboard_rounded,
                  AppArena.admin => Icons.admin_panel_settings_rounded,
                  AppArena.association => Icons.apartment_rounded,
                  AppArena.member => Icons.groups_rounded,
                  AppArena.vendor => Icons.storefront_rounded,
                  AppArena.events => Icons.event_available_rounded,
                  AppArena.profile => Icons.person_rounded,
                  AppArena.timeline => Icons.bolt_rounded,
                },
              ),
            )
            .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 24, 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height - 48,
        ),
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const _SynetraLogoBadge(size: 56),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppRoleVisibility.shellRoleTitle(viewerRole),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppRoleVisibility.shellRoleSubtitle(viewerRole),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 36),
              const Text(
                'Know your association',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              for (final item in items) ...[
                _DrawerItem(
                  label: item.$1.label,
                  icon: item.$2,
                  selected: selectedArena == item.$1,
                  onTap: () => onArenaSelected(item.$1),
                ),
                if (item.$1 == AppArena.member &&
                    selectedArena == AppArena.member)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 18,
                      top: 10,
                      bottom: 6,
                    ),
                    child: Column(
                      children: [
                        _DrawerSubItem(
                          label: 'Media',
                          selected:
                              selectedMemberSection == MemberArenaSection.media,
                          onTap:
                              () => onMemberSectionSelected(
                                MemberArenaSection.media,
                              ),
                        ),
                        const SizedBox(height: 8),
                        for (final section
                            in AppRoleVisibility.visibleMemberSections(
                              viewerRole,
                            ).where(
                              (section) => section != MemberArenaSection.media,
                            )) ...[
                          _DrawerSubItem(
                            label: section.label,
                            selected: selectedMemberSection == section,
                            onTap: () => onMemberSectionSelected(section),
                          ),
                          if (section !=
                              AppRoleVisibility.visibleMemberSections(
                                viewerRole,
                              ).last)
                            const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                if (item.$1 == AppArena.admin &&
                    selectedArena == AppArena.admin)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 18,
                      top: 10,
                      bottom: 6,
                    ),
                    child: Column(
                      children: [
                        for (final section in AdminArenaSection.values) ...[
                          _DrawerSubItem(
                            label: section.label,
                            selected: selectedAdminSection == section,
                            onTap: () => onAdminSectionSelected(section),
                          ),
                          if (section != AdminArenaSection.values.last)
                            const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                if (item.$1 == AppArena.association &&
                    selectedArena == AppArena.association)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 18,
                      top: 10,
                      bottom: 6,
                    ),
                    child: Column(
                      children: [
                        for (final section
                            in AppRoleVisibility.visibleAssociationSections(
                              viewerRole,
                            )) ...[
                          _DrawerSubItem(
                            label: section.label,
                            selected: selectedAssociationSection == section,
                            onTap: () => onAssociationSectionSelected(section),
                          ),
                          if (section !=
                              AppRoleVisibility.visibleAssociationSections(
                                viewerRole,
                              ).last)
                            const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                if (item.$1 == AppArena.events &&
                    selectedArena == AppArena.events)
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 18,
                      top: 10,
                      bottom: 6,
                    ),
                    child: Column(
                      children: [
                        for (final section
                            in AppRoleVisibility.visibleEventSections(
                              viewerRole,
                            )) ...[
                          _DrawerSubItem(
                            label: section.label,
                            selected: selectedEventsSection == section,
                            onTap: () => onEventsSectionSelected(section),
                          ),
                          if (section !=
                              AppRoleVisibility.visibleEventSections(
                                viewerRole,
                              ).last)
                            const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
              ],
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: onProfileSelected,
                      borderRadius: BorderRadius.circular(18),
                      child: Row(
                        children: [
                          _ProfileAvatar(
                            displayName: profileDraft.displayName,
                            avatarBytes: profileDraft.avatarBytes,
                            size: 48,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  viewerRole.label,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.88),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (displayEmail.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        displayEmail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                    Text(
                      'Tap avatar to open profile',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: onSignOut,
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text('Log out'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.22),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _displayNameFromUsername(String username, AppViewerRole viewerRole) {
  final trimmed = username.trim();
  if (trimmed.isEmpty) {
    return switch (viewerRole) {
      AppViewerRole.admin => 'Admin User',
      AppViewerRole.member => 'Member User',
      AppViewerRole.vendor => 'Vendor User',
      AppViewerRole.viewOnly => 'User',
    };
  }

  final localPart = trimmed.contains('@') ? trimmed.split('@').first : trimmed;
  final words =
      localPart
          .split(RegExp(r'[._-]+'))
          .where((part) => part.trim().isNotEmpty)
          .map((part) {
            final normalized = part.trim();
            return normalized[0].toUpperCase() + normalized.substring(1);
          })
          .toList();

  return words.isEmpty ? trimmed : words.join(' ');
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.displayName,
    required this.avatarBytes,
    this.size = 44,
  });

  final String displayName;
  final Uint8List? avatarBytes;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials =
        displayName
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join();

    if (avatarBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.memory(
          avatarBytes!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD946EF), Color(0xFF5B21B6)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? 'P' : initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.32,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _ProfileArenaView extends ConsumerStatefulWidget {
  const _ProfileArenaView({
    required this.viewerRole,
    required this.profileDraft,
    required this.onSaved,
  });

  final AppViewerRole viewerRole;
  final _LocalProfileDraft profileDraft;
  final ValueChanged<_LocalProfileDraft> onSaved;

  @override
  ConsumerState<_ProfileArenaView> createState() => _ProfileArenaViewState();
}

class _ProfileArenaViewState extends ConsumerState<_ProfileArenaView> {
  late final TextEditingController _displayNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _aboutMeController;
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  Uint8List? _avatarBytes;
  String _avatarFileName = '';
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(
      text: widget.profileDraft.displayName,
    );
    _emailController = TextEditingController(text: widget.profileDraft.email);
    _aboutMeController = TextEditingController(
      text: widget.profileDraft.aboutMe,
    );
    _avatarBytes = widget.profileDraft.avatarBytes;
    _avatarFileName = widget.profileDraft.avatarFileName;
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _emailController.dispose();
    _aboutMeController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    if (file == null || file.bytes == null) {
      return;
    }
    setState(() {
      _avatarBytes = file.bytes;
      _avatarFileName = file.name;
    });
  }

  void _saveProfile() {
    if (_newPasswordController.text.isNotEmpty &&
        _newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New password and confirm password must match.'),
        ),
      );
      return;
    }

    final draft = widget.profileDraft.copyWith(
      displayName:
          _displayNameController.text.trim().isEmpty
              ? widget.profileDraft.displayName
              : _displayNameController.text.trim(),
      email: _emailController.text.trim(),
      aboutMe: _aboutMeController.text.trim(),
      avatarBytes: _avatarBytes,
      avatarFileName: _avatarFileName,
    );
    widget.onSaved(draft);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _newPasswordController.text.isEmpty
              ? 'Profile updated for this review build.'
              : 'Profile and password preview updated for this review build.',
        ),
      ),
    );

    _currentPasswordController.clear();
    _newPasswordController.clear();
    _confirmPasswordController.clear();
  }

  Future<void> _saveAppPin() async {
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();
    if (pin.length < 4 || pin.length > 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Use a 4 to 6 digit PIN.')));
      return;
    }
    if (pin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN and confirm PIN must match.')),
      );
      return;
    }
    await ref.read(appLockProvider.notifier).setPin(pin);
    _pinController.clear();
    _confirmPinController.clear();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('App PIN saved for local unlock.')),
    );
  }

  Future<void> _toggleBiometrics(bool enabled) async {
    if (!enabled) {
      await ref.read(appLockProvider.notifier).disableBiometrics();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric unlock turned off.')),
      );
      return;
    }

    final enabledSuccessfully =
        await ref.read(appLockProvider.notifier).enableBiometrics();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabledSuccessfully
              ? 'Biometric unlock is ready for your next app entry.'
              : 'Biometric unlock is not available on this device.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLock = ref.watch(appLockProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Profile',
          subtitle:
              'Update your profile photo, password preview, and personal introduction for the feedback build.',
        ),
        const SizedBox(height: 16),
        _EntityCardFrame(
          padding: const EdgeInsets.all(20),
          radius: 28,
          shadowColor: const Color(0x0D0F172A),
          shadowBlur: 24,
          shadowOffset: const Offset(0, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ProfileAvatar(
                    displayName: _displayNameController.text,
                    avatarBytes: _avatarBytes,
                    size: 74,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayNameController.text.trim().isEmpty
                              ? 'Your profile'
                              : _displayNameController.text.trim(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF171717),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.viewerRole.isAdmin
                              ? 'Admin profile'
                              : widget.viewerRole.isVendor
                              ? 'Vendor profile'
                              : 'Member profile',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF7C3AED),
                          ),
                        ),
                        if (_avatarFileName.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            _avatarFileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickAvatar,
                    icon: const Icon(Icons.photo_camera_back_outlined),
                    label: const Text('Change photo'),
                  ),
                  if (_avatarBytes != null)
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _avatarBytes = null;
                          _avatarFileName = '';
                        });
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Remove photo'),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _displayNameController,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email / username',
                  prefixIcon: Icon(Icons.mail_outline_rounded),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _EntityCardFrame(
          padding: const EdgeInsets.all(20),
          radius: 28,
          shadowColor: const Color(0x0D0F172A),
          shadowBlur: 24,
          shadowOffset: const Offset(0, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'About me',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF171717),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This section is local-only for now and is meant for feedback on the profile experience.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _aboutMeController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'About me',
                  alignLabelWithHint: true,
                  hintText:
                      'Tell others a little about yourself, your role, interests, or how you contribute to the association.',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _EntityCardFrame(
          padding: const EdgeInsets.all(20),
          radius: 28,
          shadowColor: const Color(0x0D0F172A),
          shadowBlur: 24,
          shadowOffset: const Offset(0, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Password',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF171717),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This password form is included for experience review in this build.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New password',
                  prefixIcon: Icon(Icons.password_rounded),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                  prefixIcon: Icon(Icons.verified_user_outlined),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _saveProfile,
                  icon: const Icon(Icons.save_rounded),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text('Save profile'),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _EntityCardFrame(
          padding: const EdgeInsets.all(20),
          radius: 28,
          shadowColor: const Color(0x0D0F172A),
          shadowBlur: 24,
          shadowOffset: const Offset(0, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'App Unlock',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF171717),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Keep backend auth as the source of truth, then use biometrics or a local PIN to re-enter the app quickly on this device.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: appLock.biometricEnabled,
                onChanged: _toggleBiometrics,
                title: const Text('Enable biometric unlock'),
                subtitle: const Text(
                  'Use fingerprint or Face ID the next time the app reopens.',
                ),
                activeColor: const Color(0xFF7C3AED),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText:
                      appLock.hasPin ? 'Change app PIN' : 'Create app PIN',
                  prefixIcon: const Icon(Icons.pin_outlined),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmPinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Confirm app PIN',
                  prefixIcon: Icon(Icons.verified_user_outlined),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: _saveAppPin,
                    icon: const Icon(Icons.pin_rounded),
                    label: Text(appLock.hasPin ? 'Update PIN' : 'Save PIN'),
                  ),
                  if (appLock.hasPin)
                    OutlinedButton.icon(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        await ref.read(appLockProvider.notifier).clearPin();
                        if (!mounted) {
                          return;
                        }
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('App PIN removed from this device.'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Remove PIN'),
                    ),
                  if (appLock.requiresUnlock)
                    OutlinedButton.icon(
                      onPressed: () {
                        ref
                            .read(appLockProvider.notifier)
                            .lockForCurrentSession();
                      },
                      icon: const Icon(Icons.lock_rounded),
                      label: const Text('Lock now'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroSection extends ConsumerWidget {
  const _HeroSection({
    required this.selectedArena,
    required this.selectedMemberSection,
    required this.selectedAdminSection,
    required this.selectedAssociationSection,
    required this.selectedEventsSection,
    required this.dashboardAssociationName,
    required this.viewerRole,
  });

  final AppArena selectedArena;
  final MemberArenaSection selectedMemberSection;
  final AdminArenaSection selectedAdminSection;
  final AssociationArenaSection selectedAssociationSection;
  final EventsArenaSection selectedEventsSection;
  final String dashboardAssociationName;
  final AppViewerRole viewerRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMemberArena = selectedArena == AppArena.member;
    final isDashboard = selectedArena == AppArena.dashboard;
    final resolvedDashboardAssociationName =
        dashboardAssociationName.trim().isEmpty
            ? 'your association'
            : dashboardAssociationName.trim();
    final dashboardDataAsync =
        isDashboard ? ref.watch(dashboardDataProvider) : null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF59E0B), Color(0xFFD946EF), Color(0xFF5B21B6)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x332D106B),
            blurRadius: 28,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDashboard) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const _NimaBrandLockup(wordmarkWidth: 122, compact: true),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            isDashboard
                ? AppArena.dashboard.label
                : 'Hello, ${viewerRole.label}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          if (isDashboard)
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w500,
                  height: 1.08,
                ),
                children: [
                  const TextSpan(text: 'Welcome to '),
                  TextSpan(
                    text: resolvedDashboardAssociationName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            )
          else
            Text(
              isMemberArena
                  ? 'Member ${selectedMemberSection.label} is synced with the backend.'
                  : selectedArena == AppArena.admin
                  ? 'Admin access is synced with live backend data.'
                  : selectedArena == AppArena.association
                  ? 'Association profile is synced with live backend data.'
                  : selectedArena == AppArena.events
                  ? 'Events Arena is synced with live event and event-type data.'
                  : '${selectedArena.label} is ready for the first module build.',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                height: 1.08,
              ),
            ),
          const SizedBox(height: 12),
          Text(
            isDashboard
                ? _formatCurrentDateTime()
                : isMemberArena
                ? viewerRole.isAdmin
                    ? 'Admins can moderate member posts directly from the feed, while member and view-only modes only surface approved content.'
                    : 'Browse approved member updates and directory details curated for association members.'
                : selectedArena == AppArena.admin
                ? 'This arena mirrors the current web and backend workflows for member access, content review, and event oversight.'
                : selectedArena == AppArena.association
                ? 'The same association navigation from the web app now lives in the side drawer here, starting with the backend-linked profile screen.'
                : selectedArena == AppArena.events
                ? viewerRole.isAdmin
                    ? 'Create events with media, manage event types, and browse the live event timeline from the same arena shell used on web.'
                    : 'See upcoming and recent association events without any editing or setup controls.'
                : viewerRole.isAdmin
                ? 'Use the animated side drawer to move between admin, association, member, and vendor workspaces while keeping the premium hero and clean data canvas.'
                : 'Use the animated side drawer to move between association, member, vendor, and event workspaces with a clean mobile-first layout.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.84),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          if (isDashboard)
            _DashboardHeroStats(dataAsync: dashboardDataAsync!)
          else
            Row(
              children: [
                Expanded(
                  child: _HeroActionChip(
                    icon: Icons.groups_rounded,
                    label: selectedArena.label,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HeroActionChip(
                    icon: Icons.view_carousel_rounded,
                    label:
                        isMemberArena
                            ? selectedMemberSection.label
                            : selectedArena == AppArena.dashboard
                            ? 'Overview'
                            : selectedArena == AppArena.admin
                            ? selectedAdminSection.label
                            : selectedArena == AppArena.association
                            ? selectedAssociationSection.label
                            : selectedArena == AppArena.events
                            ? selectedEventsSection.label
                            : 'Reports',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _HeroActionChip(
                    icon: Icons.visibility_rounded,
                    label: viewerRole.label,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _DashboardHeroStats extends StatelessWidget {
  const _DashboardHeroStats({required this.dataAsync});

  final AsyncValue<DashboardData> dataAsync;

  @override
  Widget build(BuildContext context) {
    return dataAsync.when(
      loading:
          () => const _DashboardHeroStatsGrid(
            stats: [
              _DashboardHeroStat(label: 'Members', value: '--'),
              _DashboardHeroStat(label: 'Cities', value: '--'),
              _DashboardHeroStat(label: 'Guests', value: '--'),
              _DashboardHeroStat(label: 'Vendors', value: '--'),
            ],
          ),
      error:
          (_, __) => const _DashboardHeroStatsGrid(
            stats: [
              _DashboardHeroStat(label: 'Members', value: '--'),
              _DashboardHeroStat(label: 'Cities', value: '--'),
              _DashboardHeroStat(label: 'Guests', value: '--'),
              _DashboardHeroStat(label: 'Vendors', value: '--'),
            ],
          ),
      data:
          (data) => _DashboardHeroStatsGrid(
            stats: [
              _DashboardHeroStat(
                label: 'Members',
                value: data.totalMembers.toString(),
              ),
              _DashboardHeroStat(
                label: 'Cities',
                value: data.totalCities.toString(),
              ),
              _DashboardHeroStat(
                label: 'Guests',
                value: data.totalGuests.toString(),
              ),
              _DashboardHeroStat(
                label: 'Vendors',
                value: data.totalVendors.toString(),
              ),
            ],
          ),
    );
  }
}

class _DashboardHeroStatsGrid extends StatelessWidget {
  const _DashboardHeroStatsGrid({required this.stats});

  final List<_DashboardHeroStat> stats;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              stats
                  .map(
                    (stat) => SizedBox(
                      width: itemWidth,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              stat.label,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              stat.value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
        );
      },
    );
  }
}

class _DashboardHeroStat {
  const _DashboardHeroStat({required this.label, required this.value});

  final String label;
  final String value;
}

class _SynetraLogoBadge extends StatelessWidget {
  const _SynetraLogoBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size * 0.14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: const Color(0xFFF5D0D2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: FittedBox(
        fit: BoxFit.contain,
        child: SizedBox(width: size * 0.86, child: const _NimaWordmark()),
      ),
    );
  }
}

class _NimaEntryCard extends StatelessWidget {
  const _NimaEntryCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF0DCDD)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _NimaBrandLockup extends StatelessWidget {
  const _NimaBrandLockup({this.wordmarkWidth = 240, this.compact = false});

  final double wordmarkWidth;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(width: wordmarkWidth, child: const _NimaWordmark()),
        SizedBox(height: compact ? 10 : 14),
        Text(
          "Nashik Industries &\nManufacturers' Association",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _nimaBrandRed,
            fontSize: compact ? 18 : 22,
            fontWeight: FontWeight.w800,
            height: 1.18,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _NimaPoweredByFooter extends StatelessWidget {
  const _NimaPoweredByFooter({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Powered by Synetra',
          style: TextStyle(
            color: const Color(0xFF4B5563),
            fontSize: compact ? 14 : 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'v1.0.0',
          style: TextStyle(
            color: const Color(0xFF6B7280),
            fontSize: compact ? 12 : 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _NimaLoadingDots extends StatelessWidget {
  const _NimaLoadingDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _NimaDot(),
        SizedBox(width: 10),
        _NimaDot(),
        SizedBox(width: 10),
        _NimaDot(),
      ],
    );
  }
}

class _NimaDot extends StatelessWidget {
  const _NimaDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: _nimaBrandRed,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _NimaWordmark extends StatelessWidget {
  const _NimaWordmark();

  @override
  Widget build(BuildContext context) {
    return const AspectRatio(
      aspectRatio: 4.8,
      child: CustomPaint(painter: _NimaWordmarkPainter()),
    );
  }
}

class _NimaWordmarkPainter extends CustomPainter {
  const _NimaWordmarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = _nimaBrandRed
          ..style = PaintingStyle.fill;
    final h = size.height;
    final gap = size.width * 0.035;
    final segmentWidth = (size.width - gap * 3) / 4;

    void rect(double x, double y, double width, double height) {
      canvas.drawRect(Rect.fromLTWH(x, y, width, height), paint);
    }

    final nX = 0.0;
    rect(nX, h * 0.22, segmentWidth * 0.24, h * 0.58);
    rect(nX + segmentWidth * 0.78, h * 0.22, segmentWidth * 0.22, h * 0.58);
    final nPath =
        Path()
          ..moveTo(nX + segmentWidth * 0.22, h * 0.8)
          ..lineTo(nX + segmentWidth * 0.78, h * 0.8)
          ..lineTo(nX + segmentWidth * 0.22, h * 0.22)
          ..close();
    canvas.drawPath(nPath, paint);

    final iX = segmentWidth + gap;
    rect(iX + segmentWidth * 0.38, 0, segmentWidth * 0.24, h * 0.18);
    rect(iX + segmentWidth * 0.38, h * 0.22, segmentWidth * 0.24, h * 0.58);

    final mX = (segmentWidth + gap) * 2;
    rect(mX, h * 0.22, segmentWidth * 0.18, h * 0.58);
    rect(mX + segmentWidth * 0.82, h * 0.22, segmentWidth * 0.18, h * 0.58);
    final mLeft =
        Path()
          ..moveTo(mX + segmentWidth * 0.18, h * 0.8)
          ..lineTo(mX + segmentWidth * 0.5, h * 0.22)
          ..lineTo(mX + segmentWidth * 0.5, h * 0.8)
          ..close();
    final mRight =
        Path()
          ..moveTo(mX + segmentWidth * 0.5, h * 0.8)
          ..lineTo(mX + segmentWidth * 0.5, h * 0.22)
          ..lineTo(mX + segmentWidth * 0.82, h * 0.8)
          ..close();
    canvas.drawPath(mLeft, paint);
    canvas.drawPath(mRight, paint);

    final aX = (segmentWidth + gap) * 3;
    rect(aX + segmentWidth * 0.1, h * 0.7, segmentWidth * 0.72, h * 0.1);
    rect(aX + segmentWidth * 0.26, h * 0.54, segmentWidth * 0.42, h * 0.08);
    final aTop =
        Path()
          ..moveTo(aX, h * 0.5)
          ..lineTo(aX + segmentWidth * 0.46, h * 0.22)
          ..lineTo(aX + segmentWidth * 0.92, h * 0.5)
          ..close();
    canvas.drawPath(aTop, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

InputDecoration _nimaInputDecoration({
  required String labelText,
  required IconData prefixIcon,
  Widget? suffixIcon,
}) {
  OutlineInputBorder border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(18),
    borderSide: BorderSide(color: color),
  );

  return InputDecoration(
    labelText: labelText,
    prefixIcon: Icon(prefixIcon, color: _nimaBrandRedDark),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: const Color(0xFFFFFBFB),
    labelStyle: const TextStyle(color: _nimaMuted, fontWeight: FontWeight.w600),
    enabledBorder: border(const Color(0xFFEBC7C9)),
    focusedBorder: border(_nimaBrandRed),
    border: border(const Color(0xFFEBC7C9)),
  );
}

ButtonStyle _nimaFilledButtonStyle() {
  return FilledButton.styleFrom(
    backgroundColor: _nimaBrandRed,
    foregroundColor: Colors.white,
    textStyle: const TextStyle(fontWeight: FontWeight.w700),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
  );
}

ButtonStyle _nimaOutlinedButtonStyle() {
  return OutlinedButton.styleFrom(
    foregroundColor: _nimaBrandRedDark,
    side: const BorderSide(color: Color(0xFFE1B6B9)),
    textStyle: const TextStyle(fontWeight: FontWeight.w700),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
  );
}

class _TopBarIconButton extends StatelessWidget {
  const _TopBarIconButton({
    required this.icon,
    required this.onTap,
    required this.isOnLightSurface,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isOnLightSurface;

  @override
  Widget build(BuildContext context) {
    final backgroundColor =
        isOnLightSurface
            ? Colors.white.withValues(alpha: 0.96)
            : const Color(0xFFF8FAFC).withValues(alpha: 0.88);
    final borderColor =
        isOnLightSurface
            ? const Color(0xFFDDE3EC)
            : Colors.white.withValues(alpha: 0.42);
    final iconColor = const Color(0xFF111827);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color:
                    isOnLightSurface
                        ? const Color(0x120F172A)
                        : const Color(0x240F172A),
                blurRadius: isOnLightSurface ? 16 : 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor),
        ),
      ),
    );
  }
}

class _HeroActionChip extends StatelessWidget {
  const _HeroActionChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF18181B).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({
    required this.selectedArena,
    required this.stat1Value,
    required this.stat2Value,
    required this.stat3Value,
  });

  final String selectedArena;
  final String stat1Value;
  final String stat2Value;
  final String stat3Value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            label: selectedArena,
            value: stat1Value,
            accent: const Color(0xFF7C3AED),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStatCard(
            label: 'Section',
            value: stat2Value,
            accent: const Color(0xFFF57C00),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MiniStatCard(
            label: 'Visibility',
            value: stat3Value,
            accent: const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(height: 18),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF171717),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
