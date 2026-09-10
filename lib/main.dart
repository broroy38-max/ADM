import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/download_provider.dart';
import 'providers/settings_provider.dart';
import 'services/scheduler_service.dart';
import 'ui/screens/main_screen.dart';
import 'ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge to edge transparent system bars
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();

  final downloadProvider = DownloadProvider();
  await downloadProvider.init(settingsProvider.settings);

  SchedulerService.instance.start();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: downloadProvider),
      ],
      child: const ADMApp(),
    ),
  );
}

class ADMApp extends StatelessWidget {
  const ADMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          title: 'ADM',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: AppTheme.lightTheme(),
          darkTheme: AppTheme.darkTheme(isAmoled: settings.isAmoled),
          home: const MainScreen(),
        );
      },
    );
  }
}
