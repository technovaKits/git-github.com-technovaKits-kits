import 'package:flutter/material.dart';
import 'package:flutter_auth_buttons/flutter_auth_buttons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:kits/util/LoginUser.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart' as xml;
import 'package:kits/pages/firstPage.dart';
import 'firstPage.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['profile', 'email']);

class LoginPage extends StatefulWidget {
  static const routeName = '/loginPage';

  @override
  _SignInDemoState createState() => _SignInDemoState();
}

class _SignInDemoState extends State<LoginPage> {
  bool
      firstLoginCheck; // true -> daha önce giriş yapıldı. null&false -> ilk giriş
  bool isLogin;

  GoogleSignInAccount _currentUser;
  String loginUserName, loginUname;

  ProgressDialog progressDialog;
  String _message = '';

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  _registerToken() {
    _firebaseMessaging.getToken().then(
        (token) => _sendToBackendToken(_googleSignIn.currentUser.email, token));

    setFirstLoginCheck(true); //evet giriş yapıldı ilk kez , firstLoginCheck True olacak.
  }

  @override
  void initState() {
    super.initState();
    getFirstLoginCheck();

    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      setState(() {
        _currentUser = account;
      });
      print('Change Sign in: $account');
    });
    try {
      _googleSignIn.signInSilently(suppressErrors: false);
    } catch (e) {
      print('SigninSilent error $e');
    }
    print('Done with initState');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
          
      if (_currentUser == null) {
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
      } else if (_currentUser != null) {
        //mail adresi ile sistemdeki mail eşleşiyor mu ?
        loginCheck(_currentUser.email, context);
        return Text("Giriş yapılıyor.");
      }
    
    return Text("Giriş yapılıyor.");
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

  Future wsLoginRequest(var envelope, BuildContext context) async {
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
  }

  Future _parsing(var _response, BuildContext context) async {
    //progressDialog.show();
    await Future.delayed(Duration(seconds: 1));
    var _document = xml.parse(_response);

    //final mail = _document.findAllElements('EV_MAIL').map((node) => node.text);
    final uname =
        _document.findAllElements('EV_UNAME').map((node) => node.text);
    final userFullName =
        _document.findAllElements('EV_USER_FULLNAME').map((node) => node.text);

    //progressDialog.hide();

    /* eğer uname.first boş ise, bir şey dönmemiştir. Giriş yapılmıyor. 
     Email disconnect edilip başa dönüyor */

    if (uname.first == "") {
      Fluttertoast.showToast(
          msg: "Giriş başarısız!.",
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
  }

  getValue(Iterable<xml.XmlElement> items) {
    var textValue;
    items.map((xml.XmlElement node) {
      textValue = node.text;
    }).toList();
    return textValue;
  }

// Uygulama ana ekranına giriş yapılması
  signIn(String userName, String uname, GoogleSignInAccount account) {
    if (firstLoginCheck == null) {
      //firstLoginCheck - ilk giriş mi ?
      try {
        getMessage();
      } catch (e) {}

      try {
        _registerToken();
      } catch (e) {}
    }

    LoginUser loginUser = new LoginUser(userName, uname, account.photoUrl);

    setLoginStatus(true, loginUser); //giriş yapıldı ve sharedpref kayıt edildi.
  }

  _sendToBackendToken(String mail, String token) {
    var envelope =
        """ <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:sap-com:document:sap:soap:functions:mc-style">
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

  Future<Null> wsSendToBackendToken(var envelope) async {
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

  Future _parsingToken(var _response) async {
    await Future.delayed(Duration(seconds: 1));
    var _document = xml.parse(_response);
    final result =
        _document.findAllElements('EvSuccess').map((node) => node.text);

    if (result.first == "1") {
      print("success");
    } else if (result.first == "0") {
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

  void setFirstLoginCheck(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool("firstLogin", value);
    print("firstLogin set edildi.");
  }

  void getFirstLoginCheck() async {
    final prefs = await SharedPreferences.getInstance();
    bool status = prefs.getBool("firstLogin");
    setState(() {
      firstLoginCheck = status;
    });
    print("firstLogin get edildi.  $firstLoginCheck ");
  }
  
  void setLoginStatus(bool login, LoginUser loginUser) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool("login", true);
    prefs.setString("userName", loginUser.personName);
    prefs.setString("uname", loginUser.userName);

    if (login == true) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomePage(loginUser)),
        ModalRoute.withName(HomePage.routeName),
      );
    }

    print(
        "login set status -> $login , userName -> ${loginUser.personName}, uname -> ${loginUser.userName} ");
  }
}
