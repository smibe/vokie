import 'package:flutter/material.dart';
import 'package:vokie/DiContainer.dart';
import 'package:vokie/storage.dart';

import 'lesson_service.dart';

class SettingsView extends StatefulWidget {
  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    var storage = DiContainer.resolve<Storage>();
    _controller =
        TextEditingController(text: storage.get("learnContentId", ""));
  }

  @override
  Widget build(BuildContext context) {
    var storage = DiContainer.resolve<Storage>();
    var lessonService = DiContainer.resolve<LessonService>();
    return Container(
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text("Lern-Inhalte", style: TextStyle(fontSize: 28.0)),
          Container(width: 1, height: 20),
          Text("Google-Docs-ID:", style: TextStyle(fontSize: 18.0)),
          TextFormField(
            controller: _controller,
            onFieldSubmitted: (s) {
              lessonService.resetUnits();
              storage.set("learnContentId", s);
            },
            style: TextStyle(fontSize: 15),
          ),
          Container(width: 1, height: 20),
          Text("Lern-Einheit", style: TextStyle(fontSize: 28.0)),
          Text("(${storage.get("current_unit_name", "")})",
              style: TextStyle(fontSize: 18.0))
        ],
      ),
    );
  }
}
