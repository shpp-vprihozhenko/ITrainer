import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'EngWords.dart';
import 'RusWords.dart';
import 'EngExpressions.dart';
import 'RusExpressions.dart';
import 'EngDialogs.dart';
import 'RusDialogs.dart';

enum TtsState { playing, stopped, paused, continued }

class MyEnglishPage extends StatefulWidget {
  MyEnglishPage() : super();

  @override
  _MyEnglishPage createState() => _MyEnglishPage();
}

class _MyEnglishPage extends State<MyEnglishPage> {
  bool showMic = false;
  bool showDebugInfo = false;
  int mode = 0, curPos = 0, maxPos = 0;
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

  List<EnglishTask> engTaskKinds = EnglishTask.getList();
  List<DropdownMenuItem> _dropDownMenuEngTaskKindItems;
  EnglishTask _selectedEngTaskKind;

  List<String> myEngWords = EngWords.getList();
  List<String> myRusWords = RusWords.getList();
  List<String> myEngExpressions = EngExpressions.getList();
  List<String> myRusExpressions = RusExpressions.getList();
  List<String> myEngDialogs = EngDialogs.getList();
  List<String> myRusDialogs = RusDialogs.getList();

  @override
  initState() {
    super.initState();
    initTTS();
    initSTT();
    _dropDownMenuEngTaskKindItems = buildDropDownEngTaskKindItems();
    _selectedEngTaskKind = engTaskKinds[1];
  }

