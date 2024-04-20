import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:vokie/jsonApi.dart';
import 'package:vokie/json_object.dart';

class JsonHttpApi extends JsonApi {
  Future<String> readResponse(HttpClientResponse response) {
    var completer = new Completer<String>();
    var contents = new StringBuffer();
    response.transform(utf8.decoder).listen((String data) {
      contents.write(data);
    },
        onDone: () => completer.complete(contents.toString()),
        onError: (e) => print("something went wrong"));
    return completer.future;
  }

  Future<JsonObject> get(String url) async {
    var jsonString = await getString(url);
    return JsonObject(jsonString);
  }

  Future<String> getString(String url) async {
    var http = HttpClient();
    var response = await http.getUrl(Uri.parse(url));
    var r = await response.close();
    if (r.statusCode != HttpStatus.ok) return "";

    var result = await readResponse(r);
    return result;
  }

  Future<JsonObject> getJsonById(String id, {String source = "gfile"}) async {
    switch (source) {
      case "gdoc":
        return getJsonFromGDocs(id);
      case "gfile":
      default:
        return getJsonFromDrive(id);
    }
  }

  Future<String> getTsvContentById(String id) async {
    return await getTsvFromDrive(id);
  }

  Future<JsonObject> getJsonFromDrive(String id) async {
    var url = "https://drive.google.com/uc?export=download&id=" + id;
    return await get(url);
  }

  Future<JsonObject> getJsonFromGDocs(String id) async {
    var url = "https://docs.google.com/document/d/" + id + "/export?format=txt";
    return await get(url);
  }

  Future<String> getTsvFromDrive(String id) async {
    var url =
        "https://docs.google.com/spreadsheets/d/" + id + "/export?format=tsv";
    return await getString(url);
  }
}
