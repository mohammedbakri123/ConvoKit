import 'package:convokit/convokit.dart';
import 'package:flutter/material.dart';
import '../../../convokit_uikit.dart';

/// Plain [ChangeNotifier] controller for [ConvoKitGroupMembers], backed by
/// [GroupRepository] (`listMembers`, `addMembers`, `removeMember`) via
/// [ConvoKitScope].
///
/// Gated on `capabilities.groups && kit.groups != null`. When groups are
/// disabled or absent, mutations return a [ChatFailure] with
/// [ChatErrorCode.unsupported] and reads settle cleanly into a disabled/empty
/// state without throwing.
class ConvoKitGroupMembersController extends ChangeNotifier {
  ConvoKitGroupMembersController({
    required this.group,
    GroupRepository? groupRepository,
    bool groupsEnabled = false,
    this.loggedInUser,
    this.selectionMode = SelectionMode.none,
    this.usersStatusVisibility = true,
    this.confirmDialogStyle,
    this.changeScopeStyle,
    this.onError,
    this.onEmpty,
    this.onLoad,
    this.hideBanMemberOption,
    this.hideKickMemberOption,
    this.hideScopeChangeOption,
    this.pageLimit = 30,
    String? initialSearchKeyword,
  }) : _groupRepository = groupRepository,
       _groupsEnabled = groupsEnabled,
       _searchQuery = initialSearchKeyword?.trim() ?? '';

  final ChatGroup group;
  GroupRepository? _groupRepository;
  bool _groupsEnabled;
  ChatUser? loggedInUser;
  SelectionMode selectionMode;
  bool usersStatusVisibility;
  ConvoKitConfirmDialogStyle? confirmDialogStyle;
  ConvoKitChangeScopeStyle? changeScopeStyle;
  final OnError? onError;
  final OnEmpty? onEmpty;
  final OnLoad<ChatMember>? onLoad;
  final bool? hideKickMemberOption;
  final bool? hideBanMemberOption;
  final bool? hideScopeChangeOption;
  final int pageLimit;

  final ValueNotifier<bool> isActionRunning = ValueNotifier<bool>(false);

  List<ChatMember> _members = const [];
  String _searchQuery = '';
  String? _nextCursor;
  bool _hasMore = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _isDisabled = false;
  bool _hasLoadedOnce = false;
  ChatError? _error;
  int _requestSeq = 0;

  final Set<String> _selectedMemberIds = <String>{};
  final Map<String, ChatMember> selectionMap = <String, ChatMember>{};

  bool get isGroupsEnabled => _groupsEnabled && _groupRepository != null;
  List<ChatMember> get members => List.unmodifiable(_members);
  String get searchQuery => _searchQuery;
  bool get hasMore => _searchQuery.isEmpty && _hasMore;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get isDisabled => _isDisabled;
  bool get hasLoadedOnce => _hasLoadedOnce;
  ChatError? get error => _error;
  Set<String> get selectedMemberIds => Set.unmodifiable(_selectedMemberIds);
  bool get isOwner =>
      loggedInUser != null &&
      _members.any(
        (m) => m.user.id == loggedInUser!.id && m.role == GroupRole.owner,
      );

  List<ChatMember> get visibleMembers {
    if (_searchQuery.isEmpty) return _members;
    final needle = _searchQuery.toLowerCase();
    return _members
        .where((m) => m.user.name.toLowerCase().contains(needle))
        .toList();
  }

  /// Binds this controller to a [ConvoKit] instance from [ConvoKitScope].
  void attachKit(ConvoKit? kit) {
    _groupsEnabled = kit?.capabilities.groups ?? false;
    _groupRepository = _groupsEnabled ? kit?.groups : null;
    loggedInUser = kit?.session.currentUser;
  }

  /// Loads the first page of members via [GroupRepository.listMembers].
  Future<void> loadMembers() async {
    final repo = isGroupsEnabled ? _groupRepository : null;
    if (repo == null) {
      _isDisabled = true;
      _isLoading = false;
      _isLoadingMore = false;
      _hasLoadedOnce = true;
      _members = const [];
      _nextCursor = null;
      _hasMore = false;
      _error = null;
      notifyListeners();
      onEmpty?.call();
      return;
    }

    final seq = ++_requestSeq;
    _isDisabled = false;
    _isLoading = true;
    _isLoadingMore = false;
    _error = null;
    _nextCursor = null;
    _hasMore = false;
    notifyListeners();

    try {
      final result = await repo.listMembers(group.id, limit: pageLimit);
      if (seq != _requestSeq) return;

      result.fold(
        onSuccess: (page) {
          _members = List<ChatMember>.of(page.items);
          _nextCursor = page.olderCursor;
          _hasMore = page.hasOlder;
          _isLoading = false;
          _hasLoadedOnce = true;
          _error = null;
          _syncSelectionMap();
          notifyListeners();
          if (visibleMembers.isEmpty) {
            onEmpty?.call();
          } else {
            onLoad?.call(visibleMembers);
          }
        },
        onFailure: (err) {
          _members = const [];
          _nextCursor = null;
          _hasMore = false;
          _isLoading = false;
          _hasLoadedOnce = true;
          _error = err;
          notifyListeners();
          onError?.call(Exception(err.message));
        },
      );
    } catch (e) {
      if (seq != _requestSeq) return;
      final err = ChatError(ChatErrorCode.unknown, e.toString(), cause: e);
      _members = const [];
      _nextCursor = null;
      _hasMore = false;
      _isLoading = false;
      _hasLoadedOnce = true;
      _error = err;
      notifyListeners();
      onError?.call(Exception(err.message));
    }
  }

