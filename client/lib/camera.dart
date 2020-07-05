import 'package:flutter/material.dart';
import './util.dart';
import './websocket.dart';


import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';


List<CameraDescription> cameras = [];

void initCamera() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras();
  } on CameraException catch (e) {
    logError(e.code, e.description);
  }
}

class CameraPage extends StatefulWidget {
  @override
  _CameraPageState createState() {
    return _CameraPageState();
  }
}

class _CameraPageState extends State<CameraPage>
    with WidgetsBindingObserver {

  CameraController controller;
  String imagePath;
  Image image;
  bool enableAudio = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    CameraDescription c;
    if (cameras.length >= 2) {
      CameraDescription c = cameras[0];
      onNewCameraSelected(c);
    }
    else if(cameras.length == 1) {
      CameraDescription c = cameras[0];
      onNewCameraSelected(c);
    }
    else {
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (controller != null) {
        onNewCameraSelected(controller.description);
      }
    }
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text('表情じゃんけん'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.camera_rear),
            onPressed: () => setState(() {
              onNewCameraSelected(cameras[0]);
            }),
          ),
          IconButton(
            icon: Icon(Icons.camera_front),
            onPressed: () => setState(() {
              onNewCameraSelected(cameras[1]);
            }),
          ),
        ],
      ),
      body:
          Stack(
            children: <Widget>[
              Center(
                child: _cameraPreviewWidget(),
              ),
              Align(
                alignment : Alignment(0.0, 0.8),
                child: _captureControlRowWidget(),
              )
            ],
          fit: StackFit.expand,
          ),
    );
  }

  /// Display the preview from the camera (or a message if the preview is not available).
  Widget _cameraPreviewWidget() {
    if (controller == null || !controller.value.isInitialized) {
      return const Text(
        'カメラが取得できません',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    } else {
      return AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: CameraPreview(controller),
      );
    }
  }

  /// Display the control bar with buttons to take pictures and record videos.
  Widget _captureControlRowWidget() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: <Widget>[
        FloatingActionButton.extended(
          onPressed: controller != null &&
              controller.value.isInitialized &&
              !controller.value.isRecordingVideo
              ? onTakePictureButtonPressed
              : null,
          icon: new Icon(Icons.camera_alt),
          label: Text("顔を撮影"),
        )
      ],
    );
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();

  void showInSnackBar(String message) {
    Scaffold.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    if (controller != null) {
      await controller.dispose();
    }
    controller = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    // If the controller is updated then update the UI.
    controller.addListener(() {
      if (mounted) setState(() {});
      if (controller.value.hasError) {
        showInSnackBar('Camera error ${controller.value.errorDescription}');
      }
    });

    try {
      await controller.initialize();
    } on CameraException catch (e) {
      _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  void onTakePictureButtonPressed() {
    takePicture().then((String filePath) {
      if (mounted) {
        setState(() {
          imagePath = filePath;
        });
        if (filePath != null) {
          //showInSnackBar('Picture saved to $filePath');
          image = new Image.file(File(imagePath));
          _showDialog();
        }
      }
    });
  }

  void confirmDialog() {
    Navigator.pop(context);
    gl_channel.sendImage(imagePath);
    Navigator.pushNamed(context, '/result');
  }

  Future _showDialog() async {
    var value = await showDialog(
        context: context,
        builder: (BuildContext context) => new AlertDialog(
          title : new Text('dialog'),
          content: SingleChildScrollView (
            child : ListBody(
              children : <Widget> [
                  image
              ]
            ),
          ),
            actions: <Widget> [
              FlatButton(
                child: Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
              FlatButton(
                child: Text("OK"),
                onPressed: confirmDialog,
              ),
            ]
      )
    );
  }

  Future<String> takePicture() async {
    if (!controller.value.isInitialized) {
      showInSnackBar('Error: select a camera first.');
      return null;
    }
    final Directory extDir = await getApplicationDocumentsDirectory();
    final String dirPath = '${extDir.path}/Pictures/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';

    if (controller.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      await controller.takePicture(filePath);
    } on CameraException catch (e) {
      _showCameraException(e);
      return null;
    }
    return filePath;
  }

  void _showCameraException(CameraException e) {
    logError(e.code, e.description);
    showInSnackBar('Error: ${e.code}\n${e.description}');
  }

}

/*
          Expanded(
            child: Container(
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: Center(
                  child: _cameraPreviewWidget(),
                ),
              ),
              decoration: BoxDecoration(
                color: Colors.black,
                border: Border.all(
                  color: controller != null && controller.value.isRecordingVideo
                      ? Colors.redAccent
                      : Colors.grey,
                  width: 3.0,
                ),
              ),
            ),
          ),
          _captureControlRowWidget(),
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                _cameraTogglesRowWidget(),
              ],
            ),
          ),


  /// Display a row of toggle to select the camera (or a message if no camera is available).
  Widget _cameraTogglesRowWidget() {
    final List<Widget> toggles = <Widget>[];

    if (cameras.isEmpty) {
      return const Text('No camera found');
    } else {
      bool tmp = true;
      for (CameraDescription cameraDescription in cameras) {
        toggles.add(
          SizedBox(
            width: 90.0,
            child: RadioListTile<CameraDescription>(
              title: Icon(getCameraLensIcon(cameraDescription.lensDirection)),
              groupValue: controller?.description,
              value: cameraDescription,
              onChanged: controller != null && controller.value.isRecordingVideo
                  ? null
                  : onNewCameraSelected,
              selected: tmp,
            ),
          ),
        );
        tmp = false;
      }
    }

    return Row(children: toggles);
  }
  /// Display the thumbnail of the captured image or video.
  Widget _thumbnailWidget() {
    return Expanded(
      child: Align(
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            imagePath == null
                ? Container()
                : SizedBox(
              child: Image.file(File(imagePath)),
              width: 64.0,
              height: 84.0,
            ),
          ],
        ),
      ),
    );
  }
 */