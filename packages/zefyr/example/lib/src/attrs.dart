import 'package:zefyr/zefyr.dart';

class CustomAttrDelegate implements ZefyrAttrDelegate {
  CustomAttrDelegate();

  @override
  void onLinkTap(String value) {
    print('the link is: ${value}');
  }
}
