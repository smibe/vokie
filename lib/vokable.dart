enum LastResponse { unknown, correct, wrong }

int ToInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return value == "" ? 0 : int.parse(value);
  return 0;
}

class Vokabel {
  late String source;
  late String target;
  late String source_sentence;
  late String target_sentence;
  int mp3_start = -1;
  int mp3_duration = 0;
  String mp3 = "";
  int correct = 0;
  int wrong = 0;
  bool showTarget = false;
  LastResponse lastResponse = LastResponse.unknown;

  Vokabel(this.source, this.target);
  Vokabel.fromDynamic(dynamic word) {
    source = word["src"];
    target = word["dest"];
    mp3 = word["mp3"] ?? "";
    source_sentence = word["src_sentence"] ?? "";
    target_sentence = word["dest_sentence"] ?? "";
    mp3_start = ToInt(word["mp3_start"]);
    mp3_duration = ToInt(word["mp3_duration"]);
    correct = word["c"] ?? 0;
    wrong = word["w"] ?? 0;
    showTarget = word["st"] ?? false;
  }

  toJson() {
    return {
      "src": source,
      "dest": target,
      "src_sentence": source_sentence,
      "dest_sentence": target_sentence,
      "mp3_start": mp3_start,
      "mp3_duration": mp3_duration,
      "mp3": mp3,
      "c": correct,
      "w": wrong,
      "st": showTarget,
    };
  }
}
