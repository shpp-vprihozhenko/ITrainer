import 'dart:async';
//import 'dart:io' show Platform;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'DeutschWords.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Интерактивный тренажер',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'Интерактивный тренажер'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

enum TtsState { playing, stopped, paused, continued }

class _MyHomePageState extends State<MyHomePage> {

  FlutterTts flutterTts;
  dynamic languages;
  String language;
  double volume = 1;
  double pitch = 1.2;
  double rate = 1;

  TtsState ttsState = TtsState.stopped;
  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;
  get isPaused => ttsState == TtsState.paused;
  get isContinued => ttsState == TtsState.continued;

  @override
  initState() {
    super.initState();
    initTts();
  }

  Future _getLanguages() async {
    languages = await flutterTts.getLanguages;
    if (!isSupportedLanguageInList()) {
      showAlertPage('Извините, в Вашем телефоне не установлен требуемый TTS-язык. Обновите ваш синтезатор речи (Google TTS).');
    }
  }
  isSupportedLanguageInList () {
    for (var lang in languages) {
      if (lang.toString().toUpperCase() == 'RU-RU') {
        print('ru lang present');
        return true;
      }
    }
    print('no ru lang present');
    return false;
  }

  Future _getEngines() async {
    var engines = await flutterTts.getEngines;
//    if (engines != null) {
//      print('engines:');
//      for (dynamic engine in engines) {
//        print(engine);
//      }
//    }
  }
  Future _setSpeakParameters() async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);
    // ru-RU uk-UA en-US
    await flutterTts.setLanguage('ru-RU');
  }
  Future<void> _speak(String _text, bool asyncMode) async {
    if (_text != null) {
      if (_text.isNotEmpty) {
        if (asyncMode) {
          flutterTts.speak(_text);
        } else {
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

//  @override
//  void dispose() {
//    super.dispose();
//    flutterTts.stop();
//  }

  initTts() {
    flutterTts = FlutterTts();
    _getLanguages();
//    if (!kIsWeb) {
//      if (Platform.isAndroid) {
//        _getEngines();
//      }
//    }
    _setSpeakParameters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              flex: 2,
              child: InkWell(
                splashColor: Colors.white,
                onTap: () => openMathTrainer(context), // handle your onTap here
                child: Container(
                  color: Colors.cyanAccent,
                  child: Center(child: Text('Математика', textScaleFactor: 2,)),
                ),
              ),
            ),
            Flexible(
              flex: 2,
              child: InkWell(
                splashColor: Colors.white,
                onTap: () => {runEngTrainer(context)}, // handle your onTap here
                child: Container(
                  color: Colors.yellowAccent[100],
                  child: Center(child: Text("Английский", textScaleFactor: 2))
                ),
              ),
            ),
            Flexible(
              flex: 2,
              child: InkWell(
                splashColor: Colors.white,
                focusColor: Colors.green,
                highlightColor: Colors.blue,
                hoverColor: Colors.red,
                onTap: () => runDeutschTrainer(context), // handle your onTap here
                child: Center(child: Text('Немецкий', textScaleFactor: 2)),
              ),
            ),
            Flexible(
              flex: 1,
              child: Container(
                color: Colors.greenAccent,
                width: MediaQuery.of(context).size.width,
                child: Center(
                  child: InkWell(
                    splashColor: Colors.white,
                    onTap: () => showAboutPage(),
                    child: Text('Автор идеи и разработчик -\nПрихоженко Владимир', textScaleFactor: 1.2, textAlign: TextAlign.center),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
//      floatingActionButton: FloatingActionButton(
//        onPressed: _incrementCounter,
//        tooltip: 'Increment',
//        child: Icon(Icons.add),
//      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  runEngTrainer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MyEnglishPage()),
    );
    _speakSync('Когда будешь готов - нажми Старт!');
  }

  runDeutschTrainer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MyDeutschPage()),
    );
    _speakSync('Когда будешь готов - нажми Старт!');
  }

  showAboutPage() {
    showAboutDialog(
      context: context,
      //applicationIcon: Text('Here must be Logo'),
      applicationName: 'Интерактивный тренажёр',
      applicationVersion: 'Версия 0.0.2',
      applicationLegalese: '©2020 Владимир Прихоженкo',
      children: <Widget>[
        Padding(
            padding: EdgeInsets.only(top: 15),
            child: Center(child: Text('Свои предложения и замечания пожалуйста шлите на email \nvprihogenko@gmail.com'))
        )
      ],
    );
  }

  openMathTrainer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MyMathPage()),
    );
    _speakSync('Когда будешь готов - нажми Старт!');
  }

  showAlertPage(String msg) {
    showAboutDialog(
      context: context,
      applicationName: 'Alert',
      children: <Widget>[
        Padding(
            padding: EdgeInsets.only(top: 15),
            child: Center(child: Text(msg))
        )
      ],
    );
  }
}



// ********* Math page *************

class MyMathPage extends StatefulWidget {
  MyMathPage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyMathPage createState() => _MyMathPage();
}

class _MyMathPage extends State<MyMathPage> {

  int mode = 0;

