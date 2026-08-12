import 'package:bili_novel_packer/console/selector.dart';

const String _yes = "是";
const String _no = "否";

class Prompt {
  final String question;
  final bool defaultValue;

  Prompt(this.question, {bool? defaultValue})
    : defaultValue = defaultValue ?? true;

  bool prompt() {
    return Selector(
          options: [_yes, _no],
          message: question,
          defaultValue: defaultValue ? _yes : _no,
        ).selectOne() ==
        _yes;
  }
}
