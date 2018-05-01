import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

void main() {
  timeDilation = 10.0;
  runMyApp(new MyApp());
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

// Provides a binding different from the regular Flutter binding so that
// diagrams can control their timeline and physical device size.
class _BenchmarkBinding extends BindingBase with GestureBinding, ServicesBinding, SchedulerBinding, PaintingBinding, RendererBinding, WidgetsBinding {
  @override
  void initInstances() {
    super.initInstances();
  }

  /// The current [_DiagramFlutterBinding], if one has been created.
  static _BenchmarkBinding get instance {
    _instance ??= new _BenchmarkBinding();
    return _instance;
  }

  static _BenchmarkBinding _instance;
  DateTime _lastBeginFrame;
  DateTime _firstBeginFrame;
  int frameCount = 0;

  @override
  void handleBeginFrame(Duration rawTimeStamp) {
    if (_firstBeginFrame == null) {
      _firstBeginFrame = new DateTime.now();
    }
    super.handleBeginFrame(rawTimeStamp);
    _lastBeginFrame = new DateTime.now();
  }

  @override
  void handleDrawFrame() {
    super.handleDrawFrame();
    frameCount++;
  }

  String reportResults() {
    Duration totalFrameTime = _lastBeginFrame.difference(_firstBeginFrame);
    Duration averageFrameTime = new Duration(milliseconds: totalFrameTime.inMilliseconds ~/ frameCount);
    String result = '${frameCount/2.0}\tTotal frames $frameCount, average frame time: $averageFrameTime, time: $totalFrameTime';
    _firstBeginFrame = null;
    _lastBeginFrame = null;
    frameCount = 0;
    return result;
  }
}

void runMyApp(Widget app) {
  _BenchmarkBinding.instance
    ..attachRootWidget(app)
    ..scheduleWarmUpFrame();
}

class CaptureImage extends StatefulWidget {
  @override
  State createState() => new CaptureImageState();
}

class CaptureImageState extends State<CaptureImage> with TickerProviderStateMixin<CaptureImage> {
  bool _hasAvatar = true;
  bool _hasImageAvatar = true;
  bool _hasDeleteButton = true;
  bool _enabled = true;
  static int _defaultChipCount = 1;
  static bool _defaultSelected = false;
  int _numChips = _defaultChipCount;
  List<bool> _selected = List<bool>.generate(_defaultChipCount, (int index) => _defaultSelected);

  Widget makeMockChip(int index, Color color) {
    return new Container(width: 100.0, height: 32.0, color: color);
  }

  Widget makeChip(int index) {
    return new Padding(
      padding: const EdgeInsets.all(8.0),
      child: new InputChip(
        avatar: _hasAvatar
            ? new CircleAvatar(
                backgroundImage: _hasImageAvatar ? AssetImage('assets/ali-connors.png') : null,
                child: _hasImageAvatar ? null : const Text('H'),
              )
            : null,
        selected: _selected[index],
        onSelected: _enabled
            ? (bool value) {
                setState(() {
                  print('selected: $value');
                  _selected[index] = value;
                });
              }
            : null,
        onDeleted: _hasDeleteButton ? (_enabled ? () {} : null) : null,
        label: new Text('Hello'),
      ),
    );
  }

  void addAChip() {
    _numChips++;
    _selected.add(_defaultSelected);
  }

  void _reset() {
    _numChips = _defaultChipCount;
    _selected = List<bool>.generate(_defaultChipCount, (int index) => false);
    _hasAvatar = true;
  }

  Widget _createControls() {
    return new Column(
      children: <Widget>[
        new Padding(
          padding: const EdgeInsets.all(8.0),
          child: new Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              new RaisedButton(
                onPressed: () async {
                  setState(() {
                    _hasAvatar = !_hasAvatar;
                  });
                },
                child: const Text('Behead'),
              ),
              new RaisedButton(
                onPressed: () async {
                  setState(() {
                    _enabled = !_enabled;
                  });
                },
                child: const Text('Disable'),
              ),
              new RaisedButton(
                onPressed: () async {
                  setState(_reset);
                },
                child: const Text('Reset'),
              ),
            ],
          ),
        ),
        new Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new RaisedButton(
              onPressed: () async {
                setState(() {
                  --_numChips;
                  _selected.removeLast();
                });
              },
              child: const Text('-'),
            ),
            new RaisedButton(
              onPressed: () async {
                setState(addAChip);
              },
              child: const Text('+'),
            ),
          ],
        ),
      ],
    );
  }

  AnimationController themeController;
  Tween<double> changeTween = new Tween<double>(begin: 0.0, end: 360.0);
  bool _firstBuild = true;

  @override
  void initState() {
    super.initState();
    themeController = new AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) {
          String message = _BenchmarkBinding.instance.reportResults();
          print('Chip count:\t$_numChips\t$message');
//          if (_numChips < 25) {
//            addAChip();
//            themeController.value = 0.0;
//            themeController.forward();
//          }
        }
      });
  }

  Color _getColor() {
    return new HSVColor.fromAHSV(
      1.0,
      changeTween.evaluate(themeController),
      0.5,
      0.5,
    ).toColor();
  }

  Color _getSelectColor() {
    return new HSVColor.fromAHSV(
      1.0,
      changeTween.evaluate(themeController),
      0.75,
      0.75,
    ).toColor();
  }

  @override
  Widget build(BuildContext context) {
    if (_firstBuild) {
      themeController.forward();
      _firstBuild = false;
    }
//    return new Column(
//      mainAxisAlignment: MainAxisAlignment.center,
//      children: <Widget>[
//        new Wrap(children: new List<Widget>.generate(_numChips, (int index) => makeMockChip(index, _getColor()))),
//        //_createControls(),
//      ],
//    );

    return new ChipTheme(
      data: ChipTheme.of(context).copyWith(backgroundColor: _getColor(), selectedColor: _getSelectColor()),
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          new Wrap(children: new List<Widget>.generate(_numChips, (int index) => makeChip(index))),
          //_createControls(),
        ],
      ),
    );
  }
}
