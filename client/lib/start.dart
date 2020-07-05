import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutterapp/util.dart';
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
        title: new Text('title'),
      ),
      body:
      new Center(
          child: new Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Image.asset(
                'images/title.png',
                width: 300,),
              RaisedButton(
                onPressed:
                    () => navigatorKey.currentState.pushNamed('/websocket'),
                child: new Text('対戦相手を探す'),
              ),
              RaisedButton(
                onPressed: _showDialog,
                child: new Text('ヘルプ'),
              )
            ],
          ),
      ),
    );
  }

  void _showDialog() {
    var value = showDialog(context: context,
        builder: (BuildContext context) => new AlertDialog(
            title : new Text('ヘルプ　'),
            content: SingleChildScrollView (
              child : ListBody(
                  children : <Widget> [
                    Text("顔の表情をAIが読み取り、その結果を使ってじゃんけんをするゲームです。"),
                    //Text("じゃんけんはランダムにマッチングした相手と行います。")
                  ]
              ),
            ),
            actions: <Widget> [
              FlatButton(
                child: Text("OK"),
                onPressed: () => Navigator.pop(context),
              ),
            ]
        ));
  }

}

/*
new Container(
        //padding: new EdgeInsets.all(50.0),
        child:
 */