  /// Loads the next page of members via [GroupRepository.listMembers].
  Future<void> loadMoreMembers() async {
    final repo = isGroupsEnabled ? _groupRepository : null;
    if (repo == null || !_hasMore || _isLoadingMore || _isLoading) return;

    final seq = ++_requestSeq;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await repo.listMembers(
        group.id,
        cursor: _nextCursor,
        limit: pageLimit,
      );
      if (seq != _requestSeq) return;

      result.fold(
        onSuccess: (page) {
          _members = <ChatMember>[..._members, ...page.items];
          _nextCursor = page.olderCursor;
          _hasMore = page.hasOlder;
          _isLoadingMore = false;
          _syncSelectionMap();
          notifyListeners();
        },
        onFailure: (err) {
          _isLoadingMore = false;
          notifyListeners();
          onError?.call(Exception(err.message));
        },
      );
    } catch (e) {
      if (seq != _requestSeq) return;
      _isLoadingMore = false;
      notifyListeners();
      onError?.call(Exception(e.toString()));
    }
  }

  /// Filters loaded members by [query].
  void onSearch(String query) {
    final trimmed = query.trim();
    if (_searchQuery == trimmed) return;
    _searchQuery = trimmed;
    notifyListeners();
  }

  /// Adds [userIds] to the group via [GroupRepository.addMembers].
  Future<ChatResult<void>> addMembers(List<String> userIds) async {
    final repo = isGroupsEnabled ? _groupRepository : null;
    if (repo == null) {
      return const ChatFailure(
        ChatError(ChatErrorCode.unsupported, 'Groups capability is disabled'),
      );
    }
    isActionRunning.value = true;
    try {
      final result = await repo.addMembers(group.id, userIds);
      result.fold(
        onSuccess: (_) => loadMembers(),
        onFailure: (err) => onError?.call(Exception(err.message)),
      );
      return result;
    } finally {
      isActionRunning.value = false;
    }
  }

  /// Removes [userId] from the group via [GroupRepository.removeMember].
  Future<ChatResult<void>> removeMember(String userId) async {
    final repo = isGroupsEnabled ? _groupRepository : null;
    if (repo == null) {
      return const ChatFailure(
        ChatError(ChatErrorCode.unsupported, 'Groups capability is disabled'),
      );
    }
    isActionRunning.value = true;
    try {
      final result = await repo.removeMember(group.id, userId);
      result.fold(
        onSuccess: (_) {
          _members = _members.where((m) => m.user.id != userId).toList();
          _selectedMemberIds.remove(userId);
          _syncSelectionMap();
          notifyListeners();
          if (visibleMembers.isEmpty) {
            onEmpty?.call();
          }
        },
        onFailure: (err) => onError?.call(Exception(err.message)),
      );
      return result;
    } finally {
      isActionRunning.value = false;
    }
  }

  /// Updates a member's local role representation after an external scope save.
  void updateMemberRole(String userId, GroupRole newRole) {
    final idx = _members.indexWhere((m) => m.user.id == userId);
    if (idx == -1) return;
    final updated = List<ChatMember>.of(_members);
    updated[idx] = ChatMember(user: updated[idx].user, role: newRole);
    _members = updated;
    _syncSelectionMap();
    notifyListeners();
  }

  void toggleSelection(String userId) {
    if (selectionMode == SelectionMode.single) {
      if (_selectedMemberIds.contains(userId)) {
        _selectedMemberIds.clear();
      } else {
        _selectedMemberIds
          ..clear()
          ..add(userId);
      }
    } else {
      if (_selectedMemberIds.contains(userId)) {
        _selectedMemberIds.remove(userId);
      } else {
        _selectedMemberIds.add(userId);
      }
    }
    _syncSelectionMap();
    notifyListeners();
  }

  void clearSelection() {
    _selectedMemberIds.clear();
    selectionMap.clear();
    notifyListeners();
  }

  List<ChatMember> getSelectedList() {
    return _members
        .where((m) => _selectedMemberIds.contains(m.user.id))
        .toList();
  }

  void _syncSelectionMap() {
    selectionMap
      ..clear()
      ..addEntries(
        _members
            .where((m) => _selectedMemberIds.contains(m.user.id))
            .map((m) => MapEntry(m.user.id, m)),
      );
  }

  /// Builds default member options filtered by role & hide flags.
  List<CometChatOption> defaultFunction(
    ChatGroup group,
    ChatMember member,
    BuildContext context,
    ConvoKitColorPalette colorPalette,
    ConvoKitTypography typography,
    ConvoKitSpacing spacing,
  ) {
    final groupMemberOptions = DetailUtils.getDefaultGroupMemberOptions(
      loggedInUser: loggedInUser,
      group: group,
      member: member,
      context: context,
      hideBanMemberOption: hideBanMemberOption,
      hideKickMemberOption: hideKickMemberOption,
      hideScopeChangeOption: hideScopeChangeOption,
    );

    return [
      for (final option in groupMemberOptions)
        CometChatOption(
          id: option.id,
          title: option.title,
          packageName: option.packageName,
          backgroundColor: option.backgroundColor,
          icon: option.icon,
          iconTint: colorPalette.iconSecondary,
          iconWidget: option.iconWidget,
        ),
    ];
  }

  @override
  void dispose() {
    _requestSeq++;
    isActionRunning.dispose();
    super.dispose();
  }
}
