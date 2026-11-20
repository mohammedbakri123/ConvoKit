import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Public API cleanliness checks', () {
    final libDir = Directory('lib');

    test('lib/convokit.dart and its exported files contain no cometchat SDK imports or CometChat naming', () {
      final publicEntryFile = File('lib/convokit.dart');
      expect(publicEntryFile.existsSync(), isTrue);

      final content = publicEntryFile.readAsStringSync();
      expect(content.contains('cometchat_sdk'), isFalse);
      expect(content.contains('cometchat_calls_sdk'), isFalse);

      // Collect all files in src/contracts, src/core, and the ConvoKit public UI widgets
      final dirsToCheck = [
        Directory('lib/src/contracts'),
        Directory('lib/src/core'),
      ];

      final filesToCheck = <File>[
        publicEntryFile,
        File('lib/src/ui/convo_kit_scope.dart'),
        File('lib/src/ui/views/conversations_view.dart'),
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
        final text = file.readAsStringSync();

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
          text.contains('CometChatUIKit'),
          isFalse,
          reason: '${file.path} must not contain CometChatUIKit',
        );
        expect(
          text.contains('muid'),
          isFalse,
          reason: '${file.path} must not contain muid (use localId)',
        );
      }
    });

    test('no public barrel re-exports package:cometchat_sdk', () {
      final mainBarrel = File('lib/cometchat_chat_uikit.dart');
      expect(mainBarrel.existsSync(), isTrue);
      final text = mainBarrel.readAsStringSync();

      expect(
        text.contains("export 'package:cometchat_sdk/cometchat_sdk.dart'"),
        isFalse,
        reason: 'lib/cometchat_chat_uikit.dart must not re-export package:cometchat_sdk',
      );
    });
  });
}
