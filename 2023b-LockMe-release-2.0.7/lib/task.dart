import 'package:flutter/material.dart';
import 'package:lock_me/appDrawer.dart';
import 'colors.dart';
import 'package:lock_me/userInfo.dart';
import 'package:provider/provider.dart';
import 'package:is_lock_screen/is_lock_screen.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:showcaseview/showcaseview.dart';
import 'timer_screen.dart';
import 'stopWatch_screen.dart';
import 'package:audioplayers/audioplayers.dart' as audio;
import 'package:wakelock/wakelock.dart';


class task extends StatefulWidget  {
  GlobalKey<timer_screen> globalKey = GlobalKey();
  task({Key? globalKey}) : super(key: globalKey );

  @override
  _task_screen createState() => _task_screen();
}

class ScreenLifecycleObserver extends WidgetsBindingObserver {
  final screen;
  ScreenLifecycleObserver(this.screen);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async{
    bool? result = await isLockScreen();
    if ((state == AppLifecycleState.paused || state == AppLifecycleState.inactive)&& result==false) {
      screen.audioPlayer.release();
      screen.set_audio();
    }
  }
}

class RunningInBackground {

  var androidConfig = FlutterBackgroundAndroidConfig();
  bool success = false;

  void intilize() async {
    androidConfig = const FlutterBackgroundAndroidConfig(
      notificationTitle: "LockMe",
      notificationText: "timer is running, don't lose focus!",
      notificationImportance: AndroidNotificationImportance.Default,
      notificationIcon: AndroidResource(name: 'background_icon', defType: 'drawable'), // Default is ic_launcher from folder mipmap
    );
    success = await FlutterBackground.initialize(androidConfig: androidConfig);
  }

  void run_in_background() async{
    success = await FlutterBackground.enableBackgroundExecution();

  }

  void stop_run_in_background() async{
    await FlutterBackground.disableBackgroundExecution();
  }
}

class _task_screen extends State<task> with TickerProviderStateMixin{

  RunningInBackground runningInBackground = RunningInBackground();
  late AuthRepository authRepository;

  void set_audio(){
    setState(() {
      audioImagePath = 'assets/images/mute.png';
    });
  }

  @override
  void initState(){
    super.initState();
    Wakelock.enable();
    WidgetsBinding.instance.addObserver(ScreenLifecycleObserver(this));
    audioPlayer = AudioPlayer();
    audioPlayer.setReleaseMode(ReleaseMode.loop);
    audioImagePath = 'assets/images/mute.png';
  }

  @override
  void dispose() {
    Wakelock.disable();
    WidgetsBinding.instance.removeObserver(ScreenLifecycleObserver(this));
    audioPlayer.release();
    super.dispose();
  }

