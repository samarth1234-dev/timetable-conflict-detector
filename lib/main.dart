import 'package:flutter/material.dart';
import 'services/storage_service.dart';
import 'state/timetable_controller.dart';
import 'widgets/weekly_grid_view.dart';
import 'widgets/slot_list_view.dart';
import 'widgets/audit_log_sheet.dart';
import 'widgets/theory_documentation_sheet.dart';
import 'widgets/offline_status_bar.dart';
import 'widgets/clash_warning_banner.dart';
import 'widgets/slot_editor_dialog.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Uncaught Error: ${details.exception}');
  };

  runApp(const TimetableApp());
}

class TimetableApp extends StatefulWidget {
  const TimetableApp({super.key});

  @override
  State<TimetableApp> createState() => _TimetableAppState();
}

class _TimetableAppState extends State<TimetableApp> {
  TimetableController? _controller;
  String? _initError;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _isLoading = true;
      _initError = null;
    });

    try {
      final storage = await StorageService.initialize();
      final controller = TimetableController(storage);
      await controller.initialize();

      if (mounted) {
        setState(() {
          _controller = controller;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('Fatal init error: $e\n$stack');
      if (mounted) {
        setState(() {
          _initError = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Timetable Clash Detector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5),
          brightness: Brightness.light,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
        ),
      ),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  size: 48,
                  color: Color(0xFF1E88E5),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Timetable Clash Detector',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Loading timetable & collision engine...',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ],
          ),
        ),
      );
    }

    if (_initError != null || _controller == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Initialization Issue',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  _initError ?? 'Unknown error during startup',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _bootstrap,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Startup'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return TimetableHomeScreen(controller: _controller!);
  }
}

class TimetableHomeScreen extends StatefulWidget {
  final TimetableController controller;

  const TimetableHomeScreen({super.key, required this.controller});

  @override
  State<TimetableHomeScreen> createState() => _TimetableHomeScreenState();
}

class _TimetableHomeScreenState extends State<TimetableHomeScreen> {
  int _currentTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final clashCount = controller.clashReport.totalConflictPairs;
        final pendingCount = controller.pendingMutationCount;

        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 2,
            backgroundColor: Colors.white,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_month_rounded,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Timetable Clash Detector',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Real-time collision detection',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (clashCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning, color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '$clashCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'Developer & Demo Options',
                onSelected: (value) async {
                  if (value == 'restart') {
                    await controller.simulateAppRestart();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Simulated restart: reloaded directly from persistent disk!')),
                      );
                    }
                  } else if (value == 'inject') {
                    await controller.injectRemoteServerConflict();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Injected remote slot on server!')),
                      );
                    }
                  } else if (value == 'reset') {
                    await controller.resetToSampleData();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reset to sample dataset with conflicts.')),
                      );
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'restart',
                    child: Row(
                      children: [
                        Icon(Icons.restart_alt, size: 18),
                        SizedBox(width: 8),
                        Text('Simulate App Restart (Disk Reload)'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'inject',
                    child: Row(
                      children: [
                        Icon(Icons.cloud_upload_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Inject External Server Conflict'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'reset',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Reset Sample Timetable', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: Column(
            children: [
              // 1. Persistent Offline Status Bar
              OfflineStatusBar(controller: controller),

              // 2. Real-Time Clash Alert Banner
              ClashWarningBanner(controller: controller),

              // 3. Tab Body
              Expanded(
                child: IndexedStack(
                  index: _currentTabIndex,
                  children: [
                    WeeklyGridView(controller: controller),
                    SlotListView(controller: controller),
                    AuditLogView(controller: controller),
                    const TheoryDocumentationView(),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentTabIndex,
            onDestinationSelected: (idx) {
              setState(() => _currentTabIndex = idx);
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.grid_view_outlined),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: 'Weekly Grid',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: clashCount > 0,
                  backgroundColor: Colors.red,
                  label: Text('$clashCount'),
                  child: const Icon(Icons.format_list_bulleted_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: clashCount > 0,
                  backgroundColor: Colors.red,
                  label: Text('$clashCount'),
                  child: const Icon(Icons.format_list_bulleted),
                ),
                label: 'Slot Manager',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: pendingCount > 0,
                  backgroundColor: Colors.amber.shade800,
                  label: Text('$pendingCount'),
                  child: const Icon(Icons.history_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: pendingCount > 0,
                  backgroundColor: Colors.amber.shade800,
                  label: Text('$pendingCount'),
                  child: const Icon(Icons.history),
                ),
                label: 'Offline Log & Sync',
              ),
              const NavigationDestination(
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book),
                label: 'Theory & Logic',
              ),
            ],
          ),
          floatingActionButton: _currentTabIndex <= 1
              ? FloatingActionButton.extended(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => SlotEditorDialog(
                        controller: controller,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Slot'),
                )
              : null,
        );
      },
    );
  }
}
