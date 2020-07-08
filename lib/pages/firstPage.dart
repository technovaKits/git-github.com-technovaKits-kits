import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:kits/pages/list.dart';
import 'package:kits/pages/login.dart';
import 'package:kits/classes/LoginUser.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kits/classes/Records.dart';
import "package:kits/classes/RecordTypes.dart";
import 'package:kits/classes/ScreenArgument.dart';

GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['profile', 'email']);

class HomePage extends StatefulWidget {
  
  static const routeName = '/mainPage';
  LoginUser loginUser;
  HomePage(this.loginUser);
  @override
  _HomePageState createState() => new _HomePageState(loginUser);
}

class _HomePageState extends State<HomePage> {
    GoogleSignInAccount _currentUser;

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

   String userNameSet(String uname){
    return  """<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"
       xmlns:urn=\"urn:sap-com:document:sap:rfc:functions\"> 
     <soapenv:Header/> <soapenv:Body> <urn:ZCRM_WS_RECORDS> 
     <!--Optional:--> <IV_UNAME>$uname</IV_UNAME></urn:ZCRM_WS_RECORDS></soapenv:Body></soapenv:Envelope>""";
  }

  var refreshKey = GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {

      _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      setState(() {
        _currentUser = account;
      });
      print('Change Sign in: $account');
    });

    super.initState();
    recordTypeList2.clear();
    recordTypeList.clear();
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
          new IconButton(
            icon: new Icon(Icons.time_to_leave), 
            onPressed: _handleSignOut
            )
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


    Future<void> _handleSignOut() async {
    _googleSignIn.disconnect();

    setLoginStatus(false);
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
          ModalRoute.withName(LoginPage.routeName));

  
  }

  void setLoginStatus(bool login) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool("login", login);
    prefs.setString("userName", '');
    prefs.setString("uname", '');

       print(
        "login set status -> $login , userName -> null, uname -> null ");
  }
  Future<Null> refreshList() async {
    recordList.clear();
    recordTypeList.clear();
    recordTypeList2.clear();

    refreshKey.currentState?.show(atTop: false);

   envelope = userNameSet(loginUser.userName);
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
          if (element.onayDurum == "1") {
            if (!map.containsKey("Onay Beklenen|Onay"))
              map["Onay Beklenen|Onay"] = 1;
            else {
              map["Onay Beklenen|Onay"] += 1;
            }
          } else if (element.onayDurum == "2") {
            if (!map.containsKey("Paslanma Istegi|Paslama"))
              map["Paslanma Istegi|Paslama"] = 1;
            else {
              map["Paslanma Istegi|Paslama"] += 1;
            }
          } else if (!map
              .containsKey(element.recordType + "|" + element.recordDecs)) {
            map[element.recordType + "|" + element.recordDecs] = 1;
          } else if (map
              .containsKey(element.recordType + "|" + element.recordDecs)) {
            map[element.recordType + "|" + element.recordDecs] += 1;
          }
        });

        map.forEach((k, v) => recordTypeList.add(RecordTypes(k, k, v)));

        recordTypeList.sort((a, b) => a.count.compareTo(b.count));
        recordTypeList2.clear();

        for (int i = recordTypeList.length; i > 0; i--) {
          String onayDurumu = "0";

          if (recordTypeList[i - 1].typeDesc.contains("Onay")) {
            onayDurumu = "1";
          } else if (recordTypeList[i - 1].typeDesc.contains("Paslama")) {
            onayDurumu = "2";
          }

          recordTypeList2.add(RecordTypes.overloadedContructor(
              recordTypeList[i - 1].typeName,
              recordTypeList[i - 1].typeDesc,
              onayDurumu,
              recordTypeList[i - 1].count));
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

      return true;

    //return prefs.commit();
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

    if (item.typeDesc == "Onay") {
      p = 1;
    } else if (item.typeDesc == "Paslama") {
      p = 2;
    }

    if (p == 1 || p == 2) {
      recordList.forEach((f) {
        if ((f.onayDurum == p.toString())) {
          for (int i = 0; i < recordList2.length; i++) {
            if (recordList2[i].recordID == f.recordID &&
                recordList2[i].itemID == f.itemID) {
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
        if (f.recordType.contains(item.typeName.toString())) {
          if (f.onayDurum.toString() != "1" && f.onayDurum.toString() != "2") {
            for (int i = 0; i < recordList2.length; i++) {
              if (recordList2[i].recordID == f.recordID &&
                  recordList2[i].itemID == f.itemID) {
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

    //final newList = [];

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
              item.typeDesc,
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
              item.count.toString(),
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
              item.typeDesc.toString(),
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        )
      ],
    );
  }


}


