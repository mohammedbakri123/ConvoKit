import 'dart:io';

import 'package:convokit/cometchat_chat_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Phase 4: Calling cut verification (zero cometchat_calls_sdk)', () {
    test('lib/ and pubspec.yaml contain ZERO references to cometchat_calls_sdk', () {
      final libDir = Directory('lib');
      expect(libDir.existsSync(), isTrue);

      final dartFiles = libDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in dartFiles) {
        final text = file.readAsStringSync();
        expect(
          text.contains('cometchat_calls_sdk'),
          isFalse,
          reason: '${file.path} must not reference cometchat_calls_sdk',
        );
      }

      final pubspec = File('pubspec.yaml');
      expect(pubspec.existsSync(), isTrue);
      expect(
        pubspec.readAsStringSync().contains('cometchat_calls_sdk'),
        isFalse,
        reason: 'pubspec.yaml must not depend on cometchat_calls_sdk',
      );
    });

    test('lib/call_ui/ directory and cometchat_calls_uikit.dart do not exist', () {
      final callUiDir = Directory('lib/call_ui');
      expect(
        callUiDir.existsSync(),
        isFalse,
        reason: 'lib/call_ui/ must be deleted for v1',
      );

      final callsBarrel = File('lib/cometchat_calls_uikit.dart');
      expect(
        callsBarrel.existsSync(),
        isFalse,
        reason: 'lib/cometchat_calls_uikit.dart must be deleted for v1',
      );
    });

    test('lib/src/ contains no calling implementation files', () {
      final srcDir = Directory('lib/src');
      expect(srcDir.existsSync(), isTrue);

      final callFilePatterns = [
        'active_call_tracker.dart',
        'busy_reject.dart',
        'call_activity_listener.dart',
        'call_audio_handover.dart',
        'call_errors.dart',
        'call_logs_load_more_retry.dart',
        'call_orientation.dart',
        'call_permission_check.dart',
        'call_permission_notice.dart',
        'call_prepare_settings.dart',
        'call_session_settings.dart',
        'call_tone.dart',
        'call_user_lookup.dart',
        'calling_configuration_resolver.dart',
        'calls_join.dart',
        'calls_lifecycle.dart',
        'calls_ringing.dart',
        'calls_sdk_gateway.dart',
        'calls_sdk_session.dart',
        'ghost_join_guard.dart',
        'incoming_call_gate.dart',
        'incoming_ringtone.dart',
        'meeting_session_settings.dart',
        'missed_call_rule.dart',
        'outgoing_call_launcher.dart',
        'outgoing_call_watch.dart',
        'push_ringing.dart',
        'ringing_call_mapping.dart',
        'sound_loop_owner.dart',
      ];

      for (final pattern in callFilePatterns) {
        final f = File('lib/src/$pattern');
        expect(
          f.existsSync(),
          isFalse,
          reason: 'lib/src/$pattern must be deleted for v1',
        );
      }
    });

    test('message templates contain no call or meeting categories/types', () {
      final templates = MessageTemplateUtils.getAllMessageTemplates();
      for (final template in templates) {
        expect(
          template.category.toLowerCase(),
          isNot('call'),
          reason: 'Template ${template.type} has category call',
        );
        expect(
          template.type.toLowerCase(),
          isNot('meeting'),
          reason: 'Template has meeting type',
        );
      }

      expect(
        MessageTemplateUtils.getMessageTemplate(
          messageType: 'audio',
          messageCategory: 'call',
        ),
        isNull,
      );
      expect(
        MessageTemplateUtils.getMessageTemplate(
          messageType: 'video',
          messageCategory: 'call',
        ),
        isNull,
      );
      expect(
        MessageTemplateUtils.getMessageTemplate(
          messageType: 'meeting',
          messageCategory: 'call',
        ),
        isNull,
      );
    });

    testWidgets('ConvoKitMessageHeader renders no call buttons or call icons', (tester) async {
      final user = User(uid: 'u_alice', name: 'Alice', status: 'online');

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: Translations.localizationsDelegates,
          supportedLocales: const [Locale('en')],
          home: Scaffold(
            appBar: ConvoKitMessageHeader(
              user: user,
            ),
          ),
        ),
      );
      await tester.pump();

      // No call or video icons rendered in header
      expect(find.byIcon(Icons.call), findsNothing);
      expect(find.byIcon(Icons.videocam), findsNothing);
      expect(find.byIcon(Icons.call_outlined), findsNothing);
      expect(find.byIcon(Icons.videocam_outlined), findsNothing);
    });
  });
}
