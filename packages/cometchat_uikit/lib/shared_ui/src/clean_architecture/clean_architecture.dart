// Clean Architecture - Complete Structure
// This is the main export file for the entire clean architecture

// External Dependencies
export '../../../src/core/models/models.dart'
    show
        ChatUser,
        UserPresence,
        ChatGroup,
        ChatMember,
        GroupRole,
        GroupType,
        ChatConversation,
        ChatConversationType,
        ChatMessage,
        TextMessage,
        MediaMessage,
        CustomMessage,
        SendState,
        DeliveryState,
        ChatAttachment,
        AttachmentKind,
        AttachmentState;
export '../../../src/contracts/result.dart';

// Legacy exports needed by clean architecture
export '../../l10n/translations.dart';
export '../../../src/convokit_ui_kit.dart' show ConvoKitUIKit;

// Core Layer
export 'core/core.dart';

// Domain Layer
export 'domain/domain.dart' hide MessageRepository, UserRepository, GroupRepository;

// Data Layer
export 'data/data.dart';

// Presentation Layer
export 'presentation/presentation.dart';

// Services Layer
export 'services/audio_state/domain/entities/audio_state_entity.dart';
export 'services/audio_state/domain/repositories/audio_state_repository.dart';
export 'services/audio_state/domain/usecases/audio_state_usecases.dart';
export 'services/stream/domain/entities/stream_entity.dart';
