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

  void onAddMemberClicked(ChatGroup group);

  void onTransferOwnershipClicked(ChatGroup group);

  void onBanMemberClicked(ChatGroup group);

  void onViewMemberClicked(ChatGroup group);

  List<ConvoKitDetailsTemplate> getDetailsTemplateList();

  Map<String, List<ConvoKitDetailsOption>> getDetailsOptionMap();
}
