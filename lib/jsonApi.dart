import 'dart:async';
import 'package:vokie/json_object.dart';

abstract class JsonApi {
   Future<JsonObject> get(String url);
   Future<String> getString(String url);
   Future<JsonObject> getJsonById(String id, {String source = "gfile"});
   Future<String> getTsvContentById(String id);
}
