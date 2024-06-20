import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vokie/DiContainer.dart';
import 'package:vokie/LessonView.dart';
import 'package:vokie/jsonApi.dart';
import 'package:vokie/jsonHttp_api.dart';

import 'package:vokie/json_object.dart';
import 'package:vokie/lesson.dart';
import 'package:vokie/lesson_service.dart';
import 'package:vokie/settingsView.dart';
import 'package:vokie/storage.dart';
import 'package:vokie/timedAudioPlayer.dart';
import 'package:vokie/unit_view.dart';
import 'package:vokie/vokable.dart';

void main() async {
  await initialize();
  runApp(new MyApp());
}

Future initialize() async {
  WidgetsFlutterBinding.ensureInitialized();
  DiContainer.setInstance<JsonApi>(new JsonHttpApi());
  var sharedPreferences = await SharedPreferences.getInstance();
  DiContainer.setInstance<SharedPreferences>(sharedPreferences);
  DiContainer.setInstance<Storage>(Storage());
  DiContainer.setInstance<LessonService>(LessonService());
  DiContainer.setInstance<TimedAudioPlayer>(TimedAudioPlayer());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Vokabeltrainer',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Vokie'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var lessonsJson = """
  {
    "name": "dummy",
    "source": "Deutsch",
    "destination": "English",
    "words":[
    ]
  }""";

  _MyHomePageState() {
    var jsonLessons = JsonObject.fromDynamic(json.decode(lessonsJson));
    this.lessonController = Lesson(jsonLessons);
  }

  late Lesson lessonController;
  String view = "lesson";

  late Storage _storage;
  bool _hasChanged = false;

  bool _playingAudio = false;

  late LessonService service;
  late List<Vokabel> lesson;

  int selected = 0;
  bool allTargetsVisible = false;

  Widget empty = Container(width: 0.0, height: 0.0);
  late Timer _timer;

  List<int> setVisible = [];
  void allVisible() {
    setVisible.clear();
    for (int i = 0; i < lesson.length; i++) {
      if (!lesson[i].showTarget) {
        lesson[i].showTarget = true;
        setVisible.add(i);
      }
    }
    allTargetsVisible = true;
  }

  void restart() {
    for (var v in lesson) {
      v.showTarget = false;
      v.lastResponse = LastResponse.unknown;
    }
  }

  void resetVisible() {
    for (var idx in setVisible) lesson[idx].showTarget = false;
    allTargetsVisible = false;
  }

  void toggleVisible() {
    if (allTargetsVisible)
      resetVisible();
    else
      allVisible();
  }

  Future onAudioButton() async {
    var audioPlayer = DiContainer.resolve<TimedAudioPlayer>();
    var directory =
        await DiContainer.resolve<LessonService>().unitLocalDirectory;

    if (!_playingAudio)
      await audioPlayer.stop();
    else {
      for (var v in lesson) {
        if (v.mp3 != "") {
          if (!_playingAudio) break;
          await audioPlayer.playFromPath(directory + v.mp3,
              startSeconds: v.mp3_start, durationSeconds: v.mp3_duration);
          if (!_playingAudio) break;
          await Future.delayed(Duration(seconds: v.mp3_duration));
        }
      }
    }
  }

  void save() {
    if (_hasChanged) {
      service.storeCurrentLesson(_storage, lessonController);
    }
    _hasChanged = false;
  }

  @override
  void initState() {
    _storage = DiContainer.resolve<Storage>();

    _timer = Timer.periodic(Duration(seconds: 5), (t) {
      save();
    });

    getCurrentLesson();

    _storage.valueChanged("current_idx").add((v) {
      getCurrentLesson();
    });

    var audioPlayer = DiContainer.resolve<TimedAudioPlayer>();
    audioPlayer.stateChanged.listen((event) {
      setState(() {
        _playingAudio = event == PlayerState.playing;
      });
    });

    super.initState();
  }

  void getCurrentLesson() {
    this.service = DiContainer.resolve<LessonService>();
    service.getCurrentLesson(_storage).then((l) {
      var firstLesson = l.data.lesson;
      this.lessonController = l;
      this.lessonController.hasChanged.add((s) => setState(() {}));
      setState(() => this.lesson = firstLesson);
    });
  }

  @override
  void dispose() {
    save();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var iconColor = Theme.of(context).appBarTheme.backgroundColor;
    var selectedIconColor = Theme.of(context).unselectedWidgetColor;
    var scaffold = new Scaffold(
        appBar: new AppBar(title: Text(widget.title), actions: <Widget>[
          view == "lesson"
              ? IconButton(
                  icon: Icon(Icons.refresh),
                  onPressed: () => setState(() => restart()),
                )
              : empty,
          view == "lesson"
              ? GestureDetector(
                  onTap: () => setState(() => toggleVisible()),
                  child: IconButton(
                      color: allTargetsVisible ? selectedIconColor : iconColor,
                      icon: Icon(Icons.visibility),
                      onPressed: () => setState(() => toggleVisible())),
                )
              : empty,
          view == "lesson"
              ? IconButton(
                  icon: Icon(_playingAudio ? Icons.stop : Icons.play_arrow),
                  onPressed: () async {
                    setState(() => _playingAudio = !_playingAudio);
                    await onAudioButton();
                  },
                )
              : empty,
          IconButton(
            icon: Icon(
              Icons.check_box_outline_blank,
              color: view == "lesson" ? selectedIconColor : iconColor,
              size: view == "lesson" ? 34 : 24,
            ),
            onPressed: () {
              setState(() => view = "lesson");
            },
          ),
          IconButton(
            icon: Icon(
              Icons.list,
              color: view == "unit" ? selectedIconColor : iconColor,
              size: view == "unit" ? 34 : 24,
            ),
            onPressed: () {
              setState(() => view = "unit");
            },
          ),
          IconButton(
            icon: Icon(
              Icons.settings,
              size: view == "settings" ? 34 : 24,
              color: view == "settings" ? selectedIconColor : iconColor,
            ),
            onPressed: () {
              setState(() => view = "settings");
            },
          ),
        ]),
        body: getView(view));
    return scaffold;
  }

  Widget getView(String view) {
    switch (view) {
      case "lesson":
        return LessonView(this.lessonController,
            onChanged: () => _hasChanged = true,
            allTargetsVisible: allTargetsVisible);
      case "unit":
        return UnitView();
      case "settings":
        return SettingsView();
      default:
        return empty;
    }
  }
}
