import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import './camera.dart';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

//final String URL = "ws://133.68.108.164:7532"; // local
final String URL = "ws://18.181.248.47:58822/";  // aws
//final String URL = "ws://18.181.248.47:7532/";  // aws

MyChannel gl_channel;

class MyChannel {
  IOWebSocketChannel channel;
  List<String> face_classes;
  List<int> hands;

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

  var notify_state;

  MyChannel(String URL, _WebSocketPageState s) {
    this.face_classes = [
        'angry',
        'disgust',
        'fear',
        'happy',
        'sad',
        'surprise',
        'neutral'
    ];

    this.notify_state = s;
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
        break;

      case "Warning":
        break;
    }
  }
  bool wait_flg = false;
  void _wait() {
    //this.notify_state.setState(() {this.notify_state.flag = true;});
    notify_state.setFlag(false);
    notify_state.setConnectionState("マッチング中");
    print("wait");
  }

  void _found(var json) {
    //this.notify_state.setState(() {this.notify_state.flag = false;});
    notify_state.setFlag(false);
    notify_state.setConnectionState("マッチング完了!!");
    print("found");
    this.hands = [json["gu"], json["tyoki"], json["pa"]];


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
  bool flag = true;
  String connection_state = "通信中";

  void setFlag(var f) {
    this.setState(() {
      this.flag = f;
    });
  }

  void setConnectionState(var s) {
    this.setState(() {
      this.connection_state = s;
    });
  }

  @override
  void initState() {
    super.initState();
    gl_channel = MyChannel(URL, this);
    gl_channel.match();
    print("aa");
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text('websocket'),
      ),
      body: new ModalProgressHUD(
          child : new Container(
            padding: new EdgeInsets.all(32.0),
            child: buildMatchForm(context),
          ),
        inAsyncCall: this.flag,
        progressIndicator:  CircularProgressIndicator(semanticsLabel: "aaa",
        )
      ),
    );
  }

  Widget buildMatchForm(BuildContext context) {
    return new Center(
      child: new Column(
        children: <Widget>[
          Text(connection_state),
          RaisedButton(
            onPressed: ()
            => Navigator.of(context).pushNamed("/camera"),
            child: new Text('cameraへ'),
          ),
          Container(
            child : Column(
              children : <Widget>[
                Row(
                  children : <Widget>[
                    Image.asset(
                      "images/gu.png",
                      //fit: BoxFit.cover,
                    ),
                    Image.asset(
                      "images/pa.png",
                      fit: BoxFit.cover,
                    )
                  ]
                )
              ],
            ),
          ),
        ],
      ),
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