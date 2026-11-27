import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_forms/kortex_forms.dart';
import 'package:kortex_widgets/src/widgets/form_error_summary.dart';

/// Explicit tolerance of the scroll asserts (stable CI, POC lesson).
const double _tolerance = 1.0;

String? _requiredName(String value) =>
    value.isEmpty ? 'Name is required' : null;

String? _emailCheck(String value) =>
    value.contains('@') ? null : 'Email is invalid';

/// Forms owned by the running test (house leak gate, `UC-12.00` pattern:
/// every created form must be explicitly closed by its test).
final List<KortexForm> _openForms = <KortexForm>[];
final Set<KortexForm> _closedForms = <KortexForm>{};

KortexForm _track(KortexForm form) {
  _openForms.add(form);
  return form;
}

void _close(KortexForm form) {
  form.dispose();
  _closedForms.add(form);
}

Map<KortexField<dynamic>, FormErrorTarget> _targets(
  KortexField<dynamic> name,
  GlobalKey nameKey,
  KortexField<dynamic> email,
  GlobalKey emailKey,
) => <KortexField<dynamic>, FormErrorTarget>{
  name: FormErrorTarget(label: 'Name', fieldKey: nameKey),
  email: FormErrorTarget(label: 'Email', fieldKey: emailKey),
};

Widget _harness({
  required KortexForm form,
  required Map<KortexField<dynamic>, FormErrorTarget> targets,
}) => MaterialApp(
  home: Scaffold(
    body: Column(
      children: [FormErrorSummary(form: form, targets: targets)],
    ),
  ),
);

Widget _scrollHarness({
  required KortexForm form,
  required Map<KortexField<dynamic>, FormErrorTarget> targets,
  required ScrollController scrollController,
  required GlobalKey nameKey,
  required GlobalKey emailKey,
}) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      controller: scrollController,
      child: Column(
        children: [
          FormErrorSummary(form: form, targets: targets),
          const SizedBox(height: 1200),
          SizedBox(
            key: nameKey,
            height: 80,
            child: const Text('name anchor'),
          ),
          const SizedBox(height: 400),
          SizedBox(
            key: emailKey,
            height: 80,
            child: const Text('email anchor'),
          ),
          const SizedBox(height: 400),
        ],
      ),
    ),
  ),
);

/// House unmount + close epilogue (proves caller ownership per test).
Future<void> _unmountAndClose(WidgetTester tester, KortexForm form) async {
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: SizedBox())),
  );
  _close(form);
}

