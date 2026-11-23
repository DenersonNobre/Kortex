import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';
import 'package:kortex_persist/kortex_persist.dart';

/// Example: persisting user preferences without manual read/write boilerplate.
///
/// Without `kortex_persist`, the controller would have to:
/// 1. Read from storage asynchronously and guard against `isDisposed`;
/// 2. Write back to storage on every mutation;
/// 3. Keep `clear()` synchronized with the in-memory signal.
///
/// Swap [KortexMemoryStorage] for your own [IKortexStorage] adapter
/// (e.g. `SharedPreferences`, `sqflite`, or `flutter_secure_storage`) in prod.
class SettingsController extends IKortexController {
  SettingsController(IKortexStorage storage) {
    darkMode = autoDispose(
      kortexPersistedSignal<bool>(
        key: 'dark_mode',
        initialValue: false,
        storage: storage,
        encode: (v) => v.toString(),
        decode: (raw) => raw == 'true',
      ),
    );
  }

  late final KortexPersistedSignal<bool> darkMode;

  void toggleDarkMode() => darkMode.value = !darkMode.value;

  Future<void> reset() => darkMode.clear();
}

class SettingsPage extends IKortexPage<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget buildPage(BuildContext context, SettingsController controller) {
    return Scaffold(
      appBar: AppBar(title: const Text('kortex_persist example')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KortexWatch(
              builder: (context, child) => SwitchListTile(
                title: const Text('Dark Mode (auto-persisted)'),
                value: controller.darkMode.value,
                onChanged: (_) => controller.toggleDarkMode(),
              ),
            ),
            TextButton(
              onPressed: controller.reset,
              child: const Text('Reset to default'),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  final storage = KortexMemoryStorage();
  runApp(
    KortexScope(
      providers: [
        KortexProvider<SettingsController>(
          create: (_) => SettingsController(storage),
        ),
      ],
      child: const MaterialApp(home: SettingsPage()),
    ),
  );
}
