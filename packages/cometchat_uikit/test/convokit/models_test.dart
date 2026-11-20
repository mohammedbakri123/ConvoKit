import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:convokit/convokit.dart';

void main() {
  group('ChatUser models', () {
    test('creates ChatUser with default values', () {
      const user = ChatUser(id: 'u1', name: 'Alice');
      expect(user.id, 'u1');
      expect(user.name, 'Alice');
      expect(user.avatarUrl, isNull);
      expect(user.presence, UserPresence.unknown);
      expect(user.isBlocked, isFalse);
    });

    test('ChatUser equality and hashCode', () {
      const u1 = ChatUser(id: 'u1', name: 'Alice', presence: UserPresence.online);
      const u2 = ChatUser(id: 'u1', name: 'Alice', presence: UserPresence.online);
      const u3 = ChatUser(id: 'u2', name: 'Bob');

      expect(u1, equals(u2));
      expect(u1.hashCode, equals(u2.hashCode));
      expect(u1, isNot(equals(u3)));
    });
  });

  group('ChatGroup and ChatMember models', () {
    test('creates ChatMember with role', () {
      const user = ChatUser(id: 'u1', name: 'Alice');
      const member = ChatMember(user: user, role: GroupRole.owner);
      expect(member.user, user);
      expect(member.role, GroupRole.owner);
    });

    test('creates ChatGroup with members', () {
      const user = ChatUser(id: 'u1', name: 'Alice');
      const member = ChatMember(user: user, role: GroupRole.owner);
      const group = ChatGroup(
        id: 'g1',
        name: 'General',
        type: GroupType.public,
        memberCount: 1,
        members: [member],
      );

      expect(group.id, 'g1');
      expect(group.name, 'General');
      expect(group.type, GroupType.public);
      expect(group.memberCount, 1);
      expect(group.members, [member]);
    });
  });

  group('ChatConversation invariants', () {
    final now = DateTime.now();
    const peer = ChatUser(id: 'u1', name: 'Alice');
    const group = ChatGroup(id: 'g1', name: 'General');

    test('ChatConversation.direct sets type to direct and group to null', () {
      final conv = ChatConversation.direct(
        id: 'c1',
        peer: peer,
        updatedAt: now,
      );

      expect(conv.id, 'c1');
      expect(conv.peer, peer);
      expect(conv.group, isNull);
      expect(conv.type, ChatConversationType.direct);
      expect(conv.unreadCount, 0);
    });

    test('ChatConversation.group sets type to group and peer to null', () {
      final conv = ChatConversation.group(
        id: 'c2',
        group: group,
        updatedAt: now,
      );

      expect(conv.id, 'c2');
      expect(conv.group, group);
      expect(conv.peer, isNull);
      expect(conv.type, ChatConversationType.group);
      expect(conv.unreadCount, 0);
    });
  });

  group('ChatAttachment state machine and invariants', () {
    test('valid local attachment', () {
      const att = ChatAttachment(
        id: 'a1',
        kind: AttachmentKind.image,
        localPath: '/local/photo.jpg',
        state: AttachmentState.local,
      );
      expect(att.state, AttachmentState.local);
      expect(att.localPath, '/local/photo.jpg');
      expect(att.url, isNull);
      expect(att.remoteId, isNull);
      expect(att.uploadProgress, isNull);
      expect(att.uploadFailure, isNull);
    });

    test('valid uploading attachment', () {
      const att = ChatAttachment(
        id: 'a1',
        kind: AttachmentKind.image,
        localPath: '/local/photo.jpg',
        state: AttachmentState.uploading,
        uploadProgress: 0.45,
      );
      expect(att.state, AttachmentState.uploading);
      expect(att.uploadProgress, 0.45);
    });

    test('valid uploaded attachment with localPath retained (cache)', () {
      const att = ChatAttachment(
        id: 'a1',
        remoteId: 'rem_123',
        kind: AttachmentKind.image,
        localPath: '/cache/photo.jpg',
        url: 'https://cdn.example.com/photo.jpg',
        state: AttachmentState.uploaded,
      );
      expect(att.state, AttachmentState.uploaded);
      expect(att.remoteId, 'rem_123');
      expect(att.url, 'https://cdn.example.com/photo.jpg');
      expect(att.localPath, '/cache/photo.jpg');
    });

    test('valid uploaded attachment with localPath dropped', () {
      const att = ChatAttachment(
        id: 'a1',
        remoteId: 'rem_123',
        kind: AttachmentKind.image,
        localPath: null,
        url: 'https://cdn.example.com/photo.jpg',
        state: AttachmentState.uploaded,
      );
      expect(att.state, AttachmentState.uploaded);
      expect(att.remoteId, 'rem_123');
      expect(att.url, 'https://cdn.example.com/photo.jpg');
      expect(att.localPath, isNull);
    });

    test('valid failed attachment', () {
      const err = ChatError(ChatErrorCode.uploadFailed, 'Upload failed');
      const att = ChatAttachment(
        id: 'a1',
        kind: AttachmentKind.image,
        localPath: '/local/photo.jpg',
        state: AttachmentState.failed,
        uploadFailure: err,
      );
      expect(att.state, AttachmentState.failed);
      expect(att.uploadFailure, err);
      expect(att.localPath, '/local/photo.jpg');
    });

    test('asserts localPath is required until upload completes', () {
      expect(
        () => ChatAttachment(
          id: 'a1',
          kind: AttachmentKind.image,
          localPath: null,
          state: AttachmentState.local,
        ),
        throwsA(isA<AssertionError>()),
      );

      expect(
        () => ChatAttachment(
          id: 'a1',
          kind: AttachmentKind.image,
          localPath: null,
          state: AttachmentState.uploading,
          uploadProgress: 0.5,
        ),
        throwsA(isA<AssertionError>()),
      );

      expect(
        () => ChatAttachment(
          id: 'a1',
          kind: AttachmentKind.image,
          localPath: null,
          state: AttachmentState.failed,
          uploadFailure: const ChatError(ChatErrorCode.uploadFailed, 'Fail'),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('asserts url presence matches state uploaded', () {
      // url null when uploaded
      expect(
        () => ChatAttachment(
          id: 'a1',
          remoteId: 'rem_1',
          kind: AttachmentKind.image,
          url: null,
          state: AttachmentState.uploaded,
        ),
        throwsA(isA<AssertionError>()),
      );

      // url non-null when local
      expect(
        () => ChatAttachment(
          id: 'a1',
          kind: AttachmentKind.image,
          localPath: '/path',
          url: 'https://cdn.com/a.jpg',
          state: AttachmentState.local,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('asserts remoteId presence matches state uploaded', () {
      // remoteId null when uploaded
      expect(
        () => ChatAttachment(
          id: 'a1',
          remoteId: null,
          kind: AttachmentKind.image,
          url: 'https://cdn.com/a.jpg',
          state: AttachmentState.uploaded,
        ),
        throwsA(isA<AssertionError>()),
      );

      // remoteId non-null when local
      expect(
        () => ChatAttachment(
          id: 'a1',
          remoteId: 'rem_1',
          kind: AttachmentKind.image,
          localPath: '/path',
          state: AttachmentState.local,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('asserts uploadProgress presence matches state uploading', () {
      // uploadProgress null when uploading
      expect(
        () => ChatAttachment(
          id: 'a1',
          kind: AttachmentKind.image,
          localPath: '/path',
          state: AttachmentState.uploading,
          uploadProgress: null,
        ),
        throwsA(isA<AssertionError>()),
      );

      // uploadProgress non-null when local
      expect(
        () => ChatAttachment(
          id: 'a1',
          kind: AttachmentKind.image,
          localPath: '/path',
          state: AttachmentState.local,
          uploadProgress: 0.5,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('asserts uploadFailure presence matches state failed', () {
      // uploadFailure null when failed
      expect(
        () => ChatAttachment(
          id: 'a1',
          kind: AttachmentKind.image,
          localPath: '/path',
          state: AttachmentState.failed,
          uploadFailure: null,
        ),
        throwsA(isA<AssertionError>()),
      );

      // uploadFailure non-null when local
      expect(
        () => ChatAttachment(
          id: 'a1',
          kind: AttachmentKind.image,
          localPath: '/path',
          state: AttachmentState.local,
          uploadFailure: const ChatError(ChatErrorCode.uploadFailed, 'Fail'),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('ChatMessage send/delivery transitions and invariants', () {
    const sender = ChatUser(id: 'u1', name: 'Alice');
    final now = DateTime.now();

    test('valid sending message has deliveryState none and failure null', () {
      final msg = TextMessage(
        localId: 'loc_1',
        conversationId: 'c1',
        sender: sender,
        createdAt: now,
        text: 'Hello',
        sendState: SendState.sending,
        deliveryState: DeliveryState.none,
      );

      expect(msg.sendState, SendState.sending);
      expect(msg.deliveryState, DeliveryState.none);
      expect(msg.failure, isNull);
    });

    test('valid sent message can have deliveryState none, delivered, or read', () {
      final m1 = TextMessage(
        id: 'srv_1',
        localId: 'loc_1',
        conversationId: 'c1',
        sender: sender,
        createdAt: now,
        text: 'Hello',
        sendState: SendState.sent,
        deliveryState: DeliveryState.none,
      );
      expect(m1.deliveryState, DeliveryState.none);

      final m2 = TextMessage(
        id: 'srv_1',
        localId: 'loc_1',
        conversationId: 'c1',
        sender: sender,
        createdAt: now,
        text: 'Hello',
        sendState: SendState.sent,
        deliveryState: DeliveryState.delivered,
      );
      expect(m2.deliveryState, DeliveryState.delivered);

      final m3 = TextMessage(
        id: 'srv_1',
        localId: 'loc_1',
        conversationId: 'c1',
        sender: sender,
        createdAt: now,
        text: 'Hello',
        sendState: SendState.sent,
        deliveryState: DeliveryState.read,
      );
      expect(m3.deliveryState, DeliveryState.read);
    });

    test('failed message requires failure set and deliveryState none', () {
      const err = ChatError(ChatErrorCode.sendFailed, 'Failed to send');

      final validFailed = TextMessage(
        localId: 'loc_1',
        conversationId: 'c1',
        sender: sender,
        createdAt: now,
        text: 'Hello',
        sendState: SendState.failed,
        deliveryState: DeliveryState.none,
        failure: err,
      );
      expect(validFailed.failure, err);
      expect(validFailed.deliveryState, DeliveryState.none);

      // Missing failure when failed
      expect(
        () => TextMessage(
          localId: 'loc_1',
          conversationId: 'c1',
          sender: sender,
          createdAt: now,
          text: 'Hello',
          sendState: SendState.failed,
          deliveryState: DeliveryState.none,
          failure: null,
        ),
        throwsA(isA<AssertionError>()),
      );

      // Non-none deliveryState when failed
      expect(
        () => TextMessage(
          localId: 'loc_1',
          conversationId: 'c1',
          sender: sender,
          createdAt: now,
          text: 'Hello',
          sendState: SendState.failed,
          deliveryState: DeliveryState.delivered,
          failure: err,
        ),
        throwsA(isA<AssertionError>()),
      );

      // Non-null failure when sending
      expect(
        () => TextMessage(
          localId: 'loc_1',
          conversationId: 'c1',
          sender: sender,
          createdAt: now,
          text: 'Hello',
          sendState: SendState.sending,
          deliveryState: DeliveryState.none,
          failure: err,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('MediaMessage and CustomMessage subclasses retain invariants', () {
      const att = ChatAttachment(
        id: 'a1',
        kind: AttachmentKind.file,
        localPath: '/file.pdf',
        state: AttachmentState.local,
      );

      final mediaMsg = MediaMessage(
        localId: 'loc_m1',
        conversationId: 'c1',
        sender: sender,
        createdAt: now,
        attachment: att,
        caption: 'Invoice',
      );
      expect(mediaMsg.attachment, att);
      expect(mediaMsg.caption, 'Invoice');

      final customMsg = CustomMessage(
        localId: 'loc_c1',
        conversationId: 'c1',
        sender: sender,
        createdAt: now,
        kind: 'card',
        data: {'title': 'Card Title'},
      );
      expect(customMsg.kind, 'card');
      expect(customMsg.data['title'], 'Card Title');
    });
  });

  group('UploadRequest factory invariants', () {
    test('UploadRequest.file sets localPath and null bytes', () {
      final req = UploadRequest.file('/path/img.png', kind: AttachmentKind.image);
      expect(req.localPath, '/path/img.png');
      expect(req.bytes, isNull);
      expect(req.kind, AttachmentKind.image);
    });

    test('UploadRequest.bytes sets bytes and null localPath', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final req = UploadRequest.bytes(bytes, kind: AttachmentKind.file);
      expect(req.bytes, bytes);
      expect(req.localPath, isNull);
      expect(req.kind, AttachmentKind.file);
    });
  });
}