void main() {
  tearDown(() {
    final forgotten = _openForms
        .where((form) => !_closedForms.contains(form))
        .toList();
    for (final form in forgotten) {
      form.dispose();
    }
    _openForms.clear();
    _closedForms.clear();
    expect(forgotten, isEmpty, reason: 'Forms esquecidos sem dispose');
  });

  group('UC-12.05 FormErrorSummary', () {
    testWidgets('failed submit lists every field error', (tester) async {
      final name = kortexField<String>('', validators: [_requiredName]);
      final email = kortexField<String>('bad', validators: [_emailCheck]);
      final phone = kortexField<String>('11999999999', validators: [
        (v) => v.isEmpty ? 'Phone is required' : null,
      ]);
      final form = _track(kortexForm([name, email, phone]));
      final targets = _targets(name, GlobalKey(), email, GlobalKey());
      targets[phone] = FormErrorTarget(label: 'Phone', fieldKey: GlobalKey());

      // Positivo do Gherkin: submit falha e o summary lista os 2 erros.
      expect(form.validate(), isFalse);
      await tester.pumpWidget(_harness(form: form, targets: targets));
      await tester.pumpAndSettle();

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Email is invalid'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(2));
      // Negativos: o campo valido nao entra na lista; o submit falhou mesmo.
      expect(find.text('Phone'), findsNothing);
      expect(form.isValid, isFalse);

      await _unmountAndClose(tester, form);
    });

    testWidgets('tap on an item scrolls the matching field into view', (
      tester,
    ) async {
      final name = kortexField<String>('', validators: [_requiredName]);
      final email = kortexField<String>('bad', validators: [_emailCheck]);
      final form = _track(kortexForm([name, email]));
      final nameKey = GlobalKey();
      final emailKey = GlobalKey();
      final scrollController = ScrollController();
      final targets = _targets(name, nameKey, email, emailKey);

      expect(form.validate(), isFalse);
      await tester.pumpWidget(
        _scrollHarness(
          form: form,
          targets: targets,
          scrollController: scrollController,
          nameKey: nameKey,
          emailKey: emailKey,
        ),
      );
      await tester.pumpAndSettle();

      // Prova negativa: antes do toque o alvo esta fora da viewport, entao
      // o assert pos-toque nao seria capaz de passar sem rolagem real.
      final viewportHeight = tester
          .getSize(find.byType(SingleChildScrollView))
          .height;
      final before = tester.getRect(find.text('email anchor'));
      expect(before.top, greaterThan(viewportHeight));
      expect(scrollController.offset, 0.0);

      await tester.tap(find.text('Email is invalid'));
      await tester.pumpAndSettle();

      // Positivo do Gherkin: o toque rola ate o campo correspondente.
      final after = tester.getRect(find.text('email anchor'));
      expect(scrollController.offset, greaterThan(_tolerance));
      expect(after.top, greaterThanOrEqualTo(-_tolerance));
      expect(after.bottom, lessThanOrEqualTo(viewportHeight + _tolerance));
      // Negativos: o outro erro continua listado; a rolagem partiu do zero.
      expect(find.text('Name is required'), findsOneWidget);
      expect(before.top, greaterThan(after.top));

      scrollController.dispose();
      await _unmountAndClose(tester, form);
    });

    testWidgets('valid form renders nothing', (tester) async {
      final name = kortexField<String>('Ada', validators: [_requiredName]);
      final email = kortexField<String>(
        'ada@kortex.dev',
        validators: [_emailCheck],
      );
      final form = _track(kortexForm([name, email]));
      final targets = _targets(name, GlobalKey(), email, GlobalKey());

      expect(form.validate(), isTrue);
      await tester.pumpWidget(_harness(form: form, targets: targets));
      await tester.pumpAndSettle();

      // Positivo: nenhum item e nenhum espaco reservado (sem flash).
      expect(find.byType(ListTile), findsNothing);
      expect(find.text('Name is required'), findsNothing);
      expect(
        tester.getSize(find.byKey(const ValueKey<String>('form_error_empty'))),
        Size.zero,
      );
      // Negativos: vazio porque nao ha erro, nao porque nao leu o form.
      expect(name.error.peek(), isNull);
      expect(email.error.peek(), isNull);

      await _unmountAndClose(tester, form);
    });

    testWidgets('unmount keeps the caller-owned form alive', (tester) async {
      final name = kortexField<String>('', validators: [_requiredName]);
      final email = kortexField<String>('bad', validators: [_emailCheck]);
      final form = _track(kortexForm([name, email]));
      final targets = _targets(name, GlobalKey(), email, GlobalKey());

      expect(form.validate(), isFalse);
      await tester.pumpWidget(_harness(form: form, targets: targets));
      await tester.pumpAndSettle();
      expect(find.text('Name is required'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );

      // Positivo: o dono segue vivo (o widget nunca dispoe o form).
      expect(form.validate(), isFalse);
      expect(name.value, '');
      name.value = 'Ada';
      expect(name.validate(), isTrue);
      // Negativos: o outro erro sobrevive ao unmount; o form segue invalido.
      expect(email.error.peek(), 'Email is invalid');
      expect(form.isValid, isFalse);

      _close(form);
    });

    testWidgets('fixed error leaves the list', (tester) async {
      final name = kortexField<String>('', validators: [_requiredName]);
      final email = kortexField<String>('bad', validators: [_emailCheck]);
      final form = _track(kortexForm([name, email]));
      final targets = _targets(name, GlobalKey(), email, GlobalKey());

      expect(form.validate(), isFalse);
      await tester.pumpWidget(_harness(form: form, targets: targets));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsNWidgets(2));

      name.value = 'Ada';
      await tester.pump();

      // Positivo: o restante continua listado com um unico item.
      expect(find.text('Email is invalid'), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);
      // Negativos: o erro corrigido saiu; o form segue invalido no geral.
      expect(find.text('Name is required'), findsNothing);
      expect(form.validate(), isFalse);

      await _unmountAndClose(tester, form);
    });
  });
}
