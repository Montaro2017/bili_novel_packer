import 'package:test/scaffolding.dart';

void main() {
  test("hashCode",(){
    var list1 = [null,null].toString();
    var list2 = ["伪圣女，前往日本④",null].toString();
    var list3 = ["伪圣女，前往日本12",null].toString();
    var list4 = [null,"伪圣女，前往日本④"].toString();
    print(list1);
    print(list1.hashCode);
    print("[null, null]".hashCode);
    print(list2);
    print(list2.hashCode);
    print("[伪圣女，前往日本④, null]".hashCode);
    print(list3);
    print(list3.hashCode);
    print("[伪圣女，前往日本12, null]".hashCode);
    print(list4);
    print(list4.hashCode);
    print("[null, 伪圣女，前往日本④]".hashCode);
  });
}
