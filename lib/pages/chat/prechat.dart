import 'package:RessacaApp/pages/chat/join_data.dart';
import 'package:flutter/material.dart';

class PreChatPage extends StatefulWidget {
  final Function(JoinData) onJoin;
  final Function(String) onCreate;
  PreChatPage({Key key, this.onJoin, this.onCreate}) : super(key: key);

  @override
  _PreChatPageState createState() => _PreChatPageState();
}

class _PreChatPageState extends State<PreChatPage> {
  TextEditingController _nameController;
  TextEditingController _groupController;

  @override
  initState() {
    super.initState();
    _nameController = new TextEditingController();
    _groupController = new TextEditingController();
  }

  @override
  dispose() {
    _nameController.dispose();
    _groupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(color: Colors.green, width: 3)),
            child: Column(
              children: [
                Text("Seu nome será"),
                TextField(controller: _nameController),
                Text("Código de grupo"),
                TextField(controller: _groupController),
                RaisedButton(
                    child: Text("Juntar-se"), onPressed: () => _join(context)),
                RaisedButton(
                    child: Text("Criar grupo"),
                    onPressed: () => _create(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _join(BuildContext ctx) {
    JoinData data = new JoinData(
        userName: _nameController.text, groupName: _groupController.text);
    widget.onJoin.call(data);
  }

  void _create(BuildContext ctx) {
    widget.onCreate.call(_nameController.text);
  }
}
