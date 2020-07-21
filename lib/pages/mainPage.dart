import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kits/classes/Choice.dart';
import 'package:kits/classes/LoginUser.dart';
import 'package:kits/classes/NewRecordType.dart';
import 'package:kits/classes/RecordTypes.dart';
import 'package:kits/classes/Records.dart';
import 'package:kits/classes/ScreenArgument.dart';
import 'package:http/http.dart' as http;
import 'package:kits/classes/ScreenArgumentDetail.dart';
import 'package:kits/classes/User.dart';
//import 'package:kits/pages/list.dart';
import 'package:kits/pages/login.dart';
import 'package:kits/pages/paslaPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart' as xml;

const Color backGrountGrey = Colors.white;

///Color.fromRGBO(239, 244, 249, 100);
const Color bottomColor =
    Color.fromRGBO(239, 244, 249, 100); //Color.fromRGBO(158, 199, 216, 100);
const String listeName = "List";
const String gridName = "Grid";

List<Records> recordList = List();
List<RecordTypes> recordTypeList = List();
List<RecordTypes> recordTypeList2 = List();
var envelope;
var map = Map();
LoginUser loginUser;
String _selectedTypeList = 'Grid';
var refreshKey = GlobalKey<RefreshIndicatorState>();
GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['profile', 'email']);

bool boolLongClicked = false;

class MyHomePage extends StatefulWidget {
  final controller = ScrollController();
  static const routeName = '/mainPage2';
  LoginUser loginUser;

  MyHomePage(this.loginUser);
  @override
  _MyHomePageState createState() => new _MyHomePageState(loginUser);
}

class Debouncer {
  final int milliseconds;
  VoidCallback action;
  Timer _timer;

  Debouncer({this.milliseconds});

