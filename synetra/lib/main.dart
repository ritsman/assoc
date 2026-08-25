import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:local_auth/local_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

part 'app/app_shell.dart';
part 'app/shell_navigation_controller.dart';
part 'app/member_navigation.dart';
part 'app/association_navigation.dart';
part 'app/vendor_navigation.dart';
part 'app/events_navigation.dart';
part 'app/role_visibility.dart';
part 'features/arenas/arena_panels.dart';
part 'core/data/api_client.dart';
part 'core/data/models.dart';
part 'core/state/app_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();
  final initialSessionState = await AppSessionState.loadFromStorage(
    sharedPreferences,
    secureStorage,
  );
  final initialAppLockState = await AppLockState.loadFromStorage(
    sharedPreferences,
    secureStorage,
    hasActiveSession: initialSessionState.isAuthenticated,
  );
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        secureStorageProvider.overrideWithValue(secureStorage),
        localAuthenticationProvider.overrideWithValue(LocalAuthentication()),
        initialSessionStateProvider.overrideWithValue(initialSessionState),
        initialAppLockStateProvider.overrideWithValue(initialAppLockState),
      ],
      child: const SynetraApp(),
    ),
  );
}
