

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

enum TtsState { playing, stopped }

/*
Title:HomePageScreen
Purpose:HomePageScreen
Created By:Kalpesh Khandla
*/

class HomePageScreen extends StatefulWidget {
  HomePageScreen({Key key}) : super(key: key);

  @override
  _HomePageScreenState createState() => _HomePageScreenState();
}

class _HomePageScreenState extends State<HomePageScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final SpeechToText speech = SpeechToText();
  bool _hasSpeech = false;
  bool speechTest = false;
  bool _isAnimating = false;
  bool isMatchFound = false;
  String lastError = "";
  String lastStatus = "";
  String lastWords = "";
  PersistentBottomSheetController _controller;
  AnimationController _animationController;
  GlobalKey<ScaffoldState> _key = GlobalKey();
  dynamic languages;
  FlutterTts flutterTts;
  TtsState ttsState = TtsState.stopped;
  double volume = 0.5;
  double rate = 0.5;
  double pitch = 1.0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initSpeechState();
    _animationController = AnimationController(
      vsync: this,
      lowerBound: 0.5,
      duration: Duration(seconds: 3),
    )..repeat();
    initTts();
  }

  initTts() {
    flutterTts = FlutterTts();

    _getLanguages();

    flutterTts.setStartHandler(() {
      setState(() {
        ttsState = TtsState.playing;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        ttsState = TtsState.stopped;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        ttsState = TtsState.stopped;
      });
    });
  }

  Future _getLanguages() async {
    languages = await flutterTts.getLanguages;
    if (languages != null) setState(() => languages);
  }

  Future<void> initSpeechState() async {
    bool hasSpeech = await speech.initialize(
      onError: errorListener,
      onStatus: statusListener,
      debugLogging: false,
    );

    if (!mounted) return;
    setState(() {
      _hasSpeech = hasSpeech;
    });
  }

  void errorListener(SpeechRecognitionError error) {
    setState(() {
      lastError = "${error.errorMsg} - ${error.permanent}";
    });
  }

  void statusListener(String status) {
    if (status == "listening") {
    } else if (status == "notListening") {
      _animationController.reset();
      _isAnimating = false;
    }
  }

  void resultListenerCheck(SpeechRecognitionResult result) {
    if (!speech.isListening) {
      resultListener(result);
    }
  }

  void resultListener(SpeechRecognitionResult result) {
    _animationController.reset();
    _isAnimating = false;
    _controller.setState(() {
      //lastWords = "${result.recognizedWords} - ${result.finalResult}";
      lastWords = "${result.recognizedWords}";
    });
    if (speech.isListening) {
      return;
    } else {
      lastWords != null &&
          lastWords.length > 0 &&
          !speech.isListening &&
          !isMatchFound;

      ///lastWords="Sorry No Match Founds";
      isMatchFound = true;
      // _speak("sorry we can not found any match! please try again");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.only(
          left: 15,
          right: 15,
          top: 30,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                getBottomSheet(context);
                startListening();
              },
              child: Image.asset(
                'assets/images/mike.png',
                height: 120,
                width: 200,
              ),
            ),
            Text(
              "Tap on Mike to Convert Your Speech to Text",
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.caption.copyWith(
                    fontSize: 18,
                    color: Colors.black,
                    fontWeight: FontWeight.w700,
                  ),
            )
          ],
        ),
      ),
    );
  }

  void startListening() {
    _animationController.addListener(() {
      setState(() {});
    });
    //_animationController.forward();
    _animationController.repeat(period: Duration(seconds: 2));
    _isAnimating = true;
    lastWords = "";
    lastError = "";
    isMatchFound = false;
    int listenForSeconds = 10;
    if (Platform.isIOS) {
      listenForSeconds = 5;
    }
    Duration listenFor = Duration(seconds: listenForSeconds);

    speech.listen(onResult: resultListenerCheck, listenFor: listenFor);
    setState(() {
      speechTest = true;
    });
  }

  Future _speak(String message) async {
    if (Platform.isIOS) {
      volume = 0.7;
    } else {
      volume = 0.5;
    }
    await flutterTts.setVolume(volume);
    await flutterTts.setSpeechRate(rate);
    await flutterTts.setPitch(pitch);

    if (message != null) {
      if (message.isNotEmpty) {
        var result = await flutterTts.speak(message);
        if (result == 1) setState(() => ttsState = TtsState.playing);
      }
    }
  }

  Future<void> getBottomSheet(BuildContext context) async {
    _controller = _key.currentState.showBottomSheet(
      (_) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(
                Radius.circular(
                  20,
                ),
              ),
              shape: BoxShape.rectangle,
              border: Border.all(
                width: 5,
                color: Colors.grey,
              ),
            ),
            height: 250,
            width: 500,
            child: Column(
              children: <Widget>[
                Container(
                  padding: EdgeInsets.fromLTRB(20, 0, 0, 0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          lastWords,
                          style: Theme.of(context)
                              .textTheme
                              .title
                              .copyWith(fontFamily: 'ManropSemiBold')
                              .copyWith(
                                color: Color(0xffE15B4F),
                              ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          // Navigator.of(context).pop();
                          _controller.close();
                        },
                      ),
                    ],
                  ),
                ),
                _hasSpeech
                    ? Expanded(
                        child: AnimatedBuilder(
                          animation: CurvedAnimation(
                              parent: _animationController,
                              curve: Curves.fastOutSlowIn),
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: <Widget>[
                                _buildContainer(
                                    150 * _animationController.value),
                                _buildContainer(
                                    200 * _animationController.value),
                                GestureDetector(
                                  onTap: () {
                                    _controller.setState(() {
                                      lastWords = "";
                                    });
                                    startListening();
                                  },
                                  child: Center(
                                    child: Image.asset(
                                      'assets/images/mike.png',
                                      height: 120,
                                      width: 200,
                                    ),
                                  ),
                                ),
                                //Text(lastWords)
                              ],
                            );
                          },
                        ),
                      )
                    : Container(
                        height: 0,
                        width: 0,
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContainer(double radius) {
    radius = !speechTest || !_isAnimating ? 0 : radius;
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xffF7CCC9).withOpacity(1 - _animationController.value),
      ),
    );
  }
}
