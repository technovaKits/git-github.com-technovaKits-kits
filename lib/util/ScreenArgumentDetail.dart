import 'package:kits/util/User.dart';
class ScreenArgumentsDetail {
  String objectID, item, type, user, tarih, saat, description;
  List<User> userList;

  ScreenArgumentsDetail(this.objectID, this.item, this.type, this.user,
      this.tarih, this.saat, this.userList, this.description);
}
