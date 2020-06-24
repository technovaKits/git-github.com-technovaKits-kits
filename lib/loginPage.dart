import 'package:flutter/material.dart';
import 'package:flutter_auth_buttons/flutter_auth_buttons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:progress_dialog/progress_dialog.dart';
import 'package:xml/xml.dart' as xml;
import 'package:kits/firstPage.dart';

import 'firstPage.dart';

GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['profile', 'email']);

class LoginPage extends StatefulWidget {
  static const routeName = '/loginPage';

  @override
  _SignInDemoState createState() => _SignInDemoState();
}

class _SignInDemoState extends State<LoginPage> {
  GoogleSignInAccount _currentUser;
  ProgressDialog progressDialog;

  @override
  void initState() {
    super.initState();

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

  void wsLoginUser(String envelope, BuildContext context) {}

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

    final mail = _document.findAllElements('EV_MAIL').map((node) => node.text);
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
    }
    else {
      Fluttertoast.showToast(
          msg: "Giriş yapıldı..",
          gravity: ToastGravity.TOP,
          timeInSecForIos: 1,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0);

      LoginUser loginUser =
          new LoginUser(userFullName.first, uname.first, _currentUser.photoUrl);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(loginUser),
        ),
        ModalRoute.withName(HomePage.routeName),
      );
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
}

class LoginUser {
  String personName, userName, userPic;

  LoginUser(this.personName, this.userName, this.userPic);
}
