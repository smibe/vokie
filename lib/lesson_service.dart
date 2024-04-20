import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:vokie/DiContainer.dart';
import 'package:vokie/jsonApi.dart';
import 'package:vokie/json_object.dart';
import 'package:vokie/lesson.dart';
import 'package:vokie/storage.dart';

const String basicFrench = "1NRV9j0bzBAd-_0P_gdioNy24E6oE7dHL_dNSGY12nd4";
const String frenchSentences = "1XZBTlZf_Mc-Nqb6ONGhKFf0VGNZ-RoJA0YzcohMP3-M";
const String frenchSentencesMp3 = "1odtqPztmBW_Ada61BJrlb2WidqQrQmXq";

class LessonService {
  JsonApi api = DiContainer.resolve<JsonApi>();
  List<dynamic> _units = [];
  var storage = DiContainer.resolve<Storage>();

  Future<Lesson> getCurrentLesson(Storage storage) async {
    if (!storage.containsKey("current")) {
      var idx = storage.get("current_idx", 0);
      return getLesson(storage, idx: idx);
    }

    var fileName = storage.getString("current");
    if (!await File(fileName).exists()) return getLesson(storage);

    return await loadLesson(storage.getString("current"));
  }

  Future updateCurrentLesson() async {
    var storage = DiContainer.resolve<Storage>();
    var lesson = await getCurrentLesson(storage);
    var updatedLesson = await loadUpdatedLesson();
    if (lesson.data.lesson.length < updatedLesson.data.lesson.length) {
      lesson.data.lesson
          .addAll(updatedLesson.data.lesson.sublist(lesson.data.lesson.length));
      await storeCurrentLesson(storage, lesson);
    }
  }

  Future<Lesson> loadUpdatedLesson() async {
    var storage = DiContainer.resolve<Storage>();
    var idx = storage.get("current_idx", 0);
    var unit = storage.get(
        "current_unit_id", _units.length <= 0 ? "" : _units[0]["id"]);
    var data = await getData(format: "csv", unit: unit);
    if (!data.isEmpty()) return getPlainLessonFromData(data, idx);
    return getCurrentLesson(storage);
  }

  void resetUnits() => _units = [];

  Future<List<dynamic>> getUnits() async {
    if (_units.length != 0) return _units;

    var learnContentId = storage.get("learnContentId", "");
    if (learnContentId != "") {
      var content = await api.getJsonById(learnContentId, source: "gdoc");
      if (!content.isEmpty() && content.data.containsKey("learnContent")) {
        _units = content.getList("learnContent");
      }
    }
    if (_units.isEmpty) {
      _units = [
        {
          "name": "Basiswortschatz",
          "id": basicFrench,
        },
        {
          "name": "Französische Sätze",
          "id": frenchSentences,
          "mp3": frenchSentencesMp3,
        }
      ];
    }

    return _units;
  }

  Future storeCurrentLesson(Storage storage, Lesson lesson) async {
    storage.set("current", await toFileName(lesson));
    return storeLesson(lesson);
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path + "/";
  }

  Future<String> get unitLocalDirectory async {
    var unit = storage.getString("current_unit_id");
    if (unit == null) unit = "null";
    return await _localPath + unit + "/";
  }

  Future<Lesson> loadLesson(String fileName) async {
    var content = await File(fileName).readAsString();
    return Lesson.parse(content);
  }

  Future<Map<String, String>> getCurrentUnit() async {
    var currentUnitId = storage.getString("current_unit_id");
    var currentUnit = (await getUnits()).firstWhere(
        (x) => x["id"] == currentUnitId,
        orElse: (() => _units[0] as Map<String, String>));
    return currentUnit;
  }

  Future<String> toFileName(Lesson lesson, {String unit = basicFrench}) async {
    var name = lesson.data.name ?? "current_lesson";
    name = name.replaceAll(" ", "_") + ".json";
    var dir = await _localPath + unit;
    if (!await Directory(dir).exists()) Directory(dir).create();
    return await _localPath + unit + "/" + name;
  }

  Future storeLesson(Lesson lesson) async {
    var contents = json.encode(lesson);
    return await File(await toFileName(lesson)).writeAsString(contents);
  }

  Future<Lesson> getLesson(Storage storage, {int idx = 0}) async {
    if (storage.containsKey("current") &&
        await File(storage.getString("current")).exists()) {
      return await loadLesson(storage.getString("current"));
    }
    String defaultUnit =
        getUnits() == null || _units.length <= 0 ? "" : _units[0]["id"];
    var unit = storage.get("current_unit_id", defaultUnit);
    var data = await getData(format: "csv", unit: unit);
    return getLessonFromData(data, idx);
  }

