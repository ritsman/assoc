import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const SynetraApp());
}

const _synetraLogoAsset = 'assets/branding/synetra_logo.png';
const _dummyUsername = 'admin@synetra.app';
const _dummyPassword = 'Synetra@123';

enum AppViewerRole { admin, member, viewOnly }

extension AppViewerRoleLabel on AppViewerRole {
  String get label => switch (this) {
    AppViewerRole.admin => 'Admin',
    AppViewerRole.member => 'Member',
    AppViewerRole.viewOnly => 'View only',
  };

  bool get isAdmin => this == AppViewerRole.admin;
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
    MemberArenaSection.temporaryVisitors => 'Temporary Visitors',
    MemberArenaSection.committeeMembers => 'Committee Members',
    MemberArenaSection.master => 'Master',
  };
}

enum AdminArenaSection { appAccess, memberAccess, vendorAccess, eventAccess }

extension AdminArenaSectionLabel on AdminArenaSection {
  String get label => switch (this) {
    AdminArenaSection.appAccess => 'App Access',
    AdminArenaSection.memberAccess => 'Member Access',
    AdminArenaSection.vendorAccess => 'Vendor Access',
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
    AssociationArenaSection.managementCommittee => 'Management Committee',
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
    const brandOrange = Color(0xFFF57C00);
    const brandPurple = Color(0xFF6D28D9);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Synetra Admin',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: brandPurple,
          brightness: Brightness.light,
        ).copyWith(
          primary: brandPurple,
          secondary: brandOrange,
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

class SynetraLaunchScreen extends StatefulWidget {
  const SynetraLaunchScreen({super.key});

  @override
  State<SynetraLaunchScreen> createState() => _SynetraLaunchScreenState();
}

class _SynetraLaunchScreenState extends State<SynetraLaunchScreen> {
  bool _showLogin = false;
  bool _isAuthenticated = false;
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
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child:
          !_showLogin
              ? const _SynetraSplashExperience()
              : _isAuthenticated
              ? const SynetraAdminShell()
              : _SynetraLoginScreen(
                onLoginSuccess: () {
                  setState(() {
                    _isAuthenticated = true;
                  });
                },
              ),
    );
  }
}

class _SynetraSplashExperience extends StatelessWidget {
  const _SynetraSplashExperience();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.15,
            colors: [Color(0xFFFFFFFF), Color(0xFFEAF2FF)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A0F172A),
                        blurRadius: 40,
                        offset: Offset(0, 20),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    _synetraLogoAsset,
                    width: 240,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 28),
                const Text(
                  'Synetra',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0B2D7A),
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Enhancing synergy networks',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF0B5ED7),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SynetraLoginScreen extends StatefulWidget {
  const _SynetraLoginScreen({required this.onLoginSuccess});

  final VoidCallback onLoginSuccess;

  @override
  State<_SynetraLoginScreen> createState() => _SynetraLoginScreenState();
}

class _SynetraLoginScreenState extends State<_SynetraLoginScreen> {
  final TextEditingController _usernameController = TextEditingController(
    text: _dummyUsername,
  );
  final TextEditingController _passwordController = TextEditingController(
    text: _dummyPassword,
  );
  bool _showPassword = false;
  String? _errorText;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final isValid =
        username.toLowerCase() == _dummyUsername.toLowerCase() &&
        password == _dummyPassword;

    if (!isValid) {
      setState(() {
        _errorText = 'Use the demo admin credentials shown below to continue.';
      });
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _errorText = null;
    });
    widget.onLoginSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF8FAFF), Color(0xFFFFFFFF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x140F172A),
                        blurRadius: 34,
                        offset: Offset(0, 18),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            const _SynetraLogoBadge(size: 92),
                            const SizedBox(height: 18),
                            Text(
                              'Welcome back',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Sign in to open the admin draft and land on the dashboard.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _LoginHintCard(
                        username: _dummyUsername,
                        password: _dummyPassword,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _usernameController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          prefixIcon: Icon(Icons.person_outline_rounded),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: !_showPassword,
                        onSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
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
                          onPressed: _submit,
                          icon: const Icon(Icons.login_rounded),
                          label: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Text('Login to dashboard'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginHintCard extends StatelessWidget {
  const _LoginHintCard({required this.username, required this.password});

  final String username;
  final String password;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Demo Credentials',
            style: TextStyle(
              color: Color(0xFF6D28D9),
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Username: $username',
            style: const TextStyle(
              color: Color(0xFF171717),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Password: $password',
            style: const TextStyle(
              color: Color(0xFF171717),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SynetraAdminShell extends StatefulWidget {
  const SynetraAdminShell({super.key});

  @override
  State<SynetraAdminShell> createState() => _SynetraAdminShellState();
}

class _SynetraAdminShellState extends State<SynetraAdminShell> {
  bool _isDrawerOpen = false;
  String _selectedArena = 'Dashboard';
  MemberArenaSection _memberArenaSection = MemberArenaSection.media;
  AdminArenaSection _adminArenaSection = AdminArenaSection.appAccess;
  AssociationArenaSection _associationArenaSection =
      AssociationArenaSection.profile;
  EventsArenaSection _eventsArenaSection = EventsArenaSection.master;
  final AppViewerRole _viewerRole = AppViewerRole.admin;

  void _toggleDrawer() {
    setState(() {
      _isDrawerOpen = !_isDrawerOpen;
    });
  }

  void _selectArena(String arena) {
    setState(() {
      _selectedArena = arena;
      _isDrawerOpen = false;
    });
  }

  void _selectMemberSection(MemberArenaSection section) {
    setState(() {
      _selectedArena = 'Member Arena';
      _memberArenaSection = section;
      _isDrawerOpen = false;
    });
  }

  void _selectAdminSection(AdminArenaSection section) {
    setState(() {
      _selectedArena = 'Admin Arena';
      _adminArenaSection = section;
      _isDrawerOpen = false;
    });
  }

  void _selectAssociationSection(AssociationArenaSection section) {
    setState(() {
      _selectedArena = 'Association Arena';
      _associationArenaSection = section;
      _isDrawerOpen = false;
    });
  }

  void _selectEventsSection(EventsArenaSection section) {
    setState(() {
      _selectedArena = 'Events Arena';
      _eventsArenaSection = section;
      _isDrawerOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final slideX = _isDrawerOpen ? 260.0 : 0.0;
    final slideY = _isDrawerOpen ? 88.0 : 0.0;
    final scale = _isDrawerOpen ? 0.84 : 1.0;
    final radius = _isDrawerOpen ? 36.0 : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF130F27),
      body: Stack(
        children: [
          SafeArea(
            child: _AdminDrawer(
              selectedArena: _selectedArena,
              selectedMemberSection: _memberArenaSection,
              selectedAdminSection: _adminArenaSection,
              selectedAssociationSection: _associationArenaSection,
              selectedEventsSection: _eventsArenaSection,
              onArenaSelected: _selectArena,
              onMemberSectionSelected: _selectMemberSection,
              onAdminSectionSelected: _selectAdminSection,
              onAssociationSectionSelected: _selectAssociationSection,
              onEventsSectionSelected: _selectEventsSection,
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
                      _isDrawerOpen
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
                        selectedArena: _selectedArena,
                        memberArenaSection: _memberArenaSection,
                        adminArenaSection: _adminArenaSection,
                        associationArenaSection: _associationArenaSection,
                        eventsArenaSection: _eventsArenaSection,
                        viewerRole: _viewerRole,
                        isDrawerOpen: _isDrawerOpen,
                        onMenuPressed: _toggleDrawer,
                        onArenaSelected: _selectArena,
                      ),
                      if (_isDrawerOpen)
                        Positioned.fill(
                          child: GestureDetector(
                            onTap: _toggleDrawer,
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
    );
  }
}

class _AdminDashboardView extends StatelessWidget {
  const _AdminDashboardView({
    required this.selectedArena,
    required this.memberArenaSection,
    required this.adminArenaSection,
    required this.associationArenaSection,
    required this.eventsArenaSection,
    required this.viewerRole,
    required this.isDrawerOpen,
    required this.onMenuPressed,
    required this.onArenaSelected,
  });

  final String selectedArena;
  final MemberArenaSection memberArenaSection;
  final AdminArenaSection adminArenaSection;
  final AssociationArenaSection associationArenaSection;
  final EventsArenaSection eventsArenaSection;
  final AppViewerRole viewerRole;
  final bool isDrawerOpen;
  final VoidCallback onMenuPressed;
  final ValueChanged<String> onArenaSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    child: Column(
                      children: [
                        _HeroSection(
                          selectedArena: selectedArena,
                          selectedMemberSection: memberArenaSection,
                          selectedAdminSection: adminArenaSection,
                          selectedAssociationSection: associationArenaSection,
                          selectedEventsSection: eventsArenaSection,
                          viewerRole: viewerRole,
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Text(
                              selectedArena,
                              style: theme.textTheme.headlineSmall,
                            ),
                            const Spacer(),
                            Text(
                              selectedArena == 'Member Arena'
                                  ? memberArenaSection.label
                                  : selectedArena == 'Dashboard'
                                  ? 'Overview'
                                  : selectedArena == 'Admin Arena'
                                  ? adminArenaSection.label
                                  : selectedArena == 'Association Arena'
                                  ? associationArenaSection.label
                                  : selectedArena == 'Events Arena'
                                  ? eventsArenaSection.label
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
                            selectedArena == 'Member Arena'
                                ? 'Member feed and directory now read from the backend.'
                                : selectedArena == 'Dashboard'
                                ? 'The dashboard now opens first with gallery highlights, live counts, and upcoming events.'
                                : selectedArena == 'Events Arena'
                                ? 'Event master, type manager, timeline, and creation flow now run from the backend.'
                                : '$selectedArena arena is currently active for the admin view.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (selectedArena == 'Member Arena')
                          _QuickStatsRow(
                            selectedArena: viewerRole.label,
                            stat1Value: 'Live',
                            stat2Value: memberArenaSection.label,
                            stat3Value:
                                viewerRole.isAdmin ? 'All posts' : 'Approved',
                          )
                        else if (selectedArena == 'Dashboard')
                          const _QuickStatsRow(
                            selectedArena: 'Dashboard',
                            stat1Value: 'Live',
                            stat2Value: 'Gallery',
                            stat3Value: 'Events',
                          )
                        else if (selectedArena == 'Admin Arena')
                          const _QuickStatsRow(
                            selectedArena: 'Admin',
                            stat1Value: 'Members',
                            stat2Value: 'Content',
                            stat3Value: 'Events',
                          )
                        else if (selectedArena == 'Association Arena')
                          _QuickStatsRow(
                            selectedArena: 'Association',
                            stat1Value: 'Live',
                            stat2Value: associationArenaSection.label,
                            stat3Value: 'Profile',
                          )
                        else if (selectedArena == 'Events Arena')
                          _QuickStatsRow(
                            selectedArena: 'Events',
                            stat1Value: 'Live',
                            stat2Value: eventsArenaSection.label,
                            stat3Value: 'Timeline',
                          )
                        else
                          _QuickStatsRow(
                            selectedArena: selectedArena,
                            stat1Value: '12',
                            stat2Value: '₹2.4L',
                            stat3Value: '05',
                          ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverList.list(
                    children: [
                      if (selectedArena == 'Member Arena')
                        MemberArenaPanel(
                          viewerRole: viewerRole,
                          section: memberArenaSection,
                        )
                      else if (selectedArena == 'Admin Arena')
                        AdminArenaPanel(section: adminArenaSection)
                      else if (selectedArena == 'Association Arena')
                        AssociationArenaPanel(section: associationArenaSection)
                      else if (selectedArena == 'Events Arena')
                        EventsArenaPanel(section: eventsArenaSection)
                      else if (selectedArena == 'Dashboard')
                        const DashboardPanel()
                      else
                        const _PlaceholderArenaContent(),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: 32,
              top: 24,
              child: _FloatingMenuButton(
                icon: isDrawerOpen ? Icons.close_rounded : Icons.menu_rounded,
                onTap: onMenuPressed,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _AdminBottomBar(
        selectedArena: selectedArena,
        onArenaSelected: onArenaSelected,
      ),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  const _AdminDrawer({
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
  });

  final String selectedArena;
  final MemberArenaSection selectedMemberSection;
  final AdminArenaSection selectedAdminSection;
  final AssociationArenaSection selectedAssociationSection;
  final EventsArenaSection selectedEventsSection;
  final ValueChanged<String> onArenaSelected;
  final ValueChanged<MemberArenaSection> onMemberSectionSelected;
  final ValueChanged<AdminArenaSection> onAdminSectionSelected;
  final ValueChanged<AssociationArenaSection> onAssociationSectionSelected;
  final ValueChanged<EventsArenaSection> onEventsSectionSelected;

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Dashboard', Icons.dashboard_rounded),
      ('Admin Arena', Icons.admin_panel_settings_rounded),
      ('Association Arena', Icons.apartment_rounded),
      ('Member Arena', Icons.groups_rounded),
      ('Vendor Arena', Icons.storefront_rounded),
      ('Events Arena', Icons.event_available_rounded),
    ];

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
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Synetra Admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Control center',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 36),
              const Text(
                'Choose arena',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              for (final item in items) ...[
                _DrawerItem(
                  label: item.$1,
                  icon: item.$2,
                  selected: selectedArena == item.$1,
                  onTap: () => onArenaSelected(item.$1),
                ),
                if (item.$1 == 'Member Arena' &&
                    selectedArena == 'Member Arena')
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
                        _DrawerSubItem(
                          label: 'Directory',
                          selected:
                              selectedMemberSection ==
                              MemberArenaSection.directory,
                          onTap:
                              () => onMemberSectionSelected(
                                MemberArenaSection.directory,
                              ),
                        ),
                        const SizedBox(height: 8),
                        for (final section in [
                          MemberArenaSection.allMembers,
                          MemberArenaSection.primaryMembers,
                          MemberArenaSection.associateMembers,
                          MemberArenaSection.temporaryVisitors,
                          MemberArenaSection.committeeMembers,
                          MemberArenaSection.master,
                        ]) ...[
                          _DrawerSubItem(
                            label: section.label,
                            selected: selectedMemberSection == section,
                            onTap: () => onMemberSectionSelected(section),
                          ),
                          if (section != MemberArenaSection.master)
                            const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                if (item.$1 == 'Admin Arena' && selectedArena == 'Admin Arena')
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
                if (item.$1 == 'Association Arena' &&
                    selectedArena == 'Association Arena')
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 18,
                      top: 10,
                      bottom: 6,
                    ),
                    child: Column(
                      children: [
                        for (final section in AssociationArenaSection.values) ...[
                          _DrawerSubItem(
                            label: section.label,
                            selected: selectedAssociationSection == section,
                            onTap: () => onAssociationSectionSelected(section),
                          ),
                          if (section != AssociationArenaSection.values.last)
                            const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                if (item.$1 == 'Events Arena' &&
                    selectedArena == 'Events Arena')
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 18,
                      top: 10,
                      bottom: 6,
                    ),
                    child: Column(
                      children: [
                        for (final section in EventsArenaSection.values) ...[
                          _DrawerSubItem(
                            label: section.label,
                            selected: selectedEventsSection == section,
                            onTap: () => onEventsSectionSelected(section),
                          ),
                          if (section != EventsArenaSection.values.last)
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
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin note',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Member Arena now contains a media feed and a searchable directory. Admin can moderate post status from the feed itself.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.5,
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

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.selectedArena,
    required this.selectedMemberSection,
    required this.selectedAdminSection,
    required this.selectedAssociationSection,
    required this.selectedEventsSection,
    required this.viewerRole,
  });

  final String selectedArena;
  final MemberArenaSection selectedMemberSection;
  final AdminArenaSection selectedAdminSection;
  final AssociationArenaSection selectedAssociationSection;
  final EventsArenaSection selectedEventsSection;
  final AppViewerRole viewerRole;

  @override
  Widget build(BuildContext context) {
    final isMemberArena = selectedArena == 'Member Arena';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
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
          Row(
            children: [
              const SizedBox(width: 54),
              const _SynetraLogoBadge(size: 42, withSurface: false),
              const Spacer(),
              const _HeroIconButton(icon: Icons.search_rounded),
              const SizedBox(width: 10),
              const _HeroIconButton(icon: Icons.notifications_none_rounded),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Hello, ${viewerRole.label}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isMemberArena
                ? 'Member ${selectedMemberSection.label} is synced with the backend.'
                : selectedArena == 'Dashboard'
                ? 'Dashboard brings gallery, live network counts, and upcoming events together.'
                : selectedArena == 'Admin Arena'
                ? 'Admin access is synced with live backend data.'
                : selectedArena == 'Association Arena'
                ? 'Association profile is synced with live backend data.'
                : selectedArena == 'Events Arena'
                ? 'Events Arena is synced with live event and event-type data.'
                : '$selectedArena is ready for the first module build.',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isMemberArena
                ? 'Admins can moderate member posts directly from the feed, while member and view-only modes only surface approved content.'
                : selectedArena == 'Dashboard'
                ? 'Use the animated side drawer for deeper arenas while keeping this as the first-stop overview for the admin.'
                : selectedArena == 'Admin Arena'
                ? 'This arena mirrors the current web and backend workflows for member access, content review, and event oversight.'
                : selectedArena == 'Association Arena'
                ? 'The same association navigation from the web app now lives in the side drawer here, starting with the backend-linked profile screen.'
                : selectedArena == 'Events Arena'
                ? 'Create events with media, manage event types, and browse the live event timeline from the same arena shell used on web.'
                : 'Use the animated side drawer to move between admin, association, member, and vendor workspaces while keeping the premium hero and clean data canvas.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.84),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _HeroActionChip(
                  icon: Icons.groups_rounded,
                  label: selectedArena,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroActionChip(
                  icon: Icons.view_carousel_rounded,
                  label:
                      isMemberArena
                          ? selectedMemberSection.label
                          : selectedArena == 'Dashboard'
                          ? 'Overview'
                          : selectedArena == 'Admin Arena'
                          ? selectedAdminSection.label
                          : selectedArena == 'Association Arena'
                          ? selectedAssociationSection.label
                          : selectedArena == 'Events Arena'
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

class _FloatingMenuButton extends StatelessWidget {
  const _FloatingMenuButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x220F172A),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

class _SynetraLogoBadge extends StatelessWidget {
  const _SynetraLogoBadge({
    required this.size,
    this.withSurface = true,
  });

  final double size;
  final bool withSurface;

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.28),
      child: Image.asset(
        _synetraLogoAsset,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );

    if (!withSurface) {
      return image;
    }

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: image,
    );
  }
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white),
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

class MemberArenaPanel extends StatefulWidget {
  const MemberArenaPanel({
    super.key,
    required this.viewerRole,
    required this.section,
  });

  final AppViewerRole viewerRole;
  final MemberArenaSection section;

  @override
  State<MemberArenaPanel> createState() => _MemberArenaPanelState();
}

class _MemberArenaPanelState extends State<MemberArenaPanel> {
  final SynetraApiClient _apiClient = SynetraApiClient();
  late Future<MemberArenaData> _future;
  String? _updatingPostId;
  MemberMasterDraft? _memberMasterDraft;
  String? _editingMemberMasterId;
  bool _isSavingMemberMaster = false;

  @override
  void initState() {
    super.initState();
    _future = _loadData();
  }

  @override
  void didUpdateWidget(covariant MemberArenaPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewerRole != widget.viewerRole ||
        oldWidget.section != widget.section) {
      _future = _loadData();
    }
  }

  Future<MemberArenaData> _loadData() {
    return _apiClient.loadMemberArenaData(viewerRole: widget.viewerRole);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadData();
    });
    await _future;
  }

  Future<void> _updatePostStatus(
    MemberPostItem post,
    PostReviewStatus status,
  ) async {
    setState(() {
      _updatingPostId = post.id;
    });

    try {
      await _apiClient.updatePostStatus(postId: post.id, status: status);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${post.member.name} post marked ${status.label.toLowerCase()}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update post status: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingPostId = null;
        });
      }
    }
  }

  void _openMemberMasterEditor([MemberDirectoryItem? member]) {
    setState(() {
      _editingMemberMasterId = member?.id ?? '';
      _memberMasterDraft =
          member == null
              ? const MemberMasterDraft.empty()
              : MemberMasterDraft.fromMember(member);
    });
  }

  void _closeMemberMasterEditor() {
    setState(() {
      _editingMemberMasterId = null;
      _memberMasterDraft = null;
    });
  }

  Future<void> _saveMemberMaster() async {
    if (_memberMasterDraft == null || _isSavingMemberMaster) {
      return;
    }

    setState(() {
      _isSavingMemberMaster = true;
    });
    try {
      await _apiClient.saveMemberRecord(draft: _memberMasterDraft!);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      _closeMemberMasterEditor();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _memberMasterDraft!.id.isEmpty
                ? 'Member created.'
                : 'Member updated.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save member: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingMemberMaster = false;
        });
      }
    }
  }

  Future<void> _deleteMemberMaster(String memberId) async {
    if (_isSavingMemberMaster) {
      return;
    }
    setState(() {
      _isSavingMemberMaster = true;
    });
    try {
      await _apiClient.deleteMemberRecord(memberId: memberId);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      if (_editingMemberMasterId == memberId) {
        _closeMemberMasterEditor();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member deleted.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete member: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSavingMemberMaster = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MemberArenaData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingState();
        }

        if (snapshot.hasError) {
          return _ErrorState(
            message: snapshot.error.toString(),
            onRetry: _refresh,
          );
        }

        final data = snapshot.data ?? const MemberArenaData.empty();
        return Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
              ),
            ),
            const SizedBox(height: 8),
            if (widget.section == MemberArenaSection.media)
              _MemberMediaSection(
                posts: data.posts,
                viewerRole: widget.viewerRole,
                updatingPostId: _updatingPostId,
                onUpdateStatus: _updatePostStatus,
              )
            else if (widget.section == MemberArenaSection.directory)
              _MemberDirectorySection(members: data.members)
            else if (widget.section == MemberArenaSection.master)
              _AssociationMasterSection(
                members: data.members..sort(
                  (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                ),
                draft: _memberMasterDraft,
                editingMemberId: _editingMemberMasterId,
                isSaving: _isSavingMemberMaster,
                onOpenEditor: _openMemberMasterEditor,
                onCancelEdit: _closeMemberMasterEditor,
                onDraftChanged:
                    (draft) => setState(() => _memberMasterDraft = draft),
                onSave: _saveMemberMaster,
                onDelete: _deleteMemberMaster,
              )
            else
              _FilteredMemberDirectorySection(
                members: data.members,
                section: widget.section,
              ),
          ],
        );
      },
    );
  }
}

class AdminArenaPanel extends StatefulWidget {
  const AdminArenaPanel({super.key, required this.section});

  final AdminArenaSection section;

  @override
  State<AdminArenaPanel> createState() => _AdminArenaPanelState();
}

class EventsArenaPanel extends StatefulWidget {
  const EventsArenaPanel({super.key, required this.section});

  final EventsArenaSection section;

  @override
  State<EventsArenaPanel> createState() => _EventsArenaPanelState();
}

class _EventsArenaPanelState extends State<EventsArenaPanel> {
  final SynetraApiClient _apiClient = SynetraApiClient();
  late Future<EventsArenaData> _future;
  String? _savingEventId;
  String? _savingEventTypeId;

  @override
  void initState() {
    super.initState();
    _future = _apiClient.loadEventsArenaData();
  }

  @override
  void didUpdateWidget(covariant EventsArenaPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) {
      setState(() {});
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _apiClient.loadEventsArenaData();
    });
    await _future;
  }

  Future<void> _saveEvent(AdminEventDraft draft) async {
    setState(() {
      _savingEventId = draft.id.isEmpty ? '__new__' : draft.id;
    });

    try {
      await _apiClient.saveEvent(draft: draft);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            draft.id.isEmpty ? 'Event created.' : 'Event updated.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save event: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingEventId = null;
        });
      }
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    setState(() {
      _savingEventId = eventId;
    });

    try {
      await _apiClient.deleteEvent(eventId: eventId);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event deleted.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete event: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingEventId = null;
        });
      }
    }
  }

  Future<void> _saveNewEventType(EventTypeDraft draft) async {
    setState(() {
      _savingEventTypeId = '__new__';
    });
    try {
      await _apiClient.createEventType(draft: draft);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event type added.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add event type: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingEventTypeId = null;
        });
      }
    }
  }

  Future<void> _updateEventType(EventTypeDraft draft) async {
    setState(() {
      _savingEventTypeId = draft.id;
    });
    try {
      await _apiClient.updateEventType(draft: draft);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event type updated.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update event type: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingEventTypeId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<EventsArenaData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingState();
        }

        if (snapshot.hasError) {
          return _ErrorState(
            message: snapshot.error.toString(),
            onRetry: _refresh,
          );
        }

        final data = snapshot.data ?? const EventsArenaData.empty();
        return switch (widget.section) {
          EventsArenaSection.master => _EventsArenaMasterSection(
            events: data.events,
            eventTypes: data.eventTypes,
          ),
          EventsArenaSection.createNewEvent => _EventsArenaCreateSection(
            eventTypes: data.eventTypes,
            savingEventId: _savingEventId,
            onSaveEvent: _saveEvent,
          ),
          EventsArenaSection.typeOfEvent => _EventsArenaTypeManager(
            items: data.eventTypes,
            savingEventTypeId: _savingEventTypeId,
            onSaveNewType: _saveNewEventType,
            onUpdateType: _updateEventType,
          ),
          EventsArenaSection.event => _EventsArenaTimelineSection(
            events: data.events,
            eventTypes: data.eventTypes,
            savingEventId: _savingEventId,
            onSaveEvent: _saveEvent,
            onDeleteEvent: _deleteEvent,
          ),
        };
      },
    );
  }
}

class DashboardPanel extends StatefulWidget {
  const DashboardPanel({super.key});

  @override
  State<DashboardPanel> createState() => _DashboardPanelState();
}

class _DashboardPanelState extends State<DashboardPanel> {
  final SynetraApiClient _apiClient = SynetraApiClient();
  late Future<DashboardData> _future;
  final PageController _pageController = PageController(viewportFraction: 0.92);
  Timer? _carouselTimer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _future = _apiClient.loadDashboardData();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _apiClient.loadDashboardData();
    });
    await _future;
  }

  void _startCarousel(int itemCount) {
    _carouselTimer?.cancel();
    if (itemCount <= 1) {
      return;
    }
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_pageController.hasClients) {
        return;
      }
      final nextPage = (_currentPage + 1) % itemCount;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingState();
        }
        if (snapshot.hasError) {
          return _ErrorState(
            message: snapshot.error.toString(),
            onRetry: _refresh,
          );
        }

        final data = snapshot.data ?? const DashboardData.empty();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _startCarousel(data.galleryItems.length);
          }
        });

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
              ),
            ),
            const SizedBox(height: 8),
            _DashboardGalleryCarousel(
              items: data.galleryItems,
              pageController: _pageController,
              currentPage: _currentPage,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
            ),
            const SizedBox(height: 18),
            _DashboardAssociationHero(
              associationName:
                  data.associationName.isEmpty ? 'Dashboard' : data.associationName,
              totalMembers: data.totalMembers,
              totalCities: data.totalCities,
              totalVendors: data.totalVendors,
            ),
            const SizedBox(height: 22),
            _DashboardUpcomingEvents(events: data.upcomingEvents),
          ],
        );
      },
    );
  }
}

