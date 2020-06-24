import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kits/firstPage.dart';
import 'package:kits/listPage.dart';
import 'package:kits/loginPage.dart';
import 'package:kits/paslaPage.dart';

void main() {

  LoginUser loginUser;

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