  int maxNum = 100;
  int multiplierForTable = 7;
  bool dynamicDifficult = false;
  String curDoing = '+-';
  String _curTaskMsg = 'Сколько будет 2 + 2 ?', _curTaskMsgTxt='';
  int expectedRes = 0;
  int numOkAnswer = 0, numWrongAnswer = 0, numTotalAnswer = 0;
  int numOkLast5 = 0;
  bool showMic = false;

  List <TaskType> _tasksTypes = TaskType.getTaskTypes();
  List <DropdownMenuItem<TaskType>> _dropDownMenuTaskTypeItems;
  TaskType _selectedTaskType;

  final textEditController = TextEditingController();
  final textEditControllerForMult = TextEditingController();

  final SpeechToText speech = SpeechToText();
  String lastSttWords = '';
  String lastSttError = '';

  FlutterTts flutterTts;
  dynamic languages;
  String language;
  double volume = 1;
  double pitch = 1.2;
  double rate = 1;

  TtsState ttsState = TtsState.stopped;
  get isPlaying => ttsState == TtsState.playing;
  get isStopped => ttsState == TtsState.stopped;
  get isPaused => ttsState == TtsState.paused;
  get isContinued => ttsState == TtsState.continued;

  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();

  @override
  initState() {
    super.initState();
    initTTS();
    initSTT();
    _dropDownMenuTaskTypeItems = buildDropDownTaskTypeItems(_tasksTypes);
    _selectedTaskType = _tasksTypes[5];
    _prefs.then((SharedPreferences prefs) {
      setState(() {
        maxNum = (prefs.getInt('maxNum') ?? 100);
        multiplierForTable = (prefs.getInt('mult') ?? 7);
        int mode = (prefs.getInt('mode') ?? 5);
        _selectedTaskType = _tasksTypes[mode];
        dynamicDifficult = (prefs.getBool('dynDif') ?? false);
      });
    });
  }

  List<DropdownMenuItem<TaskType>> buildDropDownTaskTypeItems(List<TaskType> tasksTypes) {
    List<DropdownMenuItem<TaskType>> items = List();
    for (TaskType tt in tasksTypes) {
      items.add(
        DropdownMenuItem(
          value: tt,
          child: Text(tt.name)
        )
      );
    }
    return items;
  }