class _AdminArenaPanelState extends State<AdminArenaPanel> {
  final SynetraApiClient _apiClient = SynetraApiClient();
  final TextEditingController _searchController = TextEditingController();
  late Future<AdminArenaData> _future;
  String _query = '';
  String? _updatingMemberId;
  String? _updatingPostId;
  String? _savingEventId;

  @override
  void initState() {
    super.initState();
    _future = _apiClient.loadAdminArenaData();
  }

  @override
  void didUpdateWidget(covariant AdminArenaPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _apiClient.loadAdminArenaData();
    });
    await _future;
  }

  Future<void> _updateMemberAccess(
    AdminMemberAccessItem member,
    MemberAccessStatus status,
  ) async {
    setState(() {
      _updatingMemberId = member.id;
    });

    try {
      await _apiClient.updateMemberAccess(memberId: member.id, status: status);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${member.name} marked ${status.label.toLowerCase()}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update member access: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingMemberId = null;
        });
      }
    }
  }

  Future<void> _applyBulkMemberAccess(
    List<AdminMemberAccessItem> members,
    MemberAccessStatus status,
  ) async {
    if (members.isEmpty) {
      return;
    }

    setState(() {
      _updatingMemberId = '__bulk__';
    });

    try {
      for (final member in members) {
        await _apiClient.updateMemberAccess(memberId: member.id, status: status);
      }
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${members.length} members marked ${status.label.toLowerCase()}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update selected members: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingMemberId = null;
        });
      }
    }
  }

  Future<void> _updatePostStatus(
    MemberPostItem post,
    PostReviewStatus status,
  ) async {
    setState(() {
      _updatingPostId = post.id;
    });

    try {
      await _apiClient.updatePostStatus(postId: post.id, status: status);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${post.member.name} post moved to ${status.label.toLowerCase()}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update post status: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingPostId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminArenaData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingState();
        }

        if (snapshot.hasError) {
          return _ErrorState(
            message: snapshot.error.toString(),
            onRetry: _refresh,
          );
        }

        final data = snapshot.data ?? const AdminArenaData.empty();
        final normalizedQuery = _query.trim().toLowerCase();
        final filteredMembers =
            data.members.where((member) {
              if (normalizedQuery.isEmpty) {
                return true;
              }
              return [
                member.name,
                member.companyName,
                member.roleTitle,
                member.email,
                member.phone,
              ].join(' ').toLowerCase().contains(normalizedQuery);
            }).toList();
        final filteredPosts =
            data.posts.where((post) {
              if (normalizedQuery.isEmpty) {
                return true;
              }
              return [
                post.title,
                post.summary,
                post.member.name,
                post.member.company,
              ].join(' ').toLowerCase().contains(normalizedQuery);
            }).toList();
        final filteredEvents =
            data.events.where((event) {
              if (normalizedQuery.isEmpty) {
                return true;
              }
              return [
                event.name,
                event.type,
                event.venue,
                event.summary,
              ].join(' ').toLowerCase().contains(normalizedQuery);
            }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x0A0F172A),
                          blurRadius: 18,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        icon: Icon(Icons.search_rounded),
                        hintText:
                            'Search members, posts, or events in admin arena',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: _refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _AdminSummaryBanner(
              memberCount: data.members.length,
              postCount: data.posts.length,
              eventCount: data.events.length,
            ),
            const SizedBox(height: 18),
            switch (widget.section) {
              AdminArenaSection.appAccess => _AdminAppAccessSection(
                initialSettings: data.appAccess,
                onSave: _saveAppAccess,
              ),
              AdminArenaSection.memberAccess => Column(
                children: [
                  _AdminMemberAccessWorkspace(
                    members: filteredMembers,
                    posts: filteredPosts,
                    updatingMemberId: _updatingMemberId,
                    updatingPostId: _updatingPostId,
                    onUpdateAccess: _updateMemberAccess,
                    onBulkUpdateAccess: _applyBulkMemberAccess,
                    onUpdateStatus: _updatePostStatus,
                  ),
                ],
              ),
              AdminArenaSection.vendorAccess => const _EmptyStateCard(
                title: 'Vendor access is not live yet',
                subtitle:
                    'The Flutter drawer is ready, but the backend vendor access module has not been implemented yet.',
              ),
              AdminArenaSection.eventAccess => _AdminEventsSection(
                events: filteredEvents,
                eventTypes: data.eventTypes,
                savingEventId: _savingEventId,
                onSaveEvent: _saveEvent,
                onDeleteEvent: _deleteEvent,
              ),
            },
          ],
        );
      },
    );
  }

  Future<void> _saveAppAccess(AdminAppAccessSettings settings) async {
    try {
      await _apiClient.updateAppAccess(settings: settings);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('App access settings saved.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save app access settings: $error')),
      );
    }
  }

  Future<void> _saveEvent(AdminEventDraft draft) async {
    setState(() {
      _savingEventId = draft.id.isEmpty ? '__new__' : draft.id;
    });

    try {
      await _apiClient.saveEvent(draft: draft);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            draft.id.isEmpty ? 'Event created.' : 'Event updated.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save event: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingEventId = null;
        });
      }
    }
  }

  Future<void> _deleteEvent(String eventId) async {
    setState(() {
      _savingEventId = eventId;
    });

    try {
      await _apiClient.deleteEvent(eventId: eventId);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Event deleted.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete event: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _savingEventId = null;
        });
      }
    }
  }
}

class AssociationArenaPanel extends StatefulWidget {
  const AssociationArenaPanel({super.key, required this.section});

  final AssociationArenaSection section;

  @override
  State<AssociationArenaPanel> createState() => _AssociationArenaPanelState();
}

class _AssociationArenaPanelState extends State<AssociationArenaPanel> {
  final SynetraApiClient _apiClient = SynetraApiClient();
  late Future<AssociationProfileData> _future;
  late Future<AssociationAboutData> _aboutFuture;
  late Future<List<MemberDirectoryItem>> _membersFuture;
  late Future<AssociationCircularLibraryData> _circularsFuture;
  AssociationProfileDraft? _draft;
  AssociationAboutDraft? _aboutDraft;
  AssociationCircularDraft? _circularDraft;
  MemberMasterDraft? _memberMasterDraft;
  String? _editingMemberMasterId;
  String? _editingCircularId;
  bool _isEditing = false;
  bool _isEditingAbout = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _future = _apiClient.fetchAssociationProfile();
    _aboutFuture = _apiClient.fetchAssociationAbout();
    _membersFuture = _apiClient.fetchMembers();
    _circularsFuture = _apiClient.fetchAssociationCircularLibrary();
  }

  @override
  void didUpdateWidget(covariant AssociationArenaPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.section != widget.section) {
      setState(() {});
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _apiClient.fetchAssociationProfile();
      _aboutFuture = _apiClient.fetchAssociationAbout();
      _membersFuture = _apiClient.fetchMembers();
      _circularsFuture = _apiClient.fetchAssociationCircularLibrary();
    });
    await Future.wait([_future, _aboutFuture, _membersFuture, _circularsFuture]);
  }

  Future<void> _saveProfile() async {
    if (_draft == null || _isSaving) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      await _apiClient.updateAssociationProfile(draft: _draft!);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      setState(() {
        _isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Association profile saved.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save association profile: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _saveAbout() async {
    if (_aboutDraft == null || _isSaving) {
      return;
    }
    setState(() {
      _isSaving = true;
    });
    try {
      await _apiClient.updateAssociationAbout(draft: _aboutDraft!);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      setState(() {
        _isEditingAbout = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('About us content saved.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save about us content: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _pickCircularFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'pdf',
        'doc',
        'docx',
        'png',
        'jpg',
        'jpeg',
        'webp',
        'tif',
        'tiff',
      ],
      withData: true,
    );

    final file = result?.files.single;
    if (file == null || file.bytes == null || _circularDraft == null) {
      return;
    }

    setState(() {
      _circularDraft = _circularDraft!.copyWith(
        selectedFile: AssociationUploadFile.fromPlatformFile(file),
      );
    });
  }

  Future<void> _openCircularDocument(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid circular document URL.')),
      );
      return;
    }

    final didLaunch = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!didLaunch && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the circular document.')),
      );
    }
  }

  void _openCircularEditor([AssociationCircularDocument? item]) {
    setState(() {
      _editingCircularId = item?.id ?? '';
      _circularDraft =
          item == null
              ? const AssociationCircularDraft.empty()
              : AssociationCircularDraft.fromDocument(item);
    });
  }

  void _closeCircularEditor() {
    setState(() {
      _editingCircularId = null;
      _circularDraft = null;
    });
  }

  Future<void> _saveCircular(String associationId) async {
    if (_circularDraft == null || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _apiClient.saveAssociationCircular(
        associationId: associationId,
        draft: _circularDraft!,
      );
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      _closeCircularEditor();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Circular saved.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save circular: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteCircular(String associationId, String circularId) async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _apiClient.deleteAssociationCircular(
        associationId: associationId,
        circularId: circularId,
      );
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      if (_editingCircularId == circularId) {
        _closeCircularEditor();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Circular deleted.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete circular: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _openMemberMasterEditor([MemberDirectoryItem? member]) {
    setState(() {
      _editingMemberMasterId = member?.id ?? '';
      _memberMasterDraft =
          member == null
              ? const MemberMasterDraft.empty()
              : MemberMasterDraft.fromMember(member);
    });
  }

  void _closeMemberMasterEditor() {
    setState(() {
      _editingMemberMasterId = null;
      _memberMasterDraft = null;
    });
  }

  Future<void> _saveMemberMaster() async {
    if (_memberMasterDraft == null || _isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _apiClient.saveMemberRecord(draft: _memberMasterDraft!);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      _closeMemberMasterEditor();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _memberMasterDraft!.id.isEmpty
                ? 'Member created.'
                : 'Member updated.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save member: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _deleteMemberMaster(String memberId) async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _apiClient.deleteMemberRecord(memberId: memberId);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      if (_editingMemberMasterId == memberId) {
        _closeMemberMasterEditor();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member deleted.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete member: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.section == AssociationArenaSection.profile) {
      return FutureBuilder<AssociationProfileData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingState();
        }
        if (snapshot.hasError) {
          return _ErrorState(
            message: snapshot.error.toString(),
            onRetry: _refresh,
          );
        }

        final profile = snapshot.data ?? const AssociationProfileData.empty();
        _draft ??= AssociationProfileDraft.fromProfile(profile);

        if (_isEditing && _draft != null) {
          return _AssociationProfileEditor(
            draft: _draft!,
            isSaving: _isSaving,
            onChanged: (draft) => setState(() => _draft = draft),
            onAddRegionalAddress: () {
              setState(() {
                _draft = _draft!.copyWith(
                  regionalAddresses: [
                    ..._draft!.regionalAddresses,
                    AssociationRegionalAddressDraft.empty(
                      id: 'regional-${DateTime.now().microsecondsSinceEpoch}',
                    ),
                  ],
                );
              });
            },
            onRemoveRegionalAddress: (index) {
              setState(() {
                final nextAddresses = [..._draft!.regionalAddresses]
                  ..removeAt(index);
                _draft = _draft!.copyWith(regionalAddresses: nextAddresses);
              });
            },
            onSave: _saveProfile,
            onCancel: () {
              setState(() {
                _draft = AssociationProfileDraft.fromProfile(profile);
                _isEditing = false;
              });
            },
          );
        }

        return _AssociationProfileView(
          profile: profile,
          onEdit: () {
            setState(() {
              _draft = AssociationProfileDraft.fromProfile(profile);
              _isEditing = true;
            });
          },
        );
      },
    );
    }

    if (widget.section == AssociationArenaSection.aboutUs) {
      return FutureBuilder<AssociationAboutData>(
        future: _aboutFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingState();
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }

          final about = snapshot.data ?? const AssociationAboutData.empty();
          _aboutDraft ??= AssociationAboutDraft.fromAbout(about);

          if (_isEditingAbout && _aboutDraft != null) {
            return _AssociationAboutEditor(
              draft: _aboutDraft!,
              isSaving: _isSaving,
              onChanged: (draft) => setState(() => _aboutDraft = draft),
              onSave: _saveAbout,
              onCancel: () {
                setState(() {
                  _aboutDraft = AssociationAboutDraft.fromAbout(about);
                  _isEditingAbout = false;
                });
              },
            );
          }

          return _AssociationAboutView(
            about: about,
            onEdit: () {
              setState(() {
                _aboutDraft = AssociationAboutDraft.fromAbout(about);
                _isEditingAbout = true;
              });
            },
          );
        },
      );
    }

    if (widget.section == AssociationArenaSection.managementCommittee) {
      return FutureBuilder<List<MemberDirectoryItem>>(
        future: _membersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingState();
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }

          final committeeMembers =
              (snapshot.data ?? const <MemberDirectoryItem>[])
                  .where(
                    (member) =>
                        member.roleTitle.trim().toLowerCase() == 'committee' ||
                        member.committeePost.trim().isNotEmpty,
                  )
                  .toList()
                ..sort(
                  (a, b) =>
                      a.name.toLowerCase().compareTo(b.name.toLowerCase()),
                );

          return _AssociationCommitteeView(members: committeeMembers);
        },
      );
    }

    if (widget.section == AssociationArenaSection.circulars) {
      return FutureBuilder<AssociationCircularLibraryData>(
        future: _circularsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingState();
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }

          final library = snapshot.data ?? const AssociationCircularLibraryData.empty();
          return _AssociationCircularsSection(
            library: library,
            draft: _circularDraft,
            editingCircularId: _editingCircularId,
            isSaving: _isSaving,
            onOpenEditor: _openCircularEditor,
            onCancelEdit: _closeCircularEditor,
            onDraftChanged: (draft) => setState(() => _circularDraft = draft),
            onPickFile: _pickCircularFile,
            onOpenDocument: _openCircularDocument,
            onSave: () => _saveCircular(library.associationId),
            onDelete:
                (circularId) =>
                    _deleteCircular(library.associationId, circularId),
          );
        },
      );
    }

    if (widget.section == AssociationArenaSection.master) {
      return FutureBuilder<List<MemberDirectoryItem>>(
        future: _membersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingState();
          }
          if (snapshot.hasError) {
            return _ErrorState(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }

          final members = (snapshot.data ?? const <MemberDirectoryItem>[])
            ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

          return _AssociationMasterSection(
            members: members,
            draft: _memberMasterDraft,
            editingMemberId: _editingMemberMasterId,
            isSaving: _isSaving,
            onOpenEditor: _openMemberMasterEditor,
            onCancelEdit: _closeMemberMasterEditor,
            onDraftChanged:
                (draft) => setState(() => _memberMasterDraft = draft),
            onSave: _saveMemberMaster,
            onDelete: _deleteMemberMaster,
          );
        },
      );
    }

    return _EmptyStateCard(
      title: '${widget.section.label} is next',
      subtitle:
          'The Association Arena drawer now matches the web app. Profile, About Us, and Management Committee are live first, and ${widget.section.label} can be layered in next.',
    );
  }
}

class _MemberMediaSection extends StatelessWidget {
  const _MemberMediaSection({
    required this.posts,
    required this.viewerRole,
    required this.updatingPostId,
    required this.onUpdateStatus,
  });

