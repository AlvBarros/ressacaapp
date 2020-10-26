import 'dart:convert';
import 'dart:developer';

import 'package:RessacaApp/pages/chat/chat_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sdp_transform/sdp_transform.dart';

class ChatPage extends StatefulWidget {
  final ChatController chatController;
  final String groupName;
  final String userName;
  ChatPage(this.chatController, {Key key, this.groupName, this.userName})
      : super(key: key);

  @override
  _ChatPageState createState() =>
      _ChatPageState(chatController, this.groupName, this.userName);
}

class _ChatPageState extends State<ChatPage> {
  final ChatController chatController;
  final String groupName;
  final String userName;
  _ChatPageState(this.chatController, this.groupName, this.userName);

  List<String> _chatMessages;
  TextEditingController _messageController;

  bool _offer = false;
  RTCPeerConnection _peerConnection;
  MediaStream _localStream;

  final sdpController = TextEditingController();
  final offerController = TextEditingController();
  final candidateController = TextEditingController();
  final _localRenderer = new RTCVideoRenderer();
  final _remoteRenderer = new RTCVideoRenderer();
  final _remoteRenderers = List<RTCVideoRenderer>();
  // List<RTCVideoRenderer> _remoteRenderers = new List<RTCVideoRenderer>();

  @override
  initState() {
    _chatMessages = <String>[];
    _messageController = new TextEditingController();
    chatController.userJoined = (String user) {
      setState(() {
        _chatMessages.add("$user se juntou ao grupo. Dê boas vindas!");
      });
    };
    chatController.userLeft = (String user) {
      setState(() {
        _chatMessages.add("$user deixou o grupo.");
      });
    };
    chatController.receiveMessage = (String user, String message) {
      setState(() {
        _chatMessages.add("$user: $message");
      });
    };
    chatController.getOffer = (String user, String offer) {
      _setRemoteDescription(offer);
    };

    initRenderers();
    _createPeerConnection().then((pc) {
      setState(() {
        print("pc: " + (pc == null).toString());
        print("peerconnection is not null!");
        _peerConnection = pc;
      });
      _createOffer();
    });
    super.initState();
  }

  Future<RTCPeerConnection> _createPeerConnection() async {
    // var _newRemote = RTCVideoRenderer();
    Map<String, dynamic> configuration = {
      'iceServers': [
        {'url': 'stun:stun.l.google.com:19302'},
      ]
    };

    final Map<String, dynamic> offerSdpConstraints = {
      'mandatory': {
        'OfferToReceiveAudio': true,
        'OfferToReceiveVideo': true,
      },
      'optional': []
    };

    setState(() async {
      _localStream = await _getUserMedia();
    });

    RTCPeerConnection pc =
        await createPeerConnection(configuration, offerSdpConstraints);
    pc.addStream(_localStream);

    pc.onIceCandidate = (e) {
      if (e.candidate != null) {
        print(json.encode({
          'candidate': e.candidate.toString(),
          'sdpMid': e.sdpMid.toString(),
          'sdpMlineIndex': e.sdpMlineIndex,
        }));
      }
    };
    pc.onIceConnectionState = (e) {
      print(e);
    };

    pc.onAddStream = (stream) {
      print('addStream: ' + stream.id);
      setState(() {
        _remoteRenderer.srcObject = stream;
      });
    };

    // _remoteRenderers.add(_newRemote);

    return pc;
  }

  Future<void> initRenderers() async {
    await _localRenderer.initialize();
    // await _remoteRenderer.initialize();
  }

  _getUserMedia() async {
    final Map<String, dynamic> constraints = {
      'audio': true,
      'video': {'facingMode': 'user'}
    };
    MediaStream stream = await navigator.getUserMedia(constraints);
    setState(() {
      _localRenderer.srcObject = stream;
    });
    return stream;
  }

