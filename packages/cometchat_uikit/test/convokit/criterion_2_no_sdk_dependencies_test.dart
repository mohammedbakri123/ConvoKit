import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 7 / Plan §8 Criterion 2: No CometChat SDK dependencies', () {
    test('pubspec.yaml contains no cometchat_* dependency', () {
      final pubspecFile = File('pubspec.yaml');
      expect(pubspecFile.existsSync(), isTrue);

      final content = pubspecFile.readAsStringSync();
      // Match cometchat_* in dependencies or dev_dependencies
      final lines = content.split('\n');
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.startsWith('cometchat_sdk:') ||
            trimmed.startsWith('cometchat_cards:') ||
            trimmed.startsWith('cometchat_calls_sdk:')) {
          fail('pubspec.yaml must not contain cometchat_* dependency: $trimmed');
        }
      }
    });

    test('lib/ contains zero package:cometchat_ imports or exports', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      final violatingFiles = <String>[];
      final cometchatPkgPattern = RegExp(r"['\x22]package:cometchat_[^'\x22]+['\x22]");

      for (final file in dartFiles) {
        final text = file.readAsStringSync();
        if (cometchatPkgPattern.hasMatch(text)) {
          violatingFiles.add(file.path);
        }
      }

      expect(
        violatingFiles,
        isEmpty,
        reason: 'lib/ files must not import or export any package:cometchat_*\n'
            'Found violations in ${violatingFiles.length} files:\n'
            '${violatingFiles.take(10).join('\n')}',
      );
    });

    test('flutter pub deps shows no cometchat_* dependency', () {
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

      final cometchatDeps = output
          .split('\n')
          .map((l) => l.trim())
          .where((l) =>
              l.contains('cometchat_sdk') ||
              l.contains('cometchat_cards') ||
              l.contains('cometchat_calls_sdk'))
          .toList();

      expect(
        cometchatDeps,
        isEmpty,
        reason: 'flutter pub deps must not contain cometchat_* dependencies:\n'
            '${cometchatDeps.join('\n')}',
      );
    });
  });
}