  Future _getLanguages() async {
    languages = await flutterTts.getLanguages;
    if (!isSupportedLanguageInList()) {
      showAlertPage('Извините, в Вашем телефоне не установлен требуемый TTS-язык. Обновите ваш синтезатор речи (Google TTS).');
    }
  }
  isSupportedLanguageInList () {
    for (var lang in languages) {
      if (lang.toString().toUpperCase() == 'RU-RU') {
        print('ru lang present');
        return true;
      }
    }
    print('no ru lang present');
    return false;
  }
  Future _getEngines() async {
    var engines = await flutterTts.getEngines;
    if (engines != null) {
      print('engines:');
      for (dynamic engine in engines) {
        print(engine);
      }
    }
  }
  Future _setSpeakParameters() async {
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);
    // ru-RU uk-UA en-US
    await flutterTts.setLanguage('ru-RU');
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
    _getLanguages();
//    if (!kIsWeb) {
//      if (Platform.isAndroid) {
//        _getEngines();
//      }
//    }
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
    print("Received listener status: $status, listening: ${speech.isListening}");
//    setState(() {
//      lastStatus = "$status";
//    });
  }

  @override
  Widget build(BuildContext context) {
    if (mode == 0) {
      return startMathMenu(context);
    } else {
      return taskPage(context);
    }
  }

  Widget taskPage (BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Реши задачу')),
      body: Column(children: <Widget>[
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(_curTaskMsg, style: TextStyle(fontSize: 22.0), textAlign: TextAlign.center,),
            ),
          ),
        ),
        Expanded(
          child: BlinkWidget(
            children: <Widget>[
              Icon(Icons.mic, size: 40, color: showMic? Colors.green : Colors.transparent,),
              Icon(Icons.mic, size: 40, color: Colors.transparent),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              children: <Widget>[
                Text('Последний ответ: $lastSttWords', style: TextStyle(fontSize: 20.0)),
                Text('Всего ответов: $numTotalAnswer', style: TextStyle(fontSize: 20.0)),
                Text('Правильных ответов: $numOkAnswer', style: TextStyle(fontSize: 20.0)),
                Text('Неправильных ответов: $numWrongAnswer', style: TextStyle(fontSize: 20.0)),
              ],
            ),
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
                padding: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
                splashColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onPressed: () {
                  setState(() {
                    mode = 0;
                  });
                },
                child: Text(
                  "Настройки",
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
              FlatButton(
                color: Colors.blue,
                textColor: Colors.white,
                disabledColor: Colors.grey,
                disabledTextColor: Colors.black,
                padding: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
                splashColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onPressed: () {
                  //Future.delayed(Duration.zero, () => _mainMathLoop(context));
                  _mainMathLoop();
                },
                child: Text(
                  "Следующая задача",
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
            ],
          ),
        ),
      ],),
    );
  }

  Widget startMathMenu (BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Математика')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/math.png'),
            fit: BoxFit.fill,
            colorFilter: new ColorFilter.mode(Colors.black.withOpacity(0.2), BlendMode.dstATop),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Column(
            children: <Widget>[
              Container(
                padding: EdgeInsets.only(left: 0, right: 0, top: 0, bottom: 40),
                child: Column(
                  children: <Widget>[
                    Container(
                        padding: EdgeInsets.only(left: 0, right: 0, top: 40, bottom: 40),
                        child: Center(child: Text('Когда будешь готов - нажми', textScaleFactor: 3, textAlign: TextAlign.center,))),
                    FlatButton(
                      color: Colors.blue,
                      textColor: Colors.white,
                      disabledColor: Colors.grey,
                      disabledTextColor: Colors.black,
                      padding: EdgeInsets.only(left: 40, right: 40, top: 20, bottom: 20),
                      splashColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onPressed: () {
                        setState(() {
                          mode = 1;
                        });
                        _startMathLoop();
                      },
                      child: Text(
                        "СТАРТ",
                        style: TextStyle(fontSize: 30.0),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                  padding: EdgeInsets.only(left: 0, right: 0, top: 6, bottom: 6),
                  //height: 150,
                  color: Colors.lightBlue[100],
                  width: MediaQuery.of(context).size.width,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                        children: <Widget>[
                          Text('настройки Тренера:', textScaleFactor: 1.4, textAlign: TextAlign.center),
                          TextField(
                            controller: textEditController..text = maxNum.toString(),
                            autocorrect: true,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                                prefix: Text('Максимум: '),
                                //labelStyle: ,
                                hintText: 'Максимум:'
                            ),
                            onSubmitted: (String value) async {
                              if (_isNumeric(value)) {
                                setState(() {
                                  maxNum = int.parse(value);
                                });
                              }
                            }
                          ),
                          Row(
                            children: <Widget>[
                              Text('Режим:  ', style: TextStyle(color: Colors.grey[700]), textScaleFactor: 1.1) ,
                              DropdownButton(
                                value: _selectedTaskType,
                                items: _dropDownMenuTaskTypeItems,
                                onChanged: onChangeDropdownItem
                              ),
                            ],
                          ),
                          Row(
                            children: <Widget>[
                              Text('Динамическая сложность:', textScaleFactor: 1.1),
                              Switch(value: dynamicDifficult,
                                  onChanged: (newVal) {
                                    setState(() {
                                      dynamicDifficult = newVal;
                                    });
                                  })
                            ],
                          ),
                          TextField(
                              controller: textEditControllerForMult..text = multiplierForTable.toString(),
                              autocorrect: true,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                  prefix: Text('Множитель: '),
                                  hintText: 'Множитель для таблицы умножения:'
                              ),
                              onSubmitted: (String value) async {
                                if (_isNumeric(value)) {
                                  setState(() {
                                    multiplierForTable = int.parse(value);
                                  });
                                }
                              }
                          ),
                        ]
                    ),
                  )
              )
            ],
          ),
        ),
      ),
    );
  }

  _formCurTask(int startTask, int finTask) {
    var rng = new Random();
    int nA = rng.nextInt(maxNum);
    int nB = rng.nextInt(maxNum);
    int nRes = rng.nextInt(maxNum);

    int actionInt = startTask;
    if (finTask > startTask) {
      actionInt += rng.nextInt(finTask-startTask+1);
    }

    String actionTxt, action;

    if (actionInt == 1) {
      actionTxt = 'плюс'; action = '+';
      if (nA > nRes) {
        int n = nA; nRes = nA; nA = n;
      }
      nB = nRes - nA;
    } else if (actionInt == 2) {
      actionTxt = 'минус'; action = '-';
      if (nA > nB) {
        nRes = nA - nB;
      } else {
        nRes = nB - nA; nA = nB; nB = nA - nRes;
      }
    } else if (actionInt == 3) {
      actionTxt = 'умножить на'; action = '*';
      nA = rng.nextInt(maxNum~/10);
      if (nA == 0) {
        nA = 1;
      }
      if (nA > nRes) {
        int n = nA; nA = nRes; nRes = n;
      }
      nB = nRes ~/ nA;
      nRes = nA * nB;
    } else if (actionInt == 4) {
      actionTxt = 'разделить на'; action = '/';
      nB = rng.nextInt(maxNum~/10);
      if (nA > nB) {
        nRes = (nA / nB).round(); nA = nRes * nB;
      } else {
        nRes = (nB / nA).round(); nB = nA; nA = nB * nRes;
      }
    } else if (actionInt == 5) {
      if (nA < nB) {
        nRes = nB - nA; nA = nB; nB = nA - nRes;
      } else {
        nRes = nA - nB;
      }
      action = 'На сколько $nA больше чем $nB?';
      actionTxt = 'На сколько ${intToPropis(nA)} больше чем ${intToPropis(nB)}?';
    } else if (actionInt == 6) {
      if (nA < nB) {
        nRes = nB - nA; nA = nB; nB = nA - nRes;
      } else {
        nRes = nA - nB;
      }
      action = 'На сколько $nB меньше чем $nA?';
      actionTxt = 'На сколько ${intToPropis(nB)} меньше чем ${intToPropis(nA)}?';
    } else if (actionInt == 7) {
      if (nA < nB) {
        nRes = nB - nA; nA = nB; nB = nA - nRes;
      } else {
        nRes = nA - nB;
      }
      action = 'Сколько надо отнять от $nA, чтобы получить $nB?';
      actionTxt = 'Сколько надо отнять от ${intToPropis(nA)}, чтобы получить ${intToPropis(nB)}?';
    } else if (actionInt == 8) {
      if (nA < nB) {
        nRes = nB - nA; nA = nB; nB = nA - nRes;
      } else {
        nRes = nA - nB;
      }
      action = 'Сколько надо прибавить к $nB, чтобы получить $nA?';
      actionTxt = 'Сколько надо прибавить к ${intToPropis(nB)}, чтобы получить ${intToPropis(nA)}?';
    } else if (actionInt == 9) {
      nB = rng.nextInt(maxNum~/10);
      if (nA < nB) {
        nRes = nB ~/ nA; nA = nB; nB = nA ~/ nRes;
      } else {
        nRes = nA ~/ nB; nA = nB * nRes;
      }
      action = 'Во сколько раз $nB меньше чем $nA?';
      actionTxt = 'Во сколько раз ${intToPropis(nB)} меньше чем ${intToPropis(nA)}?';
    } else if (actionInt == 10) {
      nB = rng.nextInt(maxNum~/10);
      if (nA < nB) {
        nRes = nB ~/ nA; nA = nB; nB = nA ~/ nRes;
      } else {
        nRes = nA ~/ nB; nA = nB * nRes;
      }
      action = 'Во сколько раз $nA больше чем $nB?';
      actionTxt = 'Во сколько раз ${intToPropis(nA)} больше чем ${intToPropis(nB)}?';
    } else if (actionInt == 11) {
      nB = rng.nextInt(maxNum~/10);
      if (nA < nB) {
        nRes = nB ~/ nA; nA = nB; nB = nA ~/ nRes;
      } else {
        nRes = nA ~/ nB; nA = nB * nRes;
      }
      action = 'Машина проехала $nA километр${nA<5? 'a':'ов'} за $nB час${nB==1? '':(nB<5? 'a':'ов')}. С какой скоростью ехала машина?';
      actionTxt = 'Машина проехала ${intToPropis(nA)} километр${nA<5? 'a':'ов'} за ${intToPropis(nB)} час${nB==1? '':(nB<5? 'a':'ов')}. С какой скоростью ехала машина?';
    } else if (actionInt == 12) {
      nB = rng.nextInt(maxNum~/10);
      if (nA < nB) {
        nRes = nB ~/ nA; nA = nB; nB = nA ~/ nRes;
      } else {
        nRes = nA ~/ nB; nA = nB * nRes;
      }
      action = 'За сколько времени поезд проедет $nA километр${nA<5? 'a':'ов'} если его скорость $nB километр${nB<5? (nB==1? '':'a') : 'ов'} в час?';
      actionTxt = 'За сколько времени поезд проедет ${intToPropis(nA)} километр${nA<5? 'a':'ов'} если его скорость ${intToPropis(nB)} километр${nB<5? (nB==1? '':'a') : 'ов'} в час?';
    } else if (actionInt == 13) {
      nA = rng.nextInt(maxNum~/10);
      if (nA == 0) {
        nA = 1;
      }
      if (nA > nRes) {
        int n = nA; nA = nRes; nRes = n;
      }
      nB = nRes ~/ nA;
      nRes = nA * nB;
      action = 'Какое расстояние пролетел вертолёт за $nB час${nB==1?'':(nB<5?'a':'ов')}, если его скорость $nA километр${nA==1?'':(nA<5?'a':'ов')} в час?';
      actionTxt = 'Какое расстояние пролетел вертолёт за ${intToPropis(nB)} час${nB==1?'':(nB<5?'a':'ов')}, если его скорость ${intToPropis(nA)} километр${nA==1?'':(nA<5?'a':'ов')} в час?';
    } else if (actionInt == 14) {
      nA = multiplierForTable;
      if (nA > nRes) {
        nRes = nA;
      }
      nB = nRes ~/ nA;
      nRes = nA * nB;
      action = 'Сколько будет $nA * $nB ?';
      actionTxt = 'Сколько будет ${intToPropis(nA)} умножить на ${intToPropis(nB)}?';
    } else if (actionInt == 15) {
      nB = multiplierForTable;
      if (nA < nRes) {
        nA = nRes;
      }
      nRes = nA ~/ nB;
      nA = nB * nRes;
      action = 'Сколько будет $nA / $nB ?';
      actionTxt = 'Сколько будет ${intToPropis(nA)} разделить на ${intToPropis(nB)}?';
    }

    expectedRes = nRes;

    if (actionInt <= 4) {
      setState(() {
        _curTaskMsg = "Сколько будет "+nA.toString()+" "+action+" "+nB.toString()+" ?";
        _curTaskMsgTxt = "Сколько будет "+intToPropis(nA)+" "+actionTxt+" "+intToPropis(nB)+" ?";
      });
    } else {
      setState(() {
        _curTaskMsg = action;
        _curTaskMsgTxt = actionTxt;
      });
    }

  }

  void _startMathLoop() async {
    savePref();
    _mainMathLoop();
  }

  savePref() async {
    final SharedPreferences prefs = await _prefs;
    prefs.setInt("maxNum", maxNum);
    prefs.setInt("mult", multiplierForTable);
    prefs.setInt("mode", findCurTaskTypeNumber());
    prefs.setBool("dynDif", dynamicDifficult);
  }

  void _mainMathLoop() async {
    if (_selectedTaskType.id == '+') {
      _formCurTask(1, 1);
    } else if (_selectedTaskType.id == '-') {
      _formCurTask(2, 2);
    } else if (_selectedTaskType.id == '+-') {
      _formCurTask(1, 2);
    } else if (_selectedTaskType.id == '*/') {
      _formCurTask(3, 4);
    } else if (_selectedTaskType.id == '+-*/') {
      _formCurTask(1, 4);
    } else if (_selectedTaskType.id == '+-*/з') {
      _formCurTask(1, 13);
    } else if (_selectedTaskType.id == 'з') {
      _formCurTask(5, 13);
    } else if (_selectedTaskType.id == 'ту') {
      _formCurTask(14, 14);
    } else if (_selectedTaskType.id == 'тд') {
      _formCurTask(15, 15);
    } else if (_selectedTaskType.id == 'туд') {
      _formCurTask(14, 15);
    } else {
      _formCurTask(1, 13);
    }
    await _speakSync(_curTaskMsgTxt);
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
      localeId: 'ru_RU', // en_US uk_UA
      // onSoundLevelChange: soundLevelListener,
      cancelOnError: true,
      partialResults: true,
      // onDevice: true,
      // listenMode: ListenMode.confirmation,
      // sampleRate: 44100,
    );
  }

  void resultListener(SpeechRecognitionResult result) {
    if (result.finalResult) {
      String recognizedWords = result.recognizedWords.toString();
      setState(() {
        lastSttWords = recognizedWords;
        showMic = false;
      });
      analyzeResults(recognizedWords);
    }
  }

  bool _isNumeric(String str) {
    if(str == null) {
      return false;
    }
    return double.tryParse(str) != null;
  }

  analyzeResults(String recognizedWords) async {
    var wordsList = recognizedWords.split(' ');
    int answerRes = -1;
    for (var i=0; i < wordsList.length; i++) {
      String word = wordsList[i];
      word = word.replaceAll(':00','');
      word = word.replaceAll('один','1');
      word = word.replaceAll('два','2');
      word = word.replaceAll('три','3');
      word = word.replaceAll('четыре','4');
      word = word.replaceAll('пять','5');
      word = word.replaceAll('шесть','6');
      word = word.replaceAll('семь','7');
      word = word.replaceAll('восемь','8');
      word = word.replaceAll('девять','9');
      word = word.replaceAll('десять','10');
      if (_isNumeric(word)) {
        answerRes = int.parse(word);
        break;
      }
    }
    if (answerRes == -1) {
      await _speakSync('Повтори пожалуйста.');
      startListening();
      return;
    }
    if (answerRes == expectedRes) {
      numOkLast5++;
      setState(() {
        if (dynamicDifficult && numOkLast5 == 5) {
          maxNum = (maxNum * 1.05 + 1).toInt(); numOkLast5--;
        }
        numOkAnswer++; numTotalAnswer++;
      });
      await _speakSync('Окей!');
    } else {
      numOkLast5--;
      setState(() {
        if (dynamicDifficult && numOkLast5 == -1) {
          maxNum = (maxNum * 0.95 - 1).toInt(); numOkLast5 = 0;
        }
        numWrongAnswer++; numTotalAnswer++;
      });
      await _speakSync('Неправильно! Будет $expectedRes');
    }
    _mainMathLoop();
  }

  void displaySttDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => new CupertinoAlertDialog(
        title: new Text("Я тебя не понял..."),
        content: new Text("Повторим?"),
        actions: [
          FlatButton(child: Text('Да'), onPressed: () { startListening(); Navigator.pop(context, true); }),
          FlatButton(child: Text('Нет'), onPressed: () { Navigator.pop(context, true); }),
        ],
      ),
    );
  }

  showAlertPage(String msg) {
    showAboutDialog(
      context: context,
      applicationName: 'Alert',
      children: <Widget>[
        Padding(
            padding: EdgeInsets.only(top: 15),
            child: Center(child: Text(msg))
        )
      ],
    );
  }

  String intToPropis(int x){
      if (x == 0) {
        return 'ноль';
      }
      var groups=new List(10);

      groups[0]=new List(10);
      groups[1]=new List(10);
      groups[2]=new List(10);
      groups[3]=new List(10);
      groups[4]=new List(10);

      groups[9]=new List(10);


      groups[1][9]='тысяч';
      groups[1][1]='тысяча';
      groups[1][2]='тысячи';
      groups[1][3]='тысячи';
      groups[1][4]='тысячи';

      groups[2][9]='миллионов';
      groups[2][1]='миллион';
      groups[2][2]='миллиона';
      groups[2][3]='миллиона';
      groups[2][4]='миллиона';

      groups[3][1]='миллиард';
      groups[3][2]='миллиарда';
      groups[3][3]='миллиарда';
      groups[3][4]='миллиарда';

      groups[4][1]='триллион';
      groups[4][2]='триллиона';
      groups[4][3]='триллиона';
      groups[4][4]='триллиона';

      var names=new List(901);

      names[1]='один';
      names[2]='два';
      names[3]='три';
      names[4]='четыре';
      names[5]='пять';
      names[6]='шесть';
      names[7]='семь';
      names[8]='восемь';
      names[9]='девять';
      names[10]='десять';
      names[11]='одиннадцать';
      names[12]='двенадцать';
      names[13]='тринадцать';
      names[14]='четырнадцать';
      names[15]='пятнадцать';
      names[16]='шестнадцать';
      names[17]='семнадцать';
      names[18]='восемнадцать';
      names[19]='девятнадцать';
      names[20]='двадцать';
      names[30]='тридцать';
      names[40]='сорок';
      names[50]='пятьдесят';
      names[60]='шестьдесят';
      names[70]='семьдесят';
      names[80]='восемьдесят';
      names[90]='девяносто';
      names[100]='сто';
      names[200]='двести';
      names[300]='триста';
      names[400]='четыреста';
      names[500]='пятьсот';
      names[600]='шестьсот';
      names[700]='семьсот';
      names[800]='восемьсот';
      names[900]='девятьсот';

      var r='';
      var i,j;

      var y=x.floor();

      var t=new List(5);

      for (i=0;i<=4;i++)
      {
        t[i]=y%1000;
        y = (y/1000).floor();
      }

      var d=new List(5);

      for (i=0;i<=4;i++)
      {
        d[i]=new List(101);
        d[i][0]=t[i]%10; // единицы
        d[i][10]=t[i]%100-d[i][0]; // десятки
        d[i][100]=t[i]-d[i][10]-d[i][0]; // сотни
        d[i][11]=t[i]%100; // две правых цифры в виде числа
      }

      for (i=4; i>=0; i--)
      {
        if (t[i]>0)
        {
          if (names[d[i][100]]!=null)
            r+=' '+ names[d[i][100]];

          if (names[d[i][11]]!=null) {
            r+=' '+ names[d[i][11]];
          } else {
            if (names[d[i][10]]!=null) r+=' '+ names[d[i][10]];
            if (names[d[i][0]]!=null) r+=' '+ names[d[i][0]];
          }

          if (names[d[i][11]]!=null)  // если существует числительное
            j=d[i][11];
          else
            j=d[i][0];

          if (i>0) {
            if (groups[i][j] != null) {
              r+=' '+groups[i][j];
            } else {
              r+=' '+groups[i][9];
            }
          }

        }
      }

      return r;
  }

  void onChangeDropdownItem(TaskType value) {
    setState(() {
      _selectedTaskType = value;
    });
  }

  int findCurTaskTypeNumber() {
    for (int i=0; i<_tasksTypes.length; i++){
      if (_tasksTypes[i] == _selectedTaskType) {
        return i;
      }
    }
    return 5;
  }

}

