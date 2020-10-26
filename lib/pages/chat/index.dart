import 'dart:convert';

import 'package:RessacaApp/pages/chat/chat.dart';
import 'package:RessacaApp/pages/chat/chat_controller.dart';
import 'package:RessacaApp/pages/chat/hub_methods.dart';
import 'package:RessacaApp/pages/chat/join_data.dart';
import 'package:RessacaApp/pages/chat/prechat.dart';
import 'package:flutter/material.dart';
import 'package:signalr_client/signalr_client.dart';

import 'states.dart';

class ChatIndex extends StatefulWidget {
  ChatIndex({Key key}) : super(key: key);

  @override
  _ChatIndexState createState() => _ChatIndexState();
}

class _ChatIndexState extends State<ChatIndex> {
  ChatState currentState;

  // The location of the SignalR Server
  final serverUrl = "https://10.0.2.2:5001/chatHub";
  // Creates the connection by using the HubConnectionBuilder
  HubConnection hubConnection;

  ChatController chatController = ChatController();

  String userName;
  String groupName;

  @override
  initState() {
    super.initState();
    currentState = ChatState.loading;
    setupConnection();
  }

  @override
  Widget build(BuildContext context) {
    if (currentState.equals(ChatState.loading)) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (currentState.equals(ChatState.notConnected)) {
      return PreChatPage(
        onJoin: (JoinData data) async {
          setState(() {
            userName = data.userName;
            groupName = data.groupName;
          });
          await hubConnection.invoke(HubMethods.joinGroup,
              args: <Object>[userName, groupName]);
        },
        onCreate: (String userName) async {
          setState(() {
            this.userName = userName;
          });
          await hubConnection 
              .invoke(HubMethods.createGroup, args: <Object>[userName]);
        },
      );
    } else {
      return ChatPage(chatController, groupName: groupName, userName: userName);
    }
  }

  Future<void> setupConnection() async {
    hubConnection = HubConnectionBuilder().withUrl(serverUrl).build();
    hubConnection.onclose((error) {
      print("Connection closed.");
      if (error != null) {
        print(error);
      }
    });
    print("Connecting...");
    await hubConnection.start();
    if (hubConnection.state == HubConnectionState.Connected) {
      setState(() {
        currentState = ChatState.notConnected;
      });
      hubConnection.on(HubMethods.joinGroup, (List<Object> parameters) {
        print("JoinGroup: " + parameters.toString());
        setState(() {
          currentState = ChatState.connected;
          Map map = json.decode(json.encode(parameters[0]));
          groupName = map["name"];
          chatController.sendMessage = (String userName, String message) async {
            await hubConnection.invoke(HubMethods.sendMessage, args: <Object>[userName, message]);
          };
          chatController.leaveGroup = () async {
            await hubConnection.invoke(HubMethods.leaveGroup);
            setState(() { currentState = ChatState.notConnected; });
          };
          chatController.sendOffer = (String offer) async {
            print("Sending offer");
            await hubConnection.invoke(HubMethods.sendOffer, args: [offer]);
          };
        });
      });
      hubConnection.on(HubMethods.createGroup, (List<Object> parameters) {
        print("CreateGroup: " + parameters.toString());
        setState(() {
          currentState = ChatState.connected;
        });
      });
      hubConnection.on(HubMethods.receiveMessage, (List<Object> parameters) {
        chatController.receiveMessage(parameters[0].toString(), parameters[1].toString());
      });
      hubConnection.on(HubMethods.userJoined, (List<Object> parameters) {
        chatController.userJoined(parameters[0].toString());
      });
      hubConnection.on(HubMethods.userLeft, (List<Object> parameters) {
        chatController.userLeft(parameters[0].toString());
      });
      hubConnection.on(HubMethods.getOffer, (List<Object> parameters) {
        print(jsonEncode(parameters));
        chatController.getOffer(parameters[0].toString(), parameters[1].toString());
      });
    } else {
      print("ERROR!");
    }
  }
}
