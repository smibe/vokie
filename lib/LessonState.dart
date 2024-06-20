import 'package:flutter/services.dart';
import 'package:vokie/vokable.dart';

import 'json_object.dart';

class LessonState {
  String name = "";
  List<Vokabel> lesson = [];
  int correctCountForDone = 4;
  int selected = 0;
  Vokabel get selectedVokabel => lesson[selected];

  LessonState();
  LessonState.fromJson(dynamic obj) {
    name = obj["name"] ?? "";
    lesson = getWords(JsonObject(obj));
  }

  List<Vokabel> getWords(JsonObject values) {
    List<Vokabel> result = [];
    for (var word in values.getList("words")) {
      result.add(Vokabel.fromDynamic(word));
    }
    return result;
  }

  int get total => lesson.length;

  int get done => lesson.where((x) => x.correct - x.wrong >= correctCountForDone).length;
  int get currentDone => lesson.where((x) => x.showTarget).length;
  int get totalCorrectCount => lesson.fold(0, (sum, vokabel) => sum + (vokabel.correct - vokabel.wrong));
  int get progress => (totalCorrectCount * 100.0 / (lesson.length * correctCountForDone)).toInt();

  toJson() {
    return {
      "name": name,
      "words": lesson,
    };
  }
}
