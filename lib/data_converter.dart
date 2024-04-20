class DataConverter {
  static final fromStringConverters = {
    DateTime: (String s) => DateTime.parse(s),
    int: (String s) => int.parse(s),
    num: (String s) => num.parse(s),
    double: (String s) => double.parse(s),
    bool: (String s) => s == "true",
    String: (String s) => s,
  };

  static final toStringConverters = {
    DateTime: (dynamic v) => (v as DateTime).toIso8601String(),
    int: (dynamic v) => (v as int).toString(),
    num: (dynamic v) => (v as num).toString(),
    double: (dynamic v) => (v as double).toString(),
    bool: (dynamic v) => (v as bool).toString(),
    String: (dynamic v) => v.toString(),
  };

  static T decode<T>(String value, T defaultValue) {
    try {
      var converter = fromStringConverters[T];
      if (converter == null) return defaultValue;
      var v = converter(value);
      return v as T;
    } catch (e) {
      return defaultValue;
    }
  }

  static String encode<T>(T value) {
    var toStringConverter = toStringConverters[T];
    if (toStringConverter != null) return toStringConverter(value);
    return value.toString();
  }
}
