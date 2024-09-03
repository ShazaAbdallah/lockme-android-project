import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'colors.dart';
import 'package:lock_me/userInfo.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:is_lock_screen/is_lock_screen.dart';
import 'package:flutter_background/flutter_background.dart';
import 'dart:io';


class ScreenLifecycleObserver extends WidgetsBindingObserver {
  final screen;
  ScreenLifecycleObserver(this.screen);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async{
    bool? result = await isLockScreen();
    bool screen_was_running = screen._task_running;
    if ((state == AppLifecycleState.paused || state == AppLifecycleState.inactive)&& result==false&&screen_was_running) {
      // User has exited the screen or moved to the background
      screen._stopTask(false);
      // Check if an AlertDialog is shown and dismiss it if it exists
      if (screen._isDialogShown) {
        screen.dismissDialog();
      }
      if(screen.inBetRoom){
        var betting_room = screen.bettingRoomID;
        final authRepository = Provider.of<AuthRepository>(screen.context, listen: false);
        await authRepository.leaveBet(betting_room);
        screen.reintilizeTask();
      }
      screen.showLeavedTaskDialog();
    }
  }
}

class RunningInBackground {

  var androidConfig = const FlutterBackgroundAndroidConfig();
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

class stopwatch extends StatefulWidget  {
  final Function(bool) updateStartTask;
  const stopwatch(this.updateStartTask,{Key? key}) : super(key: key);

  @override
  stopwatch_screen createState() => stopwatch_screen();
}

class stopwatch_screen extends State<stopwatch> with TickerProviderStateMixin{

  RunningInBackground runningInBackground = RunningInBackground();
  late List<Friend> friends = [];
  String profile = 'assets/images/defult_profilePic.png';
  bool _isDialogShown = false;
  int _duration = 0;
  int _hours = 0;
  int _minutes = 0;
  int _seconds = 0;
  Timer? _timer;
  bool _task_running = false;
  int _profit_coins = 0;
  int user_coins = 0;
  late AnimationController _animationController;
  late AnimationController _animationTextSize;
  late Animation<double> _animation;
  late AnimationController fadinganimationController;
  late AnimationController appearanimationController;
  late Animation<double> _appearAnimation;
  late Animation<double> _fadingAnimation;
  bool inBetRoom = false; //for observer only, will not use it in class
  void updateCoinCount(int newCoins) {
    setState(() {
      user_coins = newCoins;
    });
  }

