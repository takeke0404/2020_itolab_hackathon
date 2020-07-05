import 'package:flutter/material.dart';
import 'dart:async';

import 'package:modal_progress_hud/modal_progress_hud.dart';


import './websocket.dart';
import './util.dart';

class ResultNotifier {
  State my_state;
  var flag = false;

  void setStateInstance(State s) {
    my_state = s;
  }
  void setValue(var value) {
    if(my_state != null) {
      my_state.setState(() {
        flag = value;
      });
    }
  }
}

class ResultPage extends StatefulWidget{
  @override
  _ResultPageState createState() {
    return _ResultPageState();
  }
}

class _ResultPageState extends State<ResultPage> {
  Timer my_timer;
  @override
  void initState() {
    gl_channel.setResultListener(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: new AppBar(
          title: new Text('結果'),
        ),
        body: ModalProgressHUD(
          child : (gl_channel.result_flag)
                    ? buildResultForm(context)
                    : buildWaitForm(context),
          inAsyncCall: !gl_channel.result_flag,
          progressIndicator:  CircularProgressIndicator()
        ),
    );
  }

  Widget buildWaitForm(BuildContext context) {
    String txt = "結果待機中...";

    return Container(
      alignment: Alignment.center,
      child: Text(txt, style: TextStyle(fontSize: 20)),
    );
  }

  Widget buildResultForm(BuildContext context) {
    var result_data = gl_channel.result_data;
    var your = result_data["you"];
    var opp = result_data["opp"];
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children : <Widget> [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              getDataText("自分", your),
              getDataText("相手", opp),
            ],
          ),
          getJudge(your, opp, TextStyle(fontSize: 50)),
          RaisedButton(
            onPressed: _toStart,
            child: new Text('タイトルに戻る', style: TextStyle(fontSize: 20),),
          )
        ],
      ),
    );
  }

  void _toStart() {
    while(navigatorKey.currentState.canPop()) {
      navigatorKey.currentState.pop();
    }
  }

  Widget getDataText(String name, var data) {
    int prob = (data["prob"] * 100).round();
    prob = (prob == 0) ? 1 : prob;
    var s1 = TextStyle(fontSize: 30, backgroundColor: Colors.white);
    var s2 = TextStyle(fontSize: 40);
    return Container(
      color: Colors.green,
      padding: EdgeInsets.all(10),
      child: Column(
        children: <Widget>[
          Text(name, style: s1),
          Text('${gl_channel.janken[data["hand"]]} : ${data["class"][1]}' , style: s2,),
          Text('${prob} %' ,style: s2,),
        ],
      )
    );
  }

  Widget getJudge(var your, var opp, TextStyle style) {
    int rst = Janken.judge(your["hand"], opp["hand"]);
    switch(rst) {
      case Janken.DRAW:
        if (your["prob"] > opp["prob"]) {
          return _getWinText(style);
        }
        else if (your["prob"] < opp["prob"]) {
          return _getLoseText(style);
        }
        return _getDrawText(style);
        break;
      case Janken.LOSE:
        return _getLoseText(style);
        break;
      case Janken.WIN:
        return _getWinText(style);
        break;
      default:
        break;
    }
  }

  Text _getWinText(TextStyle style) {
    TextStyle s1 = TextStyle(fontSize: style.fontSize, color:Colors.yellowAccent, backgroundColor: Colors.red);
    return Text("  WIN 😍 ", style: s1);
  }
  Widget _getLoseText(TextStyle style) {
    TextStyle s1 = TextStyle(fontSize: style.fontSize, color:Colors.blue, backgroundColor: Colors.greenAccent);
    return Text("  LOSE 😭  ", style: s1);
  }

  Widget _getLoseText2(TextStyle style) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text("LOSE", style: style,),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text("何で負けたか、明日まで考えといてください。", style: TextStyle(fontSize: 15),),
              Text("そしたら何かが見えてくるはずです。", style: TextStyle(fontSize: 15),),
              Text("ほな、いただきます。", style: TextStyle(fontSize: 15),),
            ],
          ),
        ],
      ),
    );
    //return Text("LOSE!何で負けたか、明日まで考えといてください。そしたら何かが見えてくるはずです。ほな、いただきます。", style:style);
  }

  Text _getDrawText(TextStyle style) {
    return Text("DRAW", style: style,);
  }
}


class Janken {
  // https://qiita.com/mpyw/items/3ffaac0f1b4a7713c869
  static const DRAW = 0;
  static const LOSE = 1;
  static const WIN = 2;
  static const STATUS = ["DRAW", "LOSE", "WIN^^"];
  static int judge(int your, int opp) {
    return (your - opp + 3) % 3;
  }
}