  void showTutorial(){
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ShowCaseWidget.of(context).startShowCase(
        [
          _keycoins,
          _keyStopWatch,
          _keyTimer,
        ],
      );
    });

  }

  final _keyStopWatch = GlobalKey();
  final _keycoins = GlobalKey();
  final _keyTimer = GlobalKey();

  final PageController _pageController = PageController();
  int _selectedIndex = 0;
  int user_coins = 0;
  bool _task_running = false;
  bool inBetRoom = false;
  var timer_size = AppBar().preferredSize.height*0.85;
  var watch_size = AppBar().preferredSize.height*0.7;
  AudioPlayer audioPlayer = AudioPlayer();
  String audioImagePath = 'assets/images/mute.png';
  String audio_play_img = 'assets/images/play.png';
  String audio_mute_img = 'assets/images/mute.png';

  @override
  Widget build(BuildContext context) {
    authRepository = Provider.of<AuthRepository>(context);
    runningInBackground.intilize();
    updateCoinCount(authRepository.userCoins);
    return Scaffold(
        backgroundColor: primary[300],

        appBar: AppBar(
          iconTheme: IconThemeData(
            color: primary[100],
          ),

          leading: (_task_running)
              ? IconButton(
            icon: const Icon(Icons.lock_clock, color: primary),
            onPressed: () {},
          )
              : Builder(
            builder: (BuildContext context) =>
                IconButton(
                  icon: inBetRoom ? const Icon(Icons.sensor_door_outlined) : const Icon(Icons.menu),
                  onPressed: () async {
                    if(inBetRoom){
                      await widget.globalKey.currentState!.leaveBetRoomDialog();
                    }else{
                      Scaffold.of(context).openDrawer();
                    }
                  },
                ),
          ),

          centerTitle: true,
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  if (!_task_running && !inBetRoom) {
                    setState(() {
                      _selectedIndex = 0;
                      timer_size = AppBar().preferredSize.height * 0.85;
                      watch_size = AppBar().preferredSize.height * 0.7;
                      _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.ease);
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 0 ? primary[100] : primary[500],
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(50),
                      bottomLeft: const Radius.circular(50),
                      topRight: _selectedIndex == 0 ? const Radius.circular(50) : const Radius.circular(25),
                      bottomRight: _selectedIndex == 0 ? const Radius.circular(50) : const Radius.circular(25),
                    ),
                  ),
                  child:Showcase(
                    key: _keyTimer,
                    description: 'Focus with Timer mode',
                    disposeOnTap: true,
                    onBarrierClick: (){
                      widget.globalKey.currentState!.showTutorial2();
                    },
                      onTargetClick: (){
                        widget.globalKey.currentState!.showTutorial2();
                      },
                    targetShapeBorder: const CircleBorder(),
                    tooltipBackgroundColor: primary[100]!,
                    descTextStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black45,
                      fontSize: 16,
                    ),
                    targetPadding: const EdgeInsets.all(6),
                    tooltipPadding: const EdgeInsets.all(20),
                    child: Image.asset(
                    'assets/images/sand_timer.png',
                    width: timer_size,
                    height: timer_size,
                  ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (!_task_running && !inBetRoom) {
                    setState(() {
                      _selectedIndex = 1;
                      watch_size = AppBar().preferredSize.height * 0.85;
                      timer_size = AppBar().preferredSize.height * 0.7;
                      _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.ease);
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _selectedIndex == 1 ? primary[100] : primary[500],
                    borderRadius: BorderRadius.only(
                      topRight: const Radius.circular(50),
                      bottomRight: const Radius.circular(50),
                      topLeft: _selectedIndex == 1 ? const Radius.circular(50) : const Radius.circular(25),
                      bottomLeft: _selectedIndex == 1 ? const Radius.circular(50) : const Radius.circular(25),
                    ),
                  ),
                  child:Showcase(
                    key: _keyStopWatch,
                    description: 'Focus with Stopwatch mode',
                    targetShapeBorder: const CircleBorder(),
                    tooltipBackgroundColor: primary[100]!,
                    descTextStyle: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.black45,
                      fontSize: 16,
                    ),
                    targetPadding: const EdgeInsets.all(6),
                    tooltipPadding: const EdgeInsets.all(20),
                    child: Image.asset(
                    'assets/images/stop_watch2.png',
                    width: watch_size,
                    height: watch_size,
                  ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
          Showcase(
          key: _keycoins,
          title: '                        Coins',
          //titleAlignment: TextAlign.center,
          titleTextStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black54,
            fontSize: 20,
          ),
          description: 'The coins you have collected while focusing, you start with 20 coins!',
          descriptionAlignment: TextAlign.center,
          targetShapeBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18.0),
          ),
          tooltipBackgroundColor: primary[100]!,
          descTextStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black45,
            fontSize: 16,
          ),
          targetPadding: const EdgeInsets.all(4),
          tooltipPadding: const EdgeInsets.all(20),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [ Container(
                  height: AppBar().preferredSize.height*0.7,
                  width: AppBar().preferredSize.height*0.7,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/coin.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Text(
                  user_coins.toString(),
                  style: TextStyle(
                    color: primary[100],
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
          ],
        ),

        drawer: (!_task_running && !inBetRoom)? const AppDrawer() : null,

        body:Stack(
          children: [

            PageView(
              physics: (!_task_running && !inBetRoom) ? const AlwaysScrollableScrollPhysics() : const NeverScrollableScrollPhysics(),
              controller: _pageController,
              onPageChanged:(int index) {
                setState(() {
                  _selectedIndex = index;
                  if(index == 0){
                    timer_size = AppBar().preferredSize.height*0.85;
                    watch_size = AppBar().preferredSize.height*0.7;
                  }else{
                    watch_size = AppBar().preferredSize.height*0.85;
                    timer_size = AppBar().preferredSize.height*0.7;
                  }
                });
              },
              children: [
                timer(update_task_running_Status,update_InBetRoom_Status,key: widget.globalKey),
                stopwatch(update_task_running_Status),
              ],
            ),

            Column(
              children: [
                GestureDetector(
                  onTap: () {
                    toggleAudioPlayback(); // Replace with your audio file path
                  },
                  child: Image.asset(audioImagePath,
                    height: 60,
                    width: 60,
                  ),
                ),

                Visibility(
                  visible: !_task_running,
                    child:GestureDetector(
                      onTap: () => setState(() {
                        showTutorial();
                      }),
                      child: Image.asset('assets/images/guid.png',
                        height: 50,
                        width: 50,
                      ),
                    ),
                ),

              ],
            ),

          ],
        )

    );
  }

  void toggleAudioPlayback() async {
    if (audioPlayer.state == PlayerState.playing) {
      await audioPlayer.pause();
      setState(() {
        audioImagePath = audio_mute_img;
      });
    } else {
      await audioPlayer.play(audio.UrlSource(authRepository.selectedMusic!));
      setState(() {
        audioImagePath = audio_play_img;
      });
    }
  }

  void updateCoinCount(int newCoins) {
    setState(() {
      user_coins = newCoins;
    });
  }

  void update_task_running_Status(bool newValue) {
    newValue ? runningInBackground.run_in_background() : runningInBackground.stop_run_in_background();
    setState(() {
      _task_running = newValue;
    });
  }

  void update_InBetRoom_Status(bool newValue) {
    setState(() {
      inBetRoom = newValue;
    });
  }
}
