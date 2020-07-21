import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:kits/pages/paslaPage.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:xml/xml.dart' as xml;
import 'package:kits/classes/Records.dart';
import 'package:kits/classes/ScreenArgument.dart';
import 'package:kits/classes/ScreenArgumentDetail.dart';
import 'package:kits/classes/User.dart';

class ListPage extends StatefulWidget {
  // ignore: prefer_const_constructors_in_immutables
  static const routeName = '/listPage';

  @override
  _ListPage createState() => _ListPage();
}

class _ListPage extends State<ListPage> {
  ProgressDialog pr;

  List<User> user = new List();

  User selectedUser = new User("1", "Emre");

  var envelope =
      "<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\" "
      "xmlns:urn=\"urn:sap-com:document:sap:rfc:functions\"><soapenv:Header/><soapenv:Body>"
      "<urn:ZKITS_USER/></soapenv:Body></soapenv:Envelope>";

  @override
  void initState() {
    super.initState();
    getUsers();
  }

  Future<Null> getUsers() async {
    http.Response response = await http.post(
        'http://crm.technova.com.tr:8001/sap/bc/srt/rfc/sap/zkits_user/100/zkits_user/zuser_kits',
        headers: {
          "Content-Type": "text/xml; charset=utf-8",
          "SOAPAction":
              "urn:sap-com:document:sap:rfc:functions:zkits_user:ZKITS_USERRequest",
          "Host": "crm.technova.com.tr:8001",
        },
        body: envelope);
    var _response = response.body;
    List<User> user2 = new List();
    user2 = await _parsing(_response);

    setState(() {
      this.user = user2;
    });

    return null;
  }

  getValue(Iterable<xml.XmlElement> items) {
    var textValue;
    items.map((xml.XmlElement node) {
      textValue = node.text;
    }).toList();
    return textValue;
  }

  Future _parsing(var _response) async {
    pr.show();
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

    pr.hide();
    return user;
  }

  paslaDialogBox(Records record, List<User> user) {
    ScreenArgumentsDetail detail = ScreenArgumentsDetail(
        record.recordID,
        record.itemID,
        record.recordType,
        record.userName,
        record.recordDate,
        record.recordTime,
        user,
        record.description);

    Navigator.of(context).pushNamed(DetailPage.routeName, arguments: detail);
  }

