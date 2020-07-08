import 'package:fancy_dialog/FancyAnimation.dart';
import 'package:fancy_dialog/FancyGif.dart';
import 'package:fancy_dialog/FancyTheme.dart';
import 'package:fancy_dialog/fancy_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:progress_dialog/progress_dialog.dart';
import 'package:xml/xml.dart' as xml;
import 'package:kits/classes/ScreenArgumentDetail.dart';
import 'package:kits/classes/User.dart';

class DetailPage extends StatefulWidget {
  static const routeName = '/paslaPage';

  @override
  _HomePageState createState() => new _HomePageState();
}

class _HomePageState extends State<DetailPage> {
  ProgressDialog p2;

  String str;
  var envelope =
      """<soapenv:Envelope xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"
       xmlns:urn=\"urn:sap-com:document:sap:rfc:functions\"> 
     <soapenv:Header/> <soapenv:Body> <urn:ZCRM_WS_RECORDS> 
     <!--Optional:--> <IV_UNAME>zcelik</IV_UNAME></urn:ZCRM_WS_RECORDS></soapenv:Body></soapenv:Envelope>""";



  @override
  void initState() {
    super.initState();
  }


  final myController = TextEditingController();
  List<User> userList = new List();
  String dropdownValue;

  Widget dropDownUserList(ScreenArgumentsDetail args) {
    userList.clear();
    args.userList.forEach((f) {
      if (f.userName == "") {
        f.userName = "Kimlik " + f.userID;
        userList.add(f);
      }
      if (f.userID != "asd") {
        userList.add(f);
      }
    });

    return DropdownButton<String>(
      value: dropdownValue,
      hint: Text('Kişi Seçiniz'),
      icon: Icon(Icons.arrow_drop_down),
      iconSize: 24,
      elevation: 10,
      style: TextStyle(color: Colors.black),
      onChanged: (String newValue) {
        setState(() {
          dropdownValue = newValue;
        });
      },
      items: userList.map<DropdownMenuItem<String>>((User user) {
        return DropdownMenuItem<String>(
          child: Text(user.userName),
          value: user.userID,
        );
      }).toList(),
    );
  }