class BlinkWidget extends StatefulWidget {
  final List<Widget> children;
  final int interval;

  BlinkWidget({@required this.children, this.interval = 500, Key key}) : super(key: key);

  @override
  _BlinkWidgetState createState() => _BlinkWidgetState();
}
class _BlinkWidgetState extends State<BlinkWidget> with SingleTickerProviderStateMixin {
  AnimationController _controller;
  int _currentWidget = 0;

  initState() {
    super.initState();

    _controller = new AnimationController(
        duration: Duration(milliseconds: widget.interval),
        vsync: this
    );

    _controller.addStatusListener((status) {
      if(status == AnimationStatus.completed) {
        setState(() {
          if(++_currentWidget == widget.children.length) {
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

class TaskType {
  String id;
  String name;

  TaskType (this.id, this.name);

  static List<TaskType> getTaskTypes() {
    return <TaskType>[
      TaskType('+', 'Сложение'),
      TaskType('-', 'Вычитание'),
      TaskType('+-', 'Сложение и вычитание'),
      TaskType('*/', 'Умножение и деление'),
      TaskType('+-*/','Все простые действия'),
      TaskType('+-*/з','Задачи и простые действия'),
      TaskType('з', 'Задачи отдельно'),
      TaskType('ту', 'Таблица умножения'),
      TaskType('тд', 'Таблица деления'),
      TaskType('туд', 'Таблица умножения и деления'),
    ];
  }
}


// ********* English page *************

class MyEnglishPage extends StatefulWidget {
  MyEnglishPage() : super();

  @override
  _MyEnglishPage createState() => _MyEnglishPage();
}

class _MyEnglishPage extends State<MyEnglishPage> {
  bool showMic = false;
  bool showDebugInfo = false;
  int mode = 0, curPos=0, maxPos=0;
  String curEngText='', curRusText='';

  final SpeechToText speech = SpeechToText();
  String lastSttWords = '';
  String lastSttError = '';

  FlutterTts flutterTts;
  dynamic languages;
  String language;
  double volume = 1;
  double pitch = 1.2;
  double rate = 1;

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
    await flutterTts.setSpeechRate(rate);
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
    print("Received listener status: $status, listening: ${speech.isListening}");
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
          FlatButton(child: Text('Да'), onPressed: () { startListening(); Navigator.pop(context, true); }),
          FlatButton(child: Text('Нет'), onPressed: () { Navigator.pop(context, true); }),
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(curEngText, textScaleFactor: 2, textAlign: TextAlign.center,),
                SizedBox(height: 20,),
                Text('Перевод: $curRusText', textScaleFactor: 1.6, textAlign: TextAlign.center, style: TextStyle(color: Colors.green[900]),),
                SizedBox(height: 20,),
                Text('Слышу: $lastSttWords', textScaleFactor: 1.4, textAlign: TextAlign.center),
              ],
            )),
          Expanded(
            child: BlinkWidget(
              children: <Widget>[
                Icon(Icons.mic, size: 40, color: showMic? Colors.green : Colors.transparent,),
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
                  padding: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
                  splashColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  padding: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
                  splashColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                  padding: EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
                  splashColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      )
    );
  }

  Widget startEnglishMenu(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Английский')),
        body: Column(
          children: <Widget>[
            Expanded(
              flex:3,
              child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('Когда будешь готов - нажми', textScaleFactor: 2, textAlign: TextAlign.center,),
                      SizedBox(height: 20,),
                      FlatButton(
                        color: Colors.blue,
                        textColor: Colors.white,
                        disabledColor: Colors.grey,
                        disabledTextColor: Colors.black,
                        padding: EdgeInsets.only(left: 40, right: 40, top: 20, bottom: 20),
                        splashColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Text('СТАРТ', textScaleFactor: 2,),
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Настройки тренера:', textScaleFactor: 1.3,),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text('Режим: ', textScaleFactor: 1.3),
                        DropdownButton(
                          value: _selectedEngTaskKind,
                          items: _dropDownMenuEngTaskKindItems,
                          onChanged: (newVal){
                            setState(() {
                              _selectedEngTaskKind = newVal;
                            });
                          }
                        ),
                      ],
                    ),
                  ],
                )
              ),
            )
          ],
        )
    );
  }