  final List<MemberPostItem> posts;
  final AppViewerRole viewerRole;
  final String? updatingPostId;
  final Future<void> Function(MemberPostItem, PostReviewStatus) onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Media Feed',
            subtitle:
                'Facebook-style informational posts from members will appear here once the backend has content.',
          ),
          SizedBox(height: 14),
          _EmptyStateCard(
            title: 'No posts yet',
            subtitle:
                'Try creating or approving a member post in the backend to populate this feed.',
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Media Feed',
          subtitle:
              'Informational member posts with admin moderation controls and role-aware visibility.',
        ),
        const SizedBox(height: 14),
        _FeedInfoBanner(viewerRole: viewerRole, postCount: posts.length),
        const SizedBox(height: 14),
        ...posts.map(
          (post) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _MemberPostCard(
              post: post,
              viewerRole: viewerRole,
              isUpdating: updatingPostId == post.id,
              onUpdateStatus: onUpdateStatus,
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _FilteredMemberDirectorySection extends StatelessWidget {
  const _FilteredMemberDirectorySection({
    required this.members,
    required this.section,
  });

  final List<MemberDirectoryItem> members;
  final MemberArenaSection section;

  @override
  Widget build(BuildContext context) {
    final config = MemberArenaSectionDirectoryMeta.configFor(section);
    return _MemberDirectorySection(
      members: members,
      initialFilter: config.filter,
      lockFilter: true,
      title: config.title,
      subtitle: config.subtitle,
    );
  }
}

class _DashboardGalleryCarousel extends StatelessWidget {
  const _DashboardGalleryCarousel({
    required this.items,
    required this.pageController,
    required this.currentPage,
    required this.onPageChanged,
  });

  final List<DashboardGalleryItem> items;
  final PageController pageController;
  final int currentPage;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyStateCard(
        title: 'No gallery highlights yet',
        subtitle:
            'Add gallery items from the association arena or web app to populate the dashboard carousel.',
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 240,
          child: PageView.builder(
            controller: pageController,
            itemCount: items.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final item = items[index];
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A0F172A),
                        blurRadius: 28,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (item.imageUrl.isNotEmpty)
                          Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => _DashboardGalleryFallback(
                                  item: item,
                                ),
                          )
                        else
                          _DashboardGalleryFallback(item: item),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.05),
                                Colors.black.withValues(alpha: 0.55),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (item.tagline.isNotEmpty)
                                Text(
                                  item.tagline,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              if (item.tagline.isNotEmpty)
                                const SizedBox(height: 6),
                              Text(
                                item.headline.isEmpty
                                    ? 'Gallery Highlight'
                                    : item.headline,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                ),
                              ),
                              if (item.description.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  item.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            items.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: currentPage == index ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(
                color:
                    currentPage == index
                        ? const Color(0xFF7C3AED)
                        : const Color(0xFFD1D5DB),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DashboardGalleryFallback extends StatelessWidget {
  const _DashboardGalleryFallback({required this.item});

  final DashboardGalleryItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF59E0B), Color(0xFFD946EF), Color(0xFF5B21B6)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            item.headline.isEmpty ? 'Synetra Gallery' : item.headline,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardAssociationHero extends StatelessWidget {
  const _DashboardAssociationHero({
    required this.associationName,
    required this.totalMembers,
    required this.totalCities,
    required this.totalVendors,
  });

  final String associationName;
  final int totalMembers;
  final int totalCities;
  final int totalVendors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF59E0B), Color(0xFFD946EF), Color(0xFF5B21B6)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260F172A),
            blurRadius: 26,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            associationName,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Association Overview',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Live counts for members, connected cities, and vendor accounts from the backend.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _DashboardHeroStatChip(
                  label: 'Members',
                  value: '$totalMembers',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DashboardHeroStatChip(
                  label: 'Cities',
                  value: '$totalCities',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DashboardHeroStatChip(
                  label: 'Vendors',
                  value: '$totalVendors',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashboardHeroStatChip extends StatelessWidget {
  const _DashboardHeroStatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardUpcomingEvents extends StatelessWidget {
  const _DashboardUpcomingEvents({required this.events});

  final List<AdminEventItem> events;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Upcoming Events',
          subtitle:
              'The next scheduled events from the backend timeline appear here first on the dashboard.',
        ),
        const SizedBox(height: 14),
        if (events.isEmpty)
          const _EmptyStateCard(
            title: 'No upcoming events',
            subtitle:
                'Create a new event in the Events Arena to start filling the dashboard schedule.',
          )
        else
          ...events.take(5).map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _EventTimelineCard(
                event: event,
                accentLabel: event.liveStatus,
              ),
            ),
          ),
      ],
    );
  }
}

class _AdminSummaryBanner extends StatelessWidget {
  const _AdminSummaryBanner({
    required this.memberCount,
    required this.postCount,
    required this.eventCount,
  });

  final int memberCount;
  final int postCount;
  final int eventCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              '$memberCount members, $postCount content items, and $eventCount events are loaded from the backend for admin review.',
              style: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssociationProfileView extends StatelessWidget {
  const _AssociationProfileView({
    required this.profile,
    required this.onEdit,
  });

  final AssociationProfileData profile;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Association Profile',
          subtitle:
              'Head office and regional office details synced from the backend.',
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0F172A),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      profile.name.isEmpty ? 'Association Profile' : profile.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF171717),
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: onEdit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF171717),
                    ),
                    child: const Text('Edit'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _AssociationInfoTile(
                    label: 'Head Office Address',
                    value: profile.headOfficeAddress,
                    wide: true,
                  ),
                  _AssociationInfoTile(
                    label: 'City, State with Pincode',
                    value: [
                      profile.city,
                      profile.state,
                      profile.pincode,
                    ].where((part) => part.isNotEmpty).join(', '),
                  ),
                  _AssociationInfoTile(
                    label: 'Registration Number',
                    value: profile.registrationNumber,
                  ),
                  _AssociationInfoTile(
                    label: 'GST Number',
                    value: profile.gstNumber,
                  ),
                  _AssociationInfoTile(
                    label: 'Website',
                    value: profile.website,
                  ),
                  _AssociationInfoTile(
                    label: 'Helpdesk Number',
                    value: profile.helpdeskNumber,
                  ),
                  _AssociationInfoTile(
                    label: 'Contact Numbers',
                    value: profile.contactNumbersLabel,
                    wide: true,
                  ),
                  _AssociationInfoTile(
                    label: 'Google Map Access Location',
                    value: profile.googleMapsLink,
                    wide: true,
                  ),
                ],
              ),
            ],
          ),
        ),
        if (profile.regionalAddresses.isNotEmpty) ...[
          const SizedBox(height: 18),
          ...profile.regionalAddresses.asMap().entries.map((entry) {
            final index = entry.key;
            final address = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D0F172A),
                      blurRadius: 24,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address.label.isEmpty
                          ? 'Regional Office ${index + 1}'
                          : address.label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF171717),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        _AssociationInfoTile(
                          label: 'Office Address',
                          value: address.officeAddress,
                          wide: true,
                        ),
                        _AssociationInfoTile(
                          label: 'City, State with Pincode',
                          value: [
                            address.city,
                            address.state,
                            address.pincode,
                          ].where((part) => part.isNotEmpty).join(', '),
                        ),
                        _AssociationInfoTile(
                          label: 'Registration Number',
                          value: address.registrationNumber,
                        ),
                        _AssociationInfoTile(
                          label: 'GST Number',
                          value: address.gstNumber,
                        ),
                        _AssociationInfoTile(
                          label: 'Website',
                          value: address.website,
                        ),
                        _AssociationInfoTile(
                          label: 'Helpdesk Number',
                          value: address.helpdeskNumber,
                        ),
                        _AssociationInfoTile(
                          label: 'Contact Numbers',
                          value: address.contactNumbersLabel,
                          wide: true,
                        ),
                        _AssociationInfoTile(
                          label: 'Google Map Access Location',
                          value: address.googleMapsLink,
                          wide: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}

class _AssociationProfileEditor extends StatelessWidget {
  const _AssociationProfileEditor({
    required this.draft,
    required this.isSaving,
    required this.onChanged,
    required this.onAddRegionalAddress,
    required this.onRemoveRegionalAddress,
    required this.onSave,
    required this.onCancel,
  });

  final AssociationProfileDraft draft;
  final bool isSaving;
  final ValueChanged<AssociationProfileDraft> onChanged;
  final VoidCallback onAddRegionalAddress;
  final ValueChanged<int> onRemoveRegionalAddress;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Edit Association Profile',
          subtitle:
              'Update the same fields used in the web profile screen, including regional offices.',
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0F172A),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            children: [
              _AssociationTextField(
                label: 'Association Name',
                value: draft.name,
                onChanged: (value) => onChanged(draft.copyWith(name: value)),
              ),
              _AssociationTextField(
                label: 'Registration Number',
                value: draft.registrationNumber,
                onChanged: (value) => onChanged(
                  draft.copyWith(registrationNumber: value),
                ),
              ),
              _AssociationTextField(
                label: 'Head Office Address',
                value: draft.headOfficeAddress,
                maxLines: 3,
                onChanged: (value) => onChanged(
                  draft.copyWith(headOfficeAddress: value),
                ),
              ),
              _AssociationTextField(
                label: 'City',
                value: draft.city,
                onChanged: (value) => onChanged(draft.copyWith(city: value)),
              ),
              _AssociationTextField(
                label: 'State',
                value: draft.state,
                onChanged: (value) => onChanged(draft.copyWith(state: value)),
              ),
              _AssociationTextField(
                label: 'Pincode',
                value: draft.pincode,
                onChanged: (value) => onChanged(draft.copyWith(pincode: value)),
              ),
              _AssociationTextField(
                label: 'GST Number',
                value: draft.gstNumber,
                onChanged: (value) =>
                    onChanged(draft.copyWith(gstNumber: value)),
              ),
              _AssociationTextField(
                label: 'Website',
                value: draft.website,
                onChanged: (value) => onChanged(draft.copyWith(website: value)),
              ),
              _AssociationTextField(
                label: 'Helpdesk Number',
                value: draft.helpdeskNumber,
                onChanged: (value) => onChanged(
                  draft.copyWith(helpdeskNumber: value),
                ),
              ),
              _AssociationTextField(
                label: 'Contact Numbers',
                value: draft.contactNumbers,
                onChanged: (value) =>
                    onChanged(draft.copyWith(contactNumbers: value)),
              ),
              _AssociationTextField(
                label: 'Google Map Access Location',
                value: draft.googleMapsLink,
                onChanged: (value) =>
                    onChanged(draft.copyWith(googleMapsLink: value)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Text(
              'Regional Address List',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF171717),
              ),
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: onAddRegionalAddress,
              child: const Text('Add Regional Address'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ...draft.regionalAddresses.asMap().entries.map((entry) {
          final index = entry.key;
          final address = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D0F172A),
                    blurRadius: 24,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        address.label.isEmpty
                            ? 'Regional Office ${index + 1}'
                            : address.label,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF171717),
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton(
                        onPressed: () => onRemoveRegionalAddress(index),
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _AssociationTextField(
                    label: 'Label',
                    value: address.label,
                    onChanged: (value) {
                      final next = [...draft.regionalAddresses];
                      next[index] = address.copyWith(label: value);
                      onChanged(draft.copyWith(regionalAddresses: next));
                    },
                  ),
                  _AssociationTextField(
                    label: 'Registration Number',
                    value: address.registrationNumber,
                    onChanged: (value) {
                      final next = [...draft.regionalAddresses];
                      next[index] =
                          address.copyWith(registrationNumber: value);
                      onChanged(draft.copyWith(regionalAddresses: next));
                    },
                  ),
                  _AssociationTextField(
                    label: 'Office Address',
                    value: address.officeAddress,
                    maxLines: 3,
                    onChanged: (value) {
                      final next = [...draft.regionalAddresses];
                      next[index] = address.copyWith(officeAddress: value);
                      onChanged(draft.copyWith(regionalAddresses: next));
                    },
                  ),
                  _AssociationTextField(
                    label: 'City',
                    value: address.city,
                    onChanged: (value) {
                      final next = [...draft.regionalAddresses];
                      next[index] = address.copyWith(city: value);
                      onChanged(draft.copyWith(regionalAddresses: next));
                    },
                  ),
                  _AssociationTextField(
                    label: 'State',
                    value: address.state,
                    onChanged: (value) {
                      final next = [...draft.regionalAddresses];
                      next[index] = address.copyWith(state: value);
                      onChanged(draft.copyWith(regionalAddresses: next));
                    },
                  ),
                  _AssociationTextField(
                    label: 'Pincode',
                    value: address.pincode,
                    onChanged: (value) {
                      final next = [...draft.regionalAddresses];
                      next[index] = address.copyWith(pincode: value);
                      onChanged(draft.copyWith(regionalAddresses: next));
                    },
                  ),
                  _AssociationTextField(
                    label: 'GST Number',
                    value: address.gstNumber,
                    onChanged: (value) {
                      final next = [...draft.regionalAddresses];
                      next[index] = address.copyWith(gstNumber: value);
                      onChanged(draft.copyWith(regionalAddresses: next));
                    },
                  ),
                  _AssociationTextField(
                    label: 'Website',
                    value: address.website,
                    onChanged: (value) {
                      final next = [...draft.regionalAddresses];
                      next[index] = address.copyWith(website: value);
                      onChanged(draft.copyWith(regionalAddresses: next));
                    },
                  ),
                  _AssociationTextField(
                    label: 'Helpdesk Number',
                    value: address.helpdeskNumber,
                    onChanged: (value) {
                      final next = [...draft.regionalAddresses];
                      next[index] = address.copyWith(helpdeskNumber: value);
                      onChanged(draft.copyWith(regionalAddresses: next));
                    },
                  ),
                  _AssociationTextField(
                    label: 'Contact Numbers',
                    value: address.contactNumbers,
                    onChanged: (value) {
                      final next = [...draft.regionalAddresses];
                      next[index] = address.copyWith(contactNumbers: value);
                      onChanged(draft.copyWith(regionalAddresses: next));
                    },
                  ),
                  _AssociationTextField(
                    label: 'Google Map Access Location',
                    value: address.googleMapsLink,
                    onChanged: (value) {
                      final next = [...draft.regionalAddresses];
                      next[index] = address.copyWith(googleMapsLink: value);
                      onChanged(draft.copyWith(regionalAddresses: next));
                    },
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton(
              onPressed: isSaving ? null : onCancel,
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: isSaving ? null : onSave,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF171717),
              ),
              child: Text(isSaving ? 'Saving...' : 'Save Profile'),
            ),
          ],
        ),
      ],
    );
  }
}

class _AssociationAboutView extends StatelessWidget {
  const _AssociationAboutView({
    required this.about,
    required this.onEdit,
  });

  final AssociationAboutData about;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'About Us',
          subtitle:
              'Landing page content synced from the backend About Us module.',
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0F172A),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      about.heroTitle.isEmpty ? 'About Us' : about.heroTitle,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF171717),
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: onEdit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF171717),
                    ),
                    child: const Text('Edit'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _AssociationInfoTile(
                label: 'Hero Intro',
                value: about.heroIntro,
                wide: true,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _AssociationInfoTile(
                    label: 'Mission Title',
                    value: about.missionTitle,
                  ),
                  _AssociationInfoTile(
                    label: 'Goals Title',
                    value: about.goalsTitle,
                  ),
                  _AssociationInfoTile(
                    label: 'Journey Title',
                    value: about.journeyTitle,
                  ),
                  _AssociationInfoTile(
                    label: 'Mission Text',
                    value: about.missionText,
                    wide: true,
                  ),
                  _AssociationInfoTile(
                    label: 'Goals Text',
                    value: about.goalsText,
                    wide: true,
                  ),
                  _AssociationInfoTile(
                    label: 'Journey Text',
                    value: about.journeyText,
                    wide: true,
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

class _AssociationAboutEditor extends StatelessWidget {
  const _AssociationAboutEditor({
    required this.draft,
    required this.isSaving,
    required this.onChanged,
    required this.onSave,
    required this.onCancel,
  });

  final AssociationAboutDraft draft;
  final bool isSaving;
  final ValueChanged<AssociationAboutDraft> onChanged;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Edit About Us',
          subtitle:
              'Update the same backend-driven landing page content used in the web app.',
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0F172A),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            children: [
              _AssociationTextField(
                label: 'Hero Title',
                value: draft.heroTitle,
                onChanged: (value) => onChanged(draft.copyWith(heroTitle: value)),
              ),
              _AssociationTextField(
                label: 'Hero Intro',
                value: draft.heroIntro,
                maxLines: 3,
                onChanged: (value) => onChanged(draft.copyWith(heroIntro: value)),
              ),
              _AssociationTextField(
                label: 'Mission Title',
                value: draft.missionTitle,
                onChanged:
                    (value) => onChanged(draft.copyWith(missionTitle: value)),
              ),
              _AssociationTextField(
                label: 'Mission Text',
                value: draft.missionText,
                maxLines: 4,
                onChanged:
                    (value) => onChanged(draft.copyWith(missionText: value)),
              ),
              _AssociationTextField(
                label: 'Goals Title',
                value: draft.goalsTitle,
                onChanged:
                    (value) => onChanged(draft.copyWith(goalsTitle: value)),
              ),
              _AssociationTextField(
                label: 'Goals Text',
                value: draft.goalsText,
                maxLines: 4,
                onChanged:
                    (value) => onChanged(draft.copyWith(goalsText: value)),
              ),
              _AssociationTextField(
                label: 'Journey Title',
                value: draft.journeyTitle,
                onChanged:
                    (value) => onChanged(draft.copyWith(journeyTitle: value)),
              ),
              _AssociationTextField(
                label: 'Journey Text',
                value: draft.journeyText,
                maxLines: 4,
                onChanged:
                    (value) => onChanged(draft.copyWith(journeyText: value)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton(
              onPressed: isSaving ? null : onCancel,
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: isSaving ? null : onSave,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF171717),
              ),
              child: Text(isSaving ? 'Saving...' : 'Save About Us'),
            ),
          ],
        ),
      ],
    );
  }
}

class _AssociationCommitteeView extends StatelessWidget {
  const _AssociationCommitteeView({required this.members});

  final List<MemberDirectoryItem> members;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const _EmptyStateCard(
        title: 'No committee members found',
        subtitle:
            'Add committee members in the backend member records to populate this section.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Management Committee',
          subtitle:
              'Committee members are loaded from the backend member records.',
        ),
        const SizedBox(height: 14),
        ...members.map(
          (member) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D0F172A),
                    blurRadius: 24,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MemberAvatar(
                    name: member.name,
                    photoUrl: member.photoUrl,
                    size: 58,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF171717),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          member.committeePost.isNotEmpty
                              ? member.committeePost
                              : 'Committee Member',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF7C3AED),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (member.companyName.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            member.companyName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                        if (member.memberBio.isNotEmpty ||
                            member.membershipDetails.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            member.memberBio.isNotEmpty
                                ? member.memberBio
                                : member.membershipDetails,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF374151),
                              height: 1.5,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (member.committeeTenureStart.isNotEmpty ||
                                member.committeeTenureEnd.isNotEmpty)
                              _MutedChip(
                                icon: Icons.calendar_today_rounded,
                                label:
                                    '${member.committeeTenureStart.isEmpty ? 'Now' : member.committeeTenureStart} to ${member.committeeTenureEnd.isEmpty ? 'Ongoing' : member.committeeTenureEnd}',
                              ),
                            if (member.email.isNotEmpty)
                              _MutedChip(
                                icon: Icons.mail_outline_rounded,
                                label: member.email,
                              ),
                            if (member.phone.isNotEmpty)
                              _MutedChip(
                                icon: Icons.call_outlined,
                                label: member.phone,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AssociationCircularsSection extends StatelessWidget {
  const _AssociationCircularsSection({
    required this.library,
    required this.draft,
    required this.editingCircularId,
    required this.isSaving,
    required this.onOpenEditor,
    required this.onCancelEdit,
    required this.onDraftChanged,
    required this.onPickFile,
    required this.onOpenDocument,
    required this.onSave,
    required this.onDelete,
  });

  final AssociationCircularLibraryData library;
  final AssociationCircularDraft? draft;
  final String? editingCircularId;
  final bool isSaving;
  final ValueChanged<AssociationCircularDocument?> onOpenEditor;
  final VoidCallback onCancelEdit;
  final ValueChanged<AssociationCircularDraft> onDraftChanged;
  final Future<void> Function() onPickFile;
  final Future<void> Function(String url) onOpenDocument;
  final Future<void> Function() onSave;
  final Future<void> Function(String circularId) onDelete;

  @override
  Widget build(BuildContext context) {
    final items = [...library.items]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: _SectionHeader(
                title: 'Document Library',
                subtitle:
                    'Upload PDFs, DOC files, or scanned circulars and make them available across admin surfaces.',
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () => onOpenEditor(null),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF171717),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text('Add New'),
            ),
          ],
        ),
        if (draft != null) ...[
          const SizedBox(height: 16),
          _AssociationCircularEditor(
            draft: draft!,
            isSaving: isSaving,
            onChanged: onDraftChanged,
            onPickFile: onPickFile,
            onSave: onSave,
            onCancel: onCancelEdit,
          ),
        ],
        const SizedBox(height: 16),
        if (items.isEmpty)
          const _EmptyStateCard(
            title: 'No circular documents yet',
            subtitle:
                'Upload your first circular to start building the association document library.',
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _AssociationCircularCard(
                item: item,
                isEditing: editingCircularId == item.id,
                onOpenDocument: () => onOpenDocument(item.documentUrl),
                onEdit: () => onOpenEditor(item),
                onDelete: () => onDelete(item.id),
              ),
            ),
          ),
      ],
    );
  }
}

class _AssociationCircularEditor extends StatelessWidget {
  const _AssociationCircularEditor({
    required this.draft,
    required this.isSaving,
    required this.onChanged,
    required this.onPickFile,
    required this.onSave,
    required this.onCancel,
  });

  final AssociationCircularDraft draft;
  final bool isSaving;
  final ValueChanged<AssociationCircularDraft> onChanged;
  final Future<void> Function() onPickFile;
  final Future<void> Function() onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Circular CMS',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF171717),
                  ),
                ),
              ),
              _MutedChip(
                icon: Icons.description_outlined,
                label: 'PDF, DOC, or image scan',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AssociationCircularPreview(draft: draft),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: isSaving ? null : () => onPickFile(),
              icon: const Icon(Icons.upload_file_rounded),
              label: Text(
                draft.selectedFile == null ? 'Upload Document' : 'Replace Document',
              ),
            ),
          ),
          const SizedBox(height: 16),
          _AssociationTextField(
            label: 'Headline',
            value: draft.headline,
            onChanged: (value) => onChanged(draft.copyWith(headline: value)),
          ),
          _AssociationTextField(
            label: 'Tagline',
            value: draft.tagline,
            onChanged: (value) => onChanged(draft.copyWith(tagline: value)),
          ),
          _AssociationTextField(
            label: 'Brief Text',
            value: draft.summary,
            maxLines: 5,
            onChanged: (value) => onChanged(draft.copyWith(summary: value)),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isSaving ? null : onCancel,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed:
                      isSaving || !draft.canSubmit ? null : () => onSave(),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF171717),
                  ),
                  child: Text(isSaving ? 'Saving...' : 'Save Circular'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssociationCircularPreview extends StatelessWidget {
  const _AssociationCircularPreview({required this.draft});

  final AssociationCircularDraft draft;

  @override
  Widget build(BuildContext context) {
    final upload = draft.selectedFile;
    final isImageUpload = upload != null && upload.mimeType.startsWith('image/');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child:
          isImageUpload
              ? ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.memory(
                  upload.bytes,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
              : draft.existingPreviewUrl.isNotEmpty
              ? ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  draft.existingPreviewUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => _AssociationCircularPlaceholder(
                        label: draft.displayFileExtension,
                      ),
                ),
              )
              : Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFFD946EF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      draft.displayFileExtension,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          draft.displayFileName.isEmpty
                              ? 'Upload a PDF, DOC, or scanned image'
                              : draft.displayFileName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF171717),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          draft.selectedFile != null
                              ? 'Selected from this device and ready to upload.'
                              : 'Keep a clear headline and short summary so members can scan the circular quickly.',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}

