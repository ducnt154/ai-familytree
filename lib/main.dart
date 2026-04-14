import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'data/hive/family_tree_hive.dart';
import 'data/repository/hive_family_tree_repository.dart';
import 'providers/family_tree_controller.dart';
import 'ui/forms/add_members_page.dart';
import 'ui/search/search_page.dart';
import 'ui/tree/family_tree_graph_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await FamilyTreeHive.init();
  final repo = HiveFamilyTreeRepository(FamilyTreeHive.instance);
  runApp(
    ChangeNotifierProvider(
      create: (_) => FamilyTreeController(repo),
      child: const FamilyTreeApp(),
    ),
  );
}

/// Root widget: Material 3 theme + shell navigation.
class FamilyTreeApp extends StatelessWidget {
  const FamilyTreeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final seed = const Color(0xFF1B5E20); // deep green — family / growth

    return MaterialApp(
      title: 'FamilyTree',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme:
            ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true),
        navigationBarTheme: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(fontWeight: FontWeight.w600, fontSize: 12);
            }
            return const TextStyle(fontWeight: FontWeight.w500, fontSize: 12);
          }),
        ),
      ),
      home: const MainNavigationShell(),
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _index = 0;

  static const _titles = ['Home', 'Tree', 'Add', 'Search', 'Settings'];

  Widget _pageFor(int index) {
    switch (index) {
      case 0:
        return const HomePage();
      case 1:
        return const FamilyTreeGraphView();
      case 2:
        return const AddMembersPage();
      case 3:
        return const SearchPage();
      case 4:
        return const SettingsPage();
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _index == 1
          ? null
          : AppBar(
              title: Text(_titles[_index]),
            ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: KeyedSubtree(
          key: ValueKey<int>(_index),
          child: _pageFor(_index),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_tree_outlined),
            selectedIcon: Icon(Icons.account_tree),
            label: 'Tree',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Add',
          ),
          NavigationDestination(
            icon: Icon(Icons.search),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<FamilyTreeController>(
      builder: (context, state, _) {
        final scheme = Theme.of(context).colorScheme;
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.family_restroom, size: 72, color: scheme.primary),
                const SizedBox(height: 16),
                Text(
                  'FamilyTree',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Repository + Provider: CRUD cây & thành viên (Hive offline), lỗi hiển thị dưới đây.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 20),
                if (state.loading)
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(),
                  )
                else ...[
                  Text(
                    'Số cây: ${state.familyTrees.length} · Đang mở: ${state.activeTree?.name ?? "—"}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () async {
                      await state
                          .createFamilyTree('Cây mẫu ${DateTime.now().second}');
                      if (!context.mounted) return;
                      final err =
                          context.read<FamilyTreeController>().lastError;
                      if (err != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(err)),
                        );
                      }
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Tạo cây thử'),
                  ),
                ],
                if (state.lastError != null) ...[
                  const SizedBox(height: 16),
                  Material(
                    color: scheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: scheme.onErrorContainer),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              state.lastError!,
                              style: TextStyle(color: scheme.onErrorContainer),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            color: scheme.onErrorContainer,
                            onPressed: state.clearError,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Cài đặt (placeholder)',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
