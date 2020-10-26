import 'package:RessacaApp/pages/chat/chat.dart';
import 'package:RessacaApp/pages/chat/chat_controller.dart';
import 'package:RessacaApp/pages/chat/index.dart';
import 'package:flutter/material.dart';

class App extends StatefulWidget {
  App({Key key}) : super(key: key);

  @override
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Ressaca",
      home: ChatIndex(),
      // home: ChatPage(ChatController())
    );
  }
} 