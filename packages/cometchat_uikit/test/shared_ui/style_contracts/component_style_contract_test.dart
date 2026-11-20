/// Table-driven `copyWith` / `merge` / `lerp` contract for the shared component and AI-view style classes.
///
/// These classes are pure data bags, so the bugs they carry are mechanical: a
/// `copyWith` that forgets a field, a `merge` that drops one (an integrator's
/// explicit value silently ignored), a `lerp` that interpolates the wrong
/// field into a slot. `test/helpers/style_contract.dart` pins each of those —
/// see the doc there for the exact list of checks. The render-verified prop
/// matrices under `test/chat_ui` and `test/shared_ui/*_props_test.dart` cover
/// the other half — that a set property reaches the pixels — and are not
/// repeated here.
///
///   flutter test test/shared_ui/style_contracts/component_style_contract_test.dart
library;

import 'package:convokit/cometchat_chat_uikit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/style_contract.dart';

void main() {
  group('component style contracts', () {
    test(
      'ConvoKitConfirmDialogStyle keeps every field through copyWith/merge/lerp',
      () {
        expectStyleContract<ConvoKitConfirmDialogStyle>(
          label: 'ConvoKitConfirmDialogStyle',
          empty: const ConvoKitConfirmDialogStyle(),
          copyWithNothing: (s) => s.copyWith(),
          merge: (s, o) => s.merge(o),
          lerp: (s, o, t) => s.lerp(o, t),
          fields: [
            Fld<ConvoKitConfirmDialogStyle, Color>(
              'backgroundColor',
              const Color(0xFF1B1614),
              const Color(0xFF251B17),
              (s, v) => s.copyWith(backgroundColor: v),
              (s) => s.backgroundColor,
            ),
            Fld<ConvoKitConfirmDialogStyle, Color>(
              'shadow',
              const Color(0xFF2F201A),
              const Color(0xFF39251D),
              (s, v) => s.copyWith(shadow: v),
              (s) => s.shadow,
            ),
            Fld<ConvoKitConfirmDialogStyle, TextStyle>(
              'confirmButtonTextStyle',
              const TextStyle(fontSize: 8.5),
              const TextStyle(fontSize: 9.5),
              (s, v) => s.copyWith(confirmButtonTextStyle: v),
              (s) => s.confirmButtonTextStyle,
            ),
            Fld<ConvoKitConfirmDialogStyle, TextStyle>(
              'cancelButtonTextStyle',
              const TextStyle(fontSize: 10.5),
              const TextStyle(fontSize: 11.5),
              (s, v) => s.copyWith(cancelButtonTextStyle: v),
              (s) => s.cancelButtonTextStyle,
            ),
            Fld<ConvoKitConfirmDialogStyle, Color>(
              'confirmButtonBackground',
              const Color(0xFF6B3E2C),
              const Color(0xFF75432F),
              (s, v) => s.copyWith(confirmButtonBackground: v),
              (s) => s.confirmButtonBackground,
            ),
            Fld<ConvoKitConfirmDialogStyle, Color>(
              'cancelButtonBackground',
              const Color(0xFF7F4832),
              const Color(0xFF894D35),
              (s, v) => s.copyWith(cancelButtonBackground: v),
              (s) => s.cancelButtonBackground,
            ),
            Fld<ConvoKitConfirmDialogStyle, Color>(
              'cancelButtonTextColor',
              const Color(0xFF935238),
              const Color(0xFF9D573B),
              (s, v) => s.copyWith(cancelButtonTextColor: v),
              (s) => s.cancelButtonTextColor,
            ),
            Fld<ConvoKitConfirmDialogStyle, Color>(
              'confirmButtonTextColor',
              const Color(0xFFA75C3E),
              const Color(0xFFB16141),
              (s, v) => s.copyWith(confirmButtonTextColor: v),
              (s) => s.confirmButtonTextColor,
            ),
            Fld<ConvoKitConfirmDialogStyle, BorderSide>(
              'border',
              const BorderSide(width: 20.5),
              const BorderSide(width: 21.5),
              (s, v) => s.copyWith(border: v),
              (s) => s.border,
            ),
            Fld<ConvoKitConfirmDialogStyle, BorderRadiusGeometry>(
              'borderRadius',
              BorderRadius.circular(22.5),
              BorderRadius.circular(23.5),
              (s, v) => s.copyWith(borderRadius: v),
              (s) => s.borderRadius,
            ),
            Fld<ConvoKitConfirmDialogStyle, TextStyle>(
              'titleTextStyle',
              const TextStyle(fontSize: 24.5),
              const TextStyle(fontSize: 25.5),
              (s, v) => s.copyWith(titleTextStyle: v),
              (s) => s.titleTextStyle,
            ),
            Fld<ConvoKitConfirmDialogStyle, Color>(
              'titleTextColor',
              const Color(0xFFF78456),
              const Color(0xFF018959),
              (s, v) => s.copyWith(titleTextColor: v),
              (s) => s.titleTextColor,
            ),
            Fld<ConvoKitConfirmDialogStyle, Color>(
              'iconColor',
              const Color(0xFF0B8E5C),
              const Color(0xFF15935F),
              (s, v) => s.copyWith(iconColor: v),
              (s) => s.iconColor,
            ),
            Fld<ConvoKitConfirmDialogStyle, Color>(
              'iconBackgroundColor',
              const Color(0xFF1F9862),
              const Color(0xFF299D65),
              (s, v) => s.copyWith(iconBackgroundColor: v),
              (s) => s.iconBackgroundColor,
            ),
            Fld<ConvoKitConfirmDialogStyle, TextStyle>(
              'messageTextStyle',
              const TextStyle(fontSize: 32.5),
              const TextStyle(fontSize: 33.5),
              (s, v) => s.copyWith(messageTextStyle: v),
              (s) => s.messageTextStyle,
            ),
            Fld<ConvoKitConfirmDialogStyle, Color>(
              'messageTextColor',
              const Color(0xFF47AC6E),
              const Color(0xFF51B171),
              (s, v) => s.copyWith(messageTextColor: v),
              (s) => s.messageTextColor,
            ),
          ],
        );
      },
    );

    test(
      'CometChatReactionListStyle keeps every field through copyWith/merge/lerp',
      () {
        expectStyleContract<CometChatReactionListStyle>(
          label: 'CometChatReactionListStyle',
          empty: CometChatReactionListStyle(),
          copyWithNothing: (s) => s.copyWith(),
          merge: (s, o) => s.merge(o),
          lerp: (s, o, t) => s.lerp(o, t),
          fields: [
            Fld<CometChatReactionListStyle, TextStyle>(
              'subtitleTextStyle',
              const TextStyle(fontSize: 36.5),
              const TextStyle(fontSize: 37.5),
              (s, v) => s.copyWith(subtitleTextStyle: v),
              (s) => s.subtitleTextStyle,
            ),
            Fld<CometChatReactionListStyle, Color>(
              'backgroundColor',
              const Color(0xFF6FC07A),
              const Color(0xFF79C57D),
              (s, v) => s.copyWith(backgroundColor: v),
              (s) => s.backgroundColor,
            ),
            Fld<CometChatReactionListStyle, BoxBorder>(
              'border',
              Border.all(width: 40.5),
              Border.all(width: 41.5),
              (s, v) => s.copyWith(border: v),
              (s) => s.border,
            ),
            Fld<CometChatReactionListStyle, BorderRadiusGeometry>(
              'borderRadius',
              BorderRadius.circular(42.5),
              BorderRadius.circular(43.5),
              (s, v) => s.copyWith(borderRadius: v),
              (s) => s.borderRadius,
            ),
            Fld<CometChatReactionListStyle, TextStyle>(
              'errorTextStyle',
              const TextStyle(fontSize: 44.5),
              const TextStyle(fontSize: 45.5),
              (s, v) => s.copyWith(errorTextStyle: v),
              (s) => s.errorTextStyle,
            ),
            Fld<CometChatReactionListStyle, Color>(
              'errorTextColor',
              const Color(0xFFBFE892),
              const Color(0xFFC9ED95),
              (s, v) => s.copyWith(errorTextColor: v),
              (s) => s.errorTextColor,
            ),
            Fld<CometChatReactionListStyle, TextStyle>(
              'errorSubtitleStyle',
              const TextStyle(fontSize: 48.5),
              const TextStyle(fontSize: 49.5),
              (s, v) => s.copyWith(errorSubtitleStyle: v),
              (s) => s.errorSubtitleStyle,
            ),
            Fld<CometChatReactionListStyle, Color>(
              'errorSubtitleColor',
              const Color(0xFFE7FC9E),
              const Color(0xFFF201A1),
              (s, v) => s.copyWith(errorSubtitleColor: v),
              (s) => s.errorSubtitleColor,
            ),
            Fld<CometChatReactionListStyle, TextStyle>(
              'titleTextStyle',
              const TextStyle(fontSize: 52.5),
              const TextStyle(fontSize: 53.5),
              (s, v) => s.copyWith(titleTextStyle: v),
              (s) => s.titleTextStyle,
            ),
            Fld<CometChatReactionListStyle, Color>(
              'titleTextColor',
              const Color(0xFF1010AA),
              const Color(0xFF1A15AD),
              (s, v) => s.copyWith(titleTextColor: v),
              (s) => s.titleTextColor,
            ),
            Fld<CometChatReactionListStyle, TextStyle>(
              'tabTextStyle',
              const TextStyle(fontSize: 56.5),
              const TextStyle(fontSize: 57.5),
              (s, v) => s.copyWith(tabTextStyle: v),
              (s) => s.tabTextStyle,
            ),
            Fld<CometChatReactionListStyle, Color>(
              'tabTextColor',
              const Color(0xFF3824B6),
              const Color(0xFF4229B9),
              (s, v) => s.copyWith(tabTextColor: v),
              (s) => s.tabTextColor,
            ),
            Fld<CometChatReactionListStyle, Color>(
              'activeTabTextColor',
              const Color(0xFF4C2EBC),
              const Color(0xFF5633BF),
              (s, v) => s.copyWith(activeTabTextColor: v),
              (s) => s.activeTabTextColor,
            ),
            Fld<CometChatReactionListStyle, Color>(
              'activeTabIndicatorColor',
              const Color(0xFF6038C2),
              const Color(0xFF6A3DC5),
              (s, v) => s.copyWith(activeTabIndicatorColor: v),
              (s) => s.activeTabIndicatorColor,
            ),
            Fld<CometChatReactionListStyle, Color>(
              'activeTabBackgroundColor',
              const Color(0xFF7442C8),
              const Color(0xFF7E47CB),
              (s, v) => s.copyWith(activeTabBackgroundColor: v),
              (s) => s.activeTabBackgroundColor,
            ),
            Fld<CometChatReactionListStyle, TextStyle>(
              'tailViewTextStyle',
              const TextStyle(fontSize: 66.5),
              const TextStyle(fontSize: 67.5),
              (s, v) => s.copyWith(tailViewTextStyle: v),
              (s) => s.tailViewTextStyle,
            ),
            Fld<CometChatReactionListStyle, Color>(
              'subtitleTextColor',
              const Color(0xFF9C56D4),
              const Color(0xFFA65BD7),
              (s, v) => s.copyWith(subtitleTextColor: v),
              (s) => s.subtitleTextColor,
            ),
            Fld<CometChatReactionListStyle, TextStyle>(
              'emptyTextStyle',
              const TextStyle(fontSize: 70.5),
              const TextStyle(fontSize: 71.5),
              (s, v) => s.copyWith(emptyTextStyle: v),
              (s) => s.emptyTextStyle,
            ),
          ],
        );
      },
    );

    test(
      'CometChatMentionsStyle keeps every field through copyWith/merge/lerp',
      () {
        expectStyleContract<CometChatMentionsStyle>(
          label: 'CometChatMentionsStyle',
          empty: CometChatMentionsStyle(),
          copyWithNothing: (s) => s.copyWith(),
          merge: (s, o) => s.merge(o),
          lerp: (s, o, t) => s.lerp(o, t),
          fields: [
            Fld<CometChatMentionsStyle, TextStyle>(
              'mentionTextStyle',
              const TextStyle(fontSize: 134.5),
              const TextStyle(fontSize: 135.5),
              (s, v) => s.copyWith(mentionTextStyle: v),
              (s) => s.mentionTextStyle,
            ),
            Fld<CometChatMentionsStyle, Color>(
              'mentionTextColor',
              const Color(0xFF45ABA0),
              const Color(0xFF4FB0A3),
              (s, v) => s.copyWith(mentionTextColor: v),
              (s) => s.mentionTextColor,
            ),
            Fld<CometChatMentionsStyle, Color>(
              'mentionTextBackgroundColor',
              const Color(0xFF59B5A6),
              const Color(0xFF63BAA9),
              (s, v) => s.copyWith(mentionTextBackgroundColor: v),
              (s) => s.mentionTextBackgroundColor,
            ),
            Fld<CometChatMentionsStyle, TextStyle>(
              'mentionSelfTextStyle',
              const TextStyle(fontSize: 140.5),
              const TextStyle(fontSize: 141.5),
              (s, v) => s.copyWith(mentionSelfTextStyle: v),
              (s) => s.mentionSelfTextStyle,
            ),
            Fld<CometChatMentionsStyle, Color>(
              'mentionSelfTextColor',
              const Color(0xFF81C9B2),
              const Color(0xFF8BCEB5),
              (s, v) => s.copyWith(mentionSelfTextColor: v),
              (s) => s.mentionSelfTextColor,
            ),
            Fld<CometChatMentionsStyle, Color>(
              'mentionSelfTextBackgroundColor',
              const Color(0xFF95D3B8),
              const Color(0xFF9FD8BB),
              (s, v) => s.copyWith(mentionSelfTextBackgroundColor: v),
              (s) => s.mentionSelfTextBackgroundColor,
            ),
            Fld<CometChatMentionsStyle, double>(
              'borderRadius',
              146.5,
              147.5,
              (s, v) => s.copyWith(borderRadius: v),
              (s) => s.borderRadius,
            ),
          ],
        );
      },
    );

    test(
      'CometChatReactionsStyle keeps every field through copyWith/merge/lerp',
      () {
        expectStyleContract<CometChatReactionsStyle>(
          label: 'CometChatReactionsStyle',
          empty: CometChatReactionsStyle(),
          copyWithNothing: (s) => s.copyWith(),
          merge: (s, o) => s.merge(o),
          lerp: (s, o, t) => s.lerp(o, t),
          fields: [
            Fld<CometChatReactionsStyle, TextStyle>(
              'emojiTextStyle',
              const TextStyle(fontSize: 148.5),
              const TextStyle(fontSize: 149.5),
              (s, v) => s.copyWith(emojiTextStyle: v),
              (s) => s.emojiTextStyle,
            ),
            Fld<CometChatReactionsStyle, TextStyle>(
              'countTextStyle',
              const TextStyle(fontSize: 150.5),
              const TextStyle(fontSize: 151.5),
              (s, v) => s.copyWith(countTextStyle: v),
              (s) => s.countTextStyle,
            ),
            Fld<CometChatReactionsStyle, BoxBorder>(
              'border',
              Border.all(width: 152.5),
              Border.all(width: 153.5),
              (s, v) => s.copyWith(border: v),
              (s) => s.border,
            ),
            Fld<CometChatReactionsStyle, BorderRadiusGeometry>(
              'borderRadius',
              BorderRadius.circular(154.5),
              BorderRadius.circular(155.5),
              (s, v) => s.copyWith(borderRadius: v),
              (s) => s.borderRadius,
            ),
            Fld<CometChatReactionsStyle, Color>(
              'activeReactionBackgroundColor',
              const Color(0xFF0E0FDC),
              const Color(0xFF1814DF),
              (s, v) => s.copyWith(activeReactionBackgroundColor: v),
              (s) => s.activeReactionBackgroundColor,
            ),
            Fld<CometChatReactionsStyle, BoxBorder>(
              'activeReactionBorder',
              Border.all(width: 158.5),
              Border.all(width: 159.5),
              (s, v) => s.copyWith(activeReactionBorder: v),
              (s) => s.activeReactionBorder,
            ),
            Fld<CometChatReactionsStyle, Color>(
              'backgroundColor',
              const Color(0xFF3623E8),
              const Color(0xFF4028EB),
              (s, v) => s.copyWith(backgroundColor: v),
              (s) => s.backgroundColor,
            ),
            Fld<CometChatReactionsStyle, Color>(
              'countTextColor',
              const Color(0xFF4A2DEE),
              const Color(0xFF5432F1),
              (s, v) => s.copyWith(countTextColor: v),
              (s) => s.countTextColor,
            ),
          ],
        );
      },
    );

    test(
      'CometChatMessageInputStyle keeps every field through copyWith/merge/lerp',
      () {
        expectStyleContract<CometChatMessageInputStyle>(
          label: 'CometChatMessageInputStyle',
          empty: const CometChatMessageInputStyle(),
          copyWithNothing: (s) => s.copyWith(),
          merge: (s, o) => s.merge(o),
          lerp: (s, o, t) => s.lerp(o, t),
          fields: [
            Fld<CometChatMessageInputStyle, TextStyle>(
              'textStyle',
              const TextStyle(fontSize: 174.5),
              const TextStyle(fontSize: 175.5),
              (s, v) => s.copyWith(textStyle: v),
              (s) => s.textStyle,
            ),
            Fld<CometChatMessageInputStyle, Color>(
              'textColor',
              const Color(0xFFD67418),
              const Color(0xFFE0791B),
              (s, v) => s.copyWith(textColor: v),
              (s) => s.textColor,
            ),
            Fld<CometChatMessageInputStyle, TextStyle>(
              'placeholderTextStyle',
              const TextStyle(fontSize: 178.5),
              const TextStyle(fontSize: 179.5),
              (s, v) => s.copyWith(placeholderTextStyle: v),
              (s) => s.placeholderTextStyle,
            ),
            Fld<CometChatMessageInputStyle, Color>(
              'placeholderColor',
              const Color(0xFFFE8824),
              const Color(0xFF088D27),
              (s, v) => s.copyWith(placeholderColor: v),
              (s) => s.placeholderColor,
            ),
            Fld<CometChatMessageInputStyle, Color>(
              'dividerTint',
              const Color(0xFF12922A),
              const Color(0xFF1C972D),
              (s, v) => s.copyWith(dividerTint: v),
              (s) => s.dividerTint,
            ),
            Fld<CometChatMessageInputStyle, double>(
              'dividerHeight',
              184.5,
              185.5,
              (s, v) => s.copyWith(dividerHeight: v),
              (s) => s.dividerHeight,
            ),
            Fld<CometChatMessageInputStyle, Color>(
              'backgroundColor',
              const Color(0xFF3AA636),
              const Color(0xFF44AB39),
              (s, v) => s.copyWith(backgroundColor: v),
              (s) => s.backgroundColor,
            ),
            Fld<CometChatMessageInputStyle, BoxBorder>(
              'border',
              Border.all(width: 188.5),
              Border.all(width: 189.5),
              (s, v) => s.copyWith(border: v),
              (s) => s.border,
            ),
            Fld<CometChatMessageInputStyle, BorderRadiusGeometry>(
              'borderRadius',
              BorderRadius.circular(190.5),
              BorderRadius.circular(191.5),
              (s, v) => s.copyWith(borderRadius: v),
              (s) => s.borderRadius,
            ),
            Fld<CometChatMessageInputStyle, Color>(
              'filledColor',
              const Color(0xFF76C448),
              const Color(0xFF80C94B),
              (s, v) => s.copyWith(filledColor: v),
              (s) => s.filledColor,
            ),
          ],
        );
      },
    );

    test(
      'DecoratedContainerStyle keeps every field through copyWith/merge/lerp',
      () {
        expectStyleContract<DecoratedContainerStyle>(
          label: 'DecoratedContainerStyle',
          empty: const DecoratedContainerStyle(),
          copyWithNothing: (s) => s.copyWith(),
          merge: (s, o) => s.merge(o),
          fields: [
            Fld<DecoratedContainerStyle, TextStyle>(
              'titleStyle',
              const TextStyle(fontSize: 194.5),
              const TextStyle(fontSize: 195.5),
              (s, v) => s.copyWith(titleStyle: v),
              (s) => s.titleStyle,
            ),
            Fld<DecoratedContainerStyle, Color>(
              'backgroundColor',
              const Color(0xFF9ED854),
              const Color(0xFFA8DD57),
              (s, v) => s.copyWith(backgroundColor: v),
              (s) => s.backgroundColor,
            ),
            Fld<DecoratedContainerStyle, BoxBorder>(
              'border',
              Border.all(width: 198.5),
              Border.all(width: 199.5),
              (s, v) => s.copyWith(border: v),
              (s) => s.border,
            ),
            Fld<DecoratedContainerStyle, BorderRadiusGeometry>(
              'borderRadius',
              BorderRadius.circular(200.5),
              BorderRadius.circular(201.5),
              (s, v) => s.copyWith(borderRadius: v),
              (s) => s.borderRadius,
            ),
            Fld<DecoratedContainerStyle, Color>(
              'closeIconColor',
              const Color(0xFFDAF666),
              const Color(0xFFE4FB69),
              (s, v) => s.copyWith(closeIconColor: v),
              (s) => s.closeIconColor,
            ),
          ],
        );
      },
    );

    test(
      'ConvoKitAvatarStyle keeps every field through copyWith/merge/lerp',
      () {
        expectStyleContract<ConvoKitAvatarStyle>(
          label: 'ConvoKitAvatarStyle',
          empty: const ConvoKitAvatarStyle(),
          copyWithNothing: (s) => s.copyWith(),
          merge: (s, o) => s.merge(o),
          lerp: (s, o, t) => s.lerp(o, t),
          fields: [
            Fld<ConvoKitAvatarStyle, Color>(
              'backgroundColor',
              const Color(0xFFEF006C),
              const Color(0xFFF9056F),
              (s, v) => s.copyWith(backgroundColor: v),
              (s) => s.backgroundColor,
            ),
            Fld<ConvoKitAvatarStyle, Border>(
              'border',
              Border.all(width: 206.5),
              Border.all(width: 207.5),
              (s, v) => s.copyWith(border: v),
              (s) => s.border,
            ),
            Fld<ConvoKitAvatarStyle, TextStyle>(
              'placeHolderTextStyle',
              const TextStyle(fontSize: 208.5),
              const TextStyle(fontSize: 209.5),
              (s, v) => s.copyWith(placeHolderTextStyle: v),
              (s) => s.placeHolderTextStyle,
            ),
            Fld<ConvoKitAvatarStyle, Color>(
              'placeHolderTextColor',
              const Color(0xFF2B1E7E),
              const Color(0xFF352381),
              (s, v) => s.copyWith(placeHolderTextColor: v),
              (s) => s.placeHolderTextColor,
            ),
            Fld<ConvoKitAvatarStyle, BorderRadiusGeometry>(
              'borderRadius',
              BorderRadius.circular(212.5),
              BorderRadius.circular(213.5),
              (s, v) => s.copyWith(borderRadius: v),
              (s) => s.borderRadius,
            ),
          ],
        );
      },
    );

    test(
      'ConvoKitBadgeStyle keeps every field through copyWith/merge/lerp',
      () {
        expectStyleContract<ConvoKitBadgeStyle>(
          label: 'ConvoKitBadgeStyle',
          empty: const ConvoKitBadgeStyle(),
          copyWithNothing: (s) => s.copyWith(),
          merge: (s, o) => s.merge(o),
          lerp: (s, o, t) => s.lerp(o, t),
          fields: [
            Fld<ConvoKitBadgeStyle, Color>(
              'backgroundColor',
              const Color(0xFF53328A),
              const Color(0xFF5D378D),
              (s, v) => s.copyWith(backgroundColor: v),
              (s) => s.backgroundColor,
            ),
            Fld<ConvoKitBadgeStyle, Border>(
              'border',
              Border.all(width: 216.5),
              Border.all(width: 217.5),
              (s, v) => s.copyWith(border: v),
              (s) => s.border,
            ),
            Fld<ConvoKitBadgeStyle, TextStyle>(
              'textStyle',
              const TextStyle(fontSize: 218.5),
              const TextStyle(fontSize: 219.5),
              (s, v) => s.copyWith(textStyle: v),
              (s) => s.textStyle,
            ),
            Fld<ConvoKitBadgeStyle, Color>(
              'textColor',
              const Color(0xFF8F509C),
              const Color(0xFF99559F),
              (s, v) => s.copyWith(textColor: v),
              (s) => s.textColor,
            ),
            Fld<ConvoKitBadgeStyle, BorderRadiusGeometry>(
              'borderRadius',
              BorderRadius.circular(222.5),
              BorderRadius.circular(223.5),
              (s, v) => s.copyWith(borderRadius: v),
              (s) => s.borderRadius,
            ),
            Fld<ConvoKitBadgeStyle, BoxShape>(
              'boxShape',
              BoxShape.rectangle,
              BoxShape.circle,
              (s, v) => s.copyWith(boxShape: v),
              (s) => s.boxShape,
            ),
          ],
        );
      },
    );

    test(
      'ConvoKitMessageOptionSheetStyle keeps every field through copyWith/merge/lerp',
      () {
        expectStyleContract<ConvoKitMessageOptionSheetStyle>(
          label: 'ConvoKitMessageOptionSheetStyle',
          empty: const ConvoKitMessageOptionSheetStyle(),
          copyWithNothing: (s) => s.copyWith(),
          merge: (s, o) => s.merge(o),
          lerp: (s, o, t) => s.lerp(o, t),
          fields: [
            Fld<ConvoKitMessageOptionSheetStyle, Color>(
              'backgroundColor',
              const Color(0xFFB764A8),
              const Color(0xFFC169AB),
              (s, v) => s.copyWith(backgroundColor: v),
              (s) => s.backgroundColor,
            ),
            Fld<ConvoKitMessageOptionSheetStyle, Border>(
              'border',
              Border.all(width: 226.5),
              Border.all(width: 227.5),
              (s, v) => s.copyWith(border: v),
              (s) => s.border,
            ),
            Fld<ConvoKitMessageOptionSheetStyle, BorderRadiusGeometry>(
              'borderRadius',
              BorderRadius.circular(228.5),
              BorderRadius.circular(229.5),
              (s, v) => s.copyWith(borderRadius: v),
              (s) => s.borderRadius,
            ),
            Fld<ConvoKitMessageOptionSheetStyle, TextStyle>(
              'titleTextStyle',
              const TextStyle(fontSize: 230.5),
              const TextStyle(fontSize: 231.5),
              (s, v) => s.copyWith(titleTextStyle: v),
              (s) => s.titleTextStyle,
            ),
            Fld<ConvoKitMessageOptionSheetStyle, Color>(
              'titleColor',
              const Color(0xFF078CC0),
              const Color(0xFF1191C3),
              (s, v) => s.copyWith(titleColor: v),
              (s) => s.titleColor,
            ),
            Fld<ConvoKitMessageOptionSheetStyle, Color>(
              'iconColor',
              const Color(0xFF1B96C6),
              const Color(0xFF259BC9),
              (s, v) => s.copyWith(iconColor: v),
              (s) => s.iconColor,
            ),
          ],
        );
      },
    );

    test(
      'CometChatAttachmentOptionSheetStyle keeps every field through copyWith/merge/lerp',
      () {
        expectStyleContract<CometChatAttachmentOptionSheetStyle>(
          label: 'CometChatAttachmentOptionSheetStyle',
          empty: const CometChatAttachmentOptionSheetStyle(),
          copyWithNothing: (s) => s.copyWith(),
          merge: (s, o) => s.merge(o),
          lerp: (s, o, t) => s.lerp(o, t),
          fields: [
            Fld<CometChatAttachmentOptionSheetStyle, Color>(
              'backgroundColor',
              const Color(0xFF2FA0CC),
              const Color(0xFF39A5CF),
              (s, v) => s.copyWith(backgroundColor: v),
              (s) => s.backgroundColor,
            ),
            Fld<CometChatAttachmentOptionSheetStyle, Border>(
              'border',
              Border.all(width: 238.5),
              Border.all(width: 239.5),
              (s, v) => s.copyWith(border: v),
              (s) => s.border,
            ),
            Fld<CometChatAttachmentOptionSheetStyle, BorderRadiusGeometry>(
              'borderRadius',
              BorderRadius.circular(240.5),
              BorderRadius.circular(241.5),
              (s, v) => s.copyWith(borderRadius: v),
              (s) => s.borderRadius,
            ),
            Fld<CometChatAttachmentOptionSheetStyle, TextStyle>(
              'titleTextStyle',
              const TextStyle(fontSize: 242.5),
              const TextStyle(fontSize: 243.5),
              (s, v) => s.copyWith(titleTextStyle: v),
              (s) => s.titleTextStyle,
            ),
            Fld<CometChatAttachmentOptionSheetStyle, Color>(
              'titleColor',
              const Color(0xFF7FC8E4),
              const Color(0xFF89CDE7),
              (s, v) => s.copyWith(titleColor: v),
              (s) => s.titleColor,
            ),
            Fld<CometChatAttachmentOptionSheetStyle, Color>(
              'iconColor',
              const Color(0xFF93D2EA),
              const Color(0xFF9DD7ED),
              (s, v) => s.copyWith(iconColor: v),
              (s) => s.iconColor,
            ),
          ],
        );
      },
    );

    test(
      'CometChatMessageReceiptStyle keeps every field through copyWith/merge/lerp',
      () {
        expectStyleContract<CometChatMessageReceiptStyle>(
          label: 'CometChatMessageReceiptStyle',
          empty: CometChatMessageReceiptStyle(),
          copyWithNothing: (s) => s.copyWith(),
          merge: (s, o) => s.merge(o),
          lerp: (s, o, t) => s.lerp(o, t),
          fields: [
            Fld<CometChatMessageReceiptStyle, Color>(
              'waitIconColor',
              const Color(0xFF0C0F0E),
              const Color(0xFF161411),
              (s, v) => s.copyWith(waitIconColor: v),
              (s) => s.waitIconColor,
            ),
            Fld<CometChatMessageReceiptStyle, Color>(
              'sentIconColor',
              const Color(0xFF201914),
              const Color(0xFF2A1E17),
              (s, v) => s.copyWith(sentIconColor: v),
              (s) => s.sentIconColor,
            ),
            Fld<CometChatMessageReceiptStyle, Color>(
              'deliveredIconColor',
              const Color(0xFF34231A),
              const Color(0xFF3E281D),
              (s, v) => s.copyWith(deliveredIconColor: v),
              (s) => s.deliveredIconColor,
            ),
            Fld<CometChatMessageReceiptStyle, Color>(
              'readIconColor',
              const Color(0xFF482D20),
              const Color(0xFF523223),
              (s, v) => s.copyWith(readIconColor: v),
              (s) => s.readIconColor,
            ),
            Fld<CometChatMessageReceiptStyle, Color>(
              'errorIconColor',
              const Color(0xFF5C3726),
              const Color(0xFF663C29),
              (s, v) => s.copyWith(errorIconColor: v),
              (s) => s.errorIconColor,
            ),
          ],
        );
      },
    );

    test(
      'ConvoKitDateStyle keeps every field through copyWith/merge/lerp',
      () {
        expectStyleContract<ConvoKitDateStyle>(
          label: 'ConvoKitDateStyle',
          empty: const ConvoKitDateStyle(),
          copyWithNothing: (s) => s.copyWith(),
          merge: (s, o) => s.merge(o),
          lerp: (s, o, t) => s.lerp(o, t),
          fields: [
            Fld<ConvoKitDateStyle, Color>(
              'backgroundColor',
              const Color(0xFF70412C),
              const Color(0xFF7A462F),
              (s, v) => s.copyWith(backgroundColor: v),
              (s) => s.backgroundColor,
            ),
            Fld<ConvoKitDateStyle, Border>(
              'border',
              Border.all(width: 270.5),
              Border.all(width: 271.5),
              (s, v) => s.copyWith(border: v),
              (s) => s.border,
            ),
            Fld<ConvoKitDateStyle, TextStyle>(
              'textStyle',
              const TextStyle(fontSize: 272.5),
              const TextStyle(fontSize: 273.5),
              (s, v) => s.copyWith(textStyle: v),
              (s) => s.textStyle,
            ),
            Fld<ConvoKitDateStyle, Color>(
              'textColor',
              const Color(0xFFAC5F3E),
              const Color(0xFFB66441),
              (s, v) => s.copyWith(textColor: v),
              (s) => s.textColor,
            ),
            Fld<ConvoKitDateStyle, BorderRadiusGeometry>(
              'borderRadius',
              BorderRadius.circular(276.5),
              BorderRadius.circular(277.5),
              (s, v) => s.copyWith(borderRadius: v),
              (s) => s.borderRadius,
            ),
          ],
        );
      },
    );

    test(
      'ConvoKitStatusIndicatorStyle keeps every field through copyWith/merge/lerp',
      () {
        expectStyleContract<ConvoKitStatusIndicatorStyle>(
          label: 'ConvoKitStatusIndicatorStyle',
          empty: const ConvoKitStatusIndicatorStyle(),
          copyWithNothing: (s) => s.copyWith(),
          merge: (s, o) => s.merge(o),
          lerp: (s, o, t) => s.lerp(o, t),
          fields: [
            Fld<ConvoKitStatusIndicatorStyle, Color>(
              'backgroundColor',
              const Color(0xFFD4734A),
              const Color(0xFFDE784D),
              (s, v) => s.copyWith(backgroundColor: v),
              (s) => s.backgroundColor,
            ),
            Fld<ConvoKitStatusIndicatorStyle, Border>(
              'border',
              Border.all(width: 280.5),
              Border.all(width: 281.5),
              (s, v) => s.copyWith(border: v),
              (s) => s.border,
            ),
            Fld<ConvoKitStatusIndicatorStyle, BorderRadiusGeometry>(
              'borderRadius',
              BorderRadius.circular(282.5),
              BorderRadius.circular(283.5),
              (s, v) => s.copyWith(borderRadius: v),
              (s) => s.borderRadius,
            ),
          ],
        );
      },
    );

    test(
      'CometChatTypingIndicatorStyle keeps every field through copyWith/merge/lerp',
      () {
        expectStyleContract<CometChatTypingIndicatorStyle>(
          label: 'CometChatTypingIndicatorStyle',
          empty: const CometChatTypingIndicatorStyle(),
          copyWithNothing: (s) => s.copyWith(),
          merge: (s, o) => s.merge(o),
          lerp: (s, o, t) => s.lerp(o, t),
          fields: [
            Fld<CometChatTypingIndicatorStyle, TextStyle>(
              'textStyle',
              const TextStyle(fontSize: 284.5),
              const TextStyle(fontSize: 285.5),
              (s, v) => s.copyWith(textStyle: v),
              (s) => s.textStyle,
            ),
          ],
        );
      },
    );
  });
}