  Future _setSpeakParameters() async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(ttsRate);
    await flutterTts.setPitch(pitch);
    // ru-RU uk-UA en-US
    await flutterTts.setLanguage('en-US');
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
    print("Received error status: $error, listening: ${speech.isListening}");
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
      return startEnglishMenu(context);
    } else {
      return englishTaskPage(context);
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

  Widget englishTaskPage(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Английский')),
        body: Column(
          children: <Widget>[
            Expanded(
                flex: 3,
                child: MediaQuery.of(context).size.height > 400
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: ewTaskList(),
                      )
                    : ListView(
                        children: ewTaskList(),
                      )),
            Expanded(
              child: BlinkWidget(
                children: <Widget>[
                  Icon(
                    Icons.mic,
                    size: 40,
                    color: showMic ? Colors.green : Colors.transparent,
                  ),
                  Icon(Icons.mic, size: 40, color: Colors.transparent),
                ],
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
                      setState(() {
                        curPos--;
                      });
                      mainEngishLoop();
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
                      mainEngishLoop();
                    },
                    onLongPress: () {
                      showDebugInfo = !showDebugInfo;
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
                      setState(() {
                        curPos++;
                      });
                      mainEngishLoop();
                    },
                  ),
                ],
              ),
            )
          ],
        ));
  }

  List<Widget> ewTaskList() {
    return [
      Text(
        curEngText,
        textScaleFactor: 2,
        textAlign: TextAlign.center,
      ),
      SizedBox(
        height: 20,
      ),
      Text(
        'Перевод: $curRusText',
        textScaleFactor: 1.6,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.green[900]),
      ),
      SizedBox(
        height: 20,
      ),
      Text('Слышу: $lastSttWords',
          textScaleFactor: 1.4, textAlign: TextAlign.center),
    ];
  }

  Widget startEnglishMenu(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Английский')),
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
                      startEngTraining();
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
                  //MediaQuery.of(context).size.height > 400
                  child: ListView(
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Настройки тренера:',
                          textScaleFactor: 1.3,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text('Режим: ', textScaleFactor: 1.3),
                          DropdownButton(
                              value: _selectedEngTaskKind,
                              items: _dropDownMenuEngTaskKindItems,
                              onChanged: (newVal) {
                                setState(() {
                                  _selectedEngTaskKind = newVal;
                                });
                              }),
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

  List<DropdownMenuItem<EnglishTask>> buildDropDownEngTaskKindItems() {
    List<DropdownMenuItem<EnglishTask>> items = List();
    for (EnglishTask tt in engTaskKinds) {
      items.add(DropdownMenuItem(value: tt, child: Text(tt.name)));
    }
    return items;
  }

  void startEngTraining() {
    if (_selectedEngTaskKind.name == 'Слова') {
      maxPos = myEngWords.length;
    } else if (_selectedEngTaskKind.name == 'Популярные выражения') {
      maxPos = myEngExpressions.length;
    } else if (_selectedEngTaskKind.name == 'Диалоги') {
      maxPos = myEngDialogs.length;
    }
    var rng = new Random();
    curPos = rng.nextInt(maxPos);
    mainEngishLoop();
  }

  void mainEngishLoop() async {
    setState(() {
      if (_selectedEngTaskKind.name == 'Слова') {
        curEngText = myEngWords[curPos];
        curRusText = myRusWords[curPos];
      } else if (_selectedEngTaskKind.name == 'Популярные выражения') {
        curEngText = myEngExpressions[curPos];
        curRusText = myRusExpressions[curPos];
      } else if (_selectedEngTaskKind.name == 'Диалоги') {
        curEngText = myEngDialogs[curPos];
        curRusText = myEngDialogs[curPos];
      }
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
      localeId: 'en_US', // en_US uk_UA ru_RU
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
        curPos++;
        if (curPos == maxPos) {
          curPos = 0;
        }
        await _speakSync('ok!');
        mainEngishLoop();
      } else {
        await _speakSync("That's wrong...");
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
    if (showDebugInfo) {
      showAlertPage(_userText + ' / ' + _expText + ' $curPos');
    }
    return false;
  }

  String removeAllGarbage(String _text) {
    return _text
        .toUpperCase()
        .replaceAll("OKAY", "OK")
        .replaceAll("FAVOURITE", "FAVORITE")
        .replaceAll("'RE", " ARE")
        .replaceAll("'S", " IS")
        .replaceAll("'M", " AM")
        .replaceAll("'LL", " WILL")
        .replaceAll("ALL RIGHT", "ALLRIGHT")
        .replaceAll("ALRIGHT", "ALLRIGHT")
        .replaceAll("APARTMENT", "APT")
        .replaceAll("BEECH", "BEACH")
        .replaceAll("COLOUR", "COLOR")
        .replaceAll("GREY", "GRAY")
        .replaceAll("KILOGRAM", "KG")
        .replaceAll("KILOMETER", "KM")
        .replaceAll("P.M.", "PM")
        .replaceAll("A.M.", "AM")
        .replaceAll(" AN ", " A ")
        .replaceAll(" THE ", " A ")
        .replaceAll(
            new RegExp(
                '(:00|PERCENT|PERCENTS|DOLLAR|DOLLARS|O\'CLOCK|O\'CLOCKS|[.,%-();№!@~#\$\'^%*&:?/\\()_+*{}])'),
            ' ')
        .replaceAll(new RegExp('[ \t]{2,}'), ' ')
        .trim();
  }

  showAlertPage(String msg) {
    showAboutDialog(
      context: context,
      applicationName: 'Alert',
      children: <Widget>[
        Padding(
            padding: EdgeInsets.only(top: 15), child: Center(child: Text(msg)))
      ],
    );
  }
}

class EnglishTask {
  String name;

  EnglishTask(this.name);

  static getList() {
    List<EnglishTask> lt = [];
    lt.add(EnglishTask('Слова'));
    lt.add(EnglishTask('Популярные выражения'));
    lt.add(EnglishTask('Диалоги'));
    return lt;
  }
}

class BlinkWidget extends StatefulWidget {
  final List<Widget> children;
  final int interval;

  BlinkWidget({@required this.children, this.interval = 500, Key key})
      : super(key: key);

  @override
  _BlinkWidgetState createState() => _BlinkWidgetState();
}

class _BlinkWidgetState extends State<BlinkWidget>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
  int _currentWidget = 0;

  initState() {
    super.initState();

    _controller = new AnimationController(
        duration: Duration(milliseconds: widget.interval), vsync: this);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          if (++_currentWidget == widget.children.length) {
            _currentWidget = 0;
          }
        });

        _controller.forward(from: 0.0);
      }
    });

    _controller.forward();
  }

  dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: widget.children[_currentWidget],
    );
  }
}
