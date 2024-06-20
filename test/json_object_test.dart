import 'package:flutter_test/flutter_test.dart';
import 'package:vokie/json_object.dart';

void main() {
  test('JsonObject correctly parses JSON and allows property access', () {
    var jsonString = '{"name":"John", "age":30, "city":"New York"}';
    var jsonObject = new JsonObject(jsonString);

    expect(jsonObject.getString("name"), 'John');
    expect(jsonObject.getInt("age"), 30);
    expect(jsonObject.getString("city"), 'New York');
  });
}
