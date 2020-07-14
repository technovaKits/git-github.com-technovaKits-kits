import 'dart:async';

import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kits/classes/LoginUser.dart';
import 'package:kits/classes/RecordTypes.dart';
import 'package:kits/classes/Records.dart';
import 'package:kits/classes/ScreenArgument.dart';
import 'package:http/http.dart' as http;
import 'package:kits/pages/list.dart';
import 'package:kits/pages/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart' as xml;

const Color backGrountGrey = Color.fromRGBO(239, 244, 249, 100);
const Color bottomColor = Color.fromRGBO(158, 199, 216, 100);
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
  List<Records> filteredRecords = List();
  final _debouncer = Debouncer(milliseconds: 500);
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
      _handleSignOut();
    } else if (_selectedChoice.id == 'type') {
      _settingModalBottomSheet(context);
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

    refreshList();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: appBar(),
        bottomNavigationBar: CurvedNavigationBar(
          key: _bottomNavigationKey,
          index: 1,
          height: 50.0,
          items: <Widget>[
            Icon(Icons.dashboard, size: 25),
            Icon(Icons.list, size: 25),
            Icon(Icons.compare_arrows, size: 25)
          ],
          color: Colors.white,
          buttonBackgroundColor: Colors.white,
          backgroundColor: backGrountGrey,
          animationCurve: Curves.easeInOutCubic,
          animationDuration: Duration(milliseconds: 100),
          onTap: (index) {
            setState(() {
              _page = index;
            });
          },
        ),
        body: screens(_page, _selectedTypeList));
  }

  //* Ekranlar arasında geçiş yapılacak bölüm.
  Widget screens(int index, String type) {
    if (index == 0) {
      return firstPage();
    } else if (index == 1 && type == 'List') {
      // list page
      return secondPageList();
    } else if (type == 'Grid' && index == 1) {
      return secondPageGrid();
    } else {
      return Text("sayfa " + index.toString());
    }
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
                      padding: EdgeInsets.all(10.0),
                      itemCount: filteredRecords.length,
                      itemBuilder: (BuildContext context, int index) {
                        return GestureDetector(
                            onTap: () => clickObject(index),
                            onLongPress: () {
                              print("long press");
                              setState(() {
                                if (filteredRecords[index].isSelected == true) {
                                  filteredRecords[index].isSelected = false;
                                } else {
                                  filteredRecords[index].isSelected = true;
                                }
                              });
                            },
                            child: Card(
                              color: filteredRecords[index].isSelected
                                  ? Colors.grey[300]
                                  : Colors.white,
                              child: Padding(
                                padding: EdgeInsets.all(10.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      filteredRecords[index].recordID,
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.black,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 5.0,
                                    ),
                                    Text(
                                      filteredRecords[index].recordType,
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ));
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

  Widget secondPageGrid() {
    return RefreshIndicator(
      key: refreshKey,
      child: Container(
        color: backGrountGrey,
        padding: EdgeInsets.only(top: 16),
        child: Stack(
          children: <Widget>[
            _buildCardsList(),
          ],
        ),
      ),
      onRefresh: refreshList,
    );
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

  Future<Null> refreshList() async {
    print("refrest edildi.");
    filteredRecords.clear();
    recordList.clear();
    recordTypeList.clear();
    recordTypeList2.clear();

    // refreshKey.currentState?.show(atTop: false);

    envelope = userNameSet("eaydin");

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
      var _response = response.body;

      await _parsing(_response);
    } catch (exception) {
      print(exception);
    }

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

      for (var i = 0; i < recordList.length; i++) {
        if (recordList[i].onayDurum == '0') {
          filteredRecords.add(recordList[i]);
        }
      }

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
              borderRadius: BorderRadius.all(Radius.circular(10)),
              boxShadow: [
                BoxShadow(color: map[item.onayDurumu], blurRadius: 1.5)
              ]),
          child: _buildItemCardChild(item),
        ));
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
                       hintStyle: TextStyle(fontSize: 20.0, color: Colors.white54),
                      contentPadding: EdgeInsets.all(3.0),
                      hintText: 'Belge tipi veya numarasını giriniz.',
                      border: InputBorder.none,
                    ),
                    onChanged: (string) {
                      _debouncer.run(() {
                        setState(() {
                          filteredRecords = recordList
                              .where((u) => (u.recordType
                                      .toLowerCase()
                                      .contains(string.toLowerCase()) ||
                                  u.recordID
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

  void _settingModalBottomSheet(context) {
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            decoration: BoxDecoration(color: Colors.transparent),
            child: new Wrap(
              children: <Widget>[
                new ListTile(
                    leading: new Icon(Icons.list),
                    title: new Text(listeName),
                    onTap: () {
                      print("tabbed list view");
                      Navigator.pop(context);
                      setState(() {
                        _selectedTypeList = listeName;
                      });
                    }),
                new ListTile(
                  leading: new Icon(Icons.grid_on),
                  title: new Text(gridName),
                  onTap: () {
                    print("tabbed grid view");
                    Navigator.pop(context);
                    setState(() {
                      _selectedTypeList = gridName;
                    });
                  },
                ),
              ],
            ),
          );
        });
  }

  clickObject(int index) {
    print("clicked {$index}");
  }
  
}

class Choice {
  const Choice({this.id, this.title, this.icon});

  final String id;
  final String title;
  final IconData icon;
}

const List<Choice> choices = const <Choice>[
  const Choice(id: 'type', title: 'Liste Tipi', icon: Icons.list),
  const Choice(id: 'noti', title: 'Bildirimler', icon: Icons.notifications),
  const Choice(id: 'exit', title: 'Çıkış yap', icon: Icons.notifications)
];
