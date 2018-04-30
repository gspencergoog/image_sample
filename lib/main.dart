import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

void main() {
  timeDilation = 5.0;
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
    _lastBeginFrame = new DateTime.now();
    _lastDrawFrame = new DateTime.now();
  }

  /// The current [_DiagramFlutterBinding], if one has been created.
  static _BenchmarkBinding get instance {
    _instance ??= new _BenchmarkBinding();
    return _instance;
  }

  static _BenchmarkBinding _instance;
  DateTime _lastBeginFrame;
  DateTime _lastDrawFrame;

  @override
  void handleBeginFrame(Duration rawTimeStamp) {
    super.handleBeginFrame(rawTimeStamp);
    DateTime newTime = new DateTime.now();
//    print('BEGIN: ${newTime.difference(_lastBeginFrame)} $rawTimeStamp');
    _lastBeginFrame = newTime;
  }

  @override
  void handleDrawFrame() {
    super.handleDrawFrame();
    DateTime newTime = new DateTime.now();
//    print('DRAW: ${newTime.difference(_lastDrawFrame)}');
    _lastDrawFrame = newTime;
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
  bool _enabled = true;
  static int _defaultChipCount = 20;
  int _numChips = _defaultChipCount;
  List<bool> _selected = List<bool>.generate(_defaultChipCount, (int index) => false);

  Widget makeChip(int index) {
    return new Padding(
      padding: const EdgeInsets.all(8.0),
      child: new InputChip(
        avatar: _hasAvatar ? new CircleAvatar(child: new Text('H')) : null,
        selected: _selected[index],
        onSelected: _enabled
            ? (bool value) {
                setState(() {
                  _selected[index] = value;
                });
              }
            : null,
        onDeleted: _enabled ? () {} : null,
        label: new Text('Hello'),
      ),
    );
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
                setState(() {
                  ++_numChips;
                  _selected.add(false);
                });
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
    )..addListener(() {
        setState(() {});
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

  @override
  Widget build(BuildContext context) {
    if (_firstBuild) {
      themeController.forward();
      _firstBuild = false;
    }
    return new ChipTheme(
      data: ChipTheme.of(context).copyWith(backgroundColor: _getColor()),
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