  List<DropdownMenuItem<EnglishTask>> buildDropDownEngTaskKindItems() {
    List<DropdownMenuItem<EnglishTask>> items = List();
    for (EnglishTask tt in engTaskKinds) {
      items.add(
          DropdownMenuItem(
              value: tt,
              child: Text(tt.name)
          )
      );
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
      showAlertPage(_userText+' / '+_expText+' $curPos');
    }
    return false;
  }

  String removeAllGarbage(String _text) {
    return _text.
    toUpperCase().
    trim().
    replaceAll('.', '').
    replaceAll(","," ").
    replaceAll("%"," ").
    replaceAll("-"," ").
    replaceAll("("," ").
    replaceAll(")"," ").
    replaceAll(";"," ").
    replaceAll("№"," ").
    replaceAll("!"," ").
    replaceAll("@"," ").
    replaceAll("#"," ").
    replaceAll("\$"," ").
    replaceAll("OKAY","OK").
    replaceAll("FAVOURITE","FAVORITE").
    replaceAll("PERCENT"," ").
    replaceAll("PERCENTS"," ").
    replaceAll("DOLLAR"," ").
    replaceAll("DOLLARS"," ").
    replaceAll("O'CLOCK"," ").
    replaceAll("O'CLOCKS"," ").
    replaceAll("'RE"," ARE").
    replaceAll("'S"," IS").
    replaceAll("'M"," AM").
    replaceAll("'LL"," WILL").
    replaceAll("ALL RIGHT","ALLRIGHT").
    replaceAll("ALRIGHT","ALLRIGHT").
    replaceAll("APARTMENT","APT").
    replaceAll("BEECH","BEACH").
    replaceAll("COLOUR","COLOR").
    replaceAll("GREY","GRAY").
    replaceAll("KILOGRAM","KG").
    replaceAll("KILOMETER","KM").
    replaceAll("P.M.","PM").
    replaceAll("A.M.","AM").
    replaceAll(" AN "," A ").
    replaceAll(" THE "," A ").
    replaceAll(":00"," ").
    replaceAll("'"," ").
    replaceAll("^"," ").
    replaceAll("*"," ").
    replaceAll("&"," ").
    replaceAll(":"," ").
    replaceAll("?"," ").
    replaceAll("/"," ").
    replaceAll("\\"," ").
    replaceAll("+"," ").
    replaceAll("*"," ").
    replaceAll("["," ").
    replaceAll("]"," ").
    replaceAll("{"," ").
    replaceAll("}"," ").
    replaceAll("  "," ").
    replaceAll("  "," ").
    replaceAll("  "," ").
    replaceAll("  "," ").
    replaceAll("  "," ").
    trim();
  }

