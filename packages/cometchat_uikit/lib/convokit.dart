/// ConvoKit public API.
///
/// Pure Dart contracts and models with UI entrypoints.
/// Zero CometChat naming or SDK dependencies.
library;

// Contracts
export 'src/contracts/contracts.dart';

// Core models
export 'src/core/models/models.dart';

// Composition root holder and EventHub
export 'src/core/convo_kit.dart';
export 'src/core/event_hub.dart';
export 'src/core/message_coordinator.dart';
export 'src/core/message_list_controller.dart';
export 'src/core/stores/stores.dart';

// Public UI widgets and scope
export 'src/ui/convo_kit_scope.dart';
export 'src/ui/views/conversations_view.dart';
export 'src/ui/views/message_list_view.dart';
