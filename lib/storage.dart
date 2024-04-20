import 'package:shared_preferences/shared_preferences.dart';

import 'DiContainer.dart';
import 'data_converter.dart';
import 'event.dart';

class Storage {
  Map<String, Event<String>> _valueChanged = Map<String, Event<String>>();
  SharedPreferences _preferences;
  Storage() : this.withDependencies(DiContainer.resolve<SharedPreferences>());
  Storage.withDependencies(this._preferences);

  bool containsKey(String key) => _preferences.containsKey(key);
  String getString(key) => _preferences.getString(key) ?? "";
  void setString(String key, String value) {
    _preferences.setString(key, value);
    if (_valueChanged.containsKey(key)) _valueChanged[key]?.invoke(value);
  }

  Event<String> valueChanged(String key) {
    if (!_valueChanged.containsKey(key))
      _valueChanged[key] = new Event<String>();
    return _valueChanged[key] ?? new Event<String>();
  }

  void remove(String key) {
    _preferences.remove(key);
    if (_valueChanged.containsKey(key)) _valueChanged[key]?.invoke("");
  }

  void set<T>(String key, T value) =>
      setString(key, DataConverter.encode(value));
  T get<T>(String key, T defaultValue) {
    if (!containsKey(key)) return defaultValue;
    return DataConverter.decode(getString(key), defaultValue);
  }
}
