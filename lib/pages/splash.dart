import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:kits/pages/login.dart';
import 'dart:async';
import 'package:kits/classes/LoginUser.dart';
import 'package:kits/pages/mainPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = '/splash';
  @override
  State<StatefulWidget> createState() => StartState();
}

class StartState extends State<SplashScreen> {
  bool isLogin;
  String loginUserName, loginUname;
  @override
  Widget build(BuildContext context) {
    return initScreen(context);
  }

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  startTimer() async {
    var duration = Duration(seconds: 2);
    return new Timer(duration, getLoginCheck);
  }

  route() {
    /* Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (context) => lo()
      /)
    );*/
  }

  initScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              height: 250,
              child: Image.asset("assets/logo.png"),
            ),
            Padding(padding: EdgeInsets.only(top: 100.0)),
            CircularProgressIndicator(
              backgroundColor: Colors.red,
              strokeWidth: 6,
            ),
            Padding(padding: EdgeInsets.only(top: 20.0)),
            Text(
              "K I T S",
              style: TextStyle(fontSize: 30.0, color: Colors.grey),
            ),
            Text(
              "Kişisel İş Takip Sistemi",
              style: TextStyle(fontSize: 18.0, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  void getLoginCheck() async {
    final prefs = await SharedPreferences.getInstance();
    bool status = prefs.getBool("login");
    String userName = prefs.getString("userName");
    String uname = prefs.getString("uname");
    setState(() {
      isLogin = status;
      loginUserName = userName;
      loginUname = uname;
    });

    print(
        "login get status -> $isLogin , userName -> $loginUserName, uname -> $loginUname ");
    if (isLogin == true) {
      LoginUser loginUser = new LoginUser(loginUserName, loginUname, '');
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MyHomePage(loginUser)),
          ModalRoute.withName(MyHomePage.routeName));
    } else {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
          ModalRoute.withName(LoginPage.routeName));
    }
  }
}
