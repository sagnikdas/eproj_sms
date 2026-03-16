import 'package:elder_shield/application/app_providers.dart';
import 'package:elder_shield/features/messages/data/message_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controller for Messages screen: loads recent or high-risk messages.
class MessagesController
    extends AutoDisposeAsyncNotifier<List<AnalyzedMessage>> {
  bool _highRiskOnly = false;

  @override
  Future<List<AnalyzedMessage>> build() async {
    final repo = ref.read(messageRepositoryProvider);
    return _highRiskOnly
        ? repo.fetchHighRisk(limit: 50)
        : repo.fetchRecent(limit: 50);
  }

  bool get highRiskOnly => _highRiskOnly;

  Future<void> setHighRiskOnly(bool value) async {
    if (_highRiskOnly == value) return;
    _highRiskOnly = value;
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

final messagesControllerProvider = AutoDisposeAsyncNotifierProvider<
    MessagesController, List<AnalyzedMessage>>(
  MessagesController.new,
);

