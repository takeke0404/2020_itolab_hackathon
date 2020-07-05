import 'package:flutter/material.dart';
import './websocket.dart';

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
  @override
  void initState() {
    gl_channel.setResultListener(this);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: new AppBar(
          title: new Text('結果画面'),
        ),
        body: (gl_channel.result_flag)
            ? Text("resultオオおおお")
            : SizedBox.shrink(),
    );
  }
}