import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kits/pages/firstPage.dart';
import 'package:kits/pages/list.dart';
import 'package:kits/pages/login.dart';
import 'package:kits/pages/paslaPage.dart';
import 'package:kits/pages/splash.dart';
import 'package:kits/util/LoginUser.dart';

void main() {

  LoginUser loginUser;

// Uygulamanın ilk çalıştığı sayfadır. Yönlendirme işlemleri yapılır. 
  runApp(MaterialApp(
      initialRoute: SplashScreen.routeName,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      routes: {
        SplashScreen.routeName: (context) => SplashScreen(),
        LoginPage.routeName: (context) => LoginPage(),
        HomePage.routeName: (context) => HomePage(loginUser),
        ListPage.routeName: (context) => ListPage(),
        DetailPage.routeName: (context) => DetailPage(),
      }));
}
