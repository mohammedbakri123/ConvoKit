import 'package:flutter/material.dart';

/// Plain [ChangeNotifier] controller replacing the legacy `ListBaseBloc`.
class ListBaseController extends ChangeNotifier {
  final ScrollController scrollController = ScrollController();
  bool _showScrollToBottom = false;
  bool _isScrolling = false;

  bool get showScrollToBottom => _showScrollToBottom;
  bool get isScrolling => _isScrolling;

  ListBaseController() {
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final showButton = scrollController.offset > 100;
    if (showButton != _showScrollToBottom) {
      _showScrollToBottom = showButton;
      notifyListeners();
    }
  }

  Future<void> scrollToTop() async {
    if (!scrollController.hasClients) return;
    _isScrolling = true;
    notifyListeners();
    await scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    _isScrolling = false;
    _showScrollToBottom = false;
    notifyListeners();
  }

  Future<void> scrollToBottom() async {
    if (!scrollController.hasClients) return;
    _isScrolling = true;
    notifyListeners();
    await scrollController.animateTo(
      scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    _isScrolling = false;
    notifyListeners();
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }
}