class _AssociationCircularCard extends StatelessWidget {
  const _AssociationCircularCard({
    required this.item,
    required this.isEditing,
    required this.onOpenDocument,
    required this.onEdit,
    required this.onDelete,
  });

  final AssociationCircularDocument item;
  final bool isEditing;
  final VoidCallback onOpenDocument;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isEditing ? const Color(0xFFDDD6FE) : const Color(0xFFF1F5F9),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AssociationCircularVisual(item: item),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.headline,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF171717),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.tagline.isEmpty ? 'No tagline added yet' : item.tagline,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF7C3AED),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.summary.isEmpty
                          ? 'No brief text added yet.'
                          : item.summary,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MutedChip(
                          icon: Icons.insert_drive_file_outlined,
                          label: item.fileExtension,
                        ),
                        if (item.originalFileName.isNotEmpty)
                          _MutedChip(
                            icon: Icons.badge_outlined,
                            label: item.originalFileName,
                          ),
                        _MutedChip(
                          icon: Icons.schedule_rounded,
                          label: item.createdDateLabel,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenDocument,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open Document'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onEdit,
                  child: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                  ),
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssociationCircularVisual extends StatelessWidget {
  const _AssociationCircularVisual({required this.item});

  final AssociationCircularDocument item;

  @override
  Widget build(BuildContext context) {
    if (item.previewUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.network(
          item.previewUrl,
          width: 92,
          height: 92,
          fit: BoxFit.cover,
          errorBuilder:
              (_, __, ___) => _AssociationCircularPlaceholder(
                label: item.fileExtension,
              ),
        ),
      );
    }

    return _AssociationCircularPlaceholder(label: item.fileExtension);
  }
}

class _AssociationCircularPlaceholder extends StatelessWidget {
  const _AssociationCircularPlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD946EF), Color(0xFF5B21B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _AssociationMasterSection extends StatefulWidget {
  const _AssociationMasterSection({
    required this.members,
    required this.draft,
    required this.editingMemberId,
    required this.isSaving,
    required this.onOpenEditor,
    required this.onCancelEdit,
    required this.onDraftChanged,
    required this.onSave,
    required this.onDelete,
  });

  final List<MemberDirectoryItem> members;
  final MemberMasterDraft? draft;
  final String? editingMemberId;
  final bool isSaving;
  final ValueChanged<MemberDirectoryItem?> onOpenEditor;
  final VoidCallback onCancelEdit;
  final ValueChanged<MemberMasterDraft> onDraftChanged;
  final Future<void> Function() onSave;
  final Future<void> Function(String memberId) onDelete;

  @override
  State<_AssociationMasterSection> createState() =>
      _AssociationMasterSectionState();
}

class _AssociationMasterSectionState extends State<_AssociationMasterSection> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredMembers =
        widget.members.where((member) {
          final query = _query.trim().toLowerCase();
          if (query.isEmpty) {
            return true;
          }
          return [
            member.name,
            member.companyName,
            member.roleTitle,
            member.email,
            member.phone,
            member.gst,
          ].join(' ').toLowerCase().contains(query);
        }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: _SectionHeader(
                title: 'Membership Master',
                subtitle:
                    'Create, update, and remove member records from the live backend membership master.',
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () => widget.onOpenEditor(null),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF171717),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text('Add User'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _AdminToolbarSearch(
          controller: _searchController,
          hintText: 'Search name, company, membership, GST, contact...',
          onChanged: (value) => setState(() => _query = value),
        ),
        if (widget.draft != null) ...[
          const SizedBox(height: 16),
          _MemberMasterEditor(
            draft: widget.draft!,
            isSaving: widget.isSaving,
            onChanged: widget.onDraftChanged,
            onSave: widget.onSave,
            onCancel: widget.onCancelEdit,
          ),
        ],
        const SizedBox(height: 16),
        if (filteredMembers.isEmpty)
          const _EmptyStateCard(
            title: 'No members found',
            subtitle: 'Try a different search or create the first member record.',
          )
        else
          ...filteredMembers.map(
            (member) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _MemberMasterCard(
                member: member,
                isEditing: widget.editingMemberId == member.id,
                onEdit: () => widget.onOpenEditor(member),
                onDelete: () => widget.onDelete(member.id),
              ),
            ),
          ),
      ],
    );
  }
}

class _MemberMasterEditor extends StatelessWidget {
  const _MemberMasterEditor({
    required this.draft,
    required this.isSaving,
    required this.onChanged,
    required this.onSave,
    required this.onCancel,
  });

  final MemberMasterDraft draft;
  final bool isSaving;
  final ValueChanged<MemberMasterDraft> onChanged;
  final Future<void> Function() onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  draft.id.isEmpty ? 'Add Member' : 'Edit Member',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF171717),
                  ),
                ),
              ),
              const _MutedChip(
                icon: Icons.admin_panel_settings_outlined,
                label: 'Admin CRUD',
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AssociationTextField(
            label: 'Full Name',
            value: draft.name,
            onChanged: (value) => onChanged(draft.copyWith(name: value)),
          ),
          _AssociationTextField(
            label: 'Company Name',
            value: draft.companyName,
            onChanged: (value) => onChanged(draft.copyWith(companyName: value)),
          ),
          _AssociationTextField(
            label: 'Email',
            value: draft.email,
            onChanged: (value) => onChanged(draft.copyWith(email: value)),
          ),
          _AssociationTextField(
            label: 'Phone',
            value: draft.phone,
            onChanged: (value) => onChanged(draft.copyWith(phone: value)),
          ),
          _AssociationTextField(
            label: 'Company Address',
            value: draft.address,
            maxLines: 3,
            onChanged: (value) => onChanged(draft.copyWith(address: value)),
          ),
          _AssociationTextField(
            label: 'GST',
            value: draft.gst,
            onChanged: (value) => onChanged(draft.copyWith(gst: value)),
          ),
          _AssociationTextField(
            label: 'Photo URL',
            value: draft.photoUrl,
            onChanged: (value) => onChanged(draft.copyWith(photoUrl: value)),
          ),
          _AssociationTextField(
            label: 'Membership Details',
            value: draft.membershipDetails,
            maxLines: 3,
            onChanged:
                (value) => onChanged(draft.copyWith(membershipDetails: value)),
          ),
          _AssociationTextField(
            label: 'Membership Start Date',
            value: draft.membershipStartDate,
            onChanged:
                (value) => onChanged(draft.copyWith(membershipStartDate: value)),
          ),
          _AssociationTextField(
            label: 'Membership End Date',
            value: draft.membershipEndDate,
            onChanged:
                (value) => onChanged(draft.copyWith(membershipEndDate: value)),
          ),
          _AssociationTextField(
            label: 'Payment Amount',
            value: draft.paymentAmount,
            onChanged:
                (value) => onChanged(draft.copyWith(paymentAmount: value)),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: DropdownButtonFormField<String>(
              value: draft.membershipType,
              decoration: const InputDecoration(
                labelText: 'Membership Type',
                border: OutlineInputBorder(),
              ),
              items:
                  const ['Primary', 'Associate', 'Guest', 'Committee']
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ),
                      )
                      .toList(),
              onChanged:
                  (value) => onChanged(
                    draft.copyWith(membershipType: value ?? 'Primary'),
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: DropdownButtonFormField<String>(
              value: draft.paymentStatus,
              decoration: const InputDecoration(
                labelText: 'Payment Status',
                border: OutlineInputBorder(),
              ),
              items:
                  const ['Pending', 'Paid', 'Overdue', 'Waived']
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ),
                      )
                      .toList(),
              onChanged:
                  (value) => onChanged(
                    draft.copyWith(paymentStatus: value ?? 'Pending'),
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isSaving ? null : onCancel,
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: isSaving || !draft.canSubmit ? null : () => onSave(),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF171717),
                  ),
                  child: Text(isSaving ? 'Saving...' : 'Save Member'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MemberMasterCard extends StatelessWidget {
  const _MemberMasterCard({
    required this.member,
    required this.isEditing,
    required this.onEdit,
    required this.onDelete,
  });

  final MemberDirectoryItem member;
  final bool isEditing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isEditing ? const Color(0xFFDDD6FE) : const Color(0xFFF1F5F9),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _MemberAvatar(
                name: member.name,
                photoUrl: member.photoUrl,
                size: 58,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF171717),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member.companyName.isEmpty ? 'No company added' : member.companyName,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MutedChip(
                          icon: Icons.verified_user_outlined,
                          label: member.roleTitle.isEmpty ? 'Primary' : member.roleTitle,
                        ),
                        if (member.gst.isNotEmpty)
                          _MutedChip(
                            icon: Icons.receipt_long_outlined,
                            label: member.gst,
                          ),
                        if (member.paymentStatus.isNotEmpty)
                          _MutedChip(
                            icon: Icons.payments_outlined,
                            label: member.paymentStatus,
                          ),
                      ],
                    ),
                    if (member.membershipDetails.isNotEmpty ||
                        member.memberBio.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        member.membershipDetails.isNotEmpty
                            ? member.membershipDetails
                            : member.memberBio,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF475569),
                          height: 1.5,
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
            spacing: 8,
            runSpacing: 8,
            children: [
              if (member.email.isNotEmpty)
                _MutedChip(
                  icon: Icons.mail_outline_rounded,
                  label: member.email,
                ),
              if (member.phone.isNotEmpty)
                _MutedChip(
                  icon: Icons.call_outlined,
                  label: member.phone,
                ),
              if (member.membershipStartDate.isNotEmpty ||
                  member.membershipEndDate.isNotEmpty)
                _MutedChip(
                  icon: Icons.calendar_today_rounded,
                  label:
                      '${member.membershipStartDate.isEmpty ? 'Start open' : member.membershipStartDate} to ${member.membershipEndDate.isEmpty ? 'Ongoing' : member.membershipEndDate}',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onEdit,
                  child: const Text('Edit'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                  ),
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AssociationInfoTile extends StatelessWidget {
  const _AssociationInfoTile({
    required this.label,
    required this.value,
    this.wide = false,
  });

  final String label;
  final String value;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: wide ? 560 : 270,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7C3AED),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.isEmpty ? 'Not added yet' : value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _AssociationTextField extends StatelessWidget {
  const _AssociationTextField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        key: ValueKey('$label-$value'),
        initialValue: value,
        minLines: maxLines,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _AdminAppAccessSection extends StatefulWidget {
  const _AdminAppAccessSection({
    required this.initialSettings,
    required this.onSave,
  });

  final AdminAppAccessSettings initialSettings;
  final Future<void> Function(AdminAppAccessSettings) onSave;

  @override
  State<_AdminAppAccessSection> createState() => _AdminAppAccessSectionState();
}

class _AdminAppAccessSectionState extends State<_AdminAppAccessSection> {
  late AdminAppAccessSettings _settings;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _settings = widget.initialSettings;
  }

  @override
  void didUpdateWidget(covariant _AdminAppAccessSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSettings != widget.initialSettings && !_isSaving) {
      _settings = widget.initialSettings;
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        'Approve members to login',
        'Require approval before members can sign into the app.',
        _settings.approveMembersLogin,
        (bool value) =>
            _settings = _settings.copyWith(approveMembersLogin: value),
      ),
      (
        'Disable screenshots',
        'Restrict screenshot capture inside the Flutter app.',
        _settings.disableScreenshots,
        (bool value) =>
            _settings = _settings.copyWith(disableScreenshots: value),
      ),
      (
        'Approve membership',
        'Keep membership activation behind admin approval.',
        _settings.approveMembership,
        (bool value) =>
            _settings = _settings.copyWith(approveMembership: value),
      ),
      (
        'Approve registration request',
        'Review and approve incoming registration requests.',
        _settings.approveRegistrationRequest,
        (bool value) => _settings = _settings.copyWith(
          approveRegistrationRequest: value,
        ),
      ),
      (
        'Disable admin functions from app',
        'Turn off admin-only features inside the member-facing app.',
        _settings.disableAdminFunctionsFromApp,
        (bool value) => _settings = _settings.copyWith(
          disableAdminFunctionsFromApp: value,
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Flutter App Permissions',
          subtitle:
              'These app access switches are now loaded from and saved back to the backend.',
        ),
        const SizedBox(height: 14),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D0F172A),
                    blurRadius: 24,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF171717),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.$2,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Switch.adaptive(
                    value: item.$3,
                    onChanged: (value) {
                      setState(() {
                        item.$4(value);
                      });
                    },
                    activeColor: const Color(0xFF7C3AED),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed:
                _isSaving
                    ? null
                    : () async {
                      setState(() {
                        _isSaving = true;
                      });
                      try {
                        await widget.onSave(_settings);
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isSaving = false;
                          });
                        }
                      }
                    },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF171717),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(_isSaving ? 'Saving...' : 'Save App Access'),
          ),
        ),
      ],
    );
  }
}

enum AdminMemberAccessView { app, content }

extension AdminMemberAccessViewMeta on AdminMemberAccessView {
  String get label => switch (this) {
    AdminMemberAccessView.app => 'Member App Access',
    AdminMemberAccessView.content => 'Member Content Access',
  };
}

enum AdminMemberTypeFilter { all, primary, associate, guest, committee }

extension AdminMemberTypeFilterMeta on AdminMemberTypeFilter {
  String get label => switch (this) {
    AdminMemberTypeFilter.all => 'All',
    AdminMemberTypeFilter.primary => 'Primary',
    AdminMemberTypeFilter.associate => 'Associate',
    AdminMemberTypeFilter.guest => 'Guest',
    AdminMemberTypeFilter.committee => 'Committee Members',
  };

  bool matches(AdminMemberAccessItem member) {
    final role = member.roleTitle.trim().toLowerCase();
    return switch (this) {
      AdminMemberTypeFilter.all =>
        ['primary', 'associate', 'temporary visit', 'committee'].contains(role),
      AdminMemberTypeFilter.primary => role == 'primary',
      AdminMemberTypeFilter.associate => role == 'associate',
      AdminMemberTypeFilter.guest =>
        role == 'temporary visit' || role == 'guest' || role == 'visitor',
      AdminMemberTypeFilter.committee => role == 'committee',
    };
  }
}

class _AdminMemberAccessWorkspace extends StatefulWidget {
  const _AdminMemberAccessWorkspace({
    required this.members,
    required this.posts,
    required this.updatingMemberId,
    required this.updatingPostId,
    required this.onUpdateAccess,
    required this.onBulkUpdateAccess,
    required this.onUpdateStatus,
  });

  final List<AdminMemberAccessItem> members;
  final List<MemberPostItem> posts;
  final String? updatingMemberId;
  final String? updatingPostId;
  final Future<void> Function(AdminMemberAccessItem, MemberAccessStatus)
  onUpdateAccess;
  final Future<void> Function(List<AdminMemberAccessItem>, MemberAccessStatus)
  onBulkUpdateAccess;
  final Future<void> Function(MemberPostItem, PostReviewStatus) onUpdateStatus;

  @override
  State<_AdminMemberAccessWorkspace> createState() =>
      _AdminMemberAccessWorkspaceState();
}

class _AdminMemberAccessWorkspaceState
    extends State<_AdminMemberAccessWorkspace> {
  AdminMemberAccessView _activeView = AdminMemberAccessView.app;
  AdminMemberTypeFilter _activeFilter = AdminMemberTypeFilter.all;
  final TextEditingController _appSearchController = TextEditingController();
  final TextEditingController _contentSearchController =
      TextEditingController();
  String _appQuery = '';
  String _contentQuery = '';
  final Set<String> _selectedMemberIds = <String>{};
  final Set<String> _selectedContentMemberIds = <String>{};

  @override
  void dispose() {
    _appSearchController.dispose();
    _contentSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredMembers =
        widget.members.where((member) {
          if (!_activeFilter.matches(member)) {
            return false;
          }
          if (_appQuery.trim().isEmpty) {
            return true;
          }
          return [
            member.name,
            member.companyName,
            member.roleTitle,
          ].join(' ').toLowerCase().contains(_appQuery.trim().toLowerCase());
        }).toList();
    final contentMemberMatches =
        widget.members.where((member) {
          if (_contentQuery.trim().isEmpty) {
            return true;
          }
          return [
            member.name,
            member.companyName,
          ].join(' ').toLowerCase().contains(_contentQuery.trim().toLowerCase());
        }).toList();
    final filteredPosts =
        widget.posts.where((post) {
          final query = _contentQuery.trim().toLowerCase();
          if (query.isNotEmpty &&
              ![
                post.title,
                post.summary,
                post.member.name,
                post.reviewStatus.label,
              ].join(' ').toLowerCase().contains(query)) {
            return false;
          }
          if (_selectedContentMemberIds.isEmpty) {
            return true;
          }
          return _selectedContentMemberIds.contains(post.member.id);
        }).toList();
    final allFilteredSelected =
        filteredMembers.isNotEmpty &&
        filteredMembers.every((member) => _selectedMemberIds.contains(member.id));

    if (_activeView == AdminMemberAccessView.app && filteredMembers.isEmpty) {
      return const _EmptyStateCard(
        title: 'No members found',
        subtitle: 'No member access records match the current search.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Member Access',
          subtitle:
              'Match the same member app access and member content access workflow shown in the web admin arena.',
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children:
              AdminMemberAccessView.values.map((view) {
                final selected = _activeView == view;
                return ChoiceChip(
                  label: Text(view.label),
                  selected: selected,
                  onSelected: (_) {
                    setState(() {
                      _activeView = view;
                    });
                  },
                  showCheckmark: false,
                  selectedColor: const Color(0xFFE9D5FF),
                  side: BorderSide(
                    color:
                        selected
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFFE5E7EB),
                  ),
                  labelStyle: TextStyle(
                    color:
                        selected
                            ? const Color(0xFF7C3AED)
                            : const Color(0xFF4B5563),
                    fontWeight: FontWeight.w700,
                  ),
                );
              }).toList(),
        ),
        const SizedBox(height: 14),
        if (_activeView == AdminMemberAccessView.app) ...[
          _AdminToolbarSearch(
            controller: _appSearchController,
            hintText: 'Search name, company, membership type...',
            onChanged: (value) => setState(() => _appQuery = value),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilterChip(
                label: const Text('Select filtered'),
                selected: allFilteredSelected,
                onSelected: (_) {
                  setState(() {
                    if (allFilteredSelected) {
                      _selectedMemberIds.removeAll(
                        filteredMembers.map((member) => member.id),
                      );
                    } else {
                      _selectedMemberIds.addAll(
                        filteredMembers.map((member) => member.id),
                      );
                    }
                  });
                },
              ),
              for (final filter in AdminMemberTypeFilter.values)
                ChoiceChip(
                  label: Text(filter.label),
                  selected: _activeFilter == filter,
                  onSelected: (_) {
                    setState(() {
                      _activeFilter = filter;
                    });
                  },
                  showCheckmark: false,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed:
                    _selectedMemberIds.isEmpty || widget.updatingMemberId != null
                        ? null
                        : () => widget.onBulkUpdateAccess(
                          filteredMembers
                              .where(
                                (member) =>
                                    _selectedMemberIds.contains(member.id),
                              )
                              .toList(),
                          MemberAccessStatus.approved,
                        ),
                child: const Text('Approve Membership'),
              ),
              OutlinedButton(
                onPressed:
                    _selectedMemberIds.isEmpty || widget.updatingMemberId != null
                        ? null
                        : () => widget.onBulkUpdateAccess(
                          filteredMembers
                              .where(
                                (member) =>
                                    _selectedMemberIds.contains(member.id),
                              )
                              .toList(),
                          MemberAccessStatus.suspended,
                        ),
                child: const Text('Suspend Membership'),
              ),
              OutlinedButton(
                onPressed:
                    _selectedMemberIds.isEmpty || widget.updatingMemberId != null
                        ? null
                        : () => widget.onBulkUpdateAccess(
                          filteredMembers
                              .where(
                                (member) =>
                                    _selectedMemberIds.contains(member.id),
                              )
                              .toList(),
                          MemberAccessStatus.cancelled,
                        ),
                child: const Text('Cancel Membership'),
              ),
            ],
          ),
          const SizedBox(height: 14),
        ] else ...[
          _AdminToolbarSearch(
            controller: _contentSearchController,
            hintText: 'Search member to filter content...',
            onChanged: (value) => setState(() => _contentQuery = value),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedContentMemberIds
                      ..clear()
                      ..addAll(contentMemberMatches.map((member) => member.id));
                  });
                },
                child: const Text('Select All Matched Members'),
              ),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedContentMemberIds.clear();
                  });
                },
                child: const Text('Clear Selection'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                contentMemberMatches.map((member) {
                  return FilterChip(
                    label: Text(member.name),
                    selected: _selectedContentMemberIds.contains(member.id),
                    onSelected: (_) {
                      setState(() {
                        if (_selectedContentMemberIds.contains(member.id)) {
                          _selectedContentMemberIds.remove(member.id);
                        } else {
                          _selectedContentMemberIds.add(member.id);
                        }
                      });
                    },
                  );
                }).toList(),
          ),
          const SizedBox(height: 14),
          _AdminContentReviewSection(
            posts: filteredPosts,
            updatingPostId: widget.updatingPostId,
            onUpdateStatus: widget.onUpdateStatus,
          ),
        ],
        if (_activeView == AdminMemberAccessView.app)
          ...filteredMembers.map(
            (member) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D0F172A),
                      blurRadius: 24,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: _selectedMemberIds.contains(member.id),
                          onChanged:
                              (_) => setState(() {
                                if (_selectedMemberIds.contains(member.id)) {
                                  _selectedMemberIds.remove(member.id);
                                } else {
                                  _selectedMemberIds.add(member.id);
                                }
                              }),
                        ),
                        _MemberAvatar(
                          name: member.name,
                          photoUrl: member.photoUrl,
                          size: 54,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                member.name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF171717),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                [
                                  if (member.companyName.isNotEmpty)
                                    member.companyName,
                                  if (member.roleTitle.isNotEmpty)
                                    member.roleTitle,
                                ].join(' • '),
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _AccessStatusBadge(status: member.accessStatus),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (member.email.isNotEmpty)
                          _MutedChip(
                            icon: Icons.mail_outline_rounded,
                            label: member.email,
                          ),
                        if (member.phone.isNotEmpty)
                          _MutedChip(
                            icon: Icons.call_outlined,
                            label: member.phone,
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          MemberAccessStatus.values.map((status) {
                            final selected = status == member.accessStatus;
                            return ChoiceChip(
                              label: Text(status.label),
                              selected: selected,
                              onSelected:
                                  widget.updatingMemberId != null
                                      ? null
                                      : (_) => widget.onUpdateAccess(member, status),
                              showCheckmark: false,
                              selectedColor: status.color.withValues(alpha: 0.16),
                              side: BorderSide(
                                color:
                                    selected
                                        ? status.color
                                        : const Color(0xFFE5E7EB),
                              ),
                              labelStyle: TextStyle(
                                color:
                                    selected
                                        ? status.color
                                        : const Color(0xFF4B5563),
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          }).toList(),
                    ),
                    if (widget.updatingMemberId == member.id) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AdminToolbarSearch extends StatelessWidget {
  const _AdminToolbarSearch({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          icon: const Icon(Icons.search_rounded),
          hintText: hintText,
        ),
      ),
    );
  }
}

