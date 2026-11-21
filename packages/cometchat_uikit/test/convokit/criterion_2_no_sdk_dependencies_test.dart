import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 7 / Plan §8 Criterion 2: No CometChat SDK or BLoC dependencies', () {
    const forbiddenPackages = [
      'cometchat_sdk',
      'cometchat_cards',
      'cometchat_calls_sdk',
      'flutter_bloc',
      'bloc_test',
    ];

    test('pubspec.yaml and pubspec.lock contain no cometchat_* or BLoC dependency', () {
      final pubspecFile = File('pubspec.yaml');
      expect(pubspecFile.existsSync(), isTrue);

      final content = pubspecFile.readAsStringSync();
      for (final line in content.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.startsWith('#')) continue;
        for (final pkg in forbiddenPackages) {
          if (trimmed.startsWith('$pkg:')) {
            fail('pubspec.yaml must not contain forbidden dependency: $trimmed');
          }
        }
      }

      final lockFile = File('pubspec.lock');
      if (lockFile.existsSync()) {
        final lockLines = lockFile.readAsLinesSync();
        for (final line in lockLines) {
          final trimmed = line.trim();
          for (final pkg in forbiddenPackages) {
            if (trimmed == '$pkg:') {
              fail('pubspec.lock must not contain forbidden dependency: $pkg');
            }
          }
        }
      }
    });

    test('lib/ contains zero package:cometchat_*, package:flutter_bloc, or package:bloc imports/exports', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final cometchatViolations = <String>[];
      final blocViolations = <String>[];
      final cometchatPkgPattern =
          RegExp(r"['\x22]package:cometchat_[^'\x22]+['\x22]");
      final blocDirectivePattern = RegExp(
        r"^\s*(import|export)\s+['\x22]package:(flutter_bloc|bloc_test|bloc/)",
        multiLine: true,
      );

      for (final file in dartFiles) {
        final text = file.readAsStringSync();
        if (cometchatPkgPattern.hasMatch(text)) {
          cometchatViolations.add(file.path);
        }
        if (blocDirectivePattern.hasMatch(text)) {
          blocViolations.add(file.path);
        }
      }

      expect(
        cometchatViolations,
        isEmpty,
        reason: 'lib/ files must not import or export any package:cometchat_*\n'
            'Found violations in ${cometchatViolations.length} files:\n'
            '${cometchatViolations.take(10).join('\n')}',
      );

      expect(
        blocViolations,
        isEmpty,
        reason: 'lib/ files must not import or export flutter_bloc or bloc\n'
            'Found violations in ${blocViolations.length} files:\n'
            '${blocViolations.take(10).join('\n')}',
      );
    });

    test('test/ contains zero active package:cometchat_*, flutter_bloc, or bloc_test imports/exports', () {
      final testDir = Directory('test');
      expect(testDir.existsSync(), isTrue);

      final dartFiles = testDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final violatingFiles = <String>[];
      final forbiddenDirectivePattern = RegExp(
        r"^\s*(import|export)\s+['\x22]package:(cometchat_|flutter_bloc|bloc_test|bloc/)",
        multiLine: true,
      );

      for (final file in dartFiles) {
        final text = file.readAsStringSync();
        if (forbiddenDirectivePattern.hasMatch(text)) {
          violatingFiles.add(file.path);
        }
      }

      expect(
        violatingFiles,
        isEmpty,
        reason:
            'test/ files must not import or export package:cometchat_*, flutter_bloc, bloc_test, or bloc\n'
            'Found violations in ${violatingFiles.length} files:\n'
            '${violatingFiles.take(10).join('\n')}',
      );
    });

    test('flutter pub deps shows no cometchat_* or BLoC dependency', () {
      final flutterPath = Platform.environment['PATH']
          ?.split(':')
          .map((p) => '$p/flutter')
          .firstWhere((p) => File(p).existsSync(), orElse: () => 'flutter');

      final result = Process.runSync(
        flutterPath ?? 'flutter',
        ['pub', 'deps'],
        workingDirectory: Directory.current.path,
      );

      expect(result.exitCode, equals(0),
          reason: 'flutter pub deps failed: ${result.stderr}');
      final output = result.stdout as String;

      final forbiddenDeps = output
          .split('\n')
          .map((l) => l.trim())
          .where((l) => forbiddenPackages.any(l.contains))
          .toList();

      expect(
        forbiddenDeps,
        isEmpty,
        reason: 'flutter pub deps must not contain cometchat_* or BLoC dependencies:\n'
            '${forbiddenDeps.join('\n')}',
      );
    });
  });
}
