import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart' show timeDilation;
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
      home: new MyHomePage(title: 'Testing Test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  MyHomePage({Key key, this.title}) : super(key: key);

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool selected = false;
  final GlobalKey chipKey = new GlobalKey();

  @override
  Widget build(BuildContext context) {
    timeDilation = 1.0;

    return new MaterialApp(
      home: new Material(
        child: new Center(
          child: new CastFilter(),
        ),
      ),
    );
  }
}

class ActorFilterEntry {
  const ActorFilterEntry(this.name, this.initials);
  final String name;
  final String initials;
}

class CastFilter extends StatefulWidget {
  @override
  State createState() => new CastFilterState();
}

class CastFilterState extends State<CastFilter> {
  final List<ActorFilterEntry> _cast = <ActorFilterEntry>[
    const ActorFilterEntry('Aaron Burr', 'AB'),
    const ActorFilterEntry('Alexander Hamilton', 'AH'),
    const ActorFilterEntry('Eliza Hamilton', 'EH'),
    const ActorFilterEntry('James Madison', 'JM'),
  ];
  List<String> _filters = <String>[];

  final GlobalKey boundaryKey = new GlobalKey();

  Iterable<Widget> get actorWidgets sync* {
    for (ActorFilterEntry actor in _cast) {
      yield new Padding(
        padding: const EdgeInsets.all(4.0),
        child: new FilterChip(
          avatar: new CircleAvatar(child: new Text(actor.initials)),
          label: new Text(actor.name),
          selected: _filters.contains(actor.name),
          onSelected: (bool value) {
            setState(() {
              if (value) {
                _filters.add(actor.name);
              } else {
                _filters.removeWhere((String name) {
                  return name == actor.name;
                });
              }
            });
          },
        ),
      );
    }
  }

  Future<image.Image> getImage(RenderObject object) async {
    ui.Image capture = await object.toImage();
    ByteData data = await capture.toByteData();
    const int offset = 10000;
    for (int i = 0; i < 10; ++i) {
      print('Data[${i + offset}]: 0x${data.getUint32(i+offset).toRadixString(16).padLeft(8, '0')}');
    }
    return new image.Image.fromBytes(capture.width, capture.height, data.buffer.asUint32List());
  }

  Future<File> writeFile(image.Image outputImage) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final File outputFile = new File(path.join(directory.path, 'test.png'));
    print('Writing image to ${outputFile.absolute.path}');
    return outputFile.writeAsBytes(image.encodePng(outputImage));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        new RepaintBoundary(
          key: boundaryKey,
          child: new Wrap(
            children: actorWidgets.toList(),
          ),
        ),
        new Text('Look for: ${_filters.join(', ')}'),
        new RaisedButton(
          onPressed: () async {
            final image.Image chipImage = await getImage(boundaryKey.currentContext.findRenderObject());
            await writeFile(chipImage);
          },
          child: const Text('Snap'),
        ),
      ],
    );
  }
}
