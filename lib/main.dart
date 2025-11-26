import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/config/app_config.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'models/user/app_user.dart';
import 'models/user/user_profile.dart';
import 'models/extension/extension_info.dart';
import 'models/extension/extension_metadata.dart';
import 'models/extension/extension_preferences.dart';
import 'models/extension/cache_entry.dart';
import 'services/profile_service.dart';
import 'services/extension/extension_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for local storage
  await Hive.initFlutter();
  
  // Register Hive adapters
  Hive.registerAdapter(AppUserAdapter());
  Hive.registerAdapter(UserRoleAdapter());
  Hive.registerAdapter(UserProfileAdapter());
  Hive.registerAdapter(ExtensionInfoAdapter());
  Hive.registerAdapter(ExtensionMetadataAdapter());
  Hive.registerAdapter(ExtensionPreferencesAdapter());
  Hive.registerAdapter(CacheEntryAdapter());
  
  // Initialize app configuration
  await AppConfig.initialize();
  
  // Initialize profile service
  await ProfileService.instance.init();
  
  // Initialize extension manager
  final extensionManager = await ExtensionManager.create();
  
  runApp(
    ProviderScope(
      overrides: [
        extensionManagerProvider.overrideWithValue(extensionManager),
      ],
      child: const PlayStreamApp(),
    ),
  );
}

class PlayStreamApp extends StatelessWidget {
  const PlayStreamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PlayStream',
      theme: AppTheme.darkTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
