import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'MyEnglishPage.dart';
import 'MyDeutschPage.dart';
import 'MyMathPage.dart';

enum TtsState { playing, stopped, paused, continued }

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

  initTts() {
    flutterTts = FlutterTts();
    _getLanguages();
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
                  child: Center(
                      child: Text(
                    'Математика',
                    textScaleFactor: 2,
                  )),
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
                    child:
                        Center(child: Text("Английский", textScaleFactor: 2))),
              ),
            ),
            Flexible(
              flex: 2,
              child: InkWell(
                splashColor: Colors.white,
                focusColor: Colors.green,
                highlightColor: Colors.blue,
                hoverColor: Colors.red,
                onTap: () =>
                    runDeutschTrainer(context), // handle your onTap here
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
                    child: Text(
                        'Автор идеи и разработчик -\nПрихоженко Владимир',
                        textScaleFactor: 1.2,
                        textAlign: TextAlign.center),
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
    ).then((v){
      print('go back from eng with $v');
    });
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
      applicationVersion: 'Версия 1.0.2',
      applicationLegalese: '©2020 Владимир Прихоженкo',
      children: <Widget>[
        Padding(
            padding: EdgeInsets.only(top: 15),
            child: Center(
                child: Text(
                    'Свои предложения и замечания пожалуйста шлите на email \nvprihogenko@gmail.com')))
      ],
    );
  }

  openMathTrainer(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MyMathPage()),
    );
    flutterTts.setLanguage('ru-RU');
    _speakSync('Когда будешь готов - нажми Старт!');
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