  Future<Lesson> getLessonFromData(JsonObject data, int idx) async {
    var lessons = data.getList("lessons");
    if (lessons.length == 0) return Lesson(JsonObject(""));

    var lessonData = lessons[idx];

    var fileName = await toFileName(Lesson(JsonObject.fromDynamic(lessonData)));
    if (await File(fileName).exists()) return await loadLesson(fileName);

    var lesson = lessonData["words"] != null
        ? JsonObject.fromDynamic(lessonData)
        : await api.get(lessonData["url"]);

    return Lesson(lesson);
  }

  Lesson getPlainLessonFromData(JsonObject data, int idx) {
    var lessons = data.getList("lessons");
    var lessonData = lessons[idx];
    var lesson = JsonObject.fromDynamic(lessonData);
    return Lesson(lesson);
  }

  Future<String> fileNameFromId(String unit) async {
    return (await _localPath) + unit + ".csv;";
  }

  Future removeCached({required String unit}) async {
    var filename = await fileNameFromId(unit);
    var file = File(filename);
    if (await file.exists()) await file.delete();
  }

  Future<JsonObject> getData(
      {String format = "json", required String unit}) async {
    if (format == "json") {
      return api.getJsonById("1lA-vhaxchV-4wi6quSQdOJAYbyZ3n_5g");
    } else {
      String tsvContent = await getUnitContent(unit);
      return Future.value(parseTsv(tsvContent));
    }
  }

  dynamic getUnit(String unitId) async {
    var units = await getUnits();
    if (units != null) return units.firstWhere((x) => x["id"] == unitId);
    return null;
  }

  Future<String> getUnitContent(String unitId) async {
    String csvContent;
    var file = File(await fileNameFromId(unitId));
    if (await file.exists()) {
      csvContent = await file.readAsString();
    } else {
      csvContent = await api.getTsvContentById(unitId);
      file.writeAsString(csvContent);
      var unit = await getUnit(unitId);
      if (unit["mp3"] != null) {
        downloadAndUnzip(unit["mp3"], (await _localPath) + unitId);
      }
    }
    return csvContent;
  }

  static Future downloadAndUnzip(String fileId, String path) async {
    var url = "https://drive.google.com/uc?export=download&id=" + fileId;
    var http = HttpClient();
    var filePath = path + "/" + fileId + ".zip";
    var dataFile = File(filePath);
    if (!await Directory(path).exists()) await Directory(path).create();
    var request = await http.getUrl(Uri.parse(url));
    var response = await request.close();
    await response.pipe(dataFile.openWrite());

    // Read the Zip file from disk.
    List<int> bytes = await File(filePath).readAsBytes();

    // Decode the Zip file
    Archive archive = new ZipDecoder().decodeBytes(bytes);

    // Extract the contents of the Zip archive to disk.
    for (ArchiveFile file in archive) {
      if (!file.isFile) continue;
      String filename = file.name;
      List<int> data = file.content;
      File(path + "/" + filename)
        ..createSync(recursive: true)
        ..writeAsBytesSync(data);
    }
  }

  JsonObject parseTsv(String tsvContent) {
    var lines = tsvContent.split("\n");
    var data = Map<String, dynamic>();
    var lessons = [];
    data["lessons"] = lessons;
    var lesson;
    var words;
    for (var line in lines.skip(1)) {
      var fields = line.split('\t');
      var name = fields[0].trim();
      if (name != "") {
        lesson = Map<String, dynamic>();
        lesson["name"] = name;
        words = [];
        lesson["words"] = words;
        lessons.add(lesson);
      } else if (lesson != null) {
        if (fields.length >= 2 && fields[1] != "" && fields[2] != null) {
          Map<String, dynamic> word = extractWord(fields);
          words.add(word);
        }
      }
    }
    return JsonObject.fromDynamic(data);
  }

  Map<String, dynamic> extractWord(List<String> fields) {
    var word = Map<String, dynamic>();
    var keys = ["src", "dest", "mp3"];
    for (var k in keys) word[k] = "";
    var keyIdx = 0;
    bool quotedString = false;
    for (var i = 1; i < fields.length; i++) {
      if (keyIdx >= keys.length) break;
      var key = keys[keyIdx];
      var s = fields[i].trimRight();
      if (s.startsWith("\"")) {
        word[key] += s.substring(1);
        quotedString = true;
      } else if (s.endsWith("\"")) {
        if (quotedString)
          word[key] += ";" + s.substring(0, s.length - 1);
        else
          word[key] += s;
        quotedString = false;
        keyIdx++;
      } else {
        word[key] += s.trim();
        if (!quotedString) keyIdx++;
      }
    }
    return word;
  }
}
