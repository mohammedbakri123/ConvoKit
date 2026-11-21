import 'dart:io';

import 'package:convokit/convokit.dart'
    show ConversationsView, ConvoKitScope, MessageListView;
import 'package:convokit/convokit_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:showcase_app/app.dart';
import 'package:showcase_app/backend/studio_backend.dart';
import 'package:showcase_app/backend/studio_seed_data.dart';
import 'package:showcase_app/screens/calls/calls_tab.dart';
import 'package:showcase_app/screens/chat/chat_screen.dart';
import 'package:showcase_app/screens/chat/create_poll_sheet.dart';
import 'package:showcase_app/screens/chat/message_info_sheet.dart';
import 'package:showcase_app/screens/chat/pinned_messages_sheet.dart';
import 'package:showcase_app/screens/chat/thread_screen.dart';
import 'package:showcase_app/screens/chats/chats_tab.dart';
import 'package:showcase_app/screens/directory/group_members_screen.dart';
import 'package:showcase_app/screens/directory/people_groups_screen.dart';
import 'package:showcase_app/screens/search/search_screen.dart';
import 'package:showcase_app/screens/settings/settings_tab.dart';
import 'package:showcase_app/screens/updates/core_views_demo_screen.dart';
import 'package:showcase_app/screens/updates/saved_messages_screen.dart';
import 'package:showcase_app/screens/updates/updates_tab.dart';
import 'package:showcase_app/theme/showcase_theme.dart';
import 'package:showcase_app/widgets/collapsing_glass_header.dart';
import 'package:showcase_app/widgets/floating_glass_tab_bar.dart';

import 'helpers/showcase_test_helpers.dart';

Directory _resolveShowcaseRoot() {
  final current = Directory.current;
  if (Directory('${current.path}/lib').existsSync() &&
      File('${current.path}/analysis_options.yaml').existsSync()) {
    return current;
  }
  final nested = Directory('${current.path}/examples/showcase_app');
  if (Directory('${nested.path}/lib').existsSync() &&
      File('${nested.path}/analysis_options.yaml').existsSync()) {
    return nested;
  }
  fail(
    'Could not locate examples/showcase_app root from ${current.path}.',
  );
}

List<File> _listDartFilesUnder(Directory dir) {
  expect(
    dir.existsSync(),
    isTrue,
    reason: 'Expected ${dir.path} to exist.',
  );
  final files = dir
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  expect(
    files,
    isNotEmpty,
    reason: 'Expected Dart source files under ${dir.path}.',
  );
  return files;
}

List<File> _listShowcaseLibDartFiles(Directory showcaseRoot) {
  return _listDartFilesUnder(Directory('${showcaseRoot.path}/lib'));
}

List<File> _listShowcaseScreenDartFiles(Directory showcaseRoot) {
  return _listDartFilesUnder(Directory('${showcaseRoot.path}/lib/screens'));
}

String _normalizePath(String path) => path.replaceAll('\\', '/');

String _relativeToLib(Directory showcaseRoot, File file) {
  final libPrefix = '${_normalizePath(showcaseRoot.path)}/lib/';
  final normalized = _normalizePath(file.path);
  return normalized.startsWith(libPrefix)
      ? normalized.substring(libPrefix.length)
      : normalized;
}

String _stripDartComments(String source) {
  final withoutBlockComments = source.replaceAll(
    RegExp(r'/\*[\s\S]*?\*/'),
    '',
  );
  return withoutBlockComments
      .split('\n')
      .map((line) {
        final slashIndex = line.indexOf('//');
        return slashIndex == -1 ? line : line.substring(0, slashIndex);
      })
      .join('\n');
}

Widget _wrapThemedScreen({
  required StudioBackend backend,
  required ThemeMode themeMode,
  required Widget home,
}) {
  ShowcaseTheme.syncThemeMode(themeMode);
  final themeData = themeMode == ThemeMode.dark
      ? ShowcaseTheme.darkTheme()
      : ShowcaseTheme.lightTheme();
  return ConvoKitScope(
    kit: backend.kit,
    child: MaterialApp(
      theme: themeData,
      darkTheme: ShowcaseTheme.darkTheme(),
      themeMode: themeMode,
      home: home,
    ),
  );
}

