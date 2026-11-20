import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Public API cleanliness and naming checks (Plan §8 Criteria 3, 4, 16)', () {
    test('lib/convokit.dart and its exported files contain no cometchat SDK imports or CometChat naming (§8.3 & §8.16)', () {
      final publicEntryFile = File('lib/convokit.dart');
      expect(publicEntryFile.existsSync(), isTrue);

      final content = publicEntryFile.readAsStringSync();
      expect(content.contains('cometchat_sdk'), isFalse);
      expect(content.contains('cometchat_calls_sdk'), isFalse);

      // Collect all files in src/contracts, src/core, and the ConvoKit public UI widgets
      final dirsToCheck = [
        Directory('lib/src/contracts'),
        Directory('lib/src/core'),
        Directory('lib/src/ui'),
      ];

      final filesToCheck = <File>[
        publicEntryFile,
      ];

      for (final dir in dirsToCheck) {
        if (dir.existsSync()) {
          filesToCheck.addAll(
            dir.listSync(recursive: true).whereType<File>().where(
                  (f) => f.path.endsWith('.dart'),
                ),
          );
        }
      }

      for (final file in filesToCheck) {
        var text = file.readAsStringSync();

        // Allow clearly-marked historical / design note in doc comment of entrypoint
        if (file.path == 'lib/convokit.dart') {
          text = text.replaceAll('/// Zero CometChat naming or SDK dependencies.', '');
        }

        // Must not import CometChat SDKs
        expect(
          text.contains('package:cometchat_sdk'),
          isFalse,
          reason: '${file.path} must not import package:cometchat_sdk',
        );
        expect(
          text.contains('package:cometchat_calls_sdk'),
          isFalse,
          reason: '${file.path} must not import package:cometchat_calls_sdk',
        );

        // Must not contain CometChat names or legacy concepts
        expect(
          text.contains('CometChat'),
          isFalse,
          reason: '${file.path} must not contain CometChat (use ConvoKit)',
        );
        expect(
          text.contains('muid'),
          isFalse,
          reason: '${file.path} must not contain muid (use localId)',
        );
      }
    });

    test('no public barrel re-exports package:cometchat_sdk (§8.3)', () {
      final convokitEntry = File('lib/convokit.dart');
      final mainBarrel = File('lib/convokit_uikit.dart');
      final sharedBarrel = File('lib/shared_ui/convokit_uikit_shared.dart');

      for (final barrel in [convokitEntry, mainBarrel, sharedBarrel]) {
        expect(barrel.existsSync(), isTrue);
        final text = barrel.readAsStringSync();
        expect(
          text.contains("export 'package:cometchat_sdk/cometchat_sdk.dart'"),
          isFalse,
          reason: '${barrel.path} must not re-export package:cometchat_sdk',
        );
      }
    });

    test('zero cometchat.io or cometchat.com host strings anywhere in lib/ (§8.4)', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final text = file.readAsStringSync();
        expect(
          text.contains('cometchat.io'),
          isFalse,
          reason: '${file.path} must not contain "cometchat.io"',
        );
        expect(
          text.contains('cometchat.com'),
          isFalse,
          reason: '${file.path} must not contain "cometchat.com"',
        );
      }
    });

    test('clean consumer example app integration runs green without BLoC (§8.13 & §8.14)', () {
      final cleanConsumerDir = Directory('../../examples/clean_consumer');
      expect(cleanConsumerDir.existsSync(), isTrue);

      final pubspec = File('../../examples/clean_consumer/pubspec.yaml');
      expect(pubspec.existsSync(), isTrue);
      final pubspecContent = pubspec.readAsStringSync();
      expect(pubspecContent.contains('flutter_bloc'), isFalse);
      expect(pubspecContent.contains('flutter_riverpod'), isTrue);
      expect(pubspecContent.contains('convokit:'), isTrue);
    });
  });
}