  Widget _myListView(BuildContext context, ScreenArguments args) {
    pr = new ProgressDialog(context);
    pr.style(
        message: 'Yükleniyor...',
        borderRadius: 10.0,
        backgroundColor: Colors.white,
        progressWidget: CircularProgressIndicator(),
        elevation: 10.0,
        insetAnimCurve: Curves.easeInOut,
        progress: 0.0,
        maxProgress: 100.0,
        progressTextStyle: TextStyle(
            color: Colors.black, fontSize: 13.0, fontWeight: FontWeight.w400),
        messageTextStyle: TextStyle(
            color: Colors.black, fontSize: 19.0, fontWeight: FontWeight.w600));

    return ListView.builder(
      padding: EdgeInsets.only(top: 0),
      itemCount: args.recordList.length,
      itemBuilder: (context, index) {
        return new Slidable(
          delegate: new SlidableDrawerDelegate(),
          actionExtentRatio: 0.2,
          closeOnScroll: true,
          child: new Container(
            color: Colors.white,
            child: new Card(
              elevation: 2.2,
              color: Colors.white,
              shape: Border(
                right: BorderSide(color: Colors.redAccent, width: 3),
                left: BorderSide(color: Colors.green, width: 3),
              ),
              margin:
                  const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
              child: new Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  new Container(
                    margin: const EdgeInsets.only(right: 2.0),
                    width: 100.0,
                    height: 80.0,
                    child: Container(
                      height: 100,
                      child: Icon(
                        Icons.event_note,
                        color: Colors.amber,
                        size: 24.0,
                        semanticLabel:
                            'Text to announce in accessibility modes',
                      ), //BoxDecoration
                    ), //
                  ),
                  new Expanded(
                    child: new Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        new Row(
                          children: <Widget>[
                            new Expanded(
                              child: new Container(
                                margin: const EdgeInsets.only(
                                    top: 12.0, bottom: 10.0),
                                child: new Text(
                                  args.recordList[index].recordID,
                                  style: new TextStyle(
                                    fontSize: 18.0,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            new Column(
                              children: <Widget>[
                                new Container(
                                  margin: const EdgeInsets.only(right: 10.0),
                                  child: new Text(
                                    args.recordList[index].recordDate,
                                    style: new TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600]),
                                  ),
                                ),
                                new Container(
                                  margin: const EdgeInsets.only(right: 10.0),
                                  child: new Text(
                                    args.recordList[index].recordTime,
                                    style: new TextStyle(
                                        fontSize: 13.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[600]),
                                  ),
                                ),
                                new Container(
                                  margin: const EdgeInsets.only(right: 10.0),
                                  child: new Text(
                                    args.recordList[index].recordType,
                                    style: new TextStyle(
                                        fontSize: 13.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepPurpleAccent),
                                  ),
                                ),
                                new Container(
                                  margin: const EdgeInsets.only(right: 10.0),
                                  child: new Text(
                                    args.recordList[index].userName,
                                    style: new TextStyle(
                                        fontSize: 11.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.greenAccent),
                                  ),
                                ),
                                new Container(
                                  margin: const EdgeInsets.only(right: 10.0),
                                  child: new Text(
                                    args.recordList[index].itemID,
                                    style: new TextStyle(
                                        fontSize: 11.0,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepOrangeAccent),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                        new Container(
                          margin: const EdgeInsets.only(right: 10.0),
                          child: new Text(
                            args.recordList[index].description,
                            style: new TextStyle(
                              fontSize: 16.0,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            actionLeft(args, index, user),
          ],
          secondaryActions: <Widget>[
            actionRight(args, index, user),
          ],
        );
      },
    );
  }

  Widget tittleSet(ScreenArguments args) {
    if (args.recordList[0].onayDurum == "0") {
      return Text(args.recordList[0].recordDecs +
          " (" +
          args.recordList.length.toString() +
          ")");
    } else {
      var desc;
      if (args.recordList[0].onayDurum == "1") {
        desc = "Onay Listesi";
      } else if (args.recordList[0].onayDurum == "2") {
        desc = "Pasladıklarımın Listesi";
      }
      return Text(desc + " (" + args.recordList.length.toString() + ")");
    }
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

  Future _parsingOnay(var _response, BuildContext context) async {
    pr = new ProgressDialog(context);
    pr.style(
        message: 'İşleniyor...',
        borderRadius: 10.0,
        backgroundColor: Colors.white,
        progressWidget: CircularProgressIndicator(),
        elevation: 10.0,
        insetAnimCurve: Curves.easeInOut,
        progress: 0.0,
        maxProgress: 100.0,
        progressTextStyle: TextStyle(
            color: Colors.black, fontSize: 13.0, fontWeight: FontWeight.w400),
        messageTextStyle: TextStyle(
            color: Colors.black, fontSize: 19.0, fontWeight: FontWeight.w600));
    pr.show();

    await Future.delayed(Duration(seconds: 1));
    var _document = xml.parse(_response);

    final sonuc =
        _document.findAllElements('EV_SONUC').map((node) => node.text);
    final sonucDesc =
        _document.findAllElements('EV_SONUC_DESC').map((node) => node.text);

    if (sonuc.contains("X")) {
      Fluttertoast.showToast(
          msg: sonucDesc.toString(),
          gravity: ToastGravity.CENTER,
          timeInSecForIos: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0);
    } else {
      Fluttertoast.showToast(
          msg: sonucDesc.toString(),
          gravity: ToastGravity.CENTER,
          timeInSecForIos: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    }

    pr.hide();

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ScreenArguments args = ModalRoute.of(context).settings.arguments;

    return new Scaffold(
      appBar: new AppBar(
        title: tittleSet(args),
      ),
      body: Container(
        padding: EdgeInsets.only(top: 5),
        child: Stack(
          children: <Widget>[
            _myListView(context, args),
          ],
        ),
      ),
    );
  }

  actionLeft(ScreenArguments args, int index, List<User> user) {
    if (args.recordList[index].onayDurum == "2") {
      return new IconSlideAction(
        caption: 'İptal',
        foregroundColor: Colors.white,
        color: Colors.redAccent,
        icon: Icons.cancel,
        onTap: () => print("İptal"),
      );
    } else if (args.recordList[index].onayDurum == "1") {
      return new IconSlideAction(
        caption: 'Onay',
        foregroundColor: Colors.white,
        color: Colors.green,
        icon: Icons.send,
        onTap: () => paslaOnayRed(args, index, "X"),
      );
    } else if (args.recordList[index].onayDurum == "0") {
      return new IconSlideAction(
        caption: 'Pasla',
        foregroundColor: Colors.white,
        color: Colors.blue,
        icon: Icons.send,
        onTap: () => paslaDialogBox(args.recordList[index], user),
      );
    }
  }

  actionRight(ScreenArguments args, int index, List<User> user) {
    if (args.recordList[index].onayDurum == "1") {
      return new IconSlideAction(
        caption: 'Red',
        foregroundColor: Colors.white,
        color: Colors.redAccent,
        icon: Icons.clear,
        onTap: () => paslaOnayRed(args, index, ""),
      );
    } else if (args.recordList[index].onayDurum == "0") {
      return new IconSlideAction(
        caption: 'Göster',
        foregroundColor: Colors.white,
        color: Colors.amberAccent,
        icon: Icons.pageview,
        onTap: () => print("View"),
      );
    } else if (args.recordList[index].onayDurum == "2") {
      return new IconSlideAction(
        caption: 'Görüntüle',
        foregroundColor: Colors.white,
        color: Colors.amberAccent,
        icon: Icons.pageview,
        onTap: () => print("View"),
      );
    }
  }

  paslaOnayRed(ScreenArguments args, int index, String durum) {
    wsPaslaSonuc(
        args.recordList[index].userName,
        args.recordList[index].itemID,
        args.recordList[index].recordID,
        args.recordList[index].recordType,
        durum);
  }
}

