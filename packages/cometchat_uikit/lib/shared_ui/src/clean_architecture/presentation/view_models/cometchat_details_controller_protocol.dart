import '../../../../convokit_uikit_shared.dart';

abstract class ConvoKitDetailsControllerProtocol {
  int updateOption(
    String templateId,
    String oldOptionID,
    ConvoKitDetailsOption updatedOption,
  );

  int removeOption(String templateId, String optionId);

  int addOption(
    String templateId,
    ConvoKitDetailsOption newOption, {
    int? position,
  });

  void useOption(ConvoKitDetailsOption option, String sectionId);

  void onAddMemberClicked(Group group);

  void onTransferOwnershipClicked(Group group);

  void onBanMemberClicked(Group group);

  void onViewMemberClicked(Group group);

  List<ConvoKitDetailsTemplate> getDetailsTemplateList();

  Map<String, List<ConvoKitDetailsOption>> getDetailsOptionMap();
}
