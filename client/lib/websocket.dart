import 'package:flutter/material.dart';
import './camera.dart';

class WebSocketPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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

  void test() {
    Image img = Image.asset("images/gu.jpg");

  }
}

