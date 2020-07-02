import 'package:flutter/material.dart';
import './websocket.dart';

class StartPage extends StatefulWidget {
  StartPage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _StartPageState createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  @override
  Widget build(BuildContext context) {

    return new Scaffold(
      appBar: new AppBar(
        title: new Text('表情じゃんけん'),
      ),
      body:
      new Center(
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Start'),
              RaisedButton(
                onPressed:
                    () => Navigator.of(context).pushNamed('/websocket'),
                child: new Text('サーバーに接続'),
              )
            ],
          ),
      ),
    );
  }
}

/*
new Container(
        //padding: new EdgeInsets.all(50.0),
        child:
 */