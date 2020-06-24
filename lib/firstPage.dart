import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:kits/listPage.dart';
import 'package:kits/loginPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart' as xml;


class HomePage extends StatefulWidget {
  static const routeName = '/mainPage';

  LoginUser loginUser;


  HomePage(this.loginUser);

  @override
  _HomePageState createState() => new _HomePageState(loginUser);


}

class _HomePageState extends State<HomePage> {

  LoginUser loginUser;

 /* void saveUser(){

      String name = loginUser.userName;
      saveUserName(name).then((bool committed){ ) =

  }
*/
  _HomePageState(this.loginUser);

  List<Records> recordList = List();
  List<RecordTypes> recordTypeList = List();
  List<RecordTypes> recordTypeList2 = List();
  var map = Map();
  var envelope;

   String UserNameSet(String Uname){
    return  """<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"
       xmlns:urn=\"urn:sap-com:document:sap:rfc:functions\"> 
     <soapenv:Header/> <soapenv:Body> <urn:ZCRM_WS_RECORDS> 
     <!--Optional:--> <IV_UNAME>$Uname</IV_UNAME></urn:ZCRM_WS_RECORDS></soapenv:Body></soapenv:Envelope>""";
  }

  var refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    recordTypeList2.clear();
    recordTypeList.clear();
  }

  Future<Null> refreshList() async {
    recordList.clear();
    recordTypeList.clear();
    recordTypeList2.clear();

    refreshKey.currentState?.show(atTop: false);

   envelope = UserNameSet(loginUser.userName);
    http.Response response = await http.post(
        'http://crm.technova.com.tr:8001/sap/bc/srt/rfc/sap/zkits_ws_records/100/zkits_ws_records/zkits_ws_records',
        headers: {
          "Content-Type": "text/xml; charset=UTF-8",
          "SOAPAction":
              "urn:sap-com:document:sap:rfc:functions:zkits_ws_records:ZCRM_WS_RECORDSRequest",
          "Host": "crm.technova.com.tr:8001"
        },
        body: envelope);
    var _response = response.body;

    await _parsing(_response);

    setState(() {});

    return null;
  }



  Future _parsing(var _response) async {
    refreshKey.currentState.show(atTop: false);
    await Future.delayed(Duration(seconds: 2));
    var _document = xml.parse(_response);

    Iterable<xml.XmlElement> items = _document.findAllElements('item');
    if (items.length > 0) {
      items.map((xml.XmlElement item) {
        var uName = getValue(item.findElements("USER_NAME"));
        var recordID = getValue(item.findElements("RECORD_ID"));
        var recordType = getValue(item.findElements("RECORD_TYPE"));
        var recordDesc = getValue(item.findElements("RECORD_DESCR"));
        var recordDate = getValue(item.findElements("RECORD_DATE"));
        var recordTime = getValue(item.findElements("RECORD_TIME"));
        var itemID = getValue(item.findElements("ITEM_ID"));
        var description = getValue(item.findElements("DESCRIPTION"));
        var onayDurum = getValue(item.findElements("ONAY_DURUMU"));
        var ySorumlu = getValue(item.findElements("YSORUMLU"));
        recordList.add(Records(uName, recordID, recordType, recordDesc,
            recordDate, recordTime, itemID, description, onayDurum, ySorumlu));
      }).toList();

      map.clear();
      if (recordTypeList.isEmpty) {
        recordList.forEach((element) {
          if (element.OnayDurum == "1") {
            if (!map.containsKey("Onay Beklenen|Onay"))
              map["Onay Beklenen|Onay"] = 1;
            else {
              map["Onay Beklenen|Onay"] += 1;
            }
          } else if (element.OnayDurum == "2") {
            if (!map.containsKey("Paslanma Istegi|Paslama"))
              map["Paslanma Istegi|Paslama"] = 1;
            else {
              map["Paslanma Istegi|Paslama"] += 1;
            }
          } else if (!map
              .containsKey(element.RecordType + "|" + element.RecordDecs)) {
            map[element.RecordType + "|" + element.RecordDecs] = 1;
          } else if (map
              .containsKey(element.RecordType + "|" + element.RecordDecs)) {
            map[element.RecordType + "|" + element.RecordDecs] += 1;
          }
        });

        map.forEach((k, v) => recordTypeList.add(RecordTypes(k, k, v)));

        recordTypeList.sort((a, b) => a._Count.compareTo(b._Count));
        recordTypeList2.clear();

        for (int i = recordTypeList.length; i > 0; i--) {
          String onayDurumu = "0";

          if (recordTypeList[i - 1]._TypeDesc.contains("Onay")) {
            onayDurumu = "1";
          } else if (recordTypeList[i - 1]._TypeDesc.contains("Paslama")) {
            onayDurumu = "2";
          }

          recordTypeList2.add(RecordTypes.overloadedContructor(
              recordTypeList[i - 1]._TypeName,
              recordTypeList[i - 1]._TypeDesc,
              onayDurumu,
              recordTypeList[i - 1]._Count));
        }
      }
    }
    return null;
  }

  getValue(Iterable<xml.XmlElement> items) {
    var textValue;
    items.map((xml.XmlElement node) {
      textValue = node.text;
    }).toList();
    return textValue;
  }


  Future<bool> saveUserName(String uName) async{

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString("userName", uName);


    return prefs.commit();
  }
  Future<String> getUserName() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String uname = prefs.getString("userName");
    return uname;
  }



  Widget _buildCardsList() {
    return GridView.count(
      // Create a grid with 2 columns. If you change the scrollDirection to
      // horizontal, this produces 2 rows.
      crossAxisCount: 2,
      // Generate 100 widgets that display their index in the List.
      children: List.generate(recordTypeList2.length, (index) {
        var item = recordTypeList2.elementAt(index);

        return _buildItemCard(item);
      }),
    );
  }

  newPage(RecordTypes item) {
    var boolean = true;
    List<Records> recordList2 = new List();
    var p = 0;

    if (item.TypeDesc == "Onay") {
      p = 1;
    } else if (item.TypeDesc == "Paslama") {
      p = 2;
    }

    if (p == 1 || p == 2) {
      recordList.forEach((f) {
        if ((f.OnayDurum == p.toString())) {
          for (int i = 0; i < recordList2.length; i++) {
            if (recordList2[i].RecordID == f.RecordID &&
                recordList2[i].ItemID == f.ItemID) {
              boolean = false;
            }
          }

          if (boolean == true) {
            recordList2.add(f);
          } else {
            boolean = true;
          }

        }
      });
    } else {
      recordList.forEach((f) {
        if (f.RecordType.contains(item._TypeName.toString())) {
          if (f.OnayDurum.toString() != "1" && f.OnayDurum.toString() != "2") {
            for (int i = 0; i < recordList2.length; i++) {
              if (recordList2[i].RecordID == f.RecordID &&
                  recordList2[i].ItemID == f.ItemID) {
                boolean = false;
              }
            }

            if (boolean == true) {
              recordList2.add(f);
            } else {
              boolean = true;
            }
          }
        }
      });
    }

    final newList = [];

    Navigator.of(context)
        .pushNamed(ListPage.routeName, arguments: ScreenArguments(recordList2));
  }

  Widget _buildItemCard(RecordTypes item) {
    Map map = {
      '0': Colors.blue, //normal
      '1': Colors.red, //paslanma onayı beklenen
      '2': Colors.amber, //paslanan
    };

    return GestureDetector(
        onTap: () => newPage(item),
        child: Container(
          width: 100,
          height: 100,
          padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
          margin: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 8),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(20)),
              boxShadow: [
                BoxShadow(color: map[item.onayDurumu], blurRadius: 5)
              ]),
          child: _buildItemCardChild(item),
        ));
  }

  Widget _buildItemCardChild(RecordTypes item) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            AutoSizeText(
              item._TypeDesc,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            IconButton(
              onPressed: () {
                /*Navigator.pushNamed(context, '/listPage',
                    arguments: recordList);*/
              },
              icon: Icon(
                Icons.menu,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              item._Count.toString(),
              style: TextStyle(
                fontSize: 35,
                decorationColor: Colors.amberAccent,
                color: Colors.lightBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              item._TypeDesc.toString(),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (recordList.isEmpty) {
      refreshList();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Belge"),
        actions: [
          new IconButton(
            icon: new Icon(Icons.search),
            onPressed: () {
              print("Tıklandı");
            },
          ),
          new IconButton(
            icon: new Icon(
              Icons.notifications_active,
              color: Colors.white,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        key: refreshKey,
        child: Container(
          margin: EdgeInsets.only(top: 16),
          child: Stack(
            children: <Widget>[
              _buildCardsList(),
            ],
          ),
        ),
        onRefresh: refreshList,
      ),
    );
  }
}

class Records {
  String UserName,
      RecordID,
      RecordType,
      RecordDecs,
      RecordDate,
      RecordTime,
      ItemID,
      Description,
      OnayDurum,
      Ysorumlu;

  Records(
      this.UserName,
      this.RecordID,
      this.RecordType,
      this.RecordDecs,
      this.RecordDate,
      this.RecordTime,
      this.ItemID,
      this.Description,
      this.OnayDurum,
      this.Ysorumlu);
}

class RecordTypes {
  String _TypeName, _TypeDesc, onayDurumu;
  int _Count;

  RecordTypes(String _TypeName, String _TypeDesc, int _Count) {
    List<String> type_name = new List();
    type_name = _TypeName.split("|");
    this._TypeName = type_name[0];
    this._TypeDesc = type_name[1];
    this._Count = _Count;
  }

  RecordTypes.overloadedContructor(
      String _TypeName, String _TypeDesc, String onayDurumu, int _Count) {
    this._TypeName = _TypeName;
    this._TypeDesc = _TypeDesc;
    this._Count = _Count;
    this.onayDurumu = onayDurumu;
  }

  // RecordTypes(String typeName,String typeDesc,String onayDurumu, String Count);

  int get Count => _Count;

  set Count(int value) {
    _Count = value;
  }

  get TypeDesc => _TypeDesc;

  set TypeDesc(value) {
    _TypeDesc = value;
  }

  String get TypeName => _TypeName;

  set TypeName(String value) {
    _TypeName = value;
  }
}

class ScreenArgumentsDetail {
  String objectID, item, type, user, tarih, saat, description;
  List<User> userList;

  ScreenArgumentsDetail(this.objectID, this.item, this.type, this.user,
      this.tarih, this.saat, this.userList, this.description);
}

class User {
  var userID, userName;

  User(this.userID, this.userName);
}
