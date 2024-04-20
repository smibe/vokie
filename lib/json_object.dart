/* (C) 2013 Chris Buckett (chrisbuckett@gmail.com)
 * Released under the MIT licence
 * See LICENCE file
 * http://github.com/chrisbu/dartwatch-JsonObject
 */

library json_object;

import 'dart:convert';

class JsonObject {
  late Map<String, dynamic> data;

  JsonObject(String jsonData) {
    this.data = jsonData == "" ? Map<String, dynamic>() : json.decode(jsonData);
  }

  isEmpty() => data.isEmpty;

  JsonObject.fromDynamic(this.data);
  String getString(String key) => data[key];
  void setString(String key, String value) => data[key] = value;

  List<dynamic> getList(String key) => data[key];

  bool getBool(String key) => data[key];

  getInt(String key) => data[key];
}
