import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_auth_buttons/flutter_auth_buttons.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:kits/classes/LoginUser.dart';
import 'package:kits/pages/mainPage.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:xml/xml.dart' as xml;

import 'package:firebase_messaging/firebase_messaging.dart';

GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['profile', 'email']);

class LoginPage extends StatefulWidget {
  static const routeName = '/loginPage';

  @override
  _SignInDemoState createState() => _SignInDemoState();
}

class _SignInDemoState extends State<LoginPage> {
  final myControllerMail = TextEditingController();
  final myControllerPass = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  FocusNode _emailFocusNode = FocusNode();
  String _username, _email, _password = "";

  bool passBlank = false;
  FocusNode _passwordFocusNode = FocusNode();

  bool _isSelected = false;

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

    setFirstLoginCheck(
        true); //evet giriş yapıldı ilk kez , firstLoginCheck True olacak.
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
    ScreenUtil.instance =
        ScreenUtil(width: 750, height: 1334, allowFontScaling: true)
          ..init(context);

    return Scaffold(
      body: Center(child: _buildBody(context)),
    );
  }

  Widget radioButton(bool isSelected) => Container(
        width: 20.0,
        height: 20.0,
        padding: EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(width: 2.0, color: Colors.black),
        ),
        child: isSelected
            ? Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
              )
            : Container(),
      );

  Widget horizontalLine() => Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: Container(
          width: ScreenUtil.getInstance().setWidth(120),
          height: 1.0,
          color: Colors.black26.withOpacity(.2),
        ),
      );

  Widget _buildBody(BuildContext context) {
    if (_currentUser == null) {
      return Stack(
        fit: StackFit.loose,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Padding(
                  padding: EdgeInsets.only(top: 20.0),
                  child: Image.asset('assets/image_01.png')),
              Expanded(
                child: Container(),
              ),
              Image.asset('assets/image_02.png'),
            ],
          ),
          Container(
              padding: EdgeInsets.all(10),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                    child: Padding(
                        padding:
                            EdgeInsets.only(left: 10.0, right: 10.0, top: 60.0),
                        child: Column(
                          children: <Widget>[
                            Row(
                              children: <Widget>[
                                Image.asset(
                                  'assets/logo2.png',
                                  width: ScreenUtil.getInstance().setWidth(110),
                                  height:
                                      ScreenUtil.getInstance().setHeight(110),
                                ),
                                Text('KITS',
                                    style: TextStyle(
                                      fontSize:
                                          ScreenUtil.getInstance().setSp(46),
                                      letterSpacing: .6,
                                      fontWeight: FontWeight.bold,
                                    ))
                              ],
                            ),
                            SizedBox(
                              height: ScreenUtil.getInstance().setHeight(180),
                            ),
                            Container(
                                width: double.infinity,
                                height: ScreenUtil.getInstance().setHeight(450),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      offset: Offset(0.0, 15.0),
                                      blurRadius: 15.0,
                                    ),
                                    BoxShadow(
                                      color: Colors.black12,
                                      offset: Offset(0.0, -10.0),
                                      blurRadius: 10.0,
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      left: 16.0, top: 16.0, right: 16.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text('Login',
                                          style: TextStyle(
                                            fontSize: ScreenUtil.getInstance()
                                                .setSp(45),
                                            fontFamily: 'Poppins-Bold',
                                            letterSpacing: .6,
                                          )),
                                      SizedBox(
                                        height: ScreenUtil.getInstance()
                                            .setHeight(30),
                                      ),
                                      emailInput(),
                                      passwordInput(),
                                      SizedBox(
                                        height: ScreenUtil.getInstance()
                                            .setHeight(30),
                                      ),
                                      SizedBox(
                                        height: ScreenUtil.getInstance()
                                            .setHeight(35),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: <Widget>[
                                          Text('Şifrenizi mi unuttunuz?',
                                              style: TextStyle(
                                                color: Colors.blue,
                                                fontFamily: 'Poppins-Medium',
                                                fontSize:
                                                    ScreenUtil.getInstance()
                                                        .setSp(28),
                                              ))
                                        ],
                                      ),
                                      SizedBox(
                                        height: ScreenUtil.getInstance()
                                            .setHeight(30),
                                      )
                                    ],
                                  ),
                                )),
                            SizedBox(
                              height: ScreenUtil.getInstance().setHeight(35),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                InkWell(
                                  child: Container(
                                      width: ScreenUtil.getInstance()
                                          .setWidth(300),
                                      height: ScreenUtil.getInstance()
                                          .setHeight(100),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [
                                          Color(0xFF17ead9),
                                          Color(0xFF6078ea)
                                        ]),
                                        borderRadius:
                                            BorderRadius.circular(16.0),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0xFF6078ea)
                                                .withOpacity(.4),
                                            offset: Offset(0.0, 8.0),
                                            blurRadius: 8.0,
                                          )
                                        ],
                                      ),
                                      child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                              onTap: () {
                                                if (_formKey.currentState
                                                    .validate()) {
                                                  _formKey.currentState.save();
                                                }

                                                if (EmailValidator.validate(
                                                    myControllerMail.text) && passBlank == true) {
                                                  loginCheck(
                                                      myControllerMail.text,
                                                      myControllerPass.text,
                                                      "",
                                                      context);
                                                }
                                              },
                                              child: Center(
                                                  child: Text('GİRİŞ',
                                                      style: TextStyle(
                                                          color: Colors.white,
                                                          fontFamily:
                                                              'Poppins-Bold',
                                                          fontSize: 18.0,
                                                          letterSpacing:
                                                              1.0)))))),
                                )
                              ],
                            ),
                            SizedBox(
                              height: ScreenUtil.getInstance().setHeight(40),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                horizontalLine(),
                                Text('Social Login',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontFamily: 'Poppins-Medium',
                                    )),
                                horizontalLine(),
                              ],
                            ),
                            SizedBox(
                              height: ScreenUtil.getInstance().setHeight(40),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                GoogleSignInButton(
                                  text: "Google ile bağlan",
                                  darkMode: false,
                                  onPressed: _handleSignIn,
                                )
                              ],
                            ),
                            SizedBox(
                              height: ScreenUtil.getInstance().setHeight(50),
                            )
                          ],
                        ))),
              )),
        ],
      );
    } else if (_currentUser != null) {
      //mail adresi ile sistemdeki mail eşleşiyor mu ?
      loginCheck(_currentUser.email, "", "X", context);
      return Text("Giriş yapılıyor.");
    }

    return Text("Giriş yapılıyor.");
  }

  Widget passwordInput() {
    return TextFormField(
      controller: myControllerPass,
      focusNode: _passwordFocusNode,
      keyboardType: TextInputType.text,
      obscureText: true,
      decoration: InputDecoration(
        labelText: "Password",
        suffixIcon: Icon(Icons.lock),
      ),
      textInputAction: TextInputAction.done,
      validator: (password) {
        if (password == "") {
          passBlank = false;
          return 'Şifre boş olamaz';
        } else {
          passBlank = true;
          return null;
        }
      },
      onSaved: (password) => _password = password,
    );
  }

  Widget emailInput() {
    return TextFormField(
      controller: myControllerMail,
      focusNode: _emailFocusNode,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: "Email",
        hintText: "e.g abc@gmail.com",
      ),
      textInputAction: TextInputAction.next,
      validator: (email) =>
          EmailValidator.validate(email) ? null : "Invalid email address",
      onSaved: (email) => _email = email,
      onFieldSubmitted: (_) {
        fieldFocusChange(context, _emailFocusNode, _passwordFocusNode);
      },
    );
  }

  void loginCheck(String mailAddress, String password, String isGoogle,
      BuildContext context) {
    var envelope =
        """ <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:urn="urn:sap-com:document:sap:rfc:functions">
   <soapenv:Header/>
   <soapenv:Body>
      <urn:ZKITS_USERMAIL>
         <!--Optional:-->
         <IV_GOOGLE>$isGoogle</IV_GOOGLE>
         <!--Optional:-->
         <IV_MAIL>$mailAddress</IV_MAIL>
         <!--Optional:-->
         <IV_PASSWORD>$password</IV_PASSWORD>
      </urn:ZKITS_USERMAIL>
   </soapenv:Body>
</soapenv:Envelope> """;
    /* <soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" 
    xmlns:urn="urn:sap-com:document:sap:rfc:functions">
   <soapenv:Header/>
   <soapenv:Body>
      <urn:ZKITS_USERMAIL>
         <!--Optional:-->
         <IV_MAIL>$mailAddress</IV_MAIL>
      </urn:ZKITS_USERMAIL>
   </soapenv:Body>
</soapenv:Envelope> """;*/

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
        'http://crm.technova.com.tr:8001/sap/bc/srt/rfc/sap/zkits_ws_userlogin/100/zkits_ws_userlogin/zkits_ws_userlogin',
        headers: {
          "Content-Type": "text/xml;charset=UTF-8",
          "SOAPAction":
              "urn:sap-com:document:sap:rfc:functions:ZKITS_WS_USERLOGIN:ZKITS_USERMAILRequest",
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

    final result =
        _document.findAllElements('EV_SUCCESS').map((node) => node.text);
    final uname =
        _document.findAllElements('EV_UNAME').map((node) => node.text);
    final userFullName =
        _document.findAllElements('EV_USER_FULLNAME').map((node) => node.text);

    //progressDialog.hide();

    /* eğer uname.first boş ise, bir şey dönmemiştir. Giriş yapılmıyor. 
     Email disconnect edilip başa dönüyor */

    if (result.first == "X") {
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
    } else {
      //Giriş yapılmadı.
      Fluttertoast.showToast(
          msg: "Giriş başarısız!.",
          gravity: ToastGravity.TOP,
          timeInSecForIos: 1,
          backgroundColor: Colors.redAccent,
          textColor: Colors.white,
          fontSize: 16.0);
    }
  }

  void fieldFocusChange(
      BuildContext context, FocusNode currentFocus, FocusNode nextFocus) {
    currentFocus.unfocus();
    FocusScope.of(context).requestFocus(nextFocus);
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

    String picture;

    if (account != null) {
      picture = account.photoUrl;
    }

    LoginUser loginUser = new LoginUser(userName, uname, picture);

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
        MaterialPageRoute(builder: (context) => MyHomePage(loginUser)),
        ModalRoute.withName(MyHomePage.routeName),
      );
    }

    print(
        "login set status -> $login , userName -> ${loginUser.personName}, uname -> ${loginUser.userName} ");
  }
}
