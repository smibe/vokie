# vokie

A vocabulary trainer written in flutter.

## Features:

* define learning units with lessons
* lessons can be selected for learning
* the data is downloaded from shared google drive files and stored locally
* if an audio file is available, audio can be played as well

## Data structure

An initial file can be specified with the google drive id in the settings. It needs to be a json file with the 
following structure:

```json
{
  "learnContent":
    [
      {
        "name": "name of unit1",
        "id": "<google file id for the content of unit1>"
      },
      {
        "name": "name of unit2 with audio",
        "id": "<google file id for the content of unit2",
        "mp3": "<google file id for the audio file of unit2>"
      }
    ]
}
```

The content file for each unit should be a google sheet with first row containing the column names (skipped) and 
the follwing columns:

| unit1 | German | Englisch | MP3 | German sentence | English sentence | mp3_start (seconds) | mp3_duration (seconds) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Lesson 1 | | | | | | | |
| | Tisch | table | unit1.mp3 | Die Blumen sind auf dem Tisch. | The flowers are on the table. | 0 | 21 |
| | Stuhl. | chair. | unit1.mp3  | Ich sitze auf dem Stuhl. | I sit on the chair. | 22 | 40 |
| Lesson 2 | | | | | | | |
| | Programmiersprache | programming language | unit2.mp3 | Meine bevorzugte Programmiersprache ist F#. | My favorite programming language is F#. | 0 | 31 |
