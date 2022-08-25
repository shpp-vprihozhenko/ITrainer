import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'DeutschWords.dart';

enum TtsState { playing, stopped, paused, continued }

// *********** Deutsch

class MyDeutschPage extends StatefulWidget {
  MyDeutschPage() : super();

  @override
  _MyDeutschPage createState() => _MyDeutschPage();
}

class _MyDeutschPage extends State<MyDeutschPage> {
  bool showMic = false;
  int mode = 0, curPos = 0, maxPos = 0, lastCurPos = 0;
  String curEngText = '', curRusText = '';

  final SpeechToText speech = SpeechToText();
  String lastSttWords = '';
  String lastSttError = '';

  FlutterTts flutterTts;
  dynamic languages;
  String language;
  double volume = 1;
  double pitch = 1.2;
  double ttsRate = 1;

  TtsState ttsState = TtsState.stopped;

  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;
  get isPaused => ttsState == TtsState.paused;
  get isContinued => ttsState == TtsState.continued;

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  List<String> myDWords = DeutschWords.getList();

  @override
  initState() {
    super.initState();
    initTTS();
    initSTT();
  }

  Future _setSpeakParameters() async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(ttsRate);
    await flutterTts.setPitch(pitch);
    // ru-RU uk-UA en-US de-DE
    await flutterTts.setLanguage('de-DE');
  }

  Future<void> _speak(String _text, bool asyncMode) async {
    if (_text != null) {
      if (_text.isNotEmpty) {
        if (asyncMode) {
          flutterTts.speak(_text);
        } else {
          print('speak await $_text');
          await flutterTts.speak(_text);
        }
      }
    }
  }

  Future<void> _speakSync(String _text) {
    final c = new Completer();
    flutterTts.setCompletionHandler(() {
      c.complete("ok");
    });
    _speak(_text, false);
    return c.future;
  }

  initTTS() {
    flutterTts = FlutterTts();
    _setSpeakParameters();
  }

  void initSTT() async {
    bool hasSpeech = await speech.initialize(
        onError: errorListener, onStatus: statusListener);
    print('initSpeechState hasSpeech $hasSpeech');

    speech.errorListener = errorListener;
    speech.statusListener = statusListener;

    if (hasSpeech) {
      var _localeNames = await speech.locales();
      //_localeNames.forEach((element) => print(element.localeId));
      var systemLocale = await speech.systemLocale();
      var _currentLocaleId = systemLocale.localeId;
      print('initSpeechState _currentLocaleId $_currentLocaleId');
    }

    if (!hasSpeech) {
      print('STT not mounted.');
      return;
    }
  }

  void errorListener(SpeechRecognitionError error) {
    print("Received Germ error status: $error, listening: ${speech.isListening}");
    setState(() {
      showMic = false;
    });
    displaySttDialog();
  }

  void statusListener(String status) {
    print(
        "Received listener status: $status, listening: ${speech.isListening}");
//    setState(() {
//      lastStatus = "$status";
//    });
  }

  @override
  Widget build(BuildContext context) {
    if (mode == 0) {
      return startDMenu(context);
    } else {
      return TaskPage(context);
    }
  }

  void displaySttDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => new CupertinoAlertDialog(
        title: new Text("Я тебя не понял..."),
        content: new Text("Повторим?"),
        actions: [
          FlatButton(
              child: Text('Да'),
              onPressed: () {
                startListening();
                Navigator.pop(context, true);
              }),
          FlatButton(
              child: Text('Нет'),
              onPressed: () {
                Navigator.pop(context, true);
              }),
        ],
      ),
    );
  }

  Widget startDMenu(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Немецкий')),
        body: Column(
          children: <Widget>[
            Expanded(
              flex: 3,
              child: Center(
                  child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Когда будешь готов - нажми',
                    textScaleFactor: 2,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  FlatButton(
                    color: Colors.blue,
                    textColor: Colors.white,
                    disabledColor: Colors.grey,
                    disabledTextColor: Colors.black,
                    padding: EdgeInsets.only(
                        left: 40, right: 40, top: 20, bottom: 20),
                    splashColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Text(
                      'СТАРТ',
                      textScaleFactor: 2,
                    ),
                    onPressed: () {
                      startDTraining();
                      setState(() {
                        mode = 1;
                      });
                    },
                  )
                ],
              )),
            ),
            Expanded(
              flex: 1,
              child: Container(
                  color: Colors.lightBlue[200],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Настройки тренера:',
                          textScaleFactor: 1.3,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text('Режим: Слова', textScaleFactor: 1.2),
//                          DropdownButton(
//                              value: _selectedEngTaskKind,
//                              items: _dropDownMenuEngTaskKindItems,
//                              onChanged: (newVal){
//                                setState(() {
//                                  _selectedEngTaskKind = newVal;
//                                });
//                              }
//                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Text('  Скорость:'),
                          Slider(
                            value: ttsRate,
                            min: 0.5,
                            max: 1.5,
                            onChanged: (newRate) {
                              setState(() {
                                ttsRate = newRate;
                              });
                              flutterTts.setSpeechRate(newRate);
                            },
                          ),
                        ],
                      )
                    ],
                  )),
            )
          ],
        ));
  }

  Widget TaskPage(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Немецкий')),
        body: Column(
          children: <Widget>[
            Expanded(
                flex: 3,
                child: MediaQuery.of(context).size.height > 400
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: dTasks(),
                      )
                    : ListView(
                        children: dTasks(),
                      )),
            Expanded(
              child: showMic
                  ? Image.asset(
                      'assets/images/animMicroph.gif',
                      width: 50,
                      height: 50,
                    )
                  : SizedBox(
                      height: 50,
                    ),
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  FlatButton(
                    color: Colors.blue,
                    textColor: Colors.white,
                    disabledColor: Colors.grey,
                    disabledTextColor: Colors.black,
                    padding: EdgeInsets.only(
                        left: 10, right: 10, top: 10, bottom: 10),
                    splashColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('Назад'),
                    onPressed: () {
                      curPos = lastCurPos;
                      mainDLoop(false);
                    },
                  ),
                  FlatButton(
                    color: Colors.blue,
                    textColor: Colors.white,
                    disabledColor: Colors.grey,
                    disabledTextColor: Colors.black,
                    padding: EdgeInsets.only(
                        left: 10, right: 10, top: 10, bottom: 10),
                    splashColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('Повторить'),
                    onPressed: () {
                      mainDLoop(false);
                    },
                  ),
                  FlatButton(
                    color: Colors.blue,
                    textColor: Colors.white,
                    disabledColor: Colors.grey,
                    disabledTextColor: Colors.black,
                    padding: EdgeInsets.only(
                        left: 10, right: 10, top: 10, bottom: 10),
                    splashColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: Text('Следующий'),
                    onPressed: () {
                      mainDLoop(true);
                    },
                  ),
                ],
              ),
            )
          ],
        ));
  }

  List<Widget> dTasks() {
    return [
      SizedBox(
        height: 20,
      ),
      Text(
        curEngText,
        textScaleFactor: 2,
        textAlign: TextAlign.center,
      ),
      SizedBox(
        height: 20,
      ),
      Text('Перевод: $curRusText',
          textScaleFactor: 1.6, textAlign: TextAlign.center),
      SizedBox(
        height: 20,
      ),
      Text('Слышу: $lastSttWords',
          textScaleFactor: 1.4, textAlign: TextAlign.center),
    ];
  }

  void startDTraining() {
    maxPos = myDWords.length;
    mainDLoop(true);
  }

  void mainDLoop(bool randomMode) async {
    if (randomMode) {
      var rng = new Random();
      lastCurPos = curPos;
      curPos = rng.nextInt(maxPos);
    }
    String DRwords = myDWords[curPos];
    List<String> lDRwords = DRwords.split(' - ');
    setState(() {
      curEngText = lDRwords[0];
      curRusText = lDRwords[1];
    });
    await _speakSync(curEngText);
    startListening();
  }

  void startListening() {
    setState(() {
      showMic = true;
    });
    lastSttError = "";
    speech.listen(
      onResult: resultListener,
      // listenFor: Duration(seconds: 60),
      // pauseFor: Duration(seconds: 3),
      localeId: 'de_DE', // en_US uk_UA ru_RU de_DE
      // onSoundLevelChange: soundLevelListener,
      cancelOnError: true,
      partialResults: true,
      // onDevice: true,
      // listenMode: ListenMode.confirmation,
      // sampleRate: 44100,
    );
  }

  void resultListener(SpeechRecognitionResult result) async {
    if (result.finalResult) {
      String recognizedWords = result.recognizedWords.toString();
      setState(() {
        lastSttWords = recognizedWords;
        showMic = false;
      });
      if (checkForCorrectAnswer(recognizedWords)) {
        await _speakSync('ok!');
        mainDLoop(true);
      } else {
        await _speakSync("nein, falsch...");
        await _speakSync(curEngText);
        startListening();
      }
    }
  }

  bool checkForCorrectAnswer(String recognizedWords) {
    String _userText = removeAllGarbage(recognizedWords);
    String _expText = removeAllGarbage(curEngText);
    if (_userText == _expText) {
      return true;
    }
    return false;
  }

  String removeAllGarbage(String _text) {
    return _text
        .toUpperCase()
        .replaceAll(new RegExp('(:00|[.,%-();№!@~#\$\'^%*&:?/\\()_+*{}])'), ' ')
        .replaceAll(new RegExp('[ \t]{2,}'), ' ')
        .trim();
  }
}
