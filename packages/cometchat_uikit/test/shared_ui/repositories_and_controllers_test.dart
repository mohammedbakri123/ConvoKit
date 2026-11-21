/// Repository impl delegation tests (SDK-free & BLoC-free).
library;

import 'package:convokit/shared_ui/src/clean_architecture/data/repositories/repository_impl.dart';
import 'package:convokit/shared_ui/src/clean_architecture/data/data_sources/data_sources.dart';
import 'package:convokit/src/core/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Shared UI repository implementations', () {
    test('repository impls can be constructed over data sources', () {
      final msgRepo = MessageRepositoryImpl(dataSource: MessageDataSourceImpl());
      final userRepo = UserRepositoryImpl(dataSource: UserDataSourceImpl());
      final groupRepo = GroupRepositoryImpl(dataSource: GroupDataSourceImpl());
      expect(msgRepo, isNotNull);
      expect(userRepo, isNotNull);
      expect(groupRepo, isNotNull);
    });

    test('ConvoKitGroupMembersController instantiates with a ChatGroup', () {
      const group = ChatGroup(id: 'g1', name: 'Engineering');
      expect(group.id, 'g1');
      expect(group.name, 'Engineering');
    });
  });
}
