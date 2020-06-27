import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import './camera.dart';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

IOWebSocketChannel channel = null;
var tmptmp = 123;

void sendImage(String filePath) {
  File f = new File(filePath);
  List<int> bytes = f.readAsBytesSync();
  var img_str = base64Encode(bytes);
  var raw = {"type":"Judgement", "image" : img_str};
  var json = jsonEncode(raw);
  send(json);
}


void send(dynamic data) async {
  if (channel != null) {
    await channel.sink.add(data);
  }
  else {
    print("channel null");
  }
}

class WebSocketPage extends StatefulWidget {
  @override
  _WebSocketPageState createState() {
    return _WebSocketPageState();
  }
}

class _WebSocketPageState extends State<WebSocketPage> {
  final String URL = "ws://133.68.108.164:7532";

  void _connect() {
    try {
      channel = IOWebSocketChannel.connect(URL);
      channel.stream.listen((msg) {
        var d = jsonDecode(msg);
        print(d);
      });
    } catch(e) {
      print(e.toString());
    }
  }

  void test() async {
    //await Future.delayed(Duration(milliseconds: 20));
    var scores = {'type': 'Matching'};

    var jsonText = jsonEncode(scores);
    await send(jsonText);
  }

  void _match() {
    var json = jsonEncode({'type': 'Matching'});
    send(json);
  }

  @override
  Widget build(BuildContext context) {
    _connect();
    _match();

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

//  @override
//  void dispose() {
//    channel.sink.close();
//    super.dispose();
//  }
}