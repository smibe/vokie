enum LastResponse { unknown, correct, wrong }

class Vokabel {
  late String source;
  late String target;
  String mp3 = "";
  int correct = 0;
  int wrong = 0;
  bool showTarget = false;
  LastResponse lastResponse = LastResponse.unknown;

  Vokabel(this.source, this.target);
  Vokabel.fromDynamic(dynamic word) {
    source = word["src"];
    target = word["dest"];
    mp3 = word["mp3"];
    correct = word["c"] ?? 0;
    wrong = word["w"] ?? 0;
    showTarget = word["st"] ?? false;
  }

  toJson() {
    return {
      "src": source,
      "dest": target,
      "mp3": mp3,
      "c": correct,
      "w": wrong,
      "st": showTarget,
    };
  }
}