  run(VoidCallback action) {
    if (null != _timer) {
      _timer.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  List<User> user = new List();
List<User> user2 = new List();

  List<Records> filteredRecords = List();
  List<NewRecordType> newRecordList = List();
  List<NewRecordType> newRecordList2 = List();

  bool isDataRequested = false;

  List<NewRecordType> newPaslaOnayList = List();
  List<NewRecordType> newPaslaOnayLis2 = List();

  final _debouncer = Debouncer(milliseconds: 200);
  int _page = 1;
  Choice _selectedChoice = choices[0];
  LoginUser loginUser;
  _MyHomePageState(this.loginUser);
  GoogleSignInAccount _currentUser;
  GlobalKey _bottomNavigationKey = GlobalKey();

  void _select(Choice choice) {
    // Causes the app to rebuild with the new _selectedChoice.
    setState(() {
      _selectedChoice = choice;
    });
    if (_selectedChoice.id == 'exit') {
      //çıkış yapar

      _showMyDialog();
      //_handleSignOut();
    }
  }

  @override
  void initState() {
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      setState(() {
        _currentUser = account;
      });
      print('Change Sign in: $account');
    });

    getUsers();
    refreshList();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: appBar(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _page,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                title: Text("Dasboard"),
                backgroundColor: Colors.blue),
            BottomNavigationBarItem(
                icon: Icon(Icons.list),
                title: Text("Belgeler"),
                backgroundColor: Colors.blue),
            BottomNavigationBarItem(
                icon: Icon(Icons.exit_to_app),
                title: Text("Pas & Onay"),
                backgroundColor: Colors.blue),
          ],
          onTap: (index) {
            setState(() {
              _page = index;    

              //test
            });
          },
        ),
        body: screens(_page, _selectedTypeList));
  }

  //* Ekranlar arasında geçiş yapılacak bölüm.
  Widget screens(int index, String type) {
    if (index == 0) {
      return firstPage();
    } else if (index == 1) {
      // list page
      return secondPageList();
    } else {
      // bu paslama veya paslanan belgeleri gösterir.
      return paslamaPage();
      // return Text("sayfa " + index.toString());
    }
  }

  Widget paslamaPage() {
    return RefreshIndicator(
      key: refreshKey,
      child: Container(
        color: backGrountGrey,
        child: Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                Expanded(
                  child: ListView.builder(
                    itemCount: newPaslaOnayLis2.length,
                    itemBuilder: (context, i) {
                      return new ExpansionTile(
                        title: new Text(
                          newPaslaOnayLis2[i].recordId +
                              " - (" +
                              newPaslaOnayLis2[i].records.length.toString() +
                              ")",
                          style: new TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        children: <Widget>[
                          new Column(
                            children: _buildExpandableContentPasla(
                                newPaslaOnayLis2[i]),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            )
          ],
        ),
      ),
      onRefresh: refreshList,
    );
  }

  Future<Null> getUsers() async {
    var envelope2 =
        "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" "
        "xmlns:urn=\"urn:sap-com:document:sap:rfc:functions\"><soapenv:Header/><soapenv:Body>"
        "<urn:ZKITS_USER/></soapenv:Body></soapenv:Envelope>";

    http.Response response = await http.post(
        'http://crm.technova.com.tr:8001/sap/bc/srt/rfc/sap/zkits_user/100/zkits_user/zuser_kits',
        headers: {
          "Content-Type": "text/xml; charset=utf-8",
          "SOAPAction":
              "urn:sap-com:document:sap:rfc:functions:zkits_user:ZKITS_USERRequest",
          "Host": "crm.technova.com.tr:8001",
        },
        body: envelope2);
    var _response = response.body;
    List<User> user2 = new List();
    user2 = await _parsing2(_response);

    setState(() {
      this.user = user2;
    });

    return null;
  }

  Future _parsing2(var _response) async {
    //pr.show();
    await Future.delayed(Duration(seconds: 1));
    var _document = xml.parse(_response);

    Iterable<xml.XmlElement> items = _document.findAllElements('item');

    if (items.length > 0) {
      items.map((xml.XmlElement item) {
        var userID = getValue(item.findElements("UNAME"));
        var userName = getValue(item.findElements("USER_FULLNAME"));

        user.add(User(userID, userName));
      }).toList();
    }

    // pr.hide();
    return user;
  }

  Widget firstPage() {
    return Text("test");
  }

  Widget secondPageList() {
    return RefreshIndicator(
        key: refreshKey,
        child: Container(
          color: backGrountGrey,
          child: Stack(
            children: <Widget>[
              Column(
                children: <Widget>[
                  Expanded(
                    child: ListView.builder(
                      itemCount: newRecordList2.length,
                      itemBuilder: (context, i) {
                        return new ExpansionTile(
                          title: new Text(
                            newRecordList2[i].recordId +
                                " - " +
                                newRecordList2[i].type,
                            style: new TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          children: <Widget>[
                            new Column(
                              children:
                                  _buildExpandableContent(newRecordList2[i]),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
        onRefresh: refreshList);
  }

  _buildExpandableContent(NewRecordType newRecordType) {
    List<Widget> columnContent = [];

    for (Records record in newRecordType.records)
      columnContent.add(ListTile(
          dense: true,
          isThreeLine: false,
          enabled: true,
          onTap: () => _recordLongClick(context, record),
          // onLongPress: () => _recordLongClick(context),
          subtitle: new Text(record.itemID),
          leading: new Text(record.recordID),
          selected: true,
          trailing: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(record.recordDate),
              Text(record.recordTime)
            ],
          ),
          title: new Text(record.recordDecs)));

    return columnContent;
  }

  _buildExpandableContentPasla(NewRecordType newRecordType) {
    List<Widget> columnContent = [];

    for (Records record in newRecordType.records)
      columnContent.add(ListTile(
          dense: true,
          isThreeLine: false,
          enabled: true,
          onTap: () => _recordLongPasla(context, record, newRecordType.type),
          // onLongPress: () => _recordLongClick(context),
          subtitle: new Text(record.itemID),
          leading: new Text(record.recordID),
          selected: true,
          trailing: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(record.recordDate),
              Text(record.recordTime)
            ],
          ),
          title: new Text(record.recordDecs)));

    return columnContent;
  }

  Future<Null> refreshList() async {
    print("refrest edildi.");

    // refreshKey.currentState?.show(atTop: false);

    envelope = userNameSet(loginUser.userName);

    try {
      http.Response response = await http.post(
          'http://crm.technova.com.tr:8001/sap/bc/srt/rfc/sap/zkits_ws_records/100/zkits_ws_records/zkits_ws_records',
          headers: {
            "Content-Type": "text/xml; charset=UTF-8",
            "SOAPAction":
                "urn:sap-com:document:sap:rfc:functions:zkits_ws_records:ZCRM_WS_RECORDSRequest",
            "Host": "crm.technova.com.tr:8001"
          },
          body: envelope);

      if (response.statusCode == 200) {
        var _response = response.body;

        await _parsing(_response);
      }
    } catch (exception) {
      print("hataaaaaaaaaaa " + exception);
    }

    setState(() {});

    return null;
  }

  Future _parsing(var _response) async {
    refreshKey.currentState.show(atTop: false);
    await Future.delayed(Duration(seconds: 2));
    var _document = xml.parse(_response);

//clears
    recordList.clear();
    filteredRecords.clear();
    recordList.clear();
    recordTypeList.clear();
    recordTypeList2.clear();
    newRecordList.clear();
//clears

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

      NewRecordType tmpPasla = new NewRecordType();
      NewRecordType tmpOnay = new NewRecordType();
      List<NewRecordType> tmpList2 = List();
      for (var i = 0; i < recordList.length; i++) {
        if (recordList[i].onayDurum == '0') {
          filteredRecords.add(recordList[i]);
        } else if (recordList[i].onayDurum == '1') {
          tmpOnay.recordId = 'Size paslanmak istenen belgeler';
          tmpOnay.records.add(recordList[i]);
          tmpOnay.type = 'ONAY';
          //tmpOnay.type = recordList[i].recordType;
        } else if (recordList[i].onayDurum == '2') {
          tmpPasla.recordId = 'Onaylanmak üzere paslanan belgeler';
          tmpPasla.records.add(recordList[i]);
        }
      }
      tmpOnay.type = 'ONAY';
      tmpPasla.type = 'PASLA';
      tmpList2.add(tmpOnay);
      tmpList2.add(tmpPasla);

      newPaslaOnayList = tmpList2;
      newPaslaOnayLis2 = newPaslaOnayList;

      NewRecordType tmpList = new NewRecordType();
      List<NewRecordType> liste = List();

      for (var i = 0; i < filteredRecords.length; i++) {
        tmpList = new NewRecordType();
        if (filteredRecords[i].itemID == '0000000000') {
          tmpList.recordId = filteredRecords[i].recordID;
          tmpList.records.add(filteredRecords[i]);
          tmpList.type = filteredRecords[i].recordType;

          for (var j = 0; j < filteredRecords.length; j++) {
            if (filteredRecords[i].recordID == filteredRecords[j].recordID &&
                filteredRecords[i].itemID != filteredRecords[j].itemID) {
              tmpList.records.add(filteredRecords[j]);
            }
          }
          liste.add(tmpList);
          tmpList = null;
        }
      }
      newRecordList = liste;
      newRecordList2 = newRecordList;
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

  Icon cusIcon = Icon(Icons.search);
  Widget cusSearchBar = Text("CRM & Technova");

  Widget appBar() {
    return AppBar(
      actions: <Widget>[
        IconButton(
            icon: cusIcon,
            onPressed: () {
              setState(() {
                if (this.cusIcon.icon == Icons.search) {
                  this.cusIcon = Icon(Icons.cancel);
                  this.cusSearchBar = TextField(
                    textInputAction: TextInputAction.go,
                    decoration: InputDecoration(
                      hintStyle:
                          TextStyle(fontSize: 20.0, color: Colors.white54),
                      contentPadding: EdgeInsets.all(3.0),
                      hintText: 'Belge tipi veya numarasını giriniz.',
                      border: InputBorder.none,
                    ),
                    autofocus: true,
                    onChanged: (string) {
                      _debouncer.run(() {
                        setState(() {
                          newRecordList2 = newRecordList
                              .where((u) => (u.recordId
                                      .toLowerCase()
                                      .contains(string.toLowerCase()) ||
                                  u.type
                                      .toLowerCase()
                                      .contains(string.toLowerCase())))
                              .toList();
                        });
                      });
                    },
                    style: TextStyle(color: Colors.white, fontSize: 20.0),
                  );
                } else {
                  this.cusIcon = Icon(Icons.search);
                  cusSearchBar = Text("CRM & Technova");
                }
              });
            }),
        PopupMenuButton<Choice>(
          onSelected: _select,
          itemBuilder: (BuildContext context) {
            return choices.skip(0).map((Choice choice) {
              return PopupMenuItem<Choice>(
                value: choice,
                child: Text(choice.title),
              );
            }).toList();
          },
        ),
      ],
      title: cusSearchBar,
    );
  }

  Widget _buildItemCardChild(RecordTypes item) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Flexible(
              child: RichText(
                overflow: TextOverflow.fade,
                strutStyle: StrutStyle(fontSize: 10.0),
                text: TextSpan(
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                    text: item.getTypeDesc),
              ),
            ),
            Container(
              width: 1.0,
              height: 1.0,
              color: Colors.white,
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

  String userNameSet(String uname) {
    return """<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"
                          xmlns:urn=\"urn:sap-com:document:sap:rfc:functions\"> 
                        <soapenv:Header/> <soapenv:Body> <urn:ZCRM_WS_RECORDS> 
                        <!--Optional:--> <IV_UNAME>$uname</IV_UNAME></urn:ZCRM_WS_RECORDS></soapenv:Body></soapenv:Envelope>""";
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

    print("login set status -> $login , userName -> null, uname -> null ");
  }

  void _recordLongPasla(context, Records record, String type) {
    showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        builder: (BuildContext bc) {
          if (type == 'ONAY') {
            return Container(
              decoration: new BoxDecoration(
                  color: Colors.white,
                  borderRadius: new BorderRadius.only(
                      topLeft: const Radius.circular(10.0),
                      topRight: const Radius.circular(10.0))),
              child: new Wrap(
                children: <Widget>[
                  Center(
                    child: Container(
                      margin: new EdgeInsets.all(10.0),
                      child: new Text(record.userName +
                          ' ' +
                          record.recordID +
                          " numaralı belge"),
                    ),
                  ),
                  new ListTile(
                      leading: new Icon(
                        Icons.add,
                        color: Colors.green,
                      ),
                      title: new Text("Onayla"),
                      onTap: () {
                        print("tabbed detail");

                        paslaOnayRed(record, "X");
                        Navigator.pop(context);
                        setState(() {});
                      }),
                  new ListTile(
                      leading: new Icon(
                        Icons.cancel,
                        color: Colors.redAccent,
                      ),
                      title: new Text("Reddet"),
                      onTap: () {
                        print("tabbed detail");
                        paslaOnayRed(record, "");
                        Navigator.pop(context);
                        setState(() {});
                      }),
                ],
              ),
            );
          } else {
            return Container(
              decoration: new BoxDecoration(
                  color: Colors.white,
                  borderRadius: new BorderRadius.only(
                      topLeft: const Radius.circular(10.0),
                      topRight: const Radius.circular(10.0))),
              child: new Wrap(
                children: <Widget>[
                  Center(
                    child: Container(
                      margin: new EdgeInsets.all(10.0),
                      child: new Text(record.ysorumlu +
                          ' ' +
                          record.recordID +
                          " numaralı belge"),
                    ),
                  ),
                  new ListTile(
                      leading: new Icon(
                        Icons.backspace,
                        color: Colors.lightBlue,
                      ),
                      title: new Text("Geri Çek"),
                      onTap: () {
                        print("tabbed detail");
                        Navigator.pop(context);
                        setState(() {});
                      }),
                ],
              ),
            );
          }
        });
  }

  void _recordLongClick(context, Records record) {
    showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        builder: (BuildContext bc) {
          return Container(
            decoration: new BoxDecoration(
                color: Colors.white,
                borderRadius: new BorderRadius.only(
                    topLeft: const Radius.circular(10.0),
                    topRight: const Radius.circular(10.0))),
            child: new Wrap(
              children: <Widget>[
                Center(
                  child: Container(
                    margin: new EdgeInsets.all(10.0),
                    child: new Text(record.recordID + " numaralı belge"),
                  ),
                ),
                new ListTile(
                    leading: new Icon(
                      Icons.details,
                      color: Colors.blue,
                    ),
                    title: new Text("Detay Göster"),
                    onTap: () {
                      print("tabbed detail");
                      Navigator.pop(context);
                      setState(() {});
                    }),
                new ListTile(
                  leading: new Icon(
                    Icons.send,
                    color: Colors.cyan,
                  ),
                  title: new Text("Paslama"),
                  onTap: () {
                    
                    for(var i = 0 ; i < user.length ; i++){
                      if(user[i].userID != loginUser.userName){
                        user2.add(user[i]);
                      }
                    }

                    ScreenArgumentsDetail detail = ScreenArgumentsDetail(
                        record.recordID,
                        record.itemID,
                        record.recordType,
                        record.userName,
                        record.recordDate,
                        record.recordTime,
                        user2,
                        record.description);
                    print("tabbed pasla");
                    Navigator.pop(context);
                    Navigator.of(context)
                        .pushNamed(DetailPage.routeName, arguments: detail);
                    setState(() {});
                  },
                ),
                new ListTile(
                    leading: new Icon(
                      Icons.do_not_disturb,
                      color: Colors.lime,
                    ),
                    title: new Text("İgnore et"),
                    onTap: () {
                      print("tabbed detail");
                      Navigator.pop(context);
                      setState(() {});
                    }),
              ],
            ),
          );
        });
  }

  clickObject(String index) {
    print("clicked {$index}");
  }

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Çıkış yapılıyor'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Uygulamadan çıkış yapmak istiyor musunuz?'),
              ],
            ),
          ),
          actions: <Widget>[
            FlatButton(
              child: Text('Hayır'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            FlatButton(
              child: Text('Çıkış yap'),
              onPressed: () {
                Navigator.of(context).pop();
                _handleSignOut();
              },
            ),
          ],
        );
      },
    );
  }

  paslaOnayRed(Records record, String durum) {
    wsPaslaSonuc(record.userName, record.itemID, record.recordID,
        record.recordType, durum);
  }

  void wsPaslaSonuc(String eSorumlu, String item, String objectID,
      String recordType, String result) {
    var wsOnay = """ 
    <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:sap-com:document:sap:rfc:functions">
   <soapenv:Header/>
   <soapenv:Body>
      <urn:ZKITS_ROUTE>
         <!--Optional:-->
         <IV_ESORUMLU>$eSorumlu</IV_ESORUMLU>
         <!--Optional:-->
         <IV_KALEMID>$item</IV_KALEMID>
         <!--Optional:-->
         <IV_OBJECTID>$objectID</IV_OBJECTID>
         <!--Optional:-->
         <IV_RECORDTYPE>$recordType</IV_RECORDTYPE>
         <!--Optional:-->
         <IV_RESULT>$result</IV_RESULT>
      </urn:ZKITS_ROUTE>
   </soapenv:Body>
</soapenv:Envelope>""";

    wsPaslaRequest(wsOnay, context);
  }

  void _showToast(BuildContext context,String result,String text) {


      Color x ;
      if(result == 'X'){
          x = Colors.green; 
      }
      else{
          x = Colors.red;
      }
    Fluttertoast.showToast(
        msg: text,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIos: 1,
        backgroundColor: x,
        textColor: Colors.white,
        fontSize: 16.0
    );
  }

  Future<Null> wsPaslaRequest(var envelope, BuildContext context) async {
    http.Response response = await http.post(
        'http://crm.technova.com.tr:8001/sap/bc/srt/rfc/sap/zkits_ws_route/100/zkits_ws_route/zkits_ws_route',
        headers: {
          "Content-Type": "text/xml;charset=UTF-8",
          "SOAPAction":
              "urn:sap-com:document:sap:rfc:functions:zkits_ws_route:ZKITS_ROUTERequest",
          "Host": "crm.technova.com.tr:8001"
        },
        body: envelope);
    var _response = response.body;

    await _parsingOnay(_response, context);

    setState(() {});

    return null;
  }

  Future _parsingOnay(var _response, BuildContext context) async {
    await Future.delayed(Duration(seconds: 1));
    var _document = xml.parse(_response);

    final sonuc =
        _document.findAllElements('EV_SONUC').map((node) => node.text);
    final sonucDesc =
        _document.findAllElements('EV_SONUC_DESC').map((node) => node.text);

    if (sonuc.contains("X")) {
      print("ok -> " + sonucDesc.toString());

      _showToast(context,'X',sonucDesc.toString());
    } else {
      print("fail -> " + sonucDesc.toString());
        _showToast(context,'', sonucDesc.toString());
    }
    refreshList();
    return null;
  }
}

const List<Choice> choices = const <Choice>[
  const Choice(id: 'noti', title: 'Bildirimler', icon: Icons.notifications),
  const Choice(id: 'exit', title: 'Çıkış yap', icon: Icons.notifications)
];
