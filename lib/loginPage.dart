import 'package:flutter/material.dart';
import 'package:flutter_auth_buttons/flutter_auth_buttons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:progress_dialog/progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart' as xml;
import 'package:kits/firstPage.dart';
import 'firstPage.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['profile', 'email']);

class LoginPage extends StatefulWidget {
  static const routeName = '/loginPage';

  @override
  _SignInDemoState createState() => _SignInDemoState();
}

class _SignInDemoState extends State<LoginPage> {
  bool firstLoginCheck = false;
  GoogleSignInAccount _currentUser;
  ProgressDialog progressDialog;
  String _message = '';

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  _registerToken() {
    _firebaseMessaging.getToken().then(
        (token) => _sendToBackendToken(_googleSignIn.currentUser.email, token));

    /*  TODO : 
     1. abap tarafına gönderilecek -> token and _googleSignIn.mail adresi..
     2. shared_pref. kayıt edilecek.. token istemesin.

    */
    setLoginCheck(); //evet giriş yapıldı ilk kez , firstLoginCheck True olacak.
  }

  @override
  void initState() {
    super.initState();
    getLoginCheck();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      setState(() {
        _currentUser = account;
      });
    });
    _googleSignIn.signInSilently();

    //Navigator.of(context)
    //  .pushNamed(HomePage.routeName,arguments: _currentUser);
  }

  @override
  Widget build(BuildContext context) {
    progressDialog = new ProgressDialog(context);

    // uygulama her açıldığında girdiği kısım..
    progressDialog.style(
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

    return Scaffold(
      body: Center(child: _buildBody(context)),
    );
  }

  void loginCheck(String mailAddress, BuildContext context) {
    var envelope = """ 
    <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" 
    xmlns:urn="urn:sap-com:document:sap:rfc:functions">
   <soapenv:Header/>
   <soapenv:Body>
      <urn:ZKITS_USERMAIL>
         <!--Optional:-->
         <IV_MAIL>$mailAddress</IV_MAIL>
      </urn:ZKITS_USERMAIL>
   </soapenv:Body>
</soapenv:Envelope> """;

    wsLoginRequest(envelope, context);
  }

  Widget _buildBody(BuildContext context) {
    if (_currentUser != null) {
      loginCheck(_currentUser.email, context);
    } else {}

    if (_currentUser != null) {
      // Giriş yapmak için sisteme gidilecek.
      return Text("Giriş yapılıyor.");
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('You are not signed in..'),
          GoogleSignInButton(
            text: "Sign In",
            darkMode: false,
            onPressed: _handleSignIn,
          ),
        ],
      );
    }
  }

  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print(error);
    }
  }

  Future<void> _handleSignOut() async {
    _googleSignIn.disconnect();
  }


  Future<Null> wsLoginRequest(var envelope, BuildContext context) async {
    http.Response response = await http.post(
        'http://crm.technova.com.tr:8001/sap/bc/srt/rfc/sap/zkits_ws_usermail/100/zkits_ws_usermail/zkits_ws_usermail',
        headers: {
          "Content-Type": "text/xml;charset=UTF-8",
          "SOAPAction":
              "urn:sap-com:document:sap:rfc:functions:zkits_ws_usermail:ZKITS_USERMAILRequest",
          "Host": "crm.technova.com.tr:8001"
        },
        body: envelope);
    var _response = response.body;

    await _parsing(_response, context);

    return null;
  }

  Future _parsing(var _response, BuildContext context) async {
    progressDialog.show();
    await Future.delayed(Duration(seconds: 1));
    var _document = xml.parse(_response);

    //final mail = _document.findAllElements('EV_MAIL').map((node) => node.text);
    final uname =
        _document.findAllElements('EV_UNAME').map((node) => node.text);
    final userFullName =
        _document.findAllElements('EV_USER_FULLNAME').map((node) => node.text);

    progressDialog.hide();
    if (uname.first == "") {
      Fluttertoast.showToast(
          msg: "Giriş yapılamadı..",
          gravity: ToastGravity.TOP,
          timeInSecForIos: 1,
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
          fontSize: 16.0);
      _googleSignIn.disconnect();
    } else {
      //giriş yapılıyor. mail ile sistemdeki mail eşleşmiş.
      signIn(userFullName.first, uname.first, _currentUser);
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

// shift + alt + f .. code düzenlemesi
  signIn(String userName, String uname, GoogleSignInAccount account) {
    //ilk kez mi login oluyor ?
    

    if (firstLoginCheck == null) {
      try {
        getMessage();
      } catch (e) {}

      try {
        _registerToken();
      } catch (e) {}
    }

    LoginUser loginUser = new LoginUser(userName, uname, account.photoUrl);

    // buraya ilk kez mi geliyorsun ?
    //TODO:shared_preference ile ilk kez mi giriş boolean bir değer tutacağız.

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(loginUser),
      ),
      ModalRoute.withName(HomePage.routeName),
    );
  }

  _sendToBackendToken(String mail, String token) {

      var envelope =  """ <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:sap-com:document:sap:soap:functions:mc-style">
   <soapenv:Header/>
   <soapenv:Body>
      <urn:ZkitsSaveToken>
         <!--Optional:-->
         <IvMail>$mail</IvMail>
         <!--Optional:-->
         <IvToken>$token</IvToken>
      </urn:ZkitsSaveToken>
   </soapenv:Body>
</soapenv:Envelope>;""";
     
    wsSendToBackendToken(envelope);
    print("$mail , $token");
  }

  Future<Null> wsSendToBackendToken(var envelope) async{
      http.Response response = await http.post(
        'http://crm.technova.com.tr:8001/sap/bc/srt/rfc/sap/zkits_ws_save_token/100/zkits_ws_save_token/zkits_ws_save_token',
        headers: {
          "Content-Type": "text/xml;charset=UTF-8",
          "SOAPAction":
              "urn:sap-com:document:sap:soap:functions:mc-style:zkits_ws_save_token:ZkitsSaveTokenRequest",
          "Host": "crm.technova.com.tr:8001"
        },
        body: envelope);
    var _response = response.body;

      await _parsingToken(_response);
    
    return null;
  }

  Future _parsingToken(var _response) async{

      await Future.delayed(Duration(seconds: 1));
      var _document = xml.parse(_response);
        final result =
        _document.findAllElements('EvSuccess').map((node) => node.text);
   
    if(result.first == "1"){
      print("success");
    }
    else if(result.first == "0"){
      print("fail");
    }
  }

  void getMessage() {
    _firebaseMessaging.configure(
        onMessage: (Map<String, dynamic> message) async {
      print('on message $message');
      setState(() => _message = message["notification"]["title"]);
    }, onResume: (Map<String, dynamic> message) async {
      print('on resume $message');
      setState(() => _message = message["notification"]["title"]);
    }, onLaunch: (Map<String, dynamic> message) async {
      print('on launch $message');
      setState(() => _message = message["notification"]["title"]);
    });
  }

  void setLoginCheck() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool("firstLogin", true);
    print("firstLogin set edildi.");
  }

  void getLoginCheck() async {
    final prefs = await SharedPreferences.getInstance();
    bool status = prefs.getBool("firstLogin");
    setState(() {
      firstLoginCheck = status;
    });
    print("firstLogin get edildi.  ${firstLoginCheck} ");
  }
}

class LoginUser {
  String personName, userName, userPic;

  LoginUser(this.personName, this.userName, this.userPic);
}