  showAlertPage(String msg) {
    showAboutDialog(
      context: context,
      applicationName: 'Alert',
      children: <Widget>[
        Padding(
            padding: EdgeInsets.only(top: 15),
            child: Center(child: Text(msg))
        )
      ],
    );
  }

}

class EnglishTask {
  String name;

  EnglishTask(this.name);

  static getList() {
    List <EnglishTask> lt = [];
    lt.add(EnglishTask('Слова'));
    lt.add(EnglishTask('Популярные выражения'));
    lt.add(EnglishTask('Диалоги'));
    return lt;
  }
}


// *********** Deutsch

class MyDeutschPage extends StatefulWidget {
  MyDeutschPage() : super();

  @override
  _MyDeutschPage createState() => _MyDeutschPage();
}

class _MyDeutschPage extends State<MyDeutschPage> {
  bool showMic = false;
  int mode = 0,
      curPos = 0,
      maxPos = 0;
  String curEngText = '',
      curRusText = '';

  final SpeechToText speech = SpeechToText();
  String lastSttWords = '';
  String lastSttError = '';

  FlutterTts flutterTts;
  dynamic languages;
  String language;
  double volume = 1;
  double pitch = 1.2;
  double rate = 1;

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
    await flutterTts.setSpeechRate(rate);
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
      return startDMenu(context);
    } else {
      return TaskPage(context);
    }
  }

  void displaySttDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) =>
      new CupertinoAlertDialog(
        title: new Text("Я тебя не понял..."),
        content: new Text("Повторим?"),
        actions: [
          FlatButton(child: Text('Да'), onPressed: () {
            startListening();
            Navigator.pop(context, true);
          }),
          FlatButton(child: Text('Нет'), onPressed: () {
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
              flex:3,
              child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('Когда будешь готов - нажми', textScaleFactor: 2, textAlign: TextAlign.center,),
                      SizedBox(height: 20,),
                      FlatButton(
                        color: Colors.blue,
                        textColor: Colors.white,
                        disabledColor: Colors.grey,
                        disabledTextColor: Colors.black,
                        padding: EdgeInsets.only(left: 40, right: 40, top: 20, bottom: 20),
                        splashColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: Text('СТАРТ', textScaleFactor: 2,),
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
                        child: Text('Настройки тренера:', textScaleFactor: 1.3,),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text('Режим: Слова', textScaleFactor: 1.3),
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
                    ],
                  )
              ),
            )
          ],
        )
    );
  }

  Widget TaskPage(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('Немецкий')),
        body: Column(
          children: <Widget>[
            Expanded(
                flex: 3,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(curEngText, textScaleFactor: 2,
                      textAlign: TextAlign.center,),
                    SizedBox(height: 20,),
                    Text('Перевод: $curRusText', textScaleFactor: 1.6,
                        textAlign: TextAlign.center),
                    SizedBox(height: 20,),
                    Text('Слышу: $lastSttWords', textScaleFactor: 1.4,
                        textAlign: TextAlign.center),
                  ],
                )),
            Expanded(
              child: BlinkWidget(
                children: <Widget>[
                  Icon(Icons.mic, size: 40,
                    color: showMic ? Colors.green : Colors.transparent,),
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
                      mainDLoop();
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
                      mainDLoop();
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
                      mainDLoop();
                    },
                  ),
                ],
              ),
            )
          ],
        )
    );
  }

  void startDTraining() {
    maxPos = myDWords.length;
    mainDLoop();
  }

  void mainDLoop() async {
    var rng = new Random();
    curPos = rng.nextInt(maxPos);
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
        curPos++;
        if (curPos == maxPos) {
          curPos = 0;
        }
        await _speakSync('ok!');
        mainDLoop();
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
    return _text.
    toUpperCase().
    trim().
    replaceAll('.', '').
    replaceAll("."," ").
    replaceAll("%"," ").
    replaceAll("-"," ").
    replaceAll("("," ").
    replaceAll(")"," ").
    replaceAll(";"," ").
    replaceAll("№"," ").
    replaceAll("!"," ").
    replaceAll("@"," ").
    replaceAll("#"," ").
    replaceAll("\$"," ").
    replaceAll("OKAY","OK").
    replaceAll("FAVOURITE","FAVORITE").
    replaceAll("PERCENT"," ").
    replaceAll("PERCENTS"," ").
    replaceAll("DOLLAR"," ").
    replaceAll("DOLLARS"," ").
    replaceAll("O'CLOCK"," ").
    replaceAll("O'CLOCKS"," ").
    replaceAll("'RE"," ARE").
    replaceAll("'S"," IS").
    replaceAll("'M"," AM").
    replaceAll("'LL"," WILL").
    replaceAll("ALL RIGHT","ALLRIGHT").
    replaceAll("ALRIGHT","ALLRIGHT").
    replaceAll("APARTMENT","APT").
    replaceAll("BEECH","BEACH").
    replaceAll("COLOUR","COLOR").
    replaceAll("GREY","GRAY").
    replaceAll("KILOGRAM","KG").
    replaceAll("KILOMETER","KM").
    replaceAll("P.M.","PM").
    replaceAll("A.M.","AM").
    replaceAll("AN ","A ").
    replaceAll(":00"," ").
    replaceAll("'"," ").
    replaceAll("^"," ").
    replaceAll("*"," ").
    replaceAll("&"," ").
    replaceAll(":"," ").
    replaceAll("?"," ").
    replaceAll("/"," ").
    replaceAll("\\"," ").
    replaceAll("+"," ").
    replaceAll("*"," ").
    replaceAll("["," ").
    replaceAll("]"," ").
    replaceAll("{"," ").
    replaceAll("}"," ").
    replaceAll("  "," ").
    replaceAll("  "," ").
    replaceAll("  "," ").
    replaceAll("  "," ").
    replaceAll("  "," ").
    trim();
  }
}