import '../../../../../convokit_uikit_shared.dart'
    show Utils, ModelFieldConstants;

class OptionElement {
  OptionElement({required this.value, required this.label});

  String label;
  String value;

  Map<String, dynamic> toMap() {
    Map<String, dynamic> map = {};
    if (Utils.isValidString(value)) {
      map[ModelFieldConstants.value] = value;
    }

    if (Utils.isValidString(label)) {
      map[ModelFieldConstants.label] = label;
    }
    return map;
  }

  factory OptionElement.fromMap(dynamic rawMap) {
    final map = rawMap as Map<dynamic, dynamic>;
    return OptionElement(
      // id: map[ModelColumns.id],
      value: map[ModelFieldConstants.value],
      label: map[ModelFieldConstants.label],
    );
  }
}
