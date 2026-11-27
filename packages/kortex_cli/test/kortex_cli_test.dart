import 'dart:io';

import 'package:kortex_cli/kortex_cli.dart';
import 'package:test/test.dart';

void main() {
  test('kortex help retorna 0', () {
    final dir = Directory.systemTemp.createTempSync('kortex_cli_help_');
    addTearDown(() => dir.deleteSync(recursive: true));
    expect(runKortexCli(['help'], dir), 0);
  });

  test('kortex create gera estrutura canonica', () {
    final dir = Directory.systemTemp.createTempSync('kortex_cli_app_');
    addTearDown(() => dir.deleteSync(recursive: true));

    expect(runKortexCli(['create', 'meu_app'], dir), 0);
    expect(File('${dir.path}/meu_app/lib/main.dart').existsSync(), isTrue);
    expect(File('${dir.path}/meu_app/lib/app/app.dart').existsSync(), isTrue);
    expect(File('${dir.path}/meu_app/lib/app/routes/app_routes.dart').existsSync(), isTrue);
    expect(File('${dir.path}/meu_app/lib/app/routes/app_pages.dart').existsSync(), isTrue);
  });

  test('kortex module gera fatia vertical StatelessWidget-first', () {
    final dir = Directory.systemTemp.createTempSync('kortex_cli_mod_');
    addTearDown(() => dir.deleteSync(recursive: true));

    expect(runKortexCli(['module', 'work_orders'], dir), 0);
    expect(
      File('${dir.path}/lib/modules/work_orders/ui/work_orders_controller.dart').existsSync(),
      isTrue,
    );
    expect(
      File('${dir.path}/lib/modules/work_orders/ui/work_orders_page.dart').existsSync(),
      isTrue,
    );
    expect(
      File('${dir.path}/lib/modules/work_orders/ui/work_orders_routes.dart').existsSync(),
      isTrue,
    );
  });
}