void _expectActivePalette(
  WidgetTester tester,
  Finder anchor,
  ThemeMode themeMode,
) {
  final context = tester.element(anchor);
  final palette = ConvoKitThemeHelper.getColorPalette(context);
  if (themeMode == ThemeMode.dark) {
    expect(palette.primary, ShowcaseColors.darkAccent);
    expect(palette.background1, ShowcaseColors.darkSurface);
  } else {
    expect(palette.primary, ShowcaseColors.lightAccent);
    expect(palette.background1, ShowcaseColors.lightSurface);
  }
}

void main() {
  setUp(() {
    installFakeVideoPlayerPlatform();
  });

  for (final themeMode in const <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
    final modeLabel = themeMode == ThemeMode.dark ? 'Dark' : 'Light';

    group('Phase R6 Mount Coverage ($modeLabel mode)', () {
      testWidgets('mounts ShowcaseApp and ShowcaseShell with FloatingGlassTabBar', (
        tester,
      ) async {
        final backend = StudioBackend.create();
        addTearDown(backend.dispose);

        await tester.pumpWidget(
          ShowcaseApp(initialThemeMode: themeMode, backend: backend),
        );
        await pumpShowcaseFrames(tester);

        expect(find.byType(ShowcaseApp), findsOneWidget);
        expect(find.byType(ShowcaseShell), findsOneWidget);
        expect(find.byType(FloatingGlassTabBar), findsOneWidget);
        expect(find.byType(BottomNavigationBar), findsNothing);
        _expectActivePalette(tester, find.byType(ShowcaseShell), themeMode);
        expect(tester.takeException(), isNull);
      });

      testWidgets('mounts ChatsTab with ConvoKitConversations and CollapsingGlassHeader', (
        tester,
      ) async {
        final backend = StudioBackend.create();
        addTearDown(backend.dispose);

        await tester.pumpWidget(
          _wrapThemedScreen(
            backend: backend,
            themeMode: themeMode,
            home: const ChatsTab(),
          ),
        );
        await pumpShowcaseFrames(tester);

        expect(find.byType(ChatsTab), findsOneWidget);
        expect(find.byType(CollapsingGlassHeader), findsOneWidget);
        expect(find.byType(ConvoKitConversations), findsOneWidget);
        _expectActivePalette(tester, find.byType(ChatsTab), themeMode);
        expect(tester.takeException(), isNull);
      });

      testWidgets('mounts ChatScreen for direct and group conversations', (
        tester,
      ) async {
        final backend = StudioBackend.create();
        addTearDown(backend.dispose);

        final priya = backend.seedSnapshot.users.firstWhere(
          (user) => user.id == StudioSeedData.priyaId,
        );
        final designSystemsGroup = backend.seedSnapshot.groups.firstWhere(
          (group) => group.id == StudioSeedData.designSystemsGroupId,
        );

        // 1:1 Direct ChatScreen
        await tester.pumpWidget(
          _wrapThemedScreen(
            backend: backend,
            themeMode: themeMode,
            home: ChatScreen(
              conversationId: StudioSeedData.priyaConvId,
              user: priya,
            ),
          ),
        );
        await pumpShowcaseFrames(tester);

        expect(find.byType(ChatScreen), findsOneWidget);
        expect(find.byType(ConvoKitMessageHeader), findsOneWidget);
        expect(find.byType(ConvoKitMessageList), findsOneWidget);
        expect(find.byType(ConvoKitMessageComposer), findsOneWidget);
        _expectActivePalette(tester, find.byType(ChatScreen), themeMode);
        expect(tester.takeException(), isNull);

        // Group ChatScreen
        await tester.pumpWidget(
          _wrapThemedScreen(
            backend: backend,
            themeMode: themeMode,
            home: ChatScreen(
              conversationId: StudioSeedData.designSystemsConvId,
              group: designSystemsGroup,
            ),
          ),
        );
        await pumpShowcaseFrames(tester);

        expect(find.byType(ChatScreen), findsOneWidget);
        expect(find.byType(ConvoKitMessageHeader), findsOneWidget);
        expect(find.byType(ConvoKitMessageList), findsOneWidget);
        expect(find.byType(ConvoKitMessageComposer), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        'mounts ThreadScreen, PinnedMessagesSheet, MessageInfoSheet, and CreatePollSheet',
        (tester) async {
          final backend = StudioBackend.create();
          addTearDown(backend.dispose);

          final designSystemsGroup = backend.seedSnapshot.groups.firstWhere(
            (group) => group.id == StudioSeedData.designSystemsGroupId,
          );
          final parentMessage = backend
              .seedSnapshot
              .messagesByConversation[StudioSeedData.designSystemsConvId]!
              .first;
          final pinnedMessages = backend.messages.getPinnedMessages(
            StudioSeedData.designSystemsConvId,
          );

          // ThreadScreen
          await tester.pumpWidget(
            _wrapThemedScreen(
              backend: backend,
              themeMode: themeMode,
              home: ThreadScreen(
                conversationId: StudioSeedData.designSystemsConvId,
                parentMessage: parentMessage,
                group: designSystemsGroup,
                initialReplyCount: 2,
              ),
            ),
          );
          await pumpShowcaseFrames(tester);

          expect(find.byType(ThreadScreen), findsOneWidget);
          expect(find.byType(ConvoKitThreadedHeader), findsOneWidget);
          expect(find.byType(ConvoKitMessageList), findsOneWidget);
          expect(find.byType(ConvoKitMessageComposer), findsOneWidget);
          _expectActivePalette(tester, find.byType(ThreadScreen), themeMode);
          expect(tester.takeException(), isNull);

          // PinnedMessagesSheet
          await tester.pumpWidget(
            _wrapThemedScreen(
              backend: backend,
              themeMode: themeMode,
              home: Scaffold(
                body: PinnedMessagesSheet(
                  conversationId: StudioSeedData.designSystemsConvId,
                  group: designSystemsGroup,
                  initialMessages: pinnedMessages,
                ),
              ),
            ),
          );
          await pumpShowcaseFrames(tester);

          expect(find.byType(PinnedMessagesSheet), findsOneWidget);
          expect(find.byType(ConvoKitPinnedMessages), findsOneWidget);
          expect(tester.takeException(), isNull);

          // MessageInfoSheet
          await tester.pumpWidget(
            _wrapThemedScreen(
              backend: backend,
              themeMode: themeMode,
              home: Scaffold(
                body: MessageInfoSheet(message: parentMessage),
              ),
            ),
          );
          await pumpShowcaseFrames(tester);

          expect(find.byType(MessageInfoSheet), findsOneWidget);
          expect(find.byType(CometChatMessageInformation), findsOneWidget);
          expect(tester.takeException(), isNull);

          // CreatePollSheet
          await tester.pumpWidget(
            _wrapThemedScreen(
              backend: backend,
              themeMode: themeMode,
              home: Scaffold(
                body: CreatePollSheet(
                  conversationId: StudioSeedData.designSystemsConvId,
                  group: designSystemsGroup,
                ),
              ),
            ),
          );
          await pumpShowcaseFrames(tester);

          expect(find.byType(CreatePollSheet), findsOneWidget);
          expect(find.byType(CometChatCreatePoll), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'mounts PeopleGroupsScreen, GroupMembersScreen, and SearchScreen',
        (tester) async {
          final backend = StudioBackend.create();
          addTearDown(backend.dispose);

          final designSystemsGroup = backend.seedSnapshot.groups.firstWhere(
            (group) => group.id == StudioSeedData.designSystemsGroupId,
          );

          // PeopleGroupsScreen (People + Groups segments)
          await tester.pumpWidget(
            _wrapThemedScreen(
              backend: backend,
              themeMode: themeMode,
              home: const PeopleGroupsScreen(),
            ),
          );
          await pumpShowcaseFrames(tester);

          expect(find.byType(PeopleGroupsScreen), findsOneWidget);
          expect(find.byType(ConvoKitUsers), findsOneWidget);
          await tester.tap(find.text('Groups'));
          await pumpShowcaseFrames(tester);
          expect(find.byType(ConvoKitGroups), findsOneWidget);
          _expectActivePalette(
            tester,
            find.byType(PeopleGroupsScreen),
            themeMode,
          );
          expect(tester.takeException(), isNull);

          // GroupMembersScreen
          await tester.pumpWidget(
            _wrapThemedScreen(
              backend: backend,
              themeMode: themeMode,
              home: GroupMembersScreen(group: designSystemsGroup),
            ),
          );
          await pumpShowcaseFrames(tester);

          expect(find.byType(GroupMembersScreen), findsOneWidget);
          expect(find.byType(ConvoKitGroupMembers), findsOneWidget);
          expect(tester.takeException(), isNull);

          // SearchScreen
          await tester.pumpWidget(
            _wrapThemedScreen(
              backend: backend,
              themeMode: themeMode,
              home: const SearchScreen(),
            ),
          );
          await pumpShowcaseFrames(tester);

          expect(find.byType(SearchScreen), findsOneWidget);
          expect(find.byType(CometChatSearch), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'mounts UpdatesTab hero & gallery sections, CoreViewsDemoScreen, and SavedMessagesScreen',
        (tester) async {
          final backend = StudioBackend.create();
          addTearDown(backend.dispose);

          // UpdatesTab (hero card + 3 calm gallery sections)
          await tester.pumpWidget(
            _wrapThemedScreen(
              backend: backend,
              themeMode: themeMode,
              home: Scaffold(body: UpdatesTab(backend: backend)),
            ),
          );
          await pumpShowcaseFrames(tester);

          expect(find.byType(UpdatesTab), findsOneWidget);
          expect(find.byType(CollapsingGlassHeader), findsOneWidget);
          expect(find.byKey(const Key('updates_hero_card')), findsOneWidget);
          expect(find.text('EXTENSIONS GALLERY'), findsOneWidget);
          expect(find.text('BUBBLES & MEDIA VIEWERS GALLERY'), findsOneWidget);
          expect(
            find.text('REACTIONS, COMPOSER & INTERACTIVE PRIMITIVES'),
            findsOneWidget,
          );
          expect(find.byType(CometChatPollsBubble), findsOneWidget);
          expect(find.byType(CometChatStickerBubble), findsOneWidget);
          expect(find.byType(CometChatStickerKeyboard), findsOneWidget);
          expect(find.byType(MessageTranslationBubble), findsOneWidget);
          expect(find.byType(CometChatLinkPreviewBubble), findsOneWidget);
          expect(find.byType(ImageModerationFilter), findsOneWidget);
          expect(find.byType(CometChatCollaborativeBubble), findsOneWidget);
          expect(find.byType(ConvoKitCardView), findsOneWidget);
          expect(find.byType(CometChatVoiceNoteBubble), findsOneWidget);
          expect(find.byType(ConvoKitDeletedBubble), findsOneWidget);
          expect(find.byType(CometChatReactions), findsOneWidget);
          expect(find.byType(ConvoKitEmojiKeyboard), findsOneWidget);
          expect(find.byType(CometChatMediaRecorder), findsOneWidget);
          expect(find.byType(CometChatAttachmentOptionSheet), findsOneWidget);
          expect(find.byType(CometchatMessageOptionSheet), findsOneWidget);
          _expectActivePalette(tester, find.byType(UpdatesTab), themeMode);
          expect(tester.takeException(), isNull);

          // CoreViewsDemoScreen
          await tester.pumpWidget(
            _wrapThemedScreen(
              backend: backend,
              themeMode: themeMode,
              home: const CoreViewsDemoScreen(),
            ),
          );
          await pumpShowcaseFrames(tester);

          expect(find.byType(CoreViewsDemoScreen), findsOneWidget);
          expect(find.byType(ConversationsView), findsOneWidget);
          expect(find.byType(MessageListView), findsOneWidget);
          expect(tester.takeException(), isNull);

          // SavedMessagesScreen
          await tester.pumpWidget(
            _wrapThemedScreen(
              backend: backend,
              themeMode: themeMode,
              home: SavedMessagesScreen(backend: backend),
            ),
          );
          await pumpShowcaseFrames(tester);

          expect(find.byType(SavedMessagesScreen), findsOneWidget);
          expect(find.byType(ConvoKitSavedMessages), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets('mounts CallsTab and SettingsTab', (tester) async {
        final backend = StudioBackend.create();
        addTearDown(backend.dispose);

        // CallsTab
        await tester.pumpWidget(
          _wrapThemedScreen(
            backend: backend,
            themeMode: themeMode,
            home: const Scaffold(body: CallsTab()),
          ),
        );
        await pumpShowcaseFrames(tester);

        expect(find.byType(CallsTab), findsOneWidget);
        expect(find.byType(CollapsingGlassHeader), findsOneWidget);
        expect(find.byType(CometChatCard), findsOneWidget);
        expect(find.byType(ConvoKitActionBubble), findsWidgets);
        _expectActivePalette(tester, find.byType(CallsTab), themeMode);
        expect(tester.takeException(), isNull);

        // SettingsTab
        await tester.pumpWidget(
          _wrapThemedScreen(
            backend: backend,
            themeMode: themeMode,
            home: Scaffold(
              body: SettingsTab(
                themeMode: themeMode,
                onThemeModeChanged: (_) {},
                backend: backend,
              ),
            ),
          ),
        );
        await pumpShowcaseFrames(tester);

        expect(find.byType(SettingsTab), findsOneWidget);
        expect(find.byType(CollapsingGlassHeader), findsOneWidget);
        expect(find.byType(ConvoKitListItem), findsWidgets);
        expect(find.byType(ConvoKitAvatar), findsWidgets);
        expect(find.byType(ConvoKitStatusIndicator), findsWidgets);
        expect(find.byType(ConvoKitBadge), findsWidgets);
        expect(find.byType(ConvoKitDate), findsWidgets);
        expect(find.byType(ConvoKitReceipt), findsWidgets);
        expect(find.byType(SwipeTile), findsOneWidget);
        _expectActivePalette(tester, find.byType(SettingsTab), themeMode);
        expect(tester.takeException(), isNull);
      });
    });
  }

  group('Phase R6 Static Library-Compliance & Redesign Guardrails', () {
    test('(1) zero messageBuilder: usages in examples/showcase_app/lib/', () {
      final root = _resolveShowcaseRoot();
      final violations = <String>[];

      for (final file in _listShowcaseLibDartFiles(root)) {
        final code = _stripDartComments(file.readAsStringSync());
        if (RegExp(r'\bmessageBuilder\s*:').hasMatch(code)) {
          violations.add(_relativeToLib(root, file));
        }
      }

      expect(
        violations,
        isEmpty,
        reason: 'Forbidden custom messageBuilder: found in $violations',
      );
    });

    test(
      '(2) zero hand-rolled ListView usages in examples/showcase_app/lib/ (allowing MessageListView and comments)',
      () {
        final root = _resolveShowcaseRoot();
        final violations = <String>[];
        final handRolledListViewPattern = RegExp(r'(?<!Message)\bListView\b');

        for (final file in _listShowcaseLibDartFiles(root)) {
          final code = _stripDartComments(file.readAsStringSync());
          if (handRolledListViewPattern.hasMatch(code)) {
            violations.add(_relativeToLib(root, file));
          }
        }

        expect(
          violations,
          isEmpty,
          reason: 'Forbidden hand-rolled ListView found in $violations',
        );
      },
    );

    test(
      '(3) zero references to whatsapp_app or blue_messenger_app in examples/showcase_app/lib/',
      () {
        final root = _resolveShowcaseRoot();
        final deletedAppTokens = <String>[
          const <String>['whatsapp', 'app'].join('_'),
          const <String>['blue', 'messenger', 'app'].join('_'),
        ];
        final violations = <String>[];

        for (final file in _listShowcaseLibDartFiles(root)) {
          final content = file.readAsStringSync();
          for (final token in deletedAppTokens) {
            if (content.contains(token)) {
              violations.add('${_relativeToLib(root, file)} ($token)');
            }
          }
        }

        expect(
          violations,
          isEmpty,
          reason: 'Forbidden deleted example app reference found in $violations',
        );
      },
    );

    test(
      '(4) GlassSurface is ONLY used in nav/shell files (0 usages in lib/screens/)',
      () {
        final root = _resolveShowcaseRoot();
        const allowedNavShellFiles = <String>{
          'app.dart',
          'widgets/floating_glass_tab_bar.dart',
          'widgets/collapsing_glass_header.dart',
          'widgets/glass_surface.dart',
        };
        final glassPattern = RegExp(r'\bGlassSurface\b');
        final violations = <String>[];

        for (final file in _listShowcaseLibDartFiles(root)) {
          final relPath = _relativeToLib(root, file);
          final code = _stripDartComments(file.readAsStringSync());
          if (glassPattern.hasMatch(code) &&
              !allowedNavShellFiles.contains(relPath)) {
            violations.add(relPath);
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'Liquid Glass (GlassSurface) is strictly nav/shell-only; '
              'found disallowed usage in $violations',
        );

        // Explicit zero-in-screens assertion.
        final screenViolations = <String>[];
        for (final file in _listShowcaseScreenDartFiles(root)) {
          final code = _stripDartComments(file.readAsStringSync());
          if (glassPattern.hasMatch(code)) {
            screenViolations.add(_relativeToLib(root, file));
          }
        }
        expect(
          screenViolations,
          isEmpty,
          reason: 'GlassSurface must never appear in lib/screens/: $screenViolations',
        );
      },
    );

    test(
      '(5) zero fixed DateTime.utc(2026, 5, 14) or DateTime(2026, 5, 15) literals in examples/showcase_app/lib/',
      () {
        final root = _resolveShowcaseRoot();
        final fixedDatePattern = RegExp(
          r'DateTime(?:\.utc)?\s*\(\s*2026\s*,\s*5\s*,\s*1[45]\b',
        );
        final violations = <String>[];

        for (final file in _listShowcaseLibDartFiles(root)) {
          final code = _stripDartComments(file.readAsStringSync());
          if (fixedDatePattern.hasMatch(code)) {
            violations.add(_relativeToLib(root, file));
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'Stale fixed DateTime(2026, 5, 14/15) literal found in $violations; '
              'use relative DateTime.now() instead.',
        );
      },
    );

    test(
      '(6) zero raw Color(0xFF...) literals in examples/showcase_app/lib/screens/',
      () {
        final root = _resolveShowcaseRoot();
        final rawHexColorPattern = RegExp(r'\bColor\s*\(\s*0x[0-9A-Fa-f]{8}\s*\)');
        final violations = <String>[];

        for (final file in _listShowcaseScreenDartFiles(root)) {
          final code = _stripDartComments(file.readAsStringSync());
          if (rawHexColorPattern.hasMatch(code)) {
            violations.add(_relativeToLib(root, file));
          }
        }

        expect(
          violations,
          isEmpty,
          reason:
              'Raw Color(0x...) literal found in lib/screens/: $violations; '
              'consume semantic tokens from ShowcaseTokens / ConvoKitColorPalette / ColorScheme.',
        );
      },
    );

    test(
      'zero references to non-existent ConvoKit widgets in examples/showcase_app/lib/',
      () {
        final root = _resolveShowcaseRoot();
        const nonExistentWidgets = <String>[
          'ConvoKitCalls',
          'ConvoKitCallLogs',
          'ConvoKitCallHistory',
          'ConvoKitSettings',
          'ConvoKitProfile',
        ];
        final violations = <String>[];

        for (final file in _listShowcaseLibDartFiles(root)) {
          final content = file.readAsStringSync();
          for (final widgetName in nonExistentWidgets) {
            if (RegExp('\\b$widgetName\\b').hasMatch(content)) {
              violations.add('${_relativeToLib(root, file)} ($widgetName)');
            }
          }
        }

        expect(
          violations,
          isEmpty,
          reason: 'Non-existent widget reference found in $violations',
        );
      },
    );

    test(
      'zero global lint suppressions in examples/showcase_app/analysis_options.yaml',
      () {
        final root = _resolveShowcaseRoot();
        final analysisOptions = File('${root.path}/analysis_options.yaml');
        expect(analysisOptions.existsSync(), isTrue);

        final content = analysisOptions.readAsStringSync();
        expect(
          content,
          contains('include: package:flutter_lints/flutter.yaml'),
        );
        expect(
          RegExp(r':\s*ignore\b').hasMatch(content),
          isFalse,
          reason: 'Global analyzer error ignore found in analysis_options.yaml',
        );
        expect(
          RegExp(r':\s*false\b').hasMatch(content),
          isFalse,
          reason: 'Disabled lint rule found in analysis_options.yaml',
        );
        expect(
          content.contains('ignore_for_file'),
          isFalse,
          reason: 'ignore_for_file found in analysis_options.yaml',
        );
      },
    );
  });
}
