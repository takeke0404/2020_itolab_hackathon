import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

import './util.dart';
import './result.dart';

//final String URL = "ws://133.68.108.164:7532"; // local
final String URL = "ws://18.181.248.47:58822/";  // aws
//final String URL = "ws://18.181.248.47:7532/";  // aws

MyChannel gl_channel;

class MyChannel {
  IOWebSocketChannel channel;
  List<List<String>> face_classes;
  List<List<String>> hands;
  BuildContext context;

  State result_listener;

  void setResultListener(State s) {
    result_listener = s;
  }

  void match() {
    var json = jsonEncode({'type': 'Matching'});
    this.send(json);
  }

  void sendImage(String filePath) {
    File f = new File(filePath);
    List<int> bytes = f.readAsBytesSync();
    var img_str = base64Encode(bytes);
    var raw = {"type":"Judgment", "image" : img_str};
    var json = jsonEncode(raw);
    this.send(json);
  }

  void send(dynamic data) async {
    if (channel != null) {
      await this.channel.sink.add(data);
    }
    else {
      print("channel null");
    }
  }

  var websocket_listener;

  MyChannel(String URL, _WebSocketPageState s) {
    this.face_classes = [
        ['angry'    , '😡'],
        ['disgust'  , '😒'],
        ['fear'     , '😱'],
        ['happy'    , '😆'],
        ['sad'      , '😭'],
        ['surprise' , '😲'],
        ['neutral'  , '😐']
    ];

    this.websocket_listener = s;
    this._connect(URL);
  }

  void _connect(URL) {
    try {
      this.channel = IOWebSocketChannel.connect(URL);

      print(URL);
      print(this.channel);
      this.channel.stream.listen(this.listen);
    } catch(e) {
      print("aaaaaaa");
      print(e.toString());
    }
  }

  var result_flag = false;

  void listen(dynamic msg) {
    var json = jsonDecode(msg);
    print(json);

    switch(json["type"]) {
      case "Matching":
        switch(json["res"]){
          case "Waiting":
            _wait();
            break;
          case "Found":
            _found(json);
            break;
        }
        break;

      case "Judgment":
        switch(json["res"]) {
          case "Not Face":
            break;
          case "Result":
            _result(json);
            break;
        }
        break;

      case "Warning":
        switch(json["res"]) {
          case "Leave":
            _leave();
            break;
          case "Not Image":
            break;
          case "Not Mathcing":
            break;
        }
        break;
    }
  }

  void _wait() {
    websocket_listener.setLoadingFlag(true);
    websocket_listener.setConnectionState("マッチング中...");
  }

  void _found(var json) {
    websocket_listener.setLoadingFlag(false);
    websocket_listener.setConnectionState("マッチング完了!!");
    this.hands = [face_classes[json["gu"]], face_classes[json["tyoki"]], face_classes[json["pa"]]];
    websocket_listener.setJankenHands(this.hands);
  }

  void _leave() {
    // popUntilでエラーが出たので泣く泣くこれに...
    while(navigatorKey.currentState.canPop()) {
      navigatorKey.currentState.pop();
    }
  }

  void _result(var json) {
    if(result_listener != null) {
      result_listener.setState(()
      { this.result_flag = true; });
    }
  }

  void close() {
    this.channel.sink.close();
  }
}

class WebSocketPage extends StatefulWidget {
  @override
  _WebSocketPageState createState() {
    return _WebSocketPageState();
  }
}

class _WebSocketPageState extends State<WebSocketPage> {
  bool loading_flag = true;
  String connection_state = "通信中";

  void setLoadingFlag(var f) {
    this.setState(() {
      this.loading_flag = f;
    });
  }
  void setConnectionState(var s) {
    this.setState(() {
      this.connection_state = s;
    });
  }
  void setJankenHands(var j) async {
    this.setState(() {
      hands = j;
    });

    await Future.delayed(new Duration(seconds: 2));
    navigatorKey.currentState.pushNamed("/camera");
  }

  @override
  void initState() {
    super.initState();
    gl_channel = MyChannel(URL, this);
    gl_channel.match();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('マッチング'),
      ),
      body: new ModalProgressHUD(
          child : new Container(
            padding: new EdgeInsets.all(32.0),
            child: Center(
              child: Container(
                child: Column(
                  children: <Widget>[
                    buildMatchForm(context),
                    (hands != null) ? buildJanken2Face(context) : SizedBox.shrink() ,
                  ],
                ),
              ),
            ),
          ),
        inAsyncCall: this.loading_flag,
        progressIndicator:  CircularProgressIndicator()
      ),
    );
  }

  Widget buildMatchForm(BuildContext context) {
    return Column(
        children: <Widget>[
          Text(connection_state),
        ]
    );
  }


  var hands;
  Widget buildJanken2Face(BuildContext context) {
    return Center(
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          _getHandText("✊", hands[0]),
          _getHandText("✌️", hands[1]),
          _getHandText("✋", hands[2]),
          _getHintText(),
        ],
      ),
    );
  }
  Text _getHintText() {
    return Text(
        'カメラを起動します。',
      style: TextStyle(fontSize: 20),
    );
  }

  Widget _getHandText(String hand, List<String> face) {
    return Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(5.0),
              child: Text(
                  "${face[0]}"
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                    "$hand : ${face[1]}",
                    style: TextStyle(
                        fontSize: 50
                    )
                ),
              ],
            )
          ],
        )
    );
  }

  @override
  void dispose() {
    if(gl_channel != null) {
      gl_channel.close();
      gl_channel = null;
    }
    super.dispose();
  }

}

/*
          RaisedButton(
            child: new Text('cameraへ'),
            onPressed: ()
            => Get.to(CameraPage()),
          ),
 @override
  Widget build(BuildContext context) {
    gl_channel = MyWebSocket(URL);
    gl_channel.match();

    return new Scaffold(
      appBar: new AppBar(
        title: new Text('websocket'),
      ),
      body: new Container(
        padding: new EdgeInsets.all(32.0),
        child: new Center(
          child: new Column(
            children: <Widget>[
              Text('websocket'),
              RaisedButton(
                onPressed: ()
                => Navigator.of(context).pushNamed("/camera"),
                child: new Text('cameraへ'),
              ),
              Container(
                child : new Image.asset(
                  "images/gu.jpg",
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
 */