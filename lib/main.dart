import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image/image.dart' as image;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

void main() {
  runApp(new MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Material(
        child: new Center(
          child: new CaptureImage(),
        ),
      ),
    );
  }
}

class CaptureImage extends StatefulWidget {
  @override
  State createState() => new CaptureImageState();
}

class CaptureImageState extends State<CaptureImage> {
  final GlobalKey _boundaryKey = new GlobalKey();

  Future<image.Image> getImage(RenderRepaintBoundary object) async {
    ui.Image capture = await object.toImage(pixelRatio: 2.0);
    ByteData data = await capture.toByteData();
    return new image.Image.fromBytes(capture.width, capture.height, data.buffer.asUint32List());
  }

  Future<File> writeFile(image.Image outputImage) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File outputFile = new File(path.join(directory.path, 'test.png'));
    List<int> output = image.encodePng(outputImage);
    print('Writing image to ${outputFile.absolute.path} (${output.length} bytes)');
    return outputFile.writeAsBytes(output);
  }

  @override
  Widget build(BuildContext context) {
    return new Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        new RepaintBoundary(
          key: _boundaryKey,
          child: new Chip(
            avatar: new CircleAvatar(child: new Text('H')),
            label: new Text('Hello'),
          ),
        ),
        new RaisedButton(
          onPressed: () async {
            final image.Image chipImage = await getImage(_boundaryKey.currentContext.findRenderObject());
            await writeFile(chipImage);
          },
          child: const Text('Snap'),
        ),
      ],
    );
  }
}
