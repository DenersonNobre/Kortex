import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'gate de peso: kortex_core sem http/sqflite e kortex_rest sem sqflite',
    () {
      final corePubspec = File('../kortex_core/pubspec.yaml')
          .readAsStringSync();
      expect(corePubspec, isNot(contains('http:')));
      expect(corePubspec, isNot(contains('sqflite:')));

      final restPubspec = File('../kortex_rest/pubspec.yaml')
          .readAsStringSync();
      expect(restPubspec, isNot(contains('sqflite:')));
    },
  );
}
