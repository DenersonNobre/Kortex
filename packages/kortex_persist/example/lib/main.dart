import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';
import 'package:kortex_persist/kortex_persist.dart';

/// Controller demonstrating [KortexPersistedSignal] with [IKortexStorage].
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
}

class SettingsPage extends IKortexPage<SettingsController> {
  const SettingsPage({super.key});

  @override
  Widget buildPage(BuildContext context, SettingsController controller) {
    return Scaffold(
      appBar: AppBar(title: const Text('kortex_persist example')),
      body: Center(
        child: KortexWatch(
          builder: (context, child) => SwitchListTile(
            title: const Text('Dark Mode'),
            value: controller.darkMode.value,
            onChanged: (_) => controller.toggleDarkMode(),
          ),
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