  @override
  Widget build(BuildContext context){
    runningInBackground.intilize();
    final authRepository = Provider.of<AuthRepository>(context);
    updateCoinCount(authRepository.userCoins);
    final user_image = authRepository.userImage;
    if(user_image != '') {
      profile = user_image;
    }
    return SingleChildScrollView(
      child: Center(
        child: Column(
          children: <Widget>[

            Container(
              height: MediaQuery.of(context).size.height * 0.04,
            ),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 8.0,
                        spreadRadius: 2.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(profile.toString()),
                    radius: MediaQuery.of(context).size.height * 0.06,
                  ),
                ),
              ),
            ),

            Container(
              height: MediaQuery.of(context).size.height * 0.02 + 40,
            ),

            Visibility(
              visible: !_task_running,
              child: Container(
                  height: MediaQuery.of(context).size.height * 0.06 + 20,
                  child:FadeTransition(
                    opacity: _fadingAnimation,
                    child: Text("Count Your Focus Time\n       And Earn Coins!",
                      style: TextStyle(
                          color: primary[900],
                          fontSize: 25,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  )
              ),
            ),

            Visibility(
              visible: _task_running,
              child: Container(
                  height: MediaQuery.of(context).size.height * 0.06,
                  child:FadeTransition(
                    opacity: _appearAnimation,
                    child: Text(_profit_coins >= 1 ? "You've earned ${_profit_coins} coins so far":"Stay Focused",
                      style: TextStyle(
                          color: primary[900],
                          fontSize: 25,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                  )
              ),
            ),

            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Container(
                    height:MediaQuery.of(context).size.height *0.07,
                    width: MediaQuery.of(context).size.height *0.07,
                    decoration: const BoxDecoration(
                      image:  DecorationImage(
                        image:  AssetImage('assets/images/stop_watch2.png'),
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),

                  AnimatedBuilder(
                    animation: _animationTextSize,
                    builder: (BuildContext context, Widget? child) {
                      return Text(
                        '${_hours.toString().padLeft(2, '0')}:${_minutes.toString().padLeft(2, '0')}:${_seconds.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: _animation.value,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      );
                    },
                  ),

                ]),

            Container(
              height: MediaQuery.of(context).size.height * 0.1 + 5,
            ),

            Visibility(
              visible: !_task_running,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.675,
                height: MediaQuery.of(context).size.height * 0.3,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: FileImage(File(authRepository.getStaticAvatarPath(authRepository.selectedAvatar!))),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            AnimatedSwitcher(
                duration: const Duration(milliseconds: 500), // Adjust the duration as needed
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: child,
                  );
                },
                child: _task_running
                    ? Container(
                  key: const ValueKey<bool>(true),
                  width: MediaQuery.of(context).size.width* 0.675,
                  height: MediaQuery.of(context).size.height * 0.3,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(File(authRepository.selectedAvatar!)),
                      fit: BoxFit.contain,
                    ),
                  ),
                ): null
            ),

            SizedBox(
              width: 300.0,
              height: MediaQuery.of(context).size.height *0.06,
              child: ElevatedButton(
                onPressed: () {
                  _task_running ? _stopTask(true) : _startTask(authRepository);
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color?>(primary[500]),
                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18.0),
                    ),
                  ),
                ),
                child:  Text(_task_running? 'STOP' : 'START',
                  style: TextStyle(
                    color: primary[100],
                    fontWeight: FontWeight.bold,
                    fontSize: MediaQuery.of(context).size.height *0.03,
                  ),
                ),
              ),
            ),
          ],),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(ScreenLifecycleObserver(this));
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    ///timer font size
    _animationTextSize = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animation = Tween(begin: 45.0, end: 60.0)
        .animate(_animationTextSize);

    ///fading animation
    fadinganimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // Duration of the animation
    );
    _fadingAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(fadinganimationController);

    ///appearing animation
    appearanimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Duration of the animation
    );
    _appearAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(appearanimationController);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(ScreenLifecycleObserver(this));
    super.dispose();
  }

  void _startTask(AuthRepository authRepository ) async{

    runningInBackground.run_in_background();
    if (!_task_running) {
      int totalSeconds = 0;
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        widget.updateStartTask(true);
        if (_duration < 120) {
          setState(() {
            _task_running = true;
            totalSeconds++;
            _hours = totalSeconds ~/ 3600;
            _minutes = (totalSeconds % 3600) ~/ 60;
            _seconds = totalSeconds % 60;
            _duration = _minutes + _hours*60;
            //_profit_coins = (_duration / 5).toInt();
            _profit_coins = _duration;
          });
        }else{
          _stopTask(true);
        }
      });
      fadinganimationController.forward();
      _animationTextSize.forward();
      _animationController.forward();
      appearanimationController.forward();
    }
  }

  void showTaskCompletedDialog(int _profit_coins) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Task Completed!'),
          content: _profit_coins > 0 ?  Text('You Earned ${_profit_coins.toString()} coins!\n GOOD JOB:)')
              :const Text("unfortunately you didn't win coins\nyour task was less that one minute."),
        );
      },
    );

  }

  void showTaskStartedDialog(int _profit_coins){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Task Started!'),
          content: Text('Complete the Task to earn ${_profit_coins.toString()} coins!\n GOOD LUCK:)' ),
        );
      },
    );
  }

  void _stopTask(bool showDialog) {
    final authRepository = Provider.of<AuthRepository>(context, listen: false);
    if (_task_running) {
      if(showDialog && (_hours > 0 || _minutes > 0 || _seconds > 0) ) {
        showStopTaskDialog(authRepository);
      }else{
        widget.updateStartTask(false);
        _timer?.cancel();
        setState(() {
          //_profit_coins = (_duration / 5).toInt();
          _profit_coins = _duration;
          if(_duration == 60){
            _profit_coins +=15;
          }
          if(_duration == 120){
            _profit_coins +=30;
          }
          if(_duration > 60){
            _profit_coins +=3;
          }
          authRepository.add_stopper_time(_duration, _profit_coins);
          _task_running = false;
          _hours = 0;
          _minutes = 0;
          _seconds = 0;
          _duration = 0;
        });
        authRepository.updateCoins(authRepository.user!.uid, user_coins+_profit_coins);
        updateCoinCount(authRepository.userCoins);
        fadinganimationController.reverse();
        appearanimationController.reverse();
        _animationTextSize.reverse();
        _animationController.reverse();
      }
    }
  }

  void showStopTaskDialog(AuthRepository authRepository){
    setState(() {
      _isDialogShown = true;
    });
    stopTaskDialog(authRepository);
  }

  void dismissDialog() {
    setState(() {
      _isDialogShown = false;
    });
    Navigator.of(context).pop();
  }

  void stopTaskDialog(AuthRepository authRepository) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Wait!! you will loose coins!'),
          content: const Text('Are you sure you want to quit the task?'),
          actions: [
            TextButton(
              child: const Text('Stop Task'),
              onPressed: () async {
                runningInBackground.stop_run_in_background();
                Navigator.of(context).pop();
                _timer?.cancel();
                widget.updateStartTask(false);
                setState(() {
                  //_profit_coins = (_duration / 5).toInt();
                  _profit_coins = _duration;
                  if(_duration == 60){
                    _profit_coins +=15;
                  }
                  if(_duration == 120){
                    _profit_coins +=30;
                  }
                  if(_duration > 60){
                    _profit_coins +=3;
                  }
                  authRepository.add_stopper_time(_duration, _profit_coins);
                  _task_running = false;
                  _hours = 0;
                  _minutes = 0;
                  _seconds = 0;
                  _duration = 0;
                  _isDialogShown = false;
                });
                showTaskCompletedDialog(_profit_coins);
                authRepository.updateCoins(authRepository.user!.uid, user_coins+_profit_coins);
                updateCoinCount(authRepository.userCoins);
                fadinganimationController.reverse();
                appearanimationController.reverse();
                _animationTextSize.reverse();
                _animationController.reverse();
              },
            ),
            TextButton(
              child: const Text('Proceed'),
              onPressed: () {
                setState(() {
                  _isDialogShown = false;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void showLeavedTaskDialog( ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return  AlertDialog(
          title: const Text('Task Stopped!'),
          content: _profit_coins > 0 ? Text('Sorry the task has been stopped because you left the app.\nYou Earned ${_profit_coins} coins.')
              : const Text('Sorry the task has been stopped because you left the app.\nYour session was less that 5 minutes.'),
        );
      },
    );
  }

}