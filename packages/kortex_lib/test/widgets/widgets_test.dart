import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kortex_lib/core/core.dart' show Debouncer;
import 'package:kortex_lib/widgets/widgets.dart';

void main() {
  testWidgets('AsyncButton disables interaction while loading', (tester) async {
    final loading = ValueNotifier(false);
    addTearDown(loading.dispose);
    var pressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AsyncButton(
            loading: loading,
            onPressed: () => pressed = true,
            child: const Text('Submit'),
          ),
        ),
      ),
    );

    loading.value = true;
    await tester.pump();
    await tester.tap(find.text('Submit'));
    expect(pressed, isFalse);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('BusyOverlay blocks content only while its listenable is true', (
    tester,
  ) async {
    final busy = ValueNotifier(false);
    addTearDown(busy.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BusyOverlay(isBusy: busy, child: const Text('Content')),
        ),
      ),
    );
    final barrierCountBefore = find.byType(ModalBarrier).evaluate().length;

    busy.value = true;
    await tester.pump();
    expect(find.byType(ModalBarrier).evaluate().length, barrierCountBefore + 1);
    expect(find.text('Content'), findsOneWidget);
  });

  testWidgets('CardTile emits the inverse checked value', (tester) async {
    bool? changedTo;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CardTile(
            checkable: true,
            checked: false,
            onChanged: (value) => changedTo = value,
            title: const Text('Selectable'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Selectable'));
    expect(changedTo, isTrue);
  });

  testWidgets('SearchPanel delegates text changes to the core debouncer', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    String? submitted;
    final debouncer = Debouncer<String>(
      duration: const Duration(milliseconds: 250),
      callback: (value) => submitted = value,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchPanel(
            controller: controller,
            debouncer: debouncer,
            hintText: 'Search',
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'query');
    await tester.pump(const Duration(milliseconds: 250));

    expect(submitted, 'query');
    debouncer.cancel();
  });

  test('SearchPanel requires onChanged or debouncer', () {
    expect(SearchPanel.new, throwsAssertionError);
  });

  testWidgets('SearchPanel accepts caller-provided label and action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SearchPanel(
            label: 'Filter records',
            onChanged: (_) {},
            action: IconButton(
              tooltip: 'Add record',
              onPressed: () {},
              icon: const Icon(Icons.add),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Filter records'), findsOneWidget);
    expect(find.byTooltip('Add record'), findsOneWidget);
  });

  testWidgets('state views render supplied copy without fixed locale text', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Loading(label: 'Loading data'),
              EmptyState(title: 'Empty', message: 'No content'),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Loading data'), findsOneWidget);
    expect(find.text('Empty'), findsOneWidget);
    expect(find.text('Aguarde!'), findsNothing);
  });

  testWidgets('ConfirmDialog returns the selected boolean result', (
    tester,
  ) async {
    Future<bool?>? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                result = showDialog<bool>(
                  context: context,
                  builder: (_) => const ConfirmDialog(
                    title: 'Confirm',
                    message: 'Proceed?',
                    confirmLabel: 'Continue',
                    cancelLabel: 'Cancel',
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(await result, isTrue);
  });

  testWidgets('snapshot selects loading, error, empty, and data builders', (
    tester,
  ) async {
    Widget buildFor(AsyncSnapshot<String?> snapshot) => MaterialApp(
      home: Scaffold(
        body: SnapshotBuild<String?>(
          snapshot: snapshot,
          builder: (context, value) => Text(value.data!),
          loadingBuilder: (_) => const Text('Loading'),
          errorBuilder: (_, _) => const Text('Error'),
          emptyBuilder: (_) => const Text('Empty'),
        ),
      ),
    );

    await tester.pumpWidget(buildFor(const AsyncSnapshot<String?>.waiting()));
    expect(find.text('Loading'), findsOneWidget);

    await tester.pumpWidget(
      buildFor(
        const AsyncSnapshot<String?>.withError(ConnectionState.done, 'failure'),
      ),
    );
    expect(find.text('Error'), findsOneWidget);

    await tester.pumpWidget(
      buildFor(
        const AsyncSnapshot<String?>.withData(ConnectionState.done, null),
      ),
    );
    expect(find.text('Empty'), findsOneWidget);

    await tester.pumpWidget(
      buildFor(
        const AsyncSnapshot<String?>.withData(ConnectionState.done, 'Ready'),
      ),
    );
    expect(find.text('Ready'), findsOneWidget);
  });

  testWidgets('responsive text and action widgets do not overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              const SectionTitle(
                title: 'A long section heading intended to wrap or truncate',
                action: Icon(Icons.more_horiz),
              ),
              const StatusChip(
                text: 'A long status label which must remain constrained',
                backgroundColor: Colors.green,
              ),
              const TitlePanel.text(
                title: 'A long title which must not overflow',
              ),
              ActionBar(
                actions: [
                  for (var index = 0; index < 4; index++)
                    TextButton(onPressed: () {}, child: Text('Action $index')),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
