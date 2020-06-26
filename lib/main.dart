import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kits/pages/firstPage.dart';
import 'package:kits/pages/list.dart';
import 'package:kits/pages/login.dart';
import 'package:kits/pages/paslaPage.dart';

void main() {

  LoginUser loginUser;


// Uygulamanın ilk çalıştığı sayfadır. Yönlendirme işlemleri yapılır. 
  runApp(MaterialApp(
      initialRoute: LoginPage.routeName,
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      routes: {
        LoginPage.routeName: (context) => LoginPage(),
        HomePage.routeName: (context) => HomePage(loginUser),
        ListPage.routeName: (context) => ListPage(),
        DetailPage.routeName: (context) => DetailPage(),
      }));
}