  @override
  dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    sdpController.dispose();
    super.dispose();
  }

  void _createOffer() async {
    print("Creating offer");
    print("is peerconnectino null: " + (_peerConnection == null).toString());
    RTCSessionDescription description =
        await _peerConnection.createOffer({'offerToReceiveVideo': 1});
    print("Created offer");
    var session = parse(description.sdp);
    _offer = true;

    print("SETTING LOCAL");
    await _peerConnection.setLocalDescription(description);
    print("SENDING:");
    chatController.sendOffer(json.encode(session));
  }

  void _setRemoteDescription(String remote) async {
    // String jsonString = sdpController.text;
    String jsonString = remote;
    dynamic session = await jsonDecode('$jsonString');
    String sdp = write(session, null);
    RTCSessionDescription description =
        new RTCSessionDescription(sdp, _offer ? 'answer' : 'offer');
    print(description.toMap());
    await _peerConnection.setRemoteDescription(description);
  }

  void _createAnswer() async {
    RTCSessionDescription description =
        await _peerConnection.createAnswer({'offerToReceiveVideo': 1});
    var session = parse(description.sdp);
    print(json.encode(session));
    setState(() {
      candidateController.text = json.encode(session);
    });
    _peerConnection.setLocalDescription(description);
  }

  void _setCandidate() async {
    String jsonString = sdpController.text;
    dynamic session = await jsonDecode('$jsonString');
    print(session['candidate']);
    dynamic candidate = new RTCIceCandidate(
        session['candidate'], session['sdpMid'], session['sdpMlineIndex']);
    await _peerConnection.addCandidate(candidate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("GRUPO: $groupName"), actions: <Widget>[
        RaisedButton(
          child: Text("sair"),
          onPressed: () async {
            await chatController.leaveGroup();
          },
        )
      ]),
      body: Stack(
        children: <Widget>[
          Expanded(
            child: Container(
              child: fitEveryRemote(),
            ),
          ),
          Positioned(
              bottom: 10,
              left: 10,
              child: SizedBox(
                  width: MediaQuery.of(context).size.width * (0.2),
                  height: MediaQuery.of(context).size.height * (0.2),
                  child: RTCVideoView(_localRenderer))),
          Positioned(
            bottom: 10,
            right: 10,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * (0.2),
              height: MediaQuery.of(context).size.height * (0.2),
              child: Column(children: <Widget>[
                Expanded(
                    child:
                        RaisedButton(child: Text('no mic'), onPressed: null)),
                Expanded(
                    child: RaisedButton(child: Text('no cam'), onPressed: null))
              ]),
            ),
          ),
        ],
      ),
      /*
                    Column(
                      children: [
                        /*
                        Expanded(
                            flex: 5,
                            child: Container(
                              child: ListView(children: <Widget>[
                                videoRenderers(),
                                offerAndAnswerButtons(),
                                sdpCandidateTF(),
                                sdpCandidateButtons()
                              ]),
                            )),
                        */
                        /* chat
                        Expanded(
                          flex: 4,
                          child: Container(
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.black, width: 3)),
                            child: ListView.builder(
                                itemCount: _chatMessages.length,
                                itemBuilder: (ctx, i) {
                                  return Text(_chatMessages[i]);
                                }),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Row(
                            children: [
                              Expanded(
                                  flex: 8, child: TextField(controller: _messageController)),
                              Expanded(
                                flex: 8,
                                child: RaisedButton(
                                  child: Text('Enviar mensagem'),
                                  onPressed: () async {
                                    await chatController.sendMessage(
                                        userName, _messageController.text);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        */
                      ],
                    ),
                    */
    );
  }

  // SizedBox videoRenderers() => SizedBox(
  //       height: 301,
  //       child: Row(
  //         children: <Widget>[
  //           Flexible(
  //               child: Container(
  //                   key: Key('local'), child: RTCVideoView(_localRenderer))),
  //           Flexible(
  //               child: Container(
  //                   key: Key('remote'), child: RTCVideoView(_remoteRenderer))),
  //         ],
  //       ),
  //     );

  // Row offerAndAnswerButtons() =>
  //     Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: <Widget>[
  //       RaisedButton(
  //         onPressed: _createOffer,
  //         child: Text('Offer'),
  //         color: Colors.amber,
  //       ),
  //       RaisedButton(
  //         onPressed: _createAnswer,
  //         child: Text('Answer'),
  //         color: Colors.amber,
  //       )
  //     ]);

  // Padding sdpCandidateTF() => Padding(
  //     padding: const EdgeInsets.all(16.0),
  //     child: Column(
  //       children: [
  //         TextField(
  //             controller: offerController,
  //             keyboardType: TextInputType.multiline,
  //             maxLines: 2,
  //             maxLength: TextField.noMaxLength),
  //         TextField(
  //             controller: candidateController,
  //             keyboardType: TextInputType.multiline,
  //             maxLines: 2,
  //             maxLength: TextField.noMaxLength),
  //         TextField(
  //             controller: sdpController,
  //             keyboardType: TextInputType.multiline,
  //             maxLines: 2,
  //             maxLength: TextField.noMaxLength),
  //       ],
  //     ));

  // Row sdpCandidateButtons() => Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //       children: <Widget>[
  //         RaisedButton(
  //             onPressed: _setRemoteDescription,
  //             child: Text('Set Remote Description'),
  //             color: Colors.amber),
  //         RaisedButton(
  //             onPressed: _setCandidate,
  //             child: Text('Set Candidate'),
  //             color: Colors.amber),
  //       ],
  //     );

  Widget fitEveryRemote() {
    int count = _remoteRenderers.length;
    if (count == 0) {
      return Container(
        child: Center(child: Text("Aguardando alguém se conectar...")),
      );
    }
    if (count <= 3) {
      return Container(
        child: Column(
          children: _remoteRenderers.map<Widget>((e) {
            return Expanded(child: RTCVideoView(e));
          }).toList(),
        ),
      );
    } else if (count > 0) {
      int half = (count / 2).round();
      if (count % 2 != 0) {
        _remoteRenderers.add(RTCVideoRenderer());
      }
      return Container(
        child: Row(
          children: [
            Expanded(
              child: Column(
                  children: _remoteRenderers.sublist(0, half).map<Widget>((e) {
                return Expanded(child: RTCVideoView(e));
              }).toList()),
            ),
            Expanded(
              child: Column(
                  children: _remoteRenderers.sublist(half).map<Widget>((e) {
                return Expanded(child: RTCVideoView(e));
              }).toList()),
            )
          ],
        ),
      );
    }
  }
}
