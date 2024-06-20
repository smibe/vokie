import 'dart:io';
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:vokie/DiContainer.dart';
import 'package:vokie/LessonState.dart';
import 'package:vokie/lesson.dart';
import 'package:vokie/lesson_service.dart';
import 'package:vokie/timedAudioPlayer.dart';
import 'package:vokie/vokable.dart';

@immutable
class LessonView extends StatefulWidget {
  final LessonState state;
  final Lesson lesson;
  final Function onChanged;
  final bool allTargetsVisible;

  LessonView(this.lesson,
      {required this.onChanged, required this.allTargetsVisible})
      : this.state = lesson.data;

  @override
  State<LessonView> createState() => _LessonViewState();
}

class _LessonViewState extends State<LessonView> {
  TimedAudioPlayer audioPlayer = DiContainer.resolve<TimedAudioPlayer>();
  bool playingAudio = false;
  late StreamSubscription<PlayerState> audioPlayerSubscription;

  @override
  void initState() {
    audioPlayerSubscription = audioPlayer.stateChanged.listen((event) {
      setState(() {
        playingAudio = event == PlayerState.playing;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    audioPlayerSubscription.cancel();
    super.dispose();
  }

  final Widget empty = Container(width: 0.0, height: 0.0);

  Future<bool> _hasMp3(Vokabel vokabel) async {
    if (vokabel.mp3 == "") return Future.value(false);
    var service = DiContainer.resolve<LessonService>();
    var file = File(await service.unitLocalDirectory + vokabel.mp3);

    return vokabel.mp3 != "" && await file.exists();
  }

  void onAudioButton(Vokabel vokabel) async {
    if (playingAudio) {
      await audioPlayer.stop();
      return;
    }
    await audioPlayer.playFromPath(
      await DiContainer.resolve<LessonService>().unitLocalDirectory +
          vokabel.mp3,
      startSeconds: vokabel.mp3_start,
      durationSeconds: vokabel.mp3_duration,
    );
  }

  Widget createItem(context, i, List<int> filtered) {
    var idx = filtered[i];
    var vokabel = widget.state.lesson[idx];
    var showTarget = vokabel.showTarget;

    return GestureDetector(
      onTap: () {
        this.widget.lesson.select(idx);
      },
      child: Container(
        padding: EdgeInsets.all(10.0),
        decoration: new BoxDecoration(
            color: idx == this.widget.lesson.data.selected
                ? Color.fromRGBO(220, 220, 220, 1.0)
                : Colors.white),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vokabel.target, style: TextStyle(fontSize: 28.0)),
                    vokabel.target_sentence != "" && showTarget
                        ? Text(vokabel.target_sentence,
                            style: TextStyle(fontSize: 18.0))
                        : empty,
                    showTarget
                        ? SizedBox(
                            height: 10,
                          )
                        : empty,
                    Text(showTarget ? vokabel.source : "",
                        style: TextStyle(fontSize: 18.0)),
                    vokabel.source_sentence != "" && showTarget
                        ? Text(vokabel.source_sentence,
                            style: TextStyle(fontSize: 18.0))
                        : empty,
                    showTarget
                        ? Row(
                            children: [
                              Text(vokabel.correct.toString(),
                                  style: TextStyle(
                                      color: vokabel.correct == 0
                                          ? Colors.black
                                          : Colors.green)),
                              Text(" / "),
                              Text(vokabel.wrong.toString(),
                                  style: TextStyle(
                                      color: vokabel.wrong == 0
                                          ? Colors.black
                                          : Colors.red)),
                            ],
                          )
                        : empty,
                    FutureBuilder(
                      builder: (context, snapshot) {
                        return widget.lesson.data.selected == idx &&
                                snapshot.data != null
                            ? IconButton(
                                icon: Icon(playingAudio
                                    ? Icons.stop
                                    : Icons.play_arrow),
                                onPressed: () {
                                  onAudioButton(vokabel);
                                },
                              )
                            : empty;
                      },
                      future: _hasMp3(vokabel),
                    ),
                  ]),
            ),
            idx == this.widget.state.selected &&
                    vokabel.lastResponse == LastResponse.unknown &&
                    !widget.allTargetsVisible
                ? Container(
                    width: 100,
                    alignment: Alignment.centerRight,
                    child: Column(
                      children: <Widget>[
                        TextButton(
                            onPressed: () {
                              widget.onChanged();
                              if (!widget.state.selectedVokabel.showTarget)
                                this.widget.lesson.showTarget(true);
                              else {
                                this.widget.lesson.correct();
                                this.widget.lesson.select(idx + 1);
                              }
                            },
                            style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                    Color(0xee89fb98))),
                            child: Text(vokabel.showTarget ? "Richtig" : "OK")),
                        vokabel.showTarget
                            ? TextButton(
                                onPressed: () {
                                  this.widget.lesson.wrong();
                                  this.widget.lesson.select(idx + 1);
                                },
                                style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all(
                                        Colors.orangeAccent)),
                                child: Text("Falsch"))
                            : empty,
                      ],
                    ))
                : empty,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var body = Theme.of(context).textTheme.headlineMedium;
    List<int> filtered = [];
    for (var idx = 0; idx < widget.state.lesson.length; idx++) {
      var v = widget.state.lesson[idx];
      if (v.correct - v.wrong < 4 || v.lastResponse != LastResponse.unknown) {
        filtered.add(idx);
      }
    }
    return Column(
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(10),
          color: Color(0xffe0e0e0),
          child: Row(
            children: <Widget>[
              Text(widget.state.name ?? "unknown", style: body),
              Text(
                  "    ${widget.state.currentDone}/${widget.state.total - widget.state.done} (${widget.state.total})",
                  style: body),
            ],
          ),
        ),
        Expanded(
          child: Container(
            child: ListView.builder(
              padding: EdgeInsets.all(10.0),
              itemCount: filtered.length,
              itemBuilder: (c, i) => createItem(c, i, filtered),
            ),
          ),
        ),
      ],
    );
  }
}
