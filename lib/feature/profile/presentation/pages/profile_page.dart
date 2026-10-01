import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';

import '../../data/chest_repository.dart';
import '../../data/dino_collection_repository.dart';
import '../../data/profile_repository.dart';
import '../../domain/chest_reward.dart';
import '../../domain/dino_collection_item.dart';
import '../../domain/profile_state.dart';
import '../widgets/chest_opening_popup.dart';
import '../widgets/profile_name_dialog.dart';
import '../widgets/profile_popup.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.repository,
    this.initialTab = ProfileTab.collection,
  });

  final ProfileRepository? repository;
  final ProfileTab initialTab;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileRepository _repository;
  late final DinoCollectionRepository _collection;
  late final ChestRepository _chests;
  late ProfileState _state;
  ChestOpeningResult? _chestResult;
  StreamSubscription<void>? _subscription;
  Timer? _messageTimer;
  int _loadVersion = 0;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? sl<ProfileRepository>();
    _collection = DinoCollectionRepository(store: _repository.store);
    _chests = ChestRepository(store: _repository.store);
    _state = ProfileState(tab: widget.initialTab);
    _initialize();
  }

  Future<void> _initialize() async {
    await _refresh();
    if (!mounted) return;
    try {
      final pending = await _chests.pending();
      if (!mounted) return;
      setState(() {
        _chestResult = pending;
        if (pending != null) _state = _state.copyWith(tab: ProfileTab.chests);
      });
    } catch (_) {
      _message('Could not restore chest rewards. Please try again.');
    }
    if (mounted) {
      _subscription ??= _repository.changes.listen((_) => _refresh());
    }
  }

  Future<void> _refresh() async {
    final version = ++_loadVersion;
    try {
      final loaded = await _repository.load();
      if (!mounted || version != _loadVersion) return;
      final selected = loaded.dinos.any((d) => d.id == _state.selectedDinoId)
          ? _state.selectedDinoId
          : loaded.selectedDinoId;
      setState(
        () => _state = loaded.copyWith(
          tab: _state.tab,
          selectedDinoId: selected,
          actionBusy: _state.actionBusy,
          message: _state.message,
        ),
      );
    } catch (_) {
      if (mounted && version == _loadVersion) {
        setState(
          () => _state = _state.copyWith(
            isLoading: false,
            error: 'Could not load your profile. Please try again.',
          ),
        );
      }
    }
  }

  void _message(String text) {
    if (!mounted) return;
    _messageTimer?.cancel();
    setState(() => _state = _state.copyWith(message: text));
    _messageTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _state = _state.copyWith(clearMessage: true));
    });
  }

  Future<void> _editName() async {
    final profile = _state.profile;
    if (profile == null || _state.actionBusy) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => ProfileNameDialog(
        initialName: profile.displayName,
        onSave: _repository.rename,
      ),
    );
    if (!mounted || saved != true) return;
    await _refresh();
    _message('Name saved');
  }

  Future<void> _action() async {
    final selected = _state.selectedDino;
    if (selected == null || _state.actionBusy) return;
    if (selected.status == DinoCollectionStatus.fragmentsMissing) {
      context.pushReplacement('/store?category=chests');
      return;
    }
    if (selected.status == DinoCollectionStatus.equipped) return;
    setState(() => _state = _state.copyWith(actionBusy: true));
    try {
      final changed = selected.status == DinoCollectionStatus.readyToUnlock
          ? await _collection.assemble(selected.id)
          : await _collection.equip(selected.id);
      await _refresh();
      if (changed) {
        _message(
          selected.status == DinoCollectionStatus.readyToUnlock
              ? 'Unlocked ${selected.name}'
              : 'Avatar updated',
        );
      }
    } catch (_) {
      _message('Could not save your change. Please try again.');
    } finally {
      if (mounted) setState(() => _state = _state.copyWith(actionBusy: false));
    }
  }

  Future<void> _openChest(String id, {String? previousId}) async {
    if (_state.actionBusy) return;
    setState(() => _state = _state.copyWith(actionBusy: true));
    try {
      final result = await _chests.open(id, expectedPreviousId: previousId);
      await _refresh();
      if (mounted) setState(() => _chestResult = result);
    } catch (_) {
      // Replay the persisted result, without rerolling or charging another chest.
      try {
        final result = await _chests.pending();
        if (mounted) setState(() => _chestResult = result);
        await _refresh();
      } catch (_) {
        /* Retain the journal for the next retry/start. */
      }
      _message('Could not finish opening the chest. Please try again.');
    } finally {
      if (mounted) setState(() => _state = _state.copyWith(actionBusy: false));
    }
  }

  Future<void> _dismissChest() async {
    final result = _chestResult;
    if (result == null || _state.actionBusy) return;
    setState(() => _state = _state.copyWith(actionBusy: true));
    try {
      await _chests.dismiss(result.id);
      if (mounted) {
        setState(() {
          _chestResult = null;
          _state = _state.copyWith(tab: ProfileTab.chests);
        });
      }
    } catch (_) {
      _message('Could not save. Please try again.');
    } finally {
      if (mounted) setState(() => _state = _state.copyWith(actionBusy: false));
    }
  }

  void _close() {
    if (_state.actionBusy) return;
    if (_chestResult != null) {
      _dismissChest();
      return;
    }
    if (context.canPop()) context.pop();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_state.actionBusy && _chestResult == null,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop && _chestResult != null) _dismissChest();
    },
    child: CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): _close},
      child: Focus(
        autofocus: true,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                  child: const ColoredBox(color: Color(0x99080c18)),
                ),
              ),
              if (_state.profile != null)
                Positioned.fill(
                  child: ProfilePopup(
                    state: _state,
                    onClose: _close,
                    onEdit: _editName,
                    onAction: _action,
                    onChest: _openChest,
                    onTab: (tab) {
                      if (!_state.actionBusy) {
                        setState(() => _state = _state.copyWith(tab: tab));
                      }
                    },
                    onSelected: (id) {
                      if (!_state.actionBusy) {
                        setState(
                          () => _state = _state.copyWith(selectedDinoId: id),
                        );
                      }
                    },
                  ),
                ),
              if (_state.isLoading)
                const Center(child: CircularProgressIndicator()),
              if (_state.error != null)
                Center(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_state.error!),
                          TextButton(
                            onPressed: _refresh,
                            child: const Text('Retry'),
                          ),
                          TextButton(
                            onPressed: _close,
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_chestResult case final result?)
                Positioned.fill(
                  child: ChestOpeningPopup(
                    key: ValueKey(result.id),
                    result: result,
                    busy: _state.actionBusy,
                    remaining:
                        _state.chests
                            .where((c) => c.id == result.chestId)
                            .firstOrNull
                            ?.quantity ??
                        0,
                    onAgain: () =>
                        _openChest(result.chestId, previousId: result.id),
                    onClose: _dismissChest,
                  ),
                ),
              if (_state.message case final message?)
                SafeArea(
                  child: Align(
                    alignment: const Alignment(0, .92),
                    child: IgnorePointer(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xeb3c2008),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Color(0xffffe7b3)),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

extension ProfileRouter on ProfilePage {
  static const path = '/profile';

  static GoRoute goRoute() => GoRoute(
    path: path,
    pageBuilder: (context, state) => CustomTransitionPage<void>(
      key: state.pageKey,
      opaque: false,
      barrierDismissible: false,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 170),
      child: ProfilePage(
        initialTab: state.uri.queryParameters['tab'] == 'chests'
            ? ProfileTab.chests
            : ProfileTab.collection,
      ),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}
