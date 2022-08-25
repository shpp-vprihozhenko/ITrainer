import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:math';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'IntToRusPropis.dart';

IntToRusPropis itp = new IntToRusPropis();
enum TtsState { playing, stopped, paused, continued }

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
  String _curTaskMsg = 'Сколько будет 2 + 2 ?', _curTaskMsgTxt = '';
  int expectedRes = 0, lastA = -1, lastB = -1;
  int numOkAnswer = 0, numWrongAnswer = 0, numTotalAnswer = 0;
  int numOkLast5 = 0;
  bool showMic = false;

  List<TaskType> _tasksTypes = TaskType.getTaskTypes();
  List<DropdownMenuItem<TaskType>> _dropDownMenuTaskTypeItems;
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
      items.add(DropdownMenuItem(value: tt, child: Text(tt.name)));
    }
    return items;
  }

  Future _getLanguages() async {
    languages = await flutterTts.getLanguages;
    if (!isSupportedLanguageInList()) {
      showAlertPage(
          'Извините, в Вашем телефоне не установлен требуемый TTS-язык. Обновите ваш синтезатор речи (Google TTS).');
    }
  }

  isSupportedLanguageInList() {
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

    speech.errorListener = errorListener;
    speech.statusListener = statusListener;

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
    print("Received MATH error status: $error, listening: ${speech.isListening}");
    setState(() {
      showMic = false;
      lastSttWords = error.toString();
    });
    displaySttDialog();
  }

  void statusListener(String status) {
    if (status == 'notListening') {
      setState(() {
        showMic = false;
        lastSttWords = 'notListening';
      });
    } else if (status == 'listening') {
      // ok
    } else {
      showAlertPage("Received strange Stt status: $status, listening: ${speech.isListening}");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (mode == 0) {
      return startMathMenu(context);
    } else {
      return taskPage(context);
    }
  }

  Widget taskPage(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Реши задачу')),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  _curTaskMsg,
                  style: TextStyle(fontSize: 22.0),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Expanded(
              child: showMic? Center(child: Image.asset('assets/images/animMicroph.gif', width: 40, height: 40)) : SizedBox(height: 40,)
            //child: BlinkWidget(children: <Widget>[Icon(Icons.mic,size: 40,color: showMic ? Colors.green : Colors.transparent,),Icon(Icons.mic, size: 40, color: Colors.transparent),],),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Text('Последний ответ: $lastSttWords',
                        style: TextStyle(fontSize: 20.0)),
                    Text('Всего ответов: $numTotalAnswer',
                        style: TextStyle(fontSize: 20.0)),
                    Text('Правильных ответов: $numOkAnswer',
                        style: TextStyle(fontSize: 20.0)),
                    Text('Неправильных ответов: $numWrongAnswer',
                        style: TextStyle(fontSize: 20.0)),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                myFlatBtn("Настройки", ()=>{ setState(() { mode = 0; }) }),
                myFlatBtn("Повторить", ()=>{ repeatTask() }),
                myFlatBtn("Следующая", ()=>{ _mainMathLoop() }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget startMathMenu(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Математика')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/math.png'),
            fit: BoxFit.fill,
            colorFilter: new ColorFilter.mode(
                Colors.black.withOpacity(0.2), BlendMode.dstATop),
          ),
        ),
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: Column(
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.only(
                          left: 0, right: 0, top: 0, bottom: 40),
                      child: Column(
                        children: <Widget>[
                          Container(
                              padding: EdgeInsets.only(
                                  left: 0, right: 0, top: 40, bottom: 40),
                              child: Center(
                                  child: Text(
                                'Когда будешь готов - нажми',
                                textScaleFactor: 3,
                                textAlign: TextAlign.center,
                              ))),
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
                  ],
                ),
              ),
            ),
            Container(
                padding: EdgeInsets.only(left: 0, right: 0, top: 6, bottom: 6),
                color: Colors.lightBlue[100],
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height / 3,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListView(children: <Widget>[
                    Text('настройки Тренера:',
                        textScaleFactor: 1.4, textAlign: TextAlign.center),
                    TextField(
                        controller: textEditController
                          ..text = maxNum.toString(),
                        autocorrect: true,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            prefix: Text('Максимум: '),
                            //labelStyle: ,
                            hintText: 'Максимум:'),
                        onSubmitted: (String value) async {
                          if (_isNumeric(value)) {
                            setState(() {
                              maxNum = int.parse(value);
                            });
                          }
                        }),
                    Row(
                      children: <Widget>[
                        Text('Режим:  ',
                            style: TextStyle(color: Colors.grey[700]),
                            textScaleFactor: 1.1),
                        DropdownButton(
                            value: _selectedTaskType,
                            items: _dropDownMenuTaskTypeItems,
                            onChanged: onChangeDropdownItem),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        Text('Динамическая сложность:', textScaleFactor: 1.1),
                        Switch(
                            value: dynamicDifficult,
                            onChanged: (newVal) {
                              setState(() {
                                dynamicDifficult = newVal;
                              });
                            })
                      ],
                    ),
                    TextField(
                        controller: textEditControllerForMult
                          ..text = multiplierForTable.toString(),
                        autocorrect: true,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                            prefix: Text('Множитель: '),
                            hintText: 'Множитель для таблицы умножения:'),
                        onSubmitted: (String value) async {
                          if (_isNumeric(value)) {
                            setState(() {
                              multiplierForTable = int.parse(value);
                            });
                          }
                        }),
                  ]),
                ))
          ],
        ),
      ),
    );
  }

  _formCurTask(int startTask, int finTask) {
    var rng = new Random();
    int nA = rng.nextInt(maxNum+1);
    int nB = rng.nextInt(maxNum+1);
    int nRes = rng.nextInt(maxNum+1);

    int actionInt = startTask;
    if (finTask > startTask) {
      actionInt += rng.nextInt(finTask - startTask + 1);
    }

    String actionTxt, action;

    if (actionInt == 1) {
      actionTxt = 'плюс';
      action = '+';
      while (nA+nB > maxNum || nA == lastA || nB == lastB) {
        nA = rng.nextInt(maxNum+1);
        nB = rng.nextInt(maxNum+1);
      }
      nRes = nA + nB;
    } else if (actionInt == 2) {
      actionTxt = 'минус';
      action = '-';
      while (nA-nB < 0 || nA == lastA || nB == lastB) {
        nA = rng.nextInt(maxNum+1);
        nB = rng.nextInt(maxNum+1);
      }
      nRes = nA - nB;
    } else if (actionInt == 3) {
      actionTxt = 'умножить на';
      action = '*';
      nA = rng.nextInt(maxNum ~/ 10);
      if (nA > nRes) {
        int n = nA;
        nA = nRes;
        nRes = n;
      }
      if (nA == 0) {
        nA = 1;
      }
      nB = nRes ~/ nA;
      nRes = nA * nB;
    } else if (actionInt == 4) {
      actionTxt = 'разделить на';
      action = '/';
      nB = rng.nextInt(maxNum ~/ 10)+1;
      if (nA > nB) {
        nRes = (nA / nB).round();
        nA = nRes * nB;
      } else {
        if (nA == 0) {
          nA = 1;
        }
        nRes = (nB / nA).round();
        nB = nA;
        nA = nB * nRes;
      }
    } else if (actionInt == 5) {
      if (nA < nB) {
        nRes = nB - nA;
        nA = nB;
        nB = nA - nRes;
      } else {
        nRes = nA - nB;
      }
      action = 'На сколько $nA больше чем $nB?';
      actionTxt =
          'На сколько ${itp.intToPropis(nA)} больше чем ${itp.intToPropis(nB)}?';
    } else if (actionInt == 6) {
      if (nA < nB) {
        nRes = nB - nA;
        nA = nB;
        nB = nA - nRes;
      } else {
        nRes = nA - nB;
      }
      action = 'На сколько $nB меньше чем $nA?';
      actionTxt =
          'На сколько ${itp.intToPropis(nB)} меньше чем ${itp.intToPropis(nA)}?';
    } else if (actionInt == 7) {
      if (nA < nB) {
        nRes = nB - nA;
        nA = nB;
        nB = nA - nRes;
      } else {
        nRes = nA - nB;
      }
      action = 'Сколько надо отнять от $nA, чтобы получить $nB?';
      actionTxt =
          'Сколько надо отнять от ${itp.intToPropis(nA)}, чтобы получить ${itp.intToPropis(nB)}?';
    } else if (actionInt == 8) {
      if (nA < nB) {
        nRes = nB - nA;
        nA = nB;
        nB = nA - nRes;
      } else {
        nRes = nA - nB;
      }
      action = 'Сколько надо прибавить к $nB, чтобы получить $nA?';
      actionTxt =
          'Сколько надо прибавить к ${itp.intToPropis(nB)}, чтобы получить ${itp.intToPropis(nA)}?';
    } else if (actionInt == 9) {
      nB = rng.nextInt(maxNum ~/ 10)+1;
      if (nA < nB) {
        if (nA == 0) {
          nA = 1;
        }
        nRes = nB ~/ nA;
        if (nRes == 0) {
          nRes = 1;
        }
        nA = nB;
        nB = nA ~/ nRes;
      } else {
        if (nB == 0) {
          nB = 1;
        }
        nRes = nA ~/ nB;
        nA = nB * nRes;
      }
      action = 'Во сколько раз $nB меньше чем $nA?';
      actionTxt =
          'Во сколько раз ${itp.intToPropis(nB)} меньше чем ${itp.intToPropis(nA)}?';
    } else if (actionInt == 10) {
      nB = rng.nextInt(maxNum ~/ 10)+1;
      if (nA < nB) {
        if (nA == 0) {
          nA = 1;
        }
        nRes = nB ~/ nA;
        nA = nB;
        if (nRes == 0) {
          nRes = 1;
        }
        nB = nA ~/ nRes;
      } else {
        nRes = nA ~/ nB;
        nA = nB * nRes;
      }
      action = 'Во сколько раз $nA больше чем $nB?';
      actionTxt =
          'Во сколько раз ${itp.intToPropis(nA)} больше чем ${itp.intToPropis(nB)}?';
    } else if (actionInt == 11) {
      nB = rng.nextInt(maxNum ~/ 10)+1;
      if (nA < nB) {
        if (nA == 0) {
          nA = 1;
        }
        nRes = nB ~/ nA;
        nA = nB;
        if (nRes == 0) {
          nRes = 1;
        }
        nB = nA ~/ nRes;
      } else {
        nRes = nA ~/ nB;
        nA = nB * nRes;
      }
      action =
          'Машина проехала $nA километр${restOfNum(nA)} за $nB час${restOfNum(nB)}. С какой скоростью ехала машина?';
      actionTxt =
          'Машина проехала ${itp.intToPropis(nA)} километр${restOfNum(nA)} за ${itp.intToPropis(nB)} час${restOfNum(nB)}. С какой скоростью ехала машина?';
    } else if (actionInt == 12) {
      nB = rng.nextInt(maxNum ~/ 10)+1;
      if (nA < nB) {
        if (nA == 0) {
          nA = 1;
        }
        nRes = nB ~/ nA;
        nA = nB;
        if (nRes == 0) {
          nRes = 1;
        }
        nB = nA ~/ nRes;
      } else {
        nRes = nA ~/ nB;
        nA = nB * nRes;
      }
      action =
          'За сколько времени поезд проедет $nA километр${restOfNum(nA)} если его скорость $nB километр${restOfNum(nB)} в час?';
      actionTxt =
          'За сколько времени поезд проедет ${itp.intToPropis(nA)} километр${restOfNum(nA)} если его скорость ${itp.intToPropis(nB)} километр${restOfNum(nB)} в час?';
    } else if (actionInt == 13) {
      nA = rng.nextInt(maxNum ~/ 10)+1;
      if (nA == 0) {
        nA = 1;
      }
      if (nA > nRes) {
        int n = nA;
        nA = nRes;
        nRes = n;
      }
      if (nA == 0) {
        nA = 1;
      }
      nB = nRes ~/ nA;
      nRes = nA * nB;
      action =
          'Какое расстояние пролетел вертолёт за $nB час${restOfNum(nB)}, если его скорость $nA километр${restOfNum(nA)} в час?';
      actionTxt =
          'Какое расстояние пролетел вертолёт за ${itp.intToPropis(nB)} час${restOfNum(nB)}, если его скорость ${itp.intToPropis(nA)} километр${restOfNum(nA)} в час?';
    } else if (actionInt == 14) {
      nA = multiplierForTable;
      if (nA == 0) {
        nA = 1;
      }
      if (nA > nRes) {
        nRes = nA;
      }
      nB = nRes ~/ nA;
      nRes = nA * nB;
      action = 'Сколько будет $nA * $nB ?';
      actionTxt =
          'Сколько будет ${itp.intToPropis(nA)} умножить на ${itp.intToPropis(nB)}?';
    } else if (actionInt == 15) {
      nB = multiplierForTable;
      if (nA < nRes) {
        nA = nRes;
      }
      nRes = nA ~/ nB;
      nA = nB * nRes;
      action = 'Сколько будет $nA / $nB ?';
      actionTxt =
          'Сколько будет ${itp.intToPropis(nA)} разделить на ${itp.intToPropis(nB)}?';
    }

    expectedRes = nRes; lastA = nA; lastB = nB;

    if (actionInt <= 4) {
      setState(() {
        _curTaskMsg = "Сколько будет $nA $action $nB ?";
        _curTaskMsgTxt = "Сколько будет " +
            itp.intToPropis(nA) +
            " " +
            actionTxt +
            " " +
            itp.intToPropis(nB) +
            " ?";
      });
    } else {
      setState(() {
        _curTaskMsg = action;
        _curTaskMsgTxt = actionTxt;
      });
    }
  }

  String restOfNum(int num) {
    if (num > 4 && num < 21) {
     return 'ов';
    }
    int lastD = num%10;
    String res = '';
    if (lastD > 4 || lastD == 0) {
      res = 'ов';
    } else if (lastD > 1) {
      res = 'a';
    }
    return res;
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
    try {
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
    } catch (err) {
      setState(() {
        lastSttWords = 'task form err $err';
        _mainMathLoop();
      });
    }

    await _speakSync(_curTaskMsgTxt);
    startListening();
  }

  repeatTask() async {
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
      listenFor: Duration(seconds: 50),
      pauseFor: Duration(seconds: 10),
      localeId: 'ru_RU', // en_US uk_UA
      // onSoundLevelChange: soundLevelListener,
      cancelOnError: true,
      partialResults: true,
      onDevice: true,
      listenMode: ListenMode.dictation,
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
    } else {
      setState(() {
        //lastSttWords = 'fr '+result.finalResult.toString() + ' conf '+result.confidence.toString()+' altL '+result.alternates.length.toString();
        if (result.alternates.length > 0) {
          setState(() {
            lastSttWords = result.alternates[0].recognizedWords;
            showMic = false;
          });
        }
        showMic = false;
      });
    }
  }

  bool _isNumeric(String str) {
    if (str == null) {
      return false;
    }
    return double.tryParse(str) != null;
  }

  analyzeResults(String recognizedWords) async {
    var wordsList = recognizedWords.split(' ');
    int answerRes = -1;
    for (var i = 0; i < wordsList.length; i++) {
      String word = wordsList[i];
      word = word.replaceAll(':00', '');
      word = word.replaceAll('один', '1');
      word = word.replaceAll('два', '2');
      word = word.replaceAll('три', '3');
      word = word.replaceAll('четыре', '4');
      word = word.replaceAll('пять', '5');
      word = word.replaceAll('шесть', '6');
      word = word.replaceAll('семь', '7');
      word = word.replaceAll('восемь', '8');
      word = word.replaceAll('девять', '9');
      word = word.replaceAll('десять', '10');
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
          maxNum = (maxNum * 1.05 + 1).toInt();
          numOkLast5--;
        }
        numOkAnswer++;
        numTotalAnswer++;
      });
      await _speakSync('Окей!');
    } else {
      numOkLast5--;
      setState(() {
        if (dynamicDifficult && numOkLast5 == -1) {
          maxNum = (maxNum * 0.95 - 1).toInt();
          numOkLast5 = 0;
        }
        numWrongAnswer++;
        numTotalAnswer++;
      });
      await _speakSync('Неправильно! Будет $expectedRes');
    }
    _mainMathLoop();
  }

  void displaySttDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => new CupertinoAlertDialog(
        title: Text("Я тебя не понял...", textScaleFactor: 1.3,),
        content: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("Повторим?", textScaleFactor: 1.6,),
        ),
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

  void onChangeDropdownItem(TaskType value) {
    setState(() {
      _selectedTaskType = value;
    });
  }

  int findCurTaskTypeNumber() {
    for (int i = 0; i < _tasksTypes.length; i++) {
      if (_tasksTypes[i] == _selectedTaskType) {
        return i;
      }
    }
    return 5;
  }

  Widget myFlatBtn(String s, cb) {
    return FlatButton(
      color: Colors.blue,
      textColor: Colors.white,
      disabledColor: Colors.grey,
      disabledTextColor: Colors.black,
      padding:
      EdgeInsets.only(left: 10, right: 10, top: 10, bottom: 10),
      splashColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)),
      onPressed: () {
        cb();
      },
      child: Text(
        s,
        style: TextStyle(fontSize: 16.0),
      ),
    );
  }
}

/*
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
        duration: Duration(milliseconds: widget.interval));

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
*/

class TaskType {
  String id;
  String name;

  TaskType(this.id, this.name);

  static List<TaskType> getTaskTypes() {
    return <TaskType>[
      TaskType('+', 'Сложение'),
      TaskType('-', 'Вычитание'),
      TaskType('+-', 'Сложение и вычитание'),
      TaskType('*/', 'Умножение и деление'),
      TaskType('+-*/', 'Все простые действия'),
      TaskType('+-*/з', 'Задачи и простые действия'),
      TaskType('з', 'Задачи отдельно'),
      TaskType('ту', 'Таблица умножения'),
      TaskType('тд', 'Таблица деления'),
      TaskType('туд', 'Таблица умножения и деления'),
    ];
  }
}
