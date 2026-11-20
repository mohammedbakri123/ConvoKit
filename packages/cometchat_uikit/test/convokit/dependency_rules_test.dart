import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Architectural dependency rule tests (Plan §2 & Acceptance Criterion 15)', () {
    test('no core -> flutter_bloc or flutter/widgets imports (plain Dart)', () {
      final coreDir = Directory('lib/src/core');
      expect(coreDir.existsSync(), isTrue);

      final coreFiles = coreDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in coreFiles) {
        final lines = file.readAsLinesSync();
        for (final line in lines) {
          final trimmed = line.trim();
          if (!trimmed.startsWith('import ') && !trimmed.startsWith('export ')) {
            continue;
          }

          expect(
            trimmed.contains('flutter_bloc'),
            isFalse,
            reason: '${file.path} must not import flutter_bloc: "$trimmed"',
          );
          expect(
            trimmed.contains('package:flutter/widgets.dart') ||
                trimmed.contains('package:flutter/material.dart') ||
                trimmed.contains('package:flutter/cupertino.dart'),
            isFalse,
            reason: '${file.path} must not import flutter widgets (plain Dart): "$trimmed"',
          );
        }
      }
    });

    test('no contracts -> implementation imports (ui, coordinator, stores, adapters, blocs)', () {
      final contractsDir = Directory('lib/src/contracts');
      expect(contractsDir.existsSync(), isTrue);

      final contractFiles = contractsDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in contractFiles) {
        final lines = file.readAsLinesSync();
        for (final line in lines) {
          final trimmed = line.trim();
          if (!trimmed.startsWith('import ') && !trimmed.startsWith('export ')) {
            continue;
          }

          // Must not import UI
          expect(
            trimmed.contains('/src/ui/') || trimmed.contains('ui/'),
            isFalse,
            reason: '${file.path} must not import UI: "$trimmed"',
          );

          // Must not import core implementations (coordinator, stores, event_hub, convo_kit)
          expect(
            trimmed.contains('event_hub.dart') ||
                trimmed.contains('convo_kit.dart') ||
                trimmed.contains('coordinator') ||
                trimmed.contains('store'),
            isFalse,
            reason: '${file.path} must not import core implementation details: "$trimmed"',
          );

          // Must not import adapters or blocs
          expect(
            trimmed.contains('adapter') ||
                trimmed.contains('bloc') ||
                trimmed.contains('_impl.dart') ||
                trimmed.contains('datasource'),
            isFalse,
            reason: '${file.path} must not import adapters or datasources: "$trimmed"',
          );
        }
      }
    });

    test('no ui -> adapter or datasource implementation imports', () {
      final uiDir = Directory('lib/src/ui');
      if (!uiDir.existsSync()) return;

      final uiFiles = uiDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in uiFiles) {
        final lines = file.readAsLinesSync();
        for (final line in lines) {
          final trimmed = line.trim();
          if (!trimmed.startsWith('import ') && !trimmed.startsWith('export ')) {
            continue;
          }

          expect(
            trimmed.contains('/src/adapters/') ||
                trimmed.contains('datasource') ||
                trimmed.contains('_impl.dart'),
            isFalse,
            reason: '${file.path} must not import adapters or datasources: "$trimmed"',
          );
        }
      }
    });
  });
}
