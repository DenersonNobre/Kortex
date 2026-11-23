import 'package:flutter/material.dart';
import 'package:kortex/kortex.dart';
import 'package:kortex_forms/kortex_forms.dart';

/// Example: reactive form validation without `GlobalKey<FormState>`.
///
/// Field state, `touched`/`dirty` flags, and validation live in pure Dart
/// inside [LoginController], making form rules unit-testable without widgets.
class LoginController extends IKortexController {
  LoginController() {
    autoDispose(form);
  }

  final email = kortexField<String>(
    '',
    validators: [
      (v) => v.trim().isEmpty ? 'Email is required' : null,
      (v) => v.contains('@') ? null : 'Enter a valid email',
    ],
  );

  final password = kortexField<String>(
    '',
    validators: [
      (v) => v.length < 6 ? 'Minimum 6 characters' : null,
    ],
  );

  late final KortexForm form = kortexForm([email, password]);

  final _submitted = false.kortex;
  IKortex<bool> get submitted => _submitted.readonly;

  void submit() {
    if (form.validate()) {
      _submitted.value = true;
    }
  }

  void reset() {
    form.reset();
    _submitted.value = false;
  }
}

class LoginPage extends IKortexPage<LoginController> {
  const LoginPage({super.key});

  @override
  Widget buildPage(BuildContext context, LoginController controller) {
    return Scaffold(
      appBar: AppBar(title: const Text('kortex_forms example')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KortexWatch(
              builder: (context, child) => TextField(
                onChanged: (v) => controller.email.value = v,
                decoration: InputDecoration(
                  labelText: 'Email',
                  errorText: controller.email.error.value,
                ),
              ),
            ),
            const SizedBox(height: 12),
            KortexWatch(
              builder: (context, child) => TextField(
                obscureText: true,
                onChanged: (v) => controller.password.value = v,
                decoration: InputDecoration(
                  labelText: 'Password',
                  errorText: controller.password.error.value,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: controller.submit,
                  child: const Text('Submit'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: controller.reset,
                  child: const Text('Reset'),
                ),
              ],
            ),
            KortexWatch(
              builder: (context, child) => controller.submitted.value
                  ? const Text('Submitted!')
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(
    KortexScope(
      providers: [
        KortexProvider<LoginController>(create: (_) => LoginController()),
      ],
      child: const MaterialApp(home: LoginPage()),
    ),
  );
}
