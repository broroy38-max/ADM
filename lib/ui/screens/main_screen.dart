import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/add_download_dialog.dart';
import 'browser_screen.dart';
import 'downloads_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import 'tools_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  static const _intentChannel = MethodChannel('com.devbox.adm/intent');
  String? _lastHandledUrl;
  DateTime? _lastHandledTime;

  @override
  void initState() {
    super.initState();
    _setupIntentChannel();
  }

  void _setupIntentChannel() {
    _intentChannel.setMethodCallHandler((call) async {
      if (call.method == 'onSharedUrl') {
        final url = call.arguments as String?;
        if (url != null && url.isNotEmpty) {
          _triggerAddDownload(url);
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final initialUrl = await _intentChannel.invokeMethod<String>('getInitialUrl');
        if (initialUrl != null && initialUrl.isNotEmpty) {
          _triggerAddDownload(initialUrl);
        }
      } catch (e) {
        debugPrint('Failed to get initial intent URL: $e');
      }
    });
  }

  void _triggerAddDownload(String url) {
    final now = DateTime.now();
    if (_lastHandledUrl == url &&
        _lastHandledTime != null &&
        now.difference(_lastHandledTime!).inMilliseconds < 1500) {
      return;
    }
    _lastHandledUrl = url;
    _lastHandledTime = now;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AddDownloadDialog(initialUrl: url),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        onNavigateToBrowser: () => setState(() => _currentIndex = 2),
        onNavigateToTools: () => setState(() => _currentIndex = 3),
      ),
      const DownloadsScreen(),
      const BrowserScreen(),
      const ToolsScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButton: _currentIndex != 2
          ? FloatingActionButton(
              backgroundColor: AppTheme.primaryCyan,
              foregroundColor: Colors.black,
              shape: const CircleBorder(),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const AddDownloadDialog(),
                );
              },
              child: const Icon(Icons.add, size: 28),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.download_done_rounded),
              label: 'Downloads',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.public_rounded),
              label: 'Browser',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.handyman_rounded),
              label: 'Tools',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