  Widget itemShow(String a) {
    if (a == "0000000000") {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          //Text("Header"),
          //Text(args.objectID),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text("Item Numarası: "),
          Text(a),
        ],
      );
    }
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
  }

  void paslamaIstegiGonder(BuildContext context, ScreenArgumentsDetail args,
      String kisi, String text) {
    var envelope2 =
        """<soap:Envelope xmlns:soap=\"http://www.w3.org/2003/05/soap-envelope\" xmlns:urn="urn:sap-com:document:sap:rfc:functions\">
    <soap:Header/>
    <soap:Body>
    <urn:ZKITS_CHANGEUSER_REQUEST>
    <!--Optional:-->
    <IV_ESORUMLU>${args.user}</IV_ESORUMLU>
    <!--Optional:-->
    <IV_KALEMID>${args.item}</IV_KALEMID>
    <!--Optional:-->
    <IV_NOT>$text</IV_NOT>
    <!--Optional:-->
    <IV_OBJECTID>${args.objectID}</IV_OBJECTID>
    <!--Optional:-->
    <IV_RECORDTYPE>${args.type}</IV_RECORDTYPE>
    <!--Optional:-->
    <IV_YSORUMLU>$kisi</IV_YSORUMLU>
    </urn:ZKITS_CHANGEUSER_REQUEST>
    </soap:Body>
    </soap:Envelope>""";

    wsPaslamaRequest(envelope2, context);
  }

  Future sleep() {
    return new Future.delayed(const Duration(seconds: 1), () => "1");
  }

  Future<Null> wsPaslamaRequest(var envelope2, BuildContext context) async {
    http.Response response = await http.post(
        'http://crm.technova.com.tr:8001/sap/bc/srt/rfc/sap/zkits_changeuser/100/zkits_changeuser/zkits_changeuser',
        headers: {
          "Content-Type": "application/soap+xml; charset=utf-8",
          "SOAPAction":
              "urn:sap-com:document:sap:rfc:functions:zkits_changeuser:ZKITS_CHANGEUSER_REQUESTRequest",
          "Host": "crm.technova.com.tr:8001"
        },
        body: envelope2);
    var _response = response.body;

    await _parsing(_response, context);

    setState(() {});

    return null;
  }

  Future _parsing(var _response, BuildContext context) async {
    p2 = new ProgressDialog(context);
    p2.style(
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
    p2.show();

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

    p2.hide();

    return null;
  }

  getValue(Iterable<xml.XmlElement> items) {
    var textValue;
    items.map((xml.XmlElement node) {
      textValue = node.text;
    }).toList();
    return textValue;
  }

  showPaslaDialog(BuildContext context, ScreenArgumentsDetail args){

    if(dropdownValue == null){
    return Fluttertoast.showToast(
          msg: "Hata: Kişi giriniz.",
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
    }
    else if(myController.text == ""){

      return Fluttertoast.showToast(
          msg: "Hata: Açıklama giriniz.",
          gravity: ToastGravity.TOP,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);

    }
    else{
      return showDialog(
          context: context,
          builder: (BuildContext context) => FancyDialog(
            gifPath: FancyGif.PLAY_MEDIA,
            title: "Paslama İsteği",
            animationType: FancyAnimation.LEFT_RIGHT,
            descreption: args.objectID +
                " numaralı belgeyi, " +
                dropdownValue +
                ""
                    " kişisine " +
                "paslama isteği işlemine devam etmek istiyor musunuz?",
            theme: FancyTheme.FANCY,
            okFun: () => paslamaIstegiGonder(context, args,
                dropdownValue, myController.text),
          ));
    }


  }

  @override
  Widget build(BuildContext context) {
    p2 = new ProgressDialog(context);
    p2.style(
        message: 'Yükleniyor...',
        borderRadius: 10.0,
        backgroundColor: Colors.white,
        progressWidget: CircularProgressIndicator(),
        elevation: 10.0,
        insetAnimCurve: Curves.easeInBack,
        progress: 0.0,
        maxProgress: 100.0,
        progressTextStyle: TextStyle(
            color: Colors.black, fontSize: 13.0, fontWeight: FontWeight.w400),
        messageTextStyle: TextStyle(
            color: Colors.black, fontSize: 19.0, fontWeight: FontWeight.w600));

    final ScreenArgumentsDetail args =
        ModalRoute.of(context).settings.arguments;


    // dropdownValue = args.userList[0].userID;
    return Scaffold(
      appBar: AppBar(
        title: Text("Detay Sayfası"),
        brightness: Brightness.dark,
      ),
      body: Container(
        color: Colors.white,
        width: MediaQuery.of(context).copyWith().size.width,
        height: MediaQuery.of(context).copyWith().size.height / 2,
        child: new Card(
          elevation: 12.2,
          color: Colors.white,
          shape: Border(
            left: BorderSide(color: Colors.purple, width: 5),
          ),
          margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
          child: new Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text("    Numara   : "),
                  Text(args.objectID),
                ],
              ),
              Row(
                children: <Widget>[
                  Text("    Açıklama :"),
                  Text(args.description),
                ],
              ),
              Row(
                children: <Widget>[
                  Text("    Tarih :"),
                  Text(args.tarih),
                ],
              ),
              Row(
                children: <Widget>[
                  Text("    Saat :"),
                  Text(args.saat),
                ],
              ),
              itemShow(args.item),
              dropDownUserList(args),
              Container(
                margin: EdgeInsets.all(10.0),
                // hack textfield height
                padding: EdgeInsets.only(bottom: 4.0),
                child: TextField(
                  controller: myController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: "Açıklama...",
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              FlatButton(
                color: Colors.blue,
                textColor: Colors.white,
                disabledColor: Colors.grey,
                disabledTextColor: Colors.black,
                padding: EdgeInsets.all(8.0),
                hoverColor: Colors.yellowAccent,
                splashColor: Colors.blueAccent,
                onPressed: () {
                  showPaslaDialog(context, args);
                },
                child: Text(
                  "Pasla",
                  style: TextStyle(fontSize: 20.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
