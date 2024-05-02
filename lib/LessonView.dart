import 'dart:io';
import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:vokie/DiContainer.dart';
import 'package:vokie/LessonState.dart';
import 'package:vokie/lesson.dart';
import 'package:vokie/lesson_service.dart';
import 'package:vokie/vokable.dart';

@immutable
class LessonView extends StatelessWidget {
  final LessonState state;
  final Lesson lesson;
  final Function onChanged;
  final bool allTargetsVisible;
  AudioPlayer audioPlayer = AudioPlayer();
  Timer? stopTimer;

  LessonView(this.lesson,
      {required this.onChanged, required this.allTargetsVisible})
      : this.state = lesson.data;

  final Widget empty = Container(width: 0.0, height: 0.0);

  Future<bool> _hasMp3(Vokabel vokabel) async {
    if (vokabel.mp3 == null) return Future.value(false);
    var service = DiContainer.resolve<LessonService>();
    var file = File(await service.unitLocalDirectory + vokabel.mp3);

    return vokabel.mp3 != null && vokabel.mp3 != "" && await file.exists();
  }

  playMp3(Vokabel vokabel) async {
    await audioPlayer.stop();
    stopTimer?.cancel();
    var service = DiContainer.resolve<LessonService>();
    var path = await service.unitLocalDirectory + vokabel.mp3;
    if (File(path).existsSync()) {
      if (vokabel.mp3_duration > 0) {
        await audioPlayer.setReleaseMode(
            ReleaseMode.stop); // Stop the audio when it finishes playing
        // Wait for the audio player to be ready before seeking
        var playerReady = Completer<void>();
        StreamSubscription<PlayerState>? playerStateSubscription;
        playerStateSubscription =
            audioPlayer.onPlayerStateChanged.listen((state) {
          if (state == PlayerState.playing) {
            playerReady.complete();
            playerStateSubscription?.cancel();
          }
        });

        await audioPlayer.play(DeviceFileSource(path));
        await playerReady.future;

        await audioPlayer.seek(Duration(
            seconds: vokabel
                .mp3_start)); // Replace 'start' with the start time in seconds

        // Stop the audio after a specific duration
        stopTimer = Timer(Duration(seconds: vokabel.mp3_duration), () {
          // Replace 'duration' with the duration in seconds
          audioPlayer.stop();
        });
      } else {
        await audioPlayer.play(DeviceFileSource(path));
      }
    }
  }

  Widget createItem(context, i, List<int> filtered) {
    var idx = filtered[i];
    var vokabel = state.lesson[idx];
    var showTarget = vokabel.showTarget;

    if (idx == this.state.selected) {
      var s = vokabel.lastResponse;
    }

    return GestureDetector(
      onTap: () {
        this.lesson.select(idx);
      },
      child: Container(
        padding: EdgeInsets.all(10.0),
        decoration: new BoxDecoration(
            color: idx == this.lesson.data.selected
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
                        return lesson.data.selected == idx &&
                                snapshot.data != null
                            ? IconButton(
                                icon: Icon(Icons.play_arrow),
                                onPressed: () {
                                  playMp3(vokabel);
                                },
                              )
                            : empty;
                      },
                      future: _hasMp3(vokabel),
                    ),
                  ]),
            ),
            idx == this.state.selected &&
                    vokabel.lastResponse == LastResponse.unknown &&
                    !allTargetsVisible
                ? Container(
                    width: 100,
                    alignment: Alignment.centerRight,
                    child: Column(
                      children: <Widget>[
                        TextButton(
                            onPressed: () {
                              onChanged();
                              if (!state.selectedVokabel.showTarget)
                                this.lesson.showTarget(true);
                              else {
                                this.lesson.correct();
                                this.lesson.select(idx + 1);
                              }
                            },
                            style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all(
                                    Color(0xee89fb98))),
                            child: Text(vokabel.showTarget ? "Richtig" : "OK")),
                        vokabel.showTarget
                            ? TextButton(
                                onPressed: () {
                                  this.lesson.wrong();
                                  this.lesson.select(idx + 1);
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
    var body = Theme.of(context).textTheme.headline5;
    List<int> filtered = [];
    for (var idx = 0; idx < state.lesson.length; idx++) {
      var v = state.lesson[idx];
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
              Text(state.name ?? "unknown", style: body),
              Text(
                  "    ${state.currentDone}/${state.total - state.done} (${state.total})",
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