class _AdminContentReviewSection extends StatelessWidget {
  const _AdminContentReviewSection({
    required this.posts,
    required this.updatingPostId,
    required this.onUpdateStatus,
  });

  final List<MemberPostItem> posts;
  final String? updatingPostId;
  final Future<void> Function(MemberPostItem, PostReviewStatus) onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const _EmptyStateCard(
        title: 'No posts found',
        subtitle: 'No member content items match the current search.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Content Review',
          subtitle:
              'Moderate member posts from the same queue used by web and member arena.',
        ),
        const SizedBox(height: 14),
        ...posts.take(8).map(
          (post) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _MemberPostCard(
              post: post,
              viewerRole: AppViewerRole.admin,
              isUpdating: updatingPostId == post.id,
              onUpdateStatus: onUpdateStatus,
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminEventsSection extends StatefulWidget {
  const _AdminEventsSection({
    required this.events,
    required this.eventTypes,
    required this.savingEventId,
    required this.onSaveEvent,
    required this.onDeleteEvent,
  });

  final List<AdminEventItem> events;
  final List<AdminEventTypeItem> eventTypes;
  final String? savingEventId;
  final Future<void> Function(AdminEventDraft) onSaveEvent;
  final Future<void> Function(String) onDeleteEvent;

  @override
  State<_AdminEventsSection> createState() => _AdminEventsSectionState();
}

class _AdminEventsSectionState extends State<_AdminEventsSection> {
  late AdminEventDraft _draft;

  @override
  void initState() {
    super.initState();
    _draft = AdminEventDraft.empty();
  }

  void _startEdit(AdminEventItem event) {
    setState(() {
      _draft = AdminEventDraft.fromEvent(event);
    });
  }

  void _resetDraft() {
    setState(() {
      _draft = AdminEventDraft.empty();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Event Access Controls',
          subtitle:
              'Search, edit, delete, and create events using the same backend-driven flow as the web app.',
        ),
        const SizedBox(height: 14),
        if (widget.events.isEmpty)
          const _EmptyStateCard(
            title: 'No events found',
            subtitle:
                'Create an event below or in the web app to start filling this list.',
          )
        else
          ...widget.events.map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D0F172A),
                      blurRadius: 24,
                      offset: Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            event.name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF171717),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _LiveStatusBadge(status: event.liveStatus),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      [
                        event.type,
                        event.date,
                        if (event.venue.isNotEmpty) event.venue,
                      ].where((value) => value.isNotEmpty).join(' • '),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF7C3AED),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (event.summary.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        event.summary,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4B5563),
                          height: 1.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (event.audience.isNotEmpty)
                          _MutedChip(
                            icon: Icons.groups_rounded,
                            label: event.audience,
                          ),
                        if (event.entryType.isNotEmpty)
                          _MutedChip(
                            icon: Icons.confirmation_number_outlined,
                            label: event.entryType,
                          ),
                        if (event.entryCharges.isNotEmpty)
                          _MutedChip(
                            icon: Icons.currency_rupee_rounded,
                            label: event.entryCharges,
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        OutlinedButton(
                          onPressed:
                              widget.savingEventId != null
                                  ? null
                                  : () => _startEdit(event),
                          child: const Text('Edit'),
                        ),
                        const SizedBox(width: 10),
                        OutlinedButton(
                          onPressed:
                              widget.savingEventId != null
                                  ? null
                                  : () => widget.onDeleteEvent(event.id),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                    if (widget.savingEventId == event.id) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(
                        borderRadius: BorderRadius.all(Radius.circular(999)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 18),
        _AdminEventForm(
          draft: _draft,
          eventTypes: widget.eventTypes,
          isSaving: widget.savingEventId == '__new__' ||
              (_draft.id.isNotEmpty && widget.savingEventId == _draft.id),
          onChanged: (draft) {
            setState(() {
              _draft = draft;
            });
          },
          onSave: () => widget.onSaveEvent(_draft),
          onCancel: _draft.id.isEmpty ? null : _resetDraft,
        ),
      ],
    );
  }
}

class _EventsArenaMasterSection extends StatelessWidget {
  const _EventsArenaMasterSection({
    required this.events,
    required this.eventTypes,
  });

  final List<AdminEventItem> events;
  final List<AdminEventTypeItem> eventTypes;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final upcoming =
        events.where((event) => event.date.compareTo(today) >= 0).length;
    final completed =
        events.where((event) => event.date.compareTo(today) < 0).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Events Master',
          subtitle:
              'A quick overview of live events, event types, and what is scheduled next from the backend.',
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _MiniStatCard(
                label: 'Total Events',
                value: '${events.length}',
                accent: const Color(0xFF7C3AED),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniStatCard(
                label: 'Upcoming',
                value: '$upcoming',
                accent: const Color(0xFFF57C00),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MiniStatCard(
                label: 'Event Types',
                value: '${eventTypes.length}',
                accent: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (events.isEmpty)
          const _EmptyStateCard(
            title: 'No events created yet',
            subtitle:
                'Use Create New Event to publish your first event and start building the timeline.',
          )
        else ...[
          ...events.take(3).map(
            (event) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _EventTimelineCard(
                event: event,
                accentLabel: event.liveStatus,
              ),
            ),
          ),
          if (completed > 0)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '$completed completed event${completed == 1 ? '' : 's'} remain available in the timeline archive.',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _EventsArenaCreateSection extends StatefulWidget {
  const _EventsArenaCreateSection({
    required this.eventTypes,
    required this.savingEventId,
    required this.onSaveEvent,
  });

  final List<AdminEventTypeItem> eventTypes;
  final String? savingEventId;
  final Future<void> Function(AdminEventDraft draft) onSaveEvent;

  @override
  State<_EventsArenaCreateSection> createState() =>
      _EventsArenaCreateSectionState();
}

class _EventsArenaCreateSectionState extends State<_EventsArenaCreateSection> {
  AdminEventDraft _draft = AdminEventDraft.empty();

  Future<void> _pickBanner() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    if (file == null || file.bytes == null) {
      return;
    }
    setState(() {
      _draft = _draft.copyWith(
        bannerFile: AssociationUploadFile.fromPlatformFile(file),
        imageName: file.name,
      );
    });
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp4', 'mov', 'avi', 'mkv', 'webm'],
      withData: true,
    );
    final file = result?.files.single;
    if (file == null || file.bytes == null) {
      return;
    }
    setState(() {
      _draft = _draft.copyWith(
        videoFile: AssociationUploadFile.fromPlatformFile(file),
        videoName: file.name,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Create New Event',
          subtitle:
              'Use the same backend event flow as web, including banner picture and promo video uploads.',
        ),
        const SizedBox(height: 14),
        _AdminEventForm(
          draft: _draft,
          eventTypes: widget.eventTypes,
          isSaving: widget.savingEventId == '__new__',
          onChanged: (draft) => setState(() => _draft = draft),
          onSave: () => widget.onSaveEvent(_draft),
          onCancel: null,
          onPickBanner: _pickBanner,
          onPickVideo: _pickVideo,
        ),
      ],
    );
  }
}

class _EventsArenaTypeManager extends StatefulWidget {
  const _EventsArenaTypeManager({
    required this.items,
    required this.savingEventTypeId,
    required this.onSaveNewType,
    required this.onUpdateType,
  });

  final List<AdminEventTypeItem> items;
  final String? savingEventTypeId;
  final Future<void> Function(EventTypeDraft draft) onSaveNewType;
  final Future<void> Function(EventTypeDraft draft) onUpdateType;

  @override
  State<_EventsArenaTypeManager> createState() => _EventsArenaTypeManagerState();
}

class _EventsArenaTypeManagerState extends State<_EventsArenaTypeManager> {
  EventTypeDraft _draft = const EventTypeDraft.empty();
  late List<EventTypeDraft> _editableTypes;

  @override
  void initState() {
    super.initState();
    _editableTypes = widget.items.map(EventTypeDraft.fromItem).toList();
  }

  @override
  void didUpdateWidget(covariant _EventsArenaTypeManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items != widget.items) {
      _editableTypes = widget.items.map(EventTypeDraft.fromItem).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Type of Event',
          subtitle:
              'Add new event types or update existing ones from the same backend catalog used across event creation.',
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D0F172A),
                blurRadius: 24,
                offset: Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            children: [
              _AssociationTextField(
                label: 'New Event Type',
                value: _draft.title,
                onChanged: (value) => setState(() => _draft = _draft.copyWith(title: value)),
              ),
              _AssociationTextField(
                label: 'Description',
                value: _draft.meta,
                onChanged: (value) => setState(() => _draft = _draft.copyWith(meta: value)),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed:
                      widget.savingEventTypeId != null || !_draft.canSubmit
                          ? null
                          : () async {
                            await widget.onSaveNewType(_draft);
                            if (!mounted) return;
                            setState(() {
                              _draft = const EventTypeDraft.empty();
                            });
                          },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF171717),
                  ),
                  child: Text(
                    widget.savingEventTypeId == '__new__'
                        ? 'Adding...'
                        : 'Add Type',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._editableTypes.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0D0F172A),
                    blurRadius: 24,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _AssociationTextField(
                    label: 'Type Name',
                    value: item.title,
                    onChanged: (value) {
                      setState(() {
                        final index = _editableTypes.indexWhere((entry) => entry.id == item.id);
                        _editableTypes[index] = item.copyWith(title: value);
                      });
                    },
                  ),
                  _AssociationTextField(
                    label: 'Description',
                    value: item.meta,
                    onChanged: (value) {
                      setState(() {
                        final index = _editableTypes.indexWhere((entry) => entry.id == item.id);
                        _editableTypes[index] = item.copyWith(meta: value);
                      });
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed:
                          widget.savingEventTypeId != null
                              ? null
                              : () => widget.onUpdateType(
                                    _editableTypes.firstWhere((entry) => entry.id == item.id),
                                  ),
                      child: Text(
                        widget.savingEventTypeId == item.id
                            ? 'Saving...'
                            : 'Save Type',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EventsArenaTimelineSection extends StatefulWidget {
  const _EventsArenaTimelineSection({
    required this.events,
    required this.eventTypes,
    required this.savingEventId,
    required this.onSaveEvent,
    required this.onDeleteEvent,
  });

  final List<AdminEventItem> events;
  final List<AdminEventTypeItem> eventTypes;
  final String? savingEventId;
  final Future<void> Function(AdminEventDraft draft) onSaveEvent;
  final Future<void> Function(String eventId) onDeleteEvent;

  @override
  State<_EventsArenaTimelineSection> createState() =>
      _EventsArenaTimelineSectionState();
}

class _EventsArenaTimelineSectionState extends State<_EventsArenaTimelineSection> {
  AdminEventDraft? _editingDraft;

  Future<void> _pickBanner() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    final file = result?.files.single;
    if (file == null || file.bytes == null || _editingDraft == null) {
      return;
    }
    setState(() {
      _editingDraft = _editingDraft!.copyWith(
        bannerFile: AssociationUploadFile.fromPlatformFile(file),
        imageName: file.name,
      );
    });
  }

  Future<void> _pickVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['mp4', 'mov', 'avi', 'mkv', 'webm'],
      withData: true,
    );
    final file = result?.files.single;
    if (file == null || file.bytes == null || _editingDraft == null) {
      return;
    }
    setState(() {
      _editingDraft = _editingDraft!.copyWith(
        videoFile: AssociationUploadFile.fromPlatformFile(file),
        videoName: file.name,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = <AdminEventItem>[];
    final completed = <AdminEventItem>[];
    final today = DateTime.now().toIso8601String().substring(0, 10);
    for (final event in widget.events) {
      if (event.date.compareTo(today) < 0) {
        completed.add(event);
      } else {
        upcoming.add(event);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(
          title: 'Event Timeline',
          subtitle:
              'Browse upcoming and completed events, and edit existing records directly from the live timeline.',
        ),
        const SizedBox(height: 14),
        if (_editingDraft != null) ...[
          _AdminEventForm(
            draft: _editingDraft!,
            eventTypes: widget.eventTypes,
            isSaving: widget.savingEventId == _editingDraft!.id,
            onChanged: (draft) => setState(() => _editingDraft = draft),
            onSave: () => widget.onSaveEvent(_editingDraft!),
            onCancel: () => setState(() => _editingDraft = null),
            onPickBanner: _pickBanner,
            onPickVideo: _pickVideo,
          ),
          const SizedBox(height: 16),
        ],
        if (widget.events.isEmpty)
          const _EmptyStateCard(
            title: 'No events yet',
            subtitle:
                'Create an event first to populate the live timeline and archive.',
          )
        else ...[
          if (upcoming.isNotEmpty) ...[
            const _SectionHeader(
              title: 'Upcoming',
              subtitle: 'Scheduled events that are still ahead of today.',
            ),
            const SizedBox(height: 12),
            ...upcoming.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _EditableEventTimelineCard(
                  event: event,
                  isSaving: widget.savingEventId == event.id,
                  onEdit: () => setState(() {
                    _editingDraft = AdminEventDraft.fromEvent(event);
                  }),
                  onDelete: () => widget.onDeleteEvent(event.id),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (completed.isNotEmpty) ...[
            const _SectionHeader(
              title: 'Completed',
              subtitle: 'Past events remain visible here as a simple archive.',
            ),
            const SizedBox(height: 12),
            ...completed.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _EditableEventTimelineCard(
                  event: event,
                  isSaving: widget.savingEventId == event.id,
                  onEdit: () => setState(() {
                    _editingDraft = AdminEventDraft.fromEvent(event);
                  }),
                  onDelete: () => widget.onDeleteEvent(event.id),
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _EventTimelineCard extends StatelessWidget {
  const _EventTimelineCard({
    required this.event,
    required this.accentLabel,
  });

  final AdminEventItem event;
  final String accentLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF171717),
                  ),
                ),
              ),
              _LiveStatusBadge(status: accentLabel),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            [event.type, event.date, event.venue]
                .where((value) => value.isNotEmpty)
                .join(' • '),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF7C3AED),
              fontWeight: FontWeight.w700,
            ),
          ),
          if (event.summary.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              event.summary,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF4B5563),
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (event.audience.isNotEmpty)
                _MutedChip(
                  icon: Icons.groups_rounded,
                  label: event.audience,
                ),
              if (event.entryType.isNotEmpty)
                _MutedChip(
                  icon: Icons.confirmation_number_outlined,
                  label: event.entryType,
                ),
              if (event.imageName.isNotEmpty)
                _MutedChip(
                  icon: Icons.image_outlined,
                  label: event.imageName,
                ),
              if (event.videoName.isNotEmpty)
                _MutedChip(
                  icon: Icons.video_library_outlined,
                  label: event.videoName,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditableEventTimelineCard extends StatelessWidget {
  const _EditableEventTimelineCard({
    required this.event,
    required this.isSaving,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminEventItem event;
  final bool isSaving;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EventTimelineCard(event: event, accentLabel: event.liveStatus),
          const SizedBox(height: 14),
          Row(
            children: [
              OutlinedButton(
                onPressed: isSaving ? null : onEdit,
                child: const Text('Edit'),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: isSaving ? null : onDelete,
                child: const Text('Delete'),
              ),
            ],
          ),
          if (isSaving) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(
              borderRadius: BorderRadius.all(Radius.circular(999)),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminEventForm extends StatelessWidget {
  const _AdminEventForm({
    required this.draft,
    required this.eventTypes,
    required this.isSaving,
    required this.onChanged,
    required this.onSave,
    required this.onCancel,
    this.onPickBanner,
    this.onPickVideo,
  });

  final AdminEventDraft draft;
  final List<AdminEventTypeItem> eventTypes;
  final bool isSaving;
  final ValueChanged<AdminEventDraft> onChanged;
  final VoidCallback onSave;
  final VoidCallback? onCancel;
  final Future<void> Function()? onPickBanner;
  final Future<void> Function()? onPickVideo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            draft.id.isEmpty ? 'Create Event' : 'Edit Event',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF171717),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              _EventField(
                width: 280,
                child: TextFormField(
                  key: ValueKey('event-name-${draft.id}-${draft.name}'),
                  initialValue: draft.name,
                  decoration: const InputDecoration(
                    labelText: 'Event Name',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => onChanged(draft.copyWith(name: value)),
                ),
              ),
              _EventField(
                width: 220,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('event-type-${draft.id}-${draft.type}'),
                  decoration: const InputDecoration(
                    labelText: 'Type',
                    border: OutlineInputBorder(),
                  ),
                  value: draft.type.isEmpty ? null : draft.type,
                  items: [
                    ...eventTypes.map(
                      (type) => DropdownMenuItem(
                        value: type.title,
                        child: Text(type.title),
                      ),
                    ),
                  ],
                  onChanged:
                      (value) => onChanged(draft.copyWith(type: value ?? '')),
                ),
              ),
              _EventField(
                width: 180,
                child: TextFormField(
                  key: ValueKey('event-date-${draft.id}-${draft.date}'),
                  initialValue: draft.date,
                  decoration: const InputDecoration(
                    labelText: 'Date',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => onChanged(draft.copyWith(date: value)),
                ),
              ),
              _EventField(
                width: 240,
                child: TextFormField(
                  key: ValueKey('event-venue-${draft.id}-${draft.venue}'),
                  initialValue: draft.venue,
                  decoration: const InputDecoration(
                    labelText: 'Venue',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => onChanged(draft.copyWith(venue: value)),
                ),
              ),
              _EventField(
                width: 220,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('event-audience-${draft.id}-${draft.audience}'),
                  decoration: const InputDecoration(
                    labelText: 'Audience',
                    border: OutlineInputBorder(),
                  ),
                  value: draft.audience.isEmpty ? null : draft.audience,
                  items: const [
                    DropdownMenuItem(
                      value: 'Primary Members',
                      child: Text('Primary Members'),
                    ),
                    DropdownMenuItem(
                      value: 'Associate Members',
                      child: Text('Associate Members'),
                    ),
                    DropdownMenuItem(value: 'Guest', child: Text('Guest')),
                    DropdownMenuItem(
                      value: 'Open for All',
                      child: Text('Open for All'),
                    ),
                  ],
                  onChanged:
                      (value) =>
                          onChanged(draft.copyWith(audience: value ?? '')),
                ),
              ),
              _EventField(
                width: 180,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('event-entry-type-${draft.id}-${draft.entryType}'),
                  decoration: const InputDecoration(
                    labelText: 'Entry Type',
                    border: OutlineInputBorder(),
                  ),
                  value: draft.entryType.isEmpty ? null : draft.entryType,
                  items: const [
                    DropdownMenuItem(value: 'Free', child: Text('Free')),
                    DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                  ],
                  onChanged:
                      (value) =>
                          onChanged(draft.copyWith(entryType: value ?? '')),
                ),
              ),
              _EventField(
                width: 180,
                child: TextFormField(
                  key: ValueKey(
                    'event-entry-charges-${draft.id}-${draft.entryCharges}',
                  ),
                  initialValue: draft.entryCharges,
                  decoration: const InputDecoration(
                    labelText: 'Entry Charges',
                    border: OutlineInputBorder(),
                  ),
                  onChanged:
                      (value) => onChanged(draft.copyWith(entryCharges: value)),
                ),
              ),
              _EventField(
                width: 200,
                child: TextFormField(
                  key: ValueKey(
                    'event-participation-${draft.id}-${draft.participationCharges}',
                  ),
                  initialValue: draft.participationCharges,
                  decoration: const InputDecoration(
                    labelText: 'Participation Charges',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => onChanged(
                    draft.copyWith(participationCharges: value),
                  ),
                ),
              ),
              _EventField(
                width: 150,
                child: TextFormField(
                  key: ValueKey('event-start-${draft.id}-${draft.startTime}'),
                  initialValue: draft.startTime,
                  decoration: const InputDecoration(
                    labelText: 'Start Time',
                    border: OutlineInputBorder(),
                  ),
                  onChanged:
                      (value) => onChanged(draft.copyWith(startTime: value)),
                ),
              ),
              _EventField(
                width: 150,
                child: TextFormField(
                  key: ValueKey('event-end-${draft.id}-${draft.endTime}'),
                  initialValue: draft.endTime,
                  decoration: const InputDecoration(
                    labelText: 'End Time',
                    border: OutlineInputBorder(),
                  ),
                  onChanged:
                      (value) => onChanged(draft.copyWith(endTime: value)),
                ),
              ),
              if (onPickBanner != null)
                _EventField(
                  width: 280,
                  child: OutlinedButton.icon(
                    onPressed: isSaving ? null : () => onPickBanner!(),
                    icon: const Icon(Icons.image_outlined),
                    label: Text(
                      draft.imageName.isEmpty
                          ? 'Pick Event Banner'
                          : 'Banner: ${draft.imageName}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              if (onPickVideo != null)
                _EventField(
                  width: 280,
                  child: OutlinedButton.icon(
                    onPressed: isSaving ? null : () => onPickVideo!(),
                    icon: const Icon(Icons.video_library_outlined),
                    label: Text(
                      draft.videoName.isEmpty
                          ? 'Pick Promo Video'
                          : 'Video: ${draft.videoName}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
          if (draft.bannerUrl.isNotEmpty ||
              draft.promoVideoUrl.isNotEmpty ||
              draft.imageName.isNotEmpty ||
              draft.videoName.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (draft.imageName.isNotEmpty)
                  _MutedChip(
                    icon: Icons.image_outlined,
                    label: draft.imageName,
                  ),
                if (draft.videoName.isNotEmpty)
                  _MutedChip(
                    icon: Icons.video_library_outlined,
                    label: draft.videoName,
                  ),
                if (draft.bannerUrl.isNotEmpty && draft.bannerFile == null)
                  const _MutedChip(
                    icon: Icons.image_search_outlined,
                    label: 'Current banner attached',
                  ),
                if (draft.promoVideoUrl.isNotEmpty && draft.videoFile == null)
                  const _MutedChip(
                    icon: Icons.movie_creation_outlined,
                    label: 'Current promo video attached',
                  ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          TextFormField(
            initialValue: draft.summary,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Event Summary',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => onChanged(draft.copyWith(summary: value)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (onCancel != null)
                OutlinedButton(
                  onPressed: isSaving ? null : onCancel,
                  child: const Text('Cancel'),
                ),
              if (onCancel != null) const SizedBox(width: 10),
              FilledButton(
                onPressed: isSaving ? null : onSave,
                child: Text(isSaving ? 'Saving...' : 'Save Event'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EventField extends StatelessWidget {
  const _EventField({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: width, child: child);
  }
}

class _FeedInfoBanner extends StatelessWidget {
  const _FeedInfoBanner({required this.viewerRole, required this.postCount});

  final AppViewerRole viewerRole;
  final int postCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F5FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE9D5FF)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED),
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.newspaper_rounded, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              viewerRole.isAdmin
                  ? '$postCount posts loaded. Admin can switch each post between approved, rejected, and pending.'
                  : '$postCount approved posts are visible in ${viewerRole.label.toLowerCase()} mode.',
              style: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 14,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberPostCard extends StatelessWidget {
  const _MemberPostCard({
    required this.post,
    required this.viewerRole,
    required this.isUpdating,
    required this.onUpdateStatus,
  });

  final MemberPostItem post;
  final AppViewerRole viewerRole;
  final bool isUpdating;
  final Future<void> Function(MemberPostItem, PostReviewStatus) onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MemberAvatar(
                  name: post.member.name,
                  photoUrl: post.member.photoUrl,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.member.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF171717),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (post.member.company.isNotEmpty)
                            post.member.company,
                          post.postedOn,
                        ].join(' • '),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _StatusBadge(status: post.reviewStatus),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
            child: Text(
              post.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF171717),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: Text(
              post.summary,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF374151),
                height: 1.55,
              ),
            ),
          ),
          if (post.body.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
              child: Text(
                post.body,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  height: 1.55,
                ),
              ),
            ),
          const SizedBox(height: 14),
          _PostMediaPreview(post: post),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MutedChip(
                      icon: Icons.category_rounded,
                      label: post.postType,
                    ),
                    if (post.displayStart.isNotEmpty ||
                        post.displayEnd.isNotEmpty)
                      _MutedChip(
                        icon: Icons.schedule_rounded,
                        label: _displayWindowLabel(post),
                      ),
                  ],
                ),
                if (viewerRole.isAdmin) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  const Text(
                    'Post status',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF171717),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        PostReviewStatus.values.map((status) {
                          final selected = post.reviewStatus == status;
                          return ChoiceChip(
                            label: Text(status.label),
                            selected: selected,
                            onSelected:
                                isUpdating
                                    ? null
                                    : (_) => onUpdateStatus(post, status),
                            showCheckmark: false,
                            selectedColor: status.color.withValues(alpha: 0.16),
                            labelStyle: TextStyle(
                              color:
                                  selected
                                      ? status.color
                                      : const Color(0xFF4B5563),
                              fontWeight: FontWeight.w700,
                            ),
                            side: BorderSide(
                              color:
                                  selected
                                      ? status.color
                                      : const Color(0xFFE5E7EB),
                            ),
                          );
                        }).toList(),
                  ),
                  if (isUpdating) ...[
                    const SizedBox(height: 10),
                    const LinearProgressIndicator(
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _displayWindowLabel(MemberPostItem post) {
    if (post.displayStart.isEmpty && post.displayEnd.isEmpty) {
      return 'No schedule';
    }
    if (post.displayEnd.isEmpty) {
      return 'From ${post.displayStart}';
    }
    if (post.displayStart.isEmpty) {
      return 'Until ${post.displayEnd}';
    }
    return '${post.displayStart} to ${post.displayEnd}';
  }
}

class _PostMediaPreview extends StatelessWidget {
  const _PostMediaPreview({required this.post});

  final MemberPostItem post;

  @override
  Widget build(BuildContext context) {
    final mediaUrl = post.mediaUrl.trim();
    if (mediaUrl.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 18),
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFDE68A), Color(0xFFF9A8D4), Color(0xFFC4B5FD)],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.photo_library_rounded,
              size: 38,
              color: Colors.white,
            ),
            const SizedBox(height: 10),
            Text(
              post.postType,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 18),
        constraints: const BoxConstraints(minHeight: 180, maxHeight: 280),
        color: const Color(0xFFF3F4F6),
        child: Image.network(
          mediaUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder:
              (_, __, ___) => Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24),
                child: const Text(
                  'Media could not be loaded.',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
        ),
      ),
    );
  }
}

class _MemberDirectorySection extends StatefulWidget {
  const _MemberDirectorySection({
    required this.members,
    this.initialFilter = MemberDirectoryFilter.all,
    this.lockFilter = false,
    this.title = 'Member Directory',
    this.subtitle =
        'Browse members alphabetically, filter by membership type, and search by name, company, city, or profile details.',
  });

  final List<MemberDirectoryItem> members;
  final MemberDirectoryFilter initialFilter;
  final bool lockFilter;
  final String title;
  final String subtitle;

  @override
  State<_MemberDirectorySection> createState() =>
      _MemberDirectorySectionState();
}

class _MemberDirectorySectionState extends State<_MemberDirectorySection> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  late MemberDirectoryFilter _activeFilter;

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter;
  }

  @override
  void didUpdateWidget(covariant _MemberDirectorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      _activeFilter = widget.initialFilter;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final filteredMembers =
        widget.members.where((member) {
          final matchesFilter = _activeFilter.matches(member);
          if (!matchesFilter) {
            return false;
          }

          if (normalizedQuery.isEmpty) {
            return true;
          }

          final haystack =
              [
                member.name,
                member.companyName,
                member.roleTitle,
                member.address,
                member.memberBio,
                member.membershipDetails,
                member.email,
                member.phone,
              ].join(' ').toLowerCase();
          return haystack.contains(normalizedQuery);
        }).toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );

    final groupedMembers = <String, List<MemberDirectoryItem>>{};
    for (final member in filteredMembers) {
      final label =
          member.name.trim().isEmpty
              ? '#'
              : member.name.trim()[0].toUpperCase().replaceAll(
                RegExp(r'[^A-Z]'),
                '#',
              );
      groupedMembers.putIfAbsent(label, () => []).add(member);
    }
    final sortedLetters = groupedMembers.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: widget.title,
          subtitle: widget.subtitle,
        ),
        const SizedBox(height: 14),
        if (!widget.lockFilter) ...[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children:
                MemberDirectoryFilter.values.map((filter) {
                  final selected = filter == _activeFilter;
                  return ChoiceChip(
                    label: Text(filter.label),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _activeFilter = filter;
                      });
                    },
                    showCheckmark: false,
                    selectedColor: const Color(0xFFE9D5FF),
                    side: BorderSide(
                      color:
                          selected
                              ? const Color(0xFF7C3AED)
                              : const Color(0xFFE5E7EB),
                    ),
                    labelStyle: TextStyle(
                      color:
                          selected
                              ? const Color(0xFF7C3AED)
                              : const Color(0xFF4B5563),
                      fontWeight: FontWeight.w700,
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(height: 14),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE5E7EB)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A0F172A),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              border: InputBorder.none,
              icon: Icon(Icons.search_rounded),
              hintText: 'Search by name, company, city, role, or intro',
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (filteredMembers.isEmpty) ...[
          const _EmptyStateCard(
            title: 'No matching members',
            subtitle:
                'Try another search term or add more member records in the backend.',
          ),
        ] else ...[
          ...sortedLetters.map(
            (letter) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      letter,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF171717),
                      ),
                    ),
                  ),
                  ...groupedMembers[letter]!.map(
                    (member) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _MemberDirectoryCard(member: member),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MemberDirectoryCard extends StatelessWidget {
  const _MemberDirectoryCard({required this.member});

  final MemberDirectoryItem member;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0F172A),
            blurRadius: 24,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MemberAvatar(name: member.name, photoUrl: member.photoUrl, size: 54),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171717),
                  ),
                ),
                if (member.companyName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    member.companyName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF7C3AED),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (member.roleTitle.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    member.roleTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
                if (member.memberBio.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    member.memberBio,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                      height: 1.5,
                    ),
                  ),
                ] else if (member.membershipDetails.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    member.membershipDetails,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                      height: 1.5,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (member.address.isNotEmpty)
                      _MutedChip(
                        icon: Icons.location_on_outlined,
                        label: member.address,
                      ),
                    if (member.email.isNotEmpty)
                      _MutedChip(
                        icon: Icons.mail_outline_rounded,
                        label: member.email,
                      ),
                    if (member.phone.isNotEmpty)
                      _MutedChip(
                        icon: Icons.call_outlined,
                        label: member.phone,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({
    required this.name,
    required this.photoUrl,
    this.size = 48,
  });

  final String name;
  final String photoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initials =
        name
            .trim()
            .split(RegExp(r'\s+'))
            .where((part) => part.isNotEmpty)
            .take(2)
            .map((part) => part[0].toUpperCase())
            .join();

    if (photoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: Image.network(
          photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder:
              (_, __, ___) =>
                  _MemberAvatarFallback(initials: initials, size: size),
        ),
      );
    }

    return _MemberAvatarFallback(initials: initials, size: size);
  }
}

class _MemberAvatarFallback extends StatelessWidget {
  const _MemberAvatarFallback({required this.initials, required this.size});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
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
        initials.isEmpty ? 'M' : initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.32,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final PostReviewStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AccessStatusBadge extends StatelessWidget {
  const _AccessStatusBadge({required this.status});

  final MemberAccessStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: status.color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LiveStatusBadge extends StatelessWidget {
  const _LiveStatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final color =
        normalized == 'completed'
            ? const Color(0xFF6B7280)
            : const Color(0xFF10B981);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MutedChip extends StatelessWidget {
  const _MutedChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderArenaContent extends StatelessWidget {
  const _PlaceholderArenaContent();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _SectionHeader(
          title: 'Priority Actions',
          subtitle: 'The first admin modules we can wire up next.',
        ),
        SizedBox(height: 14),
        _ActionCard(
          icon: Icons.groups_rounded,
          title: 'Arena workspace',
          subtitle:
              'Member Arena is now implemented first. The remaining arenas can be layered into the same shell next.',
        ),
        SizedBox(height: 12),
        _ActionCard(
          icon: Icons.receipt_long_rounded,
          title: 'Billing & dues',
          subtitle: 'Track collections, unpaid balances, and receipts.',
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return _EmptyStateCard(
      title: 'Could not load member arena',
      subtitle: message,
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 36, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF171717),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => onAction!.call(),
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFD946EF)],
              ),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF171717),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color:
              selected
                  ? Colors.white.withValues(alpha: 0.14)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border:
              selected
                  ? Border.all(color: Colors.white.withValues(alpha: 0.16))
                  : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}

class _DrawerSubItem extends StatelessWidget {
  const _DrawerSubItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:
              selected
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? const Color(0xFFF59E0B) : Colors.white54,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminBottomBar extends StatelessWidget {
  const _AdminBottomBar({
    required this.selectedArena,
    required this.onArenaSelected,
  });

  final String selectedArena;
  final ValueChanged<String> onArenaSelected;

  @override
  Widget build(BuildContext context) {
    const items = [
      ('Dashboard', Icons.dashboard_rounded, 'Home'),
      ('Association Arena', Icons.apartment_rounded, 'Association'),
      ('Member Arena', Icons.people_alt_rounded, 'Member'),
      ('Vendor Arena', Icons.storefront_rounded, 'Vendor'),
      ('Events Arena', Icons.event_available_rounded, 'Events'),
    ];

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF101114),
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24000000),
              blurRadius: 24,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children:
              items
                  .map(
                    (item) => _BottomNavItem(
                      icon: item.$2,
                      label: item.$3,
                      active: selectedArena == item.$1,
                      onTap: () => onArenaSelected(item.$1),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.white : Colors.white70;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color:
                    active
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.transparent,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SynetraApiClient {
  SynetraApiClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  final String _baseUrl = 'http://192.168.29.222:8083/api';

  Future<MemberArenaData> loadMemberArenaData({
    required AppViewerRole viewerRole,
  }) async {
    final posts = await fetchPosts(approvedOnly: !viewerRole.isAdmin);
    final members = await fetchMembers();
    return MemberArenaData(posts: posts, members: members);
  }

  Future<AdminArenaData> loadAdminArenaData() async {
    final appAccess = await fetchAppAccess();
    final members = await fetchAdminMembers();
    final posts = await fetchPosts(approvedOnly: false);
    final events = await fetchEvents();
    final eventTypes = await fetchEventTypes();
    return AdminArenaData(
      appAccess: appAccess,
      members: members,
      posts: posts,
      events: events,
      eventTypes: eventTypes,
    );
  }

  Future<List<MemberPostItem>> fetchPosts({required bool approvedOnly}) async {
    final uri = Uri.parse('$_baseUrl/member-posts').replace(
      queryParameters:
          approvedOnly
              ? {'reviewStatus': PostReviewStatus.approved.apiValue}
              : null,
    );
    final json = await _getJson(uri);
    final items = (json['posts'] as List<dynamic>? ?? const []);
    return items
        .map((item) => MemberPostItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<MemberDirectoryItem>> fetchMembers() async {
    final json = await _getJson(Uri.parse('$_baseUrl/members'));
    final items = (json['members'] as List<dynamic>? ?? const []);
    return items
        .map(
          (item) => MemberDirectoryItem.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<AdminMemberAccessItem>> fetchAdminMembers() async {
    final json = await _getJson(Uri.parse('$_baseUrl/members'));
    final items = (json['members'] as List<dynamic>? ?? const []);
    return items
        .map(
          (item) => AdminMemberAccessItem.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<AdminAppAccessSettings> fetchAppAccess() async {
    final json = await _getJson(Uri.parse('$_baseUrl/associations/current/app-access'));
    return AdminAppAccessSettings.fromJson(
      json['appAccess'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<List<AdminEventItem>> fetchEvents() async {
    final json = await _getJson(Uri.parse('$_baseUrl/events'));
    final items = (json['events'] as List<dynamic>? ?? const []);
    return items
        .map((item) => AdminEventItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<AdminEventTypeItem>> fetchEventTypes() async {
    final json = await _getJson(Uri.parse('$_baseUrl/events/types'));
    final items = (json['eventTypes'] as List<dynamic>? ?? const []);
    return items
        .map(
          (item) => AdminEventTypeItem.fromJson(item as Map<String, dynamic>),
        )
        .toList();
  }

  Future<EventsArenaData> loadEventsArenaData() async {
    final events = await fetchEvents();
    final eventTypes = await fetchEventTypes();
    return EventsArenaData(events: events, eventTypes: eventTypes);
  }

  Future<DashboardData> loadDashboardData() async {
    final associationJson = await _getJson(
      Uri.parse('$_baseUrl/associations/current'),
    );
    final association =
        associationJson['association'] as Map<String, dynamic>? ?? const {};
    final members = await fetchMembers();
    final events = await fetchEvents();
    final usersJson = await _getJson(
      Uri.parse('$_baseUrl/users'),
    );
    final users = usersJson['users'] as List<dynamic>? ?? const [];
    final galleryItems =
        (association['galleryItems'] as List<dynamic>? ?? const [])
            .map(
              (item) => DashboardGalleryItem.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();

    final citySet = <String>{};
    final headCity = association['city']?.toString().trim() ?? '';
    if (headCity.isNotEmpty) {
      citySet.add(headCity.toLowerCase());
    }
    for (final item
        in (association['regionalAddresses'] as List<dynamic>? ?? const [])) {
      final city = (item as Map<String, dynamic>)['city']?.toString().trim() ?? '';
      if (city.isNotEmpty) {
        citySet.add(city.toLowerCase());
      }
    }

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final upcomingEvents =
        events
            .where((event) => event.date.compareTo(today) >= 0)
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    final totalVendors =
        users.where((user) {
          final userMap = user as Map<String, dynamic>;
          return userMap['isVendor'] == true;
        }).length;

    return DashboardData(
      associationName: association['name']?.toString() ?? '',
      galleryItems: galleryItems,
      totalMembers: members.length,
      totalCities: citySet.length,
      totalVendors: totalVendors,
      upcomingEvents: upcomingEvents,
    );
  }

  Future<void> updateMemberAccess({
    required String memberId,
    required MemberAccessStatus status,
  }) async {
    final uri = Uri.parse('$_baseUrl/members/$memberId/access');
    final response = await _httpClient.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'accessStatus': status.apiValue}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> updateAppAccess({
    required AdminAppAccessSettings settings,
  }) async {
    final uri = Uri.parse('$_baseUrl/associations/current/app-access');
    final response = await _httpClient.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(settings.toJson()),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> saveEvent({required AdminEventDraft draft}) async {
    final uri = Uri.parse(
      '$_baseUrl/events${draft.id.isEmpty ? '' : '/${draft.id}'}',
    );
    final request =
        http.MultipartRequest(draft.id.isEmpty ? 'POST' : 'PATCH', uri)
          ..fields['name'] = draft.name
          ..fields['type'] = draft.type
          ..fields['audience'] = draft.audience
          ..fields['entryType'] = draft.entryType
          ..fields['entryCharges'] = draft.entryCharges
          ..fields['participationCharges'] = draft.participationCharges
          ..fields['date'] = draft.date
          ..fields['venue'] = draft.venue
          ..fields['startTime'] = draft.startTime
          ..fields['endTime'] = draft.endTime
          ..fields['summary'] = draft.summary;

    if (draft.bannerFile != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'bannerFile',
          draft.bannerFile!.bytes,
          filename: draft.bannerFile!.name,
        ),
      );
    }

    if (draft.videoFile != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'videoFile',
          draft.videoFile!.bytes,
          filename: draft.videoFile!.name,
        ),
      );
    }

    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> deleteEvent({required String eventId}) async {
    final uri = Uri.parse('$_baseUrl/events/$eventId');
    final response = await _httpClient.delete(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> createEventType({required EventTypeDraft draft}) async {
    final response = await _httpClient.post(
      Uri.parse('$_baseUrl/events/types'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': draft.title.trim(),
        'description': draft.meta.trim(),
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> updateEventType({required EventTypeDraft draft}) async {
    final response = await _httpClient.patch(
      Uri.parse('$_baseUrl/events/types/${draft.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': draft.title.trim(),
        'description': draft.meta.trim(),
      }),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
  }

  Future<AssociationProfileData> fetchAssociationProfile() async {
    final json = await _getJson(Uri.parse('$_baseUrl/associations/current'));
    return AssociationProfileData.fromJson(
      json['association'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<void> updateAssociationProfile({
    required AssociationProfileDraft draft,
  }) async {
    final uri = Uri.parse('$_baseUrl/associations/${draft.id}');
    final response = await _httpClient.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(draft.toJson()),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
  }

  Future<AssociationAboutData> fetchAssociationAbout() async {
    final json = await _getJson(
      Uri.parse('$_baseUrl/associations/current/about'),
    );
    return AssociationAboutData.fromJson(
      json['aboutContent'] as Map<String, dynamic>? ?? const {},
    );
  }

  Future<void> updateAssociationAbout({
    required AssociationAboutDraft draft,
  }) async {
    final profile = await fetchAssociationProfile();
    final uri = Uri.parse('$_baseUrl/associations/${profile.id}/about');
    final response = await _httpClient.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(draft.toJson()),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
  }

  Future<AssociationCircularLibraryData> fetchAssociationCircularLibrary() async {
    final profile = await fetchAssociationProfile();
    final json = await _getJson(
      Uri.parse('$_baseUrl/associations/${profile.id}/circulars'),
    );
    final items = (json['circularDocuments'] as List<dynamic>? ?? const []);
    return AssociationCircularLibraryData(
      associationId: profile.id,
      associationName: profile.name,
      items:
          items
              .map(
                (item) => AssociationCircularDocument.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList(),
    );
  }

  Future<void> saveAssociationCircular({
    required String associationId,
    required AssociationCircularDraft draft,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/associations/$associationId/circulars${draft.id.isEmpty ? '' : '/${draft.id}'}',
    );
    final request =
        http.MultipartRequest(draft.id.isEmpty ? 'POST' : 'PATCH', uri)
          ..fields['headline'] = draft.headline
          ..fields['tagline'] = draft.tagline
          ..fields['summary'] = draft.summary;

    final selectedFile = draft.selectedFile;
    if (selectedFile != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          selectedFile.bytes,
          filename: selectedFile.name,
        ),
      );
    }

    final streamedResponse = await _httpClient.send(request);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> deleteAssociationCircular({
    required String associationId,
    required String circularId,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/associations/$associationId/circulars/$circularId',
    );
    final response = await _httpClient.delete(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> saveMemberRecord({required MemberMasterDraft draft}) async {
    if (draft.id.isEmpty) {
      final createResponse = await _httpClient.post(
        Uri.parse('$_baseUrl/members'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(draft.toJson()),
      );
      if (createResponse.statusCode < 200 || createResponse.statusCode >= 300) {
        throw Exception(
          'Status ${createResponse.statusCode}: ${createResponse.body}',
        );
      }
      return;
    }

    final response = await _httpClient.patch(
      Uri.parse('$_baseUrl/members/${draft.id}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(draft.toJson()),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> deleteMemberRecord({required String memberId}) async {
    final uri = Uri.parse('$_baseUrl/members/$memberId');
    final response = await _httpClient.delete(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
  }

  Future<void> updatePostStatus({
    required String postId,
    required PostReviewStatus status,
  }) async {
    final uri = Uri.parse('$_baseUrl/member-posts/$postId/moderation');
    final response = await _httpClient.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'reviewStatus': status.apiValue}),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _httpClient.get(uri);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Status ${response.statusCode}: ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}

class AssociationCircularLibraryData {
  const AssociationCircularLibraryData({
    required this.associationId,
    required this.associationName,
    required this.items,
  });

  const AssociationCircularLibraryData.empty()
    : associationId = '',
      associationName = '',
      items = const [];

  final String associationId;
  final String associationName;
  final List<AssociationCircularDocument> items;
}

class AssociationCircularDocument {
  const AssociationCircularDocument({
    required this.id,
    required this.headline,
    required this.tagline,
    required this.summary,
    required this.originalFileName,
    required this.mimeType,
    required this.fileSize,
    required this.fileExtension,
    required this.documentUrl,
    required this.previewUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String headline;
  final String tagline;
  final String summary;
  final String originalFileName;
  final String mimeType;
  final int fileSize;
  final String fileExtension;
  final String documentUrl;
  final String previewUrl;
  final String createdAt;
  final String updatedAt;

  String get createdDateLabel =>
      createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt;

  factory AssociationCircularDocument.fromJson(Map<String, dynamic> json) {
    return AssociationCircularDocument(
      id: json['id']?.toString() ?? '',
      headline: json['headline']?.toString() ?? '',
      tagline: json['tagline']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      originalFileName: json['originalFileName']?.toString() ?? '',
      mimeType: json['mimeType']?.toString() ?? '',
      fileSize: (json['fileSize'] as num?)?.toInt() ?? 0,
      fileExtension: json['fileExtension']?.toString() ?? 'FILE',
      documentUrl: json['documentUrl']?.toString() ?? '',
      previewUrl: json['previewUrl']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }
}

class AssociationCircularDraft {
  const AssociationCircularDraft({
    required this.id,
    required this.headline,
    required this.tagline,
    required this.summary,
    required this.selectedFile,
    required this.existingFileName,
    required this.existingFileExtension,
    required this.existingPreviewUrl,
  });

  const AssociationCircularDraft.empty()
    : id = '',
      headline = '',
      tagline = '',
      summary = '',
      selectedFile = null,
      existingFileName = '',
      existingFileExtension = 'DOC',
      existingPreviewUrl = '';

  final String id;
  final String headline;
  final String tagline;
  final String summary;
  final AssociationUploadFile? selectedFile;
  final String existingFileName;
  final String existingFileExtension;
  final String existingPreviewUrl;

  bool get canSubmit =>
      headline.trim().isNotEmpty &&
      (selectedFile != null || id.isNotEmpty || existingFileName.isNotEmpty);

  String get displayFileName =>
      selectedFile?.name ?? existingFileName;

  String get displayFileExtension =>
      selectedFile?.extensionLabel ?? existingFileExtension;

  factory AssociationCircularDraft.fromDocument(
    AssociationCircularDocument document,
  ) {
    return AssociationCircularDraft(
      id: document.id,
      headline: document.headline,
      tagline: document.tagline,
      summary: document.summary,
      selectedFile: null,
      existingFileName: document.originalFileName,
      existingFileExtension: document.fileExtension,
      existingPreviewUrl: document.previewUrl,
    );
  }

  AssociationCircularDraft copyWith({
    String? id,
    String? headline,
    String? tagline,
    String? summary,
    AssociationUploadFile? selectedFile,
    bool clearSelectedFile = false,
    String? existingFileName,
    String? existingFileExtension,
    String? existingPreviewUrl,
  }) {
    return AssociationCircularDraft(
      id: id ?? this.id,
      headline: headline ?? this.headline,
      tagline: tagline ?? this.tagline,
      summary: summary ?? this.summary,
      selectedFile:
          clearSelectedFile ? null : (selectedFile ?? this.selectedFile),
      existingFileName: existingFileName ?? this.existingFileName,
      existingFileExtension:
          existingFileExtension ?? this.existingFileExtension,
      existingPreviewUrl: existingPreviewUrl ?? this.existingPreviewUrl,
    );
  }
}

class AssociationUploadFile {
  const AssociationUploadFile({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  final String name;
  final String mimeType;
  final Uint8List bytes;

  String get extensionLabel {
    final lastDot = name.lastIndexOf('.');
    if (lastDot == -1 || lastDot == name.length - 1) {
      return 'FILE';
    }
    return name.substring(lastDot + 1).toUpperCase();
  }

  factory AssociationUploadFile.fromPlatformFile(PlatformFile file) {
    final name = file.name;
    final extension = (file.extension ?? '').toLowerCase();
    return AssociationUploadFile(
      name: name,
      mimeType: _inferMimeType(extension),
      bytes: file.bytes!,
    );
  }

  static String _inferMimeType(String extension) {
    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'tif':
      case 'tiff':
        return 'image/tiff';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      case 'webm':
        return 'video/webm';
      default:
        return 'application/octet-stream';
    }
  }
}

class MemberMasterDraft {
  const MemberMasterDraft({
    required this.id,
    required this.name,
    required this.companyName,
    required this.email,
    required this.phone,
    required this.address,
    required this.gst,
    required this.photoUrl,
    required this.membershipDetails,
    required this.membershipType,
    required this.membershipStartDate,
    required this.membershipEndDate,
    required this.paymentAmount,
    required this.paymentStatus,
  });

  const MemberMasterDraft.empty()
    : id = '',
      name = '',
      companyName = '',
      email = '',
      phone = '',
      address = '',
      gst = '',
      photoUrl = '',
      membershipDetails = '',
      membershipType = 'Primary',
      membershipStartDate = '',
      membershipEndDate = '',
      paymentAmount = '',
      paymentStatus = 'Pending';

  final String id;
  final String name;
  final String companyName;
  final String email;
  final String phone;
  final String address;
  final String gst;
  final String photoUrl;
  final String membershipDetails;
  final String membershipType;
  final String membershipStartDate;
  final String membershipEndDate;
  final String paymentAmount;
  final String paymentStatus;

  bool get canSubmit =>
      name.trim().isNotEmpty &&
      companyName.trim().isNotEmpty &&
      email.trim().isNotEmpty &&
      name.trim().split(RegExp(r'\s+')).length >= 2;

  factory MemberMasterDraft.fromMember(MemberDirectoryItem member) {
    return MemberMasterDraft(
      id: member.id,
      name: member.name,
      companyName: member.companyName,
      email: member.email,
      phone: member.phone,
      address: member.address,
      gst: member.gst,
      photoUrl: member.photoUrl,
      membershipDetails: member.membershipDetails,
      membershipType: member.roleTitle.isEmpty ? 'Primary' : member.roleTitle,
      membershipStartDate: member.membershipStartDate,
      membershipEndDate: member.membershipEndDate,
      paymentAmount: member.paymentAmount,
      paymentStatus: member.paymentStatus.isEmpty ? 'Pending' : member.paymentStatus,
    );
  }

  MemberMasterDraft copyWith({
    String? id,
    String? name,
    String? companyName,
    String? email,
    String? phone,
    String? address,
    String? gst,
    String? photoUrl,
    String? membershipDetails,
    String? membershipType,
    String? membershipStartDate,
    String? membershipEndDate,
    String? paymentAmount,
    String? paymentStatus,
  }) {
    return MemberMasterDraft(
      id: id ?? this.id,
      name: name ?? this.name,
      companyName: companyName ?? this.companyName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      gst: gst ?? this.gst,
      photoUrl: photoUrl ?? this.photoUrl,
      membershipDetails: membershipDetails ?? this.membershipDetails,
      membershipType: membershipType ?? this.membershipType,
      membershipStartDate: membershipStartDate ?? this.membershipStartDate,
      membershipEndDate: membershipEndDate ?? this.membershipEndDate,
      paymentAmount: paymentAmount ?? this.paymentAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
    );
  }

  Map<String, dynamic> toJson() {
    final nameParts = name.trim().split(RegExp(r'\s+'));
    final firstName = nameParts.isNotEmpty ? nameParts.first : name.trim();
    final lastName =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '-';
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email.trim(),
      'phone': phone.trim(),
      'address': address.trim(),
      'gst': gst.trim(),
      'photoUrl': photoUrl.trim(),
      'companyName': companyName.trim(),
      'roleTitle': membershipType.trim(),
      'membershipDetails': membershipDetails.trim(),
      'membershipStartDate':
          membershipStartDate.trim().isEmpty ? null : membershipStartDate.trim(),
      'membershipEndDate':
          membershipEndDate.trim().isEmpty ? null : membershipEndDate.trim(),
      'paymentAmount': paymentAmount.trim(),
      'paymentStatus': _paymentStatusApiValue(paymentStatus),
    };
  }

  static String _paymentStatusApiValue(String value) {
    switch (value) {
      case 'Paid':
        return 'PAID';
      case 'Overdue':
        return 'OVERDUE';
      case 'Waived':
        return 'WAIVED';
      default:
        return 'PENDING';
    }
  }
}

class MemberArenaData {
  const MemberArenaData({required this.posts, required this.members});

  const MemberArenaData.empty() : posts = const [], members = const [];

  final List<MemberPostItem> posts;
  final List<MemberDirectoryItem> members;
}

class AdminArenaData {
  const AdminArenaData({
    required this.appAccess,
    required this.members,
    required this.posts,
    required this.events,
    required this.eventTypes,
  });

  const AdminArenaData.empty()
    : appAccess = const AdminAppAccessSettings.defaults(),
      members = const [],
      posts = const [],
      events = const [],
      eventTypes = const [];

  final AdminAppAccessSettings appAccess;
  final List<AdminMemberAccessItem> members;
  final List<MemberPostItem> posts;
  final List<AdminEventItem> events;
  final List<AdminEventTypeItem> eventTypes;
}

class EventsArenaData {
  const EventsArenaData({
    required this.events,
    required this.eventTypes,
  });

  const EventsArenaData.empty() : events = const [], eventTypes = const [];

  final List<AdminEventItem> events;
  final List<AdminEventTypeItem> eventTypes;
}

class DashboardData {
  const DashboardData({
    required this.associationName,
    required this.galleryItems,
    required this.totalMembers,
    required this.totalCities,
    required this.totalVendors,
    required this.upcomingEvents,
  });

  const DashboardData.empty()
    : associationName = '',
      galleryItems = const [],
      totalMembers = 0,
      totalCities = 0,
      totalVendors = 0,
      upcomingEvents = const [];

  final String associationName;
  final List<DashboardGalleryItem> galleryItems;
  final int totalMembers;
  final int totalCities;
  final int totalVendors;
  final List<AdminEventItem> upcomingEvents;
}

class DashboardGalleryItem {
  const DashboardGalleryItem({
    required this.id,
    required this.imageUrl,
    required this.headline,
    required this.tagline,
    required this.description,
  });

  final String id;
  final String imageUrl;
  final String headline;
  final String tagline;
  final String description;

  factory DashboardGalleryItem.fromJson(Map<String, dynamic> json) {
    return DashboardGalleryItem(
      id: json['id']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      headline: json['headline']?.toString() ?? '',
      tagline: json['tagline']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

class AdminAppAccessSettings {
  const AdminAppAccessSettings({
    required this.approveMembersLogin,
    required this.disableScreenshots,
    required this.approveMembership,
    required this.approveRegistrationRequest,
    required this.disableAdminFunctionsFromApp,
  });

  const AdminAppAccessSettings.defaults()
    : approveMembersLogin = true,
      disableScreenshots = false,
      approveMembership = true,
      approveRegistrationRequest = true,
      disableAdminFunctionsFromApp = false;

  final bool approveMembersLogin;
  final bool disableScreenshots;
  final bool approveMembership;
  final bool approveRegistrationRequest;
  final bool disableAdminFunctionsFromApp;

  AdminAppAccessSettings copyWith({
    bool? approveMembersLogin,
    bool? disableScreenshots,
    bool? approveMembership,
    bool? approveRegistrationRequest,
    bool? disableAdminFunctionsFromApp,
  }) {
    return AdminAppAccessSettings(
      approveMembersLogin:
          approveMembersLogin ?? this.approveMembersLogin,
      disableScreenshots:
          disableScreenshots ?? this.disableScreenshots,
      approveMembership:
          approveMembership ?? this.approveMembership,
      approveRegistrationRequest:
          approveRegistrationRequest ?? this.approveRegistrationRequest,
      disableAdminFunctionsFromApp:
          disableAdminFunctionsFromApp ?? this.disableAdminFunctionsFromApp,
    );
  }

  factory AdminAppAccessSettings.fromJson(Map<String, dynamic> json) {
    return AdminAppAccessSettings(
      approveMembersLogin: json['approveMembersLogin'] == true,
      disableScreenshots: json['disableScreenshots'] == true,
      approveMembership: json['approveMembership'] != false,
      approveRegistrationRequest:
          json['approveRegistrationRequest'] != false,
      disableAdminFunctionsFromApp:
          json['disableAdminFunctionsFromApp'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'approveMembersLogin': approveMembersLogin,
      'disableScreenshots': disableScreenshots,
      'approveMembership': approveMembership,
      'approveRegistrationRequest': approveRegistrationRequest,
      'disableAdminFunctionsFromApp': disableAdminFunctionsFromApp,
    };
  }
}

enum MemberAccessStatus { approved, pending, suspended, cancelled }

extension MemberAccessStatusMeta on MemberAccessStatus {
  String get apiValue => switch (this) {
    MemberAccessStatus.approved => 'APPROVED',
    MemberAccessStatus.pending => 'PENDING',
    MemberAccessStatus.suspended => 'SUSPENDED',
    MemberAccessStatus.cancelled => 'CANCELLED',
  };

  String get label => switch (this) {
    MemberAccessStatus.approved => 'Approved',
    MemberAccessStatus.pending => 'Pending',
    MemberAccessStatus.suspended => 'Suspended',
    MemberAccessStatus.cancelled => 'Cancelled',
  };

  Color get color => switch (this) {
    MemberAccessStatus.approved => const Color(0xFF10B981),
    MemberAccessStatus.pending => const Color(0xFFF59E0B),
    MemberAccessStatus.suspended => const Color(0xFFEF4444),
    MemberAccessStatus.cancelled => const Color(0xFF6B7280),
  };

  static MemberAccessStatus fromApi({
    required String approvalStatus,
    required bool isActive,
  }) {
    if (approvalStatus == 'CANCELLED') {
      return MemberAccessStatus.cancelled;
    }
    if (approvalStatus == 'PENDING') {
      return MemberAccessStatus.pending;
    }
    if (approvalStatus == 'APPROVED' && !isActive) {
      return MemberAccessStatus.suspended;
    }
    if (approvalStatus == 'APPROVED') {
      return MemberAccessStatus.approved;
    }
    return MemberAccessStatus.pending;
  }
}

enum PostReviewStatus { approved, rejected, pending }

extension PostReviewStatusMeta on PostReviewStatus {
  String get apiValue => switch (this) {
    PostReviewStatus.approved => 'APPROVED',
    PostReviewStatus.rejected => 'REJECTED',
    PostReviewStatus.pending => 'PENDING',
  };

  String get label => switch (this) {
    PostReviewStatus.approved => 'Approved',
    PostReviewStatus.rejected => 'Rejected',
    PostReviewStatus.pending => 'Pending',
  };

  Color get color => switch (this) {
    PostReviewStatus.approved => const Color(0xFF10B981),
    PostReviewStatus.rejected => const Color(0xFFEF4444),
    PostReviewStatus.pending => const Color(0xFFF59E0B),
  };

  static PostReviewStatus fromApi(String value) => switch (value) {
    'APPROVED' => PostReviewStatus.approved,
    'REJECTED' => PostReviewStatus.rejected,
    _ => PostReviewStatus.pending,
  };
}

class MemberPostItem {
  const MemberPostItem({
    required this.id,
    required this.title,
    required this.summary,
    required this.body,
    required this.mediaUrl,
    required this.mediaType,
    required this.postType,
    required this.reviewStatus,
    required this.displayStart,
    required this.displayEnd,
    required this.postedOn,
    required this.member,
  });

  final String id;
  final String title;
  final String summary;
  final String body;
  final String mediaUrl;
  final String mediaType;
  final String postType;
  final PostReviewStatus reviewStatus;
  final String displayStart;
  final String displayEnd;
  final String postedOn;
  final PostAuthor member;

  factory MemberPostItem.fromJson(Map<String, dynamic> json) {
    return MemberPostItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      mediaUrl: json['mediaUrl']?.toString() ?? '',
      mediaType: json['mediaType']?.toString() ?? '',
      postType: json['postType']?.toString() ?? 'Post',
      reviewStatus: PostReviewStatusMeta.fromApi(
        json['reviewStatus']?.toString() ?? 'PENDING',
      ),
      displayStart: json['displayStart']?.toString() ?? '',
      displayEnd: json['displayEnd']?.toString() ?? '',
      postedOn: json['postedOn']?.toString() ?? '',
      member: PostAuthor.fromJson(
        json['member'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

class PostAuthor {
  const PostAuthor({
    required this.id,
    required this.name,
    required this.company,
    required this.photoUrl,
  });

  final String id;
  final String name;
  final String company;
  final String photoUrl;

  factory PostAuthor.fromJson(Map<String, dynamic> json) {
    return PostAuthor(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Member',
      company: json['company']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString() ?? '',
    );
  }
}

class AdminMemberAccessItem {
  const AdminMemberAccessItem({
    required this.id,
    required this.name,
    required this.companyName,
    required this.roleTitle,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.accessStatus,
  });

  final String id;
  final String name;
  final String companyName;
  final String roleTitle;
  final String email;
  final String phone;
  final String photoUrl;
  final MemberAccessStatus accessStatus;

  factory AdminMemberAccessItem.fromJson(Map<String, dynamic> json) {
    final firstName = json['firstName']?.toString() ?? '';
    final lastName = json['lastName']?.toString() ?? '';
    final user = json['user'] as Map<String, dynamic>?;
    return AdminMemberAccessItem(
      id: json['id']?.toString() ?? '',
      name: '$firstName $lastName'.trim(),
      companyName: json['companyName']?.toString() ?? '',
      roleTitle: json['roleTitle']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString() ?? '',
      accessStatus: MemberAccessStatusMeta.fromApi(
        approvalStatus: user?['approvalStatus']?.toString() ?? 'PENDING',
        isActive: user?['isActive'] == true,
      ),
    );
  }
}

class MemberDirectoryItem {
  const MemberDirectoryItem({
    required this.id,
    required this.name,
    required this.companyName,
    required this.roleTitle,
    required this.gst,
    required this.committeePost,
    required this.committeeTenureStart,
    required this.committeeTenureEnd,
    required this.memberBio,
    required this.membershipDetails,
    required this.membershipStartDate,
    required this.membershipEndDate,
    required this.paymentAmount,
    required this.paymentStatus,
    required this.address,
    required this.email,
    required this.phone,
    required this.photoUrl,
  });

  final String id;
  final String name;
  final String companyName;
  final String roleTitle;
  final String gst;
  final String committeePost;
  final String committeeTenureStart;
  final String committeeTenureEnd;
  final String memberBio;
  final String membershipDetails;
  final String membershipStartDate;
  final String membershipEndDate;
  final String paymentAmount;
  final String paymentStatus;
  final String address;
  final String email;
  final String phone;
  final String photoUrl;

  factory MemberDirectoryItem.fromJson(Map<String, dynamic> json) {
    final firstName = json['firstName']?.toString() ?? '';
    final lastName = json['lastName']?.toString() ?? '';
    return MemberDirectoryItem(
      id: json['id']?.toString() ?? '',
      name: '$firstName $lastName'.trim(),
      companyName: json['companyName']?.toString() ?? '',
      roleTitle: json['roleTitle']?.toString() ?? '',
      gst: json['gst']?.toString() ?? '',
      committeePost: json['committeePost']?.toString() ?? '',
      committeeTenureStart:
          _asDateOnly(json['committeeTenureStart']?.toString()),
      committeeTenureEnd: _asDateOnly(json['committeeTenureEnd']?.toString()),
      memberBio: json['memberBio']?.toString() ?? '',
      membershipDetails: json['membershipDetails']?.toString() ?? '',
      membershipStartDate:
          _asDateOnly(json['membershipStartDate']?.toString()),
      membershipEndDate:
          _asDateOnly(json['membershipEndDate']?.toString()),
      paymentAmount: json['paymentAmount']?.toString() ?? '',
      paymentStatus: _paymentLabel(json['paymentStatus']?.toString() ?? ''),
      address: json['address']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      photoUrl: json['photoUrl']?.toString() ?? '',
    );
  }

  static String _asDateOnly(String? value) {
    if (value == null || value.isEmpty) {
      return '';
    }

    return value.length >= 10 ? value.substring(0, 10) : value;
  }

  static String _paymentLabel(String value) {
    switch (value) {
      case 'PAID':
        return 'Paid';
      case 'OVERDUE':
        return 'Overdue';
      case 'WAIVED':
        return 'Waived';
      case 'PENDING':
        return 'Pending';
      default:
        return value;
    }
  }
}

class AdminEventItem {
  const AdminEventItem({
    required this.id,
    required this.name,
    required this.type,
    required this.audience,
    required this.entryType,
    required this.entryCharges,
    required this.participationCharges,
    required this.date,
    required this.venue,
    required this.startTime,
    required this.endTime,
    required this.summary,
    required this.imageName,
    required this.videoName,
    required this.bannerUrl,
    required this.promoVideoUrl,
    required this.liveStatus,
  });

  final String id;
  final String name;
  final String type;
  final String audience;
  final String entryType;
  final String entryCharges;
  final String participationCharges;
  final String date;
  final String venue;
  final String startTime;
  final String endTime;
  final String summary;
  final String imageName;
  final String videoName;
  final String bannerUrl;
  final String promoVideoUrl;
  final String liveStatus;

  factory AdminEventItem.fromJson(Map<String, dynamic> json) {
    return AdminEventItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      audience: json['audience']?.toString() ?? '',
      entryType: json['entryType']?.toString() ?? '',
      entryCharges: json['entryCharges']?.toString() ?? '',
      participationCharges:
          json['participationCharges']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      venue: json['venue']?.toString() ?? '',
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      summary: json['summary']?.toString() ?? '',
      imageName: json['imageName']?.toString() ?? '',
      videoName: json['videoName']?.toString() ?? '',
      bannerUrl: json['bannerUrl']?.toString() ?? '',
      promoVideoUrl: json['promoVideoUrl']?.toString() ?? '',
      liveStatus: json['liveStatus']?.toString() ?? 'Scheduled',
    );
  }
}

class AdminEventTypeItem {
  const AdminEventTypeItem({
    required this.id,
    required this.title,
    required this.meta,
  });

  final String id;
  final String title;
  final String meta;

  factory AdminEventTypeItem.fromJson(Map<String, dynamic> json) {
    return AdminEventTypeItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      meta: json['meta']?.toString() ?? '',
    );
  }
}

class AdminEventDraft {
  const AdminEventDraft({
    required this.id,
    required this.name,
    required this.type,
    required this.audience,
    required this.entryType,
    required this.entryCharges,
    required this.participationCharges,
    required this.date,
    required this.venue,
    required this.startTime,
    required this.endTime,
    required this.summary,
    required this.imageName,
    required this.videoName,
    required this.bannerUrl,
    required this.promoVideoUrl,
    required this.bannerFile,
    required this.videoFile,
  });

  const AdminEventDraft.empty()
    : id = '',
      name = '',
      type = '',
      audience = '',
      entryType = '',
      entryCharges = '',
      participationCharges = '',
      date = '',
      venue = '',
      startTime = '',
      endTime = '',
      summary = '',
      imageName = '',
      videoName = '',
      bannerUrl = '',
      promoVideoUrl = '',
      bannerFile = null,
      videoFile = null;

  final String id;
  final String name;
  final String type;
  final String audience;
  final String entryType;
  final String entryCharges;
  final String participationCharges;
  final String date;
  final String venue;
  final String startTime;
  final String endTime;
  final String summary;
  final String imageName;
  final String videoName;
  final String bannerUrl;
  final String promoVideoUrl;
  final AssociationUploadFile? bannerFile;
  final AssociationUploadFile? videoFile;

  AdminEventDraft copyWith({
    String? id,
    String? name,
    String? type,
    String? audience,
    String? entryType,
    String? entryCharges,
    String? participationCharges,
    String? date,
    String? venue,
    String? startTime,
    String? endTime,
    String? summary,
    String? imageName,
    String? videoName,
    String? bannerUrl,
    String? promoVideoUrl,
    AssociationUploadFile? bannerFile,
    AssociationUploadFile? videoFile,
  }) {
    return AdminEventDraft(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      audience: audience ?? this.audience,
      entryType: entryType ?? this.entryType,
      entryCharges: entryCharges ?? this.entryCharges,
      participationCharges:
          participationCharges ?? this.participationCharges,
      date: date ?? this.date,
      venue: venue ?? this.venue,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      summary: summary ?? this.summary,
      imageName: imageName ?? this.imageName,
      videoName: videoName ?? this.videoName,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      promoVideoUrl: promoVideoUrl ?? this.promoVideoUrl,
      bannerFile: bannerFile ?? this.bannerFile,
      videoFile: videoFile ?? this.videoFile,
    );
  }

  factory AdminEventDraft.fromEvent(AdminEventItem event) {
    return AdminEventDraft(
      id: event.id,
      name: event.name,
      type: event.type,
      audience: event.audience,
      entryType: event.entryType,
      entryCharges: event.entryCharges,
      participationCharges: event.participationCharges,
      date: event.date,
      venue: event.venue,
      startTime: event.startTime,
      endTime: event.endTime,
      summary: event.summary,
      imageName: event.imageName,
      videoName: event.videoName,
      bannerUrl: event.bannerUrl,
      promoVideoUrl: event.promoVideoUrl,
      bannerFile: null,
      videoFile: null,
    );
  }
}

class EventTypeDraft {
  const EventTypeDraft({
    required this.id,
    required this.title,
    required this.meta,
  });

  const EventTypeDraft.empty() : id = '', title = '', meta = '';

  final String id;
  final String title;
  final String meta;

  bool get canSubmit => title.trim().isNotEmpty && meta.trim().isNotEmpty;

  factory EventTypeDraft.fromItem(AdminEventTypeItem item) {
    return EventTypeDraft(id: item.id, title: item.title, meta: item.meta);
  }

  EventTypeDraft copyWith({
    String? id,
    String? title,
    String? meta,
  }) {
    return EventTypeDraft(
      id: id ?? this.id,
      title: title ?? this.title,
      meta: meta ?? this.meta,
    );
  }
}

class AssociationProfileData {
  const AssociationProfileData({
    required this.id,
    required this.name,
    required this.slug,
    required this.headOfficeAddress,
    required this.city,
    required this.state,
    required this.pincode,
    required this.registrationNumber,
    required this.gstNumber,
    required this.website,
    required this.helpdeskNumber,
    required this.contactNumbers,
    required this.googleMapsLink,
    required this.regionalAddresses,
  });

  const AssociationProfileData.empty()
    : id = '',
      name = '',
      slug = '',
      headOfficeAddress = '',
      city = '',
      state = '',
      pincode = '',
      registrationNumber = '',
      gstNumber = '',
      website = '',
      helpdeskNumber = '',
      contactNumbers = const [],
      googleMapsLink = '',
      regionalAddresses = const [];

  final String id;
  final String name;
  final String slug;
  final String headOfficeAddress;
  final String city;
  final String state;
  final String pincode;
  final String registrationNumber;
  final String gstNumber;
  final String website;
  final String helpdeskNumber;
  final List<String> contactNumbers;
  final String googleMapsLink;
  final List<AssociationRegionalAddressData> regionalAddresses;

  String get contactNumbersLabel => contactNumbers.join(', ');

  factory AssociationProfileData.fromJson(Map<String, dynamic> json) {
    return AssociationProfileData(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      headOfficeAddress: json['headOfficeAddress']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      registrationNumber: json['registrationNumber']?.toString() ?? '',
      gstNumber: json['gstNumber']?.toString() ?? '',
      website: json['website']?.toString() ?? '',
      helpdeskNumber: json['helpdeskNumber']?.toString() ?? '',
      contactNumbers:
          (json['contactNumbers'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
      googleMapsLink: json['googleMapsLink']?.toString() ?? '',
      regionalAddresses:
          (json['regionalAddresses'] as List<dynamic>? ?? const [])
              .map(
                (item) => AssociationRegionalAddressData.fromJson(
                  item as Map<String, dynamic>,
                ),
              )
              .toList(),
    );
  }
}

class AssociationRegionalAddressData {
  const AssociationRegionalAddressData({
    required this.id,
    required this.label,
    required this.officeAddress,
    required this.city,
    required this.state,
    required this.pincode,
    required this.registrationNumber,
    required this.gstNumber,
    required this.website,
    required this.helpdeskNumber,
    required this.contactNumbers,
    required this.googleMapsLink,
  });

  final String id;
  final String label;
  final String officeAddress;
  final String city;
  final String state;
  final String pincode;
  final String registrationNumber;
  final String gstNumber;
  final String website;
  final String helpdeskNumber;
  final List<String> contactNumbers;
  final String googleMapsLink;

  String get contactNumbersLabel => contactNumbers.join(', ');

  factory AssociationRegionalAddressData.fromJson(Map<String, dynamic> json) {
    return AssociationRegionalAddressData(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      officeAddress: json['officeAddress']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      pincode: json['pincode']?.toString() ?? '',
      registrationNumber: json['registrationNumber']?.toString() ?? '',
      gstNumber: json['gstNumber']?.toString() ?? '',
      website: json['website']?.toString() ?? '',
      helpdeskNumber: json['helpdeskNumber']?.toString() ?? '',
      contactNumbers:
          (json['contactNumbers'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
      googleMapsLink: json['googleMapsLink']?.toString() ?? '',
    );
  }
}

class AssociationProfileDraft {
  const AssociationProfileDraft({
    required this.id,
    required this.name,
    required this.slug,
    required this.headOfficeAddress,
    required this.city,
    required this.state,
    required this.pincode,
    required this.registrationNumber,
    required this.gstNumber,
    required this.website,
    required this.helpdeskNumber,
    required this.contactNumbers,
    required this.googleMapsLink,
    required this.regionalAddresses,
  });

  final String id;
  final String name;
  final String slug;
  final String headOfficeAddress;
  final String city;
  final String state;
  final String pincode;
  final String registrationNumber;
  final String gstNumber;
  final String website;
  final String helpdeskNumber;
  final String contactNumbers;
  final String googleMapsLink;
  final List<AssociationRegionalAddressDraft> regionalAddresses;

  factory AssociationProfileDraft.fromProfile(AssociationProfileData profile) {
    return AssociationProfileDraft(
      id: profile.id,
      name: profile.name,
      slug: profile.slug,
      headOfficeAddress: profile.headOfficeAddress,
      city: profile.city,
      state: profile.state,
      pincode: profile.pincode,
      registrationNumber: profile.registrationNumber,
      gstNumber: profile.gstNumber,
      website: profile.website,
      helpdeskNumber: profile.helpdeskNumber,
      contactNumbers: profile.contactNumbers.join(', '),
      googleMapsLink: profile.googleMapsLink,
      regionalAddresses:
          profile.regionalAddresses
              .map(AssociationRegionalAddressDraft.fromData)
              .toList(),
    );
  }

  AssociationProfileDraft copyWith({
    String? id,
    String? name,
    String? slug,
    String? headOfficeAddress,
    String? city,
    String? state,
    String? pincode,
    String? registrationNumber,
    String? gstNumber,
    String? website,
    String? helpdeskNumber,
    String? contactNumbers,
    String? googleMapsLink,
    List<AssociationRegionalAddressDraft>? regionalAddresses,
  }) {
    return AssociationProfileDraft(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      headOfficeAddress: headOfficeAddress ?? this.headOfficeAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      gstNumber: gstNumber ?? this.gstNumber,
      website: website ?? this.website,
      helpdeskNumber: helpdeskNumber ?? this.helpdeskNumber,
      contactNumbers: contactNumbers ?? this.contactNumbers,
      googleMapsLink: googleMapsLink ?? this.googleMapsLink,
      regionalAddresses: regionalAddresses ?? this.regionalAddresses,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      'slug':
          slug.trim().isNotEmpty
              ? slug.trim()
              : name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-'),
      'headOfficeAddress': headOfficeAddress.trim(),
      'city': city.trim(),
      'state': state.trim(),
      'pincode': pincode.trim(),
      'registrationNumber': registrationNumber.trim(),
      'gstNumber': gstNumber.trim(),
      'website': website.trim(),
      'contactNumbers': contactNumbers
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      'helpdeskNumber': helpdeskNumber.trim(),
      'googleMapsLink': googleMapsLink.trim(),
      'regionalAddresses': regionalAddresses.map((item) => item.toJson()).toList(),
    };
  }
}

class AssociationRegionalAddressDraft {
  const AssociationRegionalAddressDraft({
    required this.id,
    required this.label,
    required this.officeAddress,
    required this.city,
    required this.state,
    required this.pincode,
    required this.registrationNumber,
    required this.gstNumber,
    required this.website,
    required this.helpdeskNumber,
    required this.contactNumbers,
    required this.googleMapsLink,
  });

  factory AssociationRegionalAddressDraft.empty({required String id}) {
    return AssociationRegionalAddressDraft(
      id: id,
      label: '',
      officeAddress: '',
      city: '',
      state: '',
      pincode: '',
      registrationNumber: '',
      gstNumber: '',
      website: '',
      helpdeskNumber: '',
      contactNumbers: '',
      googleMapsLink: '',
    );
  }

  factory AssociationRegionalAddressDraft.fromData(
    AssociationRegionalAddressData data,
  ) {
    return AssociationRegionalAddressDraft(
      id: data.id,
      label: data.label,
      officeAddress: data.officeAddress,
      city: data.city,
      state: data.state,
      pincode: data.pincode,
      registrationNumber: data.registrationNumber,
      gstNumber: data.gstNumber,
      website: data.website,
      helpdeskNumber: data.helpdeskNumber,
      contactNumbers: data.contactNumbers.join(', '),
      googleMapsLink: data.googleMapsLink,
    );
  }

  final String id;
  final String label;
  final String officeAddress;
  final String city;
  final String state;
  final String pincode;
  final String registrationNumber;
  final String gstNumber;
  final String website;
  final String helpdeskNumber;
  final String contactNumbers;
  final String googleMapsLink;

  AssociationRegionalAddressDraft copyWith({
    String? id,
    String? label,
    String? officeAddress,
    String? city,
    String? state,
    String? pincode,
    String? registrationNumber,
    String? gstNumber,
    String? website,
    String? helpdeskNumber,
    String? contactNumbers,
    String? googleMapsLink,
  }) {
    return AssociationRegionalAddressDraft(
      id: id ?? this.id,
      label: label ?? this.label,
      officeAddress: officeAddress ?? this.officeAddress,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      gstNumber: gstNumber ?? this.gstNumber,
      website: website ?? this.website,
      helpdeskNumber: helpdeskNumber ?? this.helpdeskNumber,
      contactNumbers: contactNumbers ?? this.contactNumbers,
      googleMapsLink: googleMapsLink ?? this.googleMapsLink,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label.trim(),
      'officeAddress': officeAddress.trim(),
      'city': city.trim(),
      'state': state.trim(),
      'pincode': pincode.trim(),
      'registrationNumber': registrationNumber.trim(),
      'gstNumber': gstNumber.trim(),
      'website': website.trim(),
      'contactNumbers': contactNumbers
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(),
      'helpdeskNumber': helpdeskNumber.trim(),
      'googleMapsLink': googleMapsLink.trim(),
    };
  }
}

class AssociationAboutData {
  const AssociationAboutData({
    required this.heroTitle,
    required this.heroIntro,
    required this.missionTitle,
    required this.missionText,
    required this.goalsTitle,
    required this.goalsText,
    required this.journeyTitle,
    required this.journeyText,
  });

  const AssociationAboutData.empty()
    : heroTitle = '',
      heroIntro = '',
      missionTitle = '',
      missionText = '',
      goalsTitle = '',
      goalsText = '',
      journeyTitle = '',
      journeyText = '';

  final String heroTitle;
  final String heroIntro;
  final String missionTitle;
  final String missionText;
  final String goalsTitle;
  final String goalsText;
  final String journeyTitle;
  final String journeyText;

  factory AssociationAboutData.fromJson(Map<String, dynamic> json) {
    return AssociationAboutData(
      heroTitle: json['heroTitle']?.toString() ?? '',
      heroIntro: json['heroIntro']?.toString() ?? '',
      missionTitle: json['missionTitle']?.toString() ?? '',
      missionText: json['missionText']?.toString() ?? '',
      goalsTitle: json['goalsTitle']?.toString() ?? '',
      goalsText: json['goalsText']?.toString() ?? '',
      journeyTitle: json['journeyTitle']?.toString() ?? '',
      journeyText: json['journeyText']?.toString() ?? '',
    );
  }
}

class AssociationAboutDraft {
  const AssociationAboutDraft({
    required this.heroTitle,
    required this.heroIntro,
    required this.missionTitle,
    required this.missionText,
    required this.goalsTitle,
    required this.goalsText,
    required this.journeyTitle,
    required this.journeyText,
  });

  final String heroTitle;
  final String heroIntro;
  final String missionTitle;
  final String missionText;
  final String goalsTitle;
  final String goalsText;
  final String journeyTitle;
  final String journeyText;

  factory AssociationAboutDraft.fromAbout(AssociationAboutData about) {
    return AssociationAboutDraft(
      heroTitle: about.heroTitle,
      heroIntro: about.heroIntro,
      missionTitle: about.missionTitle,
      missionText: about.missionText,
      goalsTitle: about.goalsTitle,
      goalsText: about.goalsText,
      journeyTitle: about.journeyTitle,
      journeyText: about.journeyText,
    );
  }

  AssociationAboutDraft copyWith({
    String? heroTitle,
    String? heroIntro,
    String? missionTitle,
    String? missionText,
    String? goalsTitle,
    String? goalsText,
    String? journeyTitle,
    String? journeyText,
  }) {
    return AssociationAboutDraft(
      heroTitle: heroTitle ?? this.heroTitle,
      heroIntro: heroIntro ?? this.heroIntro,
      missionTitle: missionTitle ?? this.missionTitle,
      missionText: missionText ?? this.missionText,
      goalsTitle: goalsTitle ?? this.goalsTitle,
      goalsText: goalsText ?? this.goalsText,
      journeyTitle: journeyTitle ?? this.journeyTitle,
      journeyText: journeyText ?? this.journeyText,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'heroTitle': heroTitle.trim(),
      'heroIntro': heroIntro.trim(),
      'missionTitle': missionTitle.trim(),
      'missionText': missionText.trim(),
      'goalsTitle': goalsTitle.trim(),
      'goalsText': goalsText.trim(),
      'journeyTitle': journeyTitle.trim(),
      'journeyText': journeyText.trim(),
    };
  }
}

enum MemberDirectoryFilter { all, primary, committee, associate, guest }

extension MemberDirectoryFilterMeta on MemberDirectoryFilter {
  String get label => switch (this) {
    MemberDirectoryFilter.all => 'All',
    MemberDirectoryFilter.primary => 'Primary',
    MemberDirectoryFilter.committee => 'Committee',
    MemberDirectoryFilter.associate => 'Associate',
    MemberDirectoryFilter.guest => 'Guest',
  };

  bool matches(MemberDirectoryItem member) {
    final role = member.roleTitle.trim().toLowerCase();
    return switch (this) {
      MemberDirectoryFilter.all => true,
      MemberDirectoryFilter.primary => role == 'primary',
      MemberDirectoryFilter.committee => role == 'committee',
      MemberDirectoryFilter.associate => role == 'associate',
      MemberDirectoryFilter.guest =>
        role == 'temporary visit' || role == 'guest' || role == 'visitor',
    };
  }
}

class MemberArenaDirectoryConfig {
  const MemberArenaDirectoryConfig({
    required this.filter,
    required this.title,
    required this.subtitle,
  });

  final MemberDirectoryFilter filter;
  final String title;
  final String subtitle;
}

extension MemberArenaSectionDirectoryMeta on MemberArenaSection {
  static MemberArenaDirectoryConfig configFor(MemberArenaSection section) {
    return switch (section) {
      MemberArenaSection.allMembers => const MemberArenaDirectoryConfig(
        filter: MemberDirectoryFilter.all,
        title: 'All Members',
        subtitle:
            'Browse every backend-loaded member in one place, sorted alphabetically with the same searchable card layout.',
      ),
      MemberArenaSection.primaryMembers => const MemberArenaDirectoryConfig(
        filter: MemberDirectoryFilter.primary,
        title: 'Primary Members',
        subtitle:
            'Primary member records from the backend, presented in the same searchable directory format.',
      ),
      MemberArenaSection.associateMembers => const MemberArenaDirectoryConfig(
        filter: MemberDirectoryFilter.associate,
        title: 'Associate Members',
        subtitle:
            'Associate member records from the backend, ready for quick search and reference.',
      ),
      MemberArenaSection.temporaryVisitors => const MemberArenaDirectoryConfig(
        filter: MemberDirectoryFilter.guest,
        title: 'Temporary Visitors',
        subtitle:
            'Guest and temporary-visitor records from the backend using the same member card view.',
      ),
      MemberArenaSection.committeeMembers => const MemberArenaDirectoryConfig(
        filter: MemberDirectoryFilter.committee,
        title: 'Committee Members',
        subtitle:
            'Committee member records from the backend, shown in the directory-style member cards.',
      ),
      _ => const MemberArenaDirectoryConfig(
        filter: MemberDirectoryFilter.all,
        title: 'Member Directory',
        subtitle:
            'Browse members alphabetically, filter by membership type, and search by name, company, city, or profile details.',
      ),
    };
  }
}
