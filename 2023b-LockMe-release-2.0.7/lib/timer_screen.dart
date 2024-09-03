import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'colors.dart';
import 'package:lock_me/userInfo.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:is_lock_screen/is_lock_screen.dart';
import 'package:badges/badges.dart' as badges;
import 'package:flutter_background/flutter_background.dart';
import 'package:showcaseview/showcaseview.dart';
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
      final authRepository = Provider.of<AuthRepository>(screen.context, listen: false);
      screen._stopTask(false,authRepository);
      // Check if an AlertDialog is shown and dismiss it if it exists
      if (screen._isDialogShown) {
        screen.dismissDialog();
      }
      if(screen.inBetRoom){
        var betting_room = screen.bettingRoomID;
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

class timer extends StatefulWidget  {
  final Function(bool) updateStartTask;
  final Function(bool) updateInBetRoom;
  timer(this.updateStartTask, this.updateInBetRoom, {Key? key}) : super(key: key);

  @override
  timer_screen createState() => timer_screen();
}

class timer_screen extends State<timer> with TickerProviderStateMixin{

  final _keyStartButton = GlobalKey();
  final _keySlider = GlobalKey();
  final _keyBet = GlobalKey();
  final _keyInvitations = GlobalKey();
  final _keyRemainingTime = GlobalKey();

  BuildContext? myContext;

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
  bool initialBet = true;
  bool inBetRoom = false;
  bool betStarted = false;
  int joined_users = 0;
  bool isAdmin = false;
  int selectedCoins = 0;
  String bettingRoomID = '-1';
  late AnimationController _animationController;
  late AnimationController _animationTextSize;
  late Animation<double> _animation;
  late AnimationController fadinganimationController;
  late Animation<double> _fadingAnimation;
  late AnimationController appearanimationController;
  late Animation<double> _appearAnimation;

  void updateCoinCount(int newCoins) {
    setState(() {
      user_coins = newCoins;
    });
  }

  @override
  Widget build(BuildContext context){
    myContext = context;
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
              child: inBetRoom ? StreamBuilder<Map<dynamic, dynamic>>(
                stream: Provider.of<AuthRepository>(context).getBetFriendStream(bettingRoomID), // Replace with your Firebase stream
                builder: (BuildContext context, AsyncSnapshot<Map<dynamic,dynamic>> snapshot) {
                  if (snapshot.hasData) {
                    var joinedList = snapshot.data ?? {};
                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      transitionBuilder: (child, animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: child,
                        );
                      },
                      child:Row(
                        children: [
                          for (var name in joinedList.entries)
                            Padding(
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
                                  backgroundImage: NetworkImage(name.value.toString()),
                                  radius: MediaQuery.of(context).size.height * 0.06,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return const CircularProgressIndicator();
                  }
                },
              ):Padding(
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
              height: MediaQuery.of(context).size.height * 0.02,
            ),

            FadeTransition(
              opacity: _fadingAnimation,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: Showcase(
                      key: _keyBet,
                      description: 'Invite your friends into focus room \n You should add friends first',
                      descriptionAlignment: TextAlign.center,
                      disableDefaultTargetGestures: true,
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
                      child: FloatingActionButton(
                        heroTag: "btn1",
                      onPressed: () async {
                        if (_duration > 0) {
                          if (await checkIfHasFriends()) {
                            if (initialBet) {
                              await showCreateBetDialog();
                            } else {
                              await _showBetFriendDialog();
                            }
                          }else{
                            showFriendErrorDialog(1);
                          }
                        } else {
                          _showInvalidTimeDialog(context);
                        }
                      },
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Stack(
                      children: [
                        Container(
                          height: 70.0,
                          //padding: EdgeInsets.all(8.1), // Adjust the padding as per your requirements
                          child:Showcase(
                            key: _keyInvitations,
                            description: 'Check if you have new invitations',
                            disableDefaultTargetGestures: true,
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
                            child: FloatingActionButton(
                              heroTag: "btn2",
                            onPressed: () async {
                              // final user = Provider.of<AuthRepository>(context, listen: false);
                              // final invite_map = await user.getBetInvites().first;
                              // setState(() {
                              //   betInvite = invite_map;
                              // });
                              await showInvitationsDialog(authRepository);
                            },
                            backgroundColor: primary[100],
                            child: Icon(
                              Icons.notifications_active,
                              color: primary[500],
                            ),
                          ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 5,
                          child: Container(
                            padding: const EdgeInsets.all(2.0), // Adjust the padding as per your requirements
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.red, // Customize the background color as desired
                            ),
                            child: badges.Badge(
                              badgeContent: StreamBuilder<Map<dynamic, dynamic>>(
                                stream: Provider.of<AuthRepository>(context, listen: false).getBetInvites(),
                                builder: (BuildContext context, AsyncSnapshot<Map<dynamic, dynamic>> snapshot) {
                                  final betInvite = snapshot.data ?? {};
                                  final notificationCount = betInvite.length;
                                  return Text(
                                    notificationCount.toString(),
                                    style: const TextStyle(color: Colors.white),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Container(
                height: MediaQuery.of(context).size.height * 0.05,
                child: FadeTransition(
                  opacity: _appearAnimation,
                  child: Text('Remaining time:',
                    style: TextStyle(
                        color: primary[900],
                        fontSize: 30,
                        fontWeight: FontWeight.bold
                    ),
                  ),
                )

            ),

            Showcase(
              key: _keyRemainingTime,
              title: '              Remaining Time',
              //titleAlignment: TextAlign.center,
              titleTextStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black54,
                fontSize: 20,
              ),
              description: 'The remaining time until the task is completed',
              descriptionAlignment:TextAlign.center,
              disableDefaultTargetGestures: true,
              targetShapeBorder: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18.0),
              ),
              tooltipBackgroundColor: primary[100]!,
              descTextStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.black45,
                fontSize: 16,
              ),
              targetPadding: const EdgeInsets.all(6),
              tooltipPadding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Container(
                    height:MediaQuery.of(context).size.height *0.07,
                    width: MediaQuery.of(context).size.height *0.05,
                    decoration: const BoxDecoration(
                      image:  DecorationImage(
                        image:  AssetImage('assets/images/sand_timer.png'),
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
      ),

            Container(
              height: MediaQuery.of(context).size.height * 0.05,
            ),

            Visibility(
              visible: (!_task_running)&&(!inBetRoom),
              child:FadeTransition(
                opacity: _fadingAnimation,
                child: Showcase(
                  key: _keySlider,
                  title: '          Set Your Focus Timer',
                  //titleAlignment: TextAlign.center,
                  titleTextStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                    fontSize: 20,
                  ),
                  description: 'The slider allows you to set a time to focus challenge, the tooltip provides information on the potential coin reward. You can earn coins by successfully completing the challenge, note that you will not lose coins in this challenge.\nTry to use the slider! ',
                  descriptionAlignment: TextAlign.center,
                  disableDefaultTargetGestures: true,
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
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      // Customize the label style
                      overlayColor: primary[500]!.withOpacity(0.2),
                      activeTrackColor: primary[500],
                      inactiveTrackColor: primary[100],
                      thumbColor: primary[500],
                      valueIndicatorColor: primary[500],
                      valueIndicatorTextStyle: TextStyle(
                        color: primary[100],
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child:Slider(
                      value: _duration.toDouble(),
                      min: 0.0,
                      max: 120.0,
                      divisions: 24,
                      label: 'Win ${_duration + (_duration > 60 ? 3 : 0) + (_duration == 60 ? 15 : 0) + (_duration == 120 ? 30 : 0) } Coins',
                      onChanged: (double value) {
                        setState(() {
                          _duration = value.toInt();
                          _hours = _duration ~/ 60;
                          _minutes = _duration% 60;
                          _seconds = (_duration ~/ 60) ~/ 60;
                        });
                      },
                    )
                ),
                ),
              ),
            ),

            Visibility(
              visible: inBetRoom && !_task_running,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.05,
              ),
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

            Visibility(
              visible: _task_running,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.04,
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
              child: Showcase(
                key: _keyStartButton,
                description: 'Start your focusing challenge',
                  disableDefaultTargetGestures: true,
                targetShapeBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18.0),
                ),
                tooltipBackgroundColor: primary[100]!,
                descTextStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.black45,
                  fontSize: 16,
                ),
                targetPadding: const EdgeInsets.all(6),
                tooltipPadding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: (inBetRoom  && !isAdmin && !betStarted) || (inBetRoom && joined_users < 2 && !betStarted) ? null : () {
                    if(_duration > 0) {
                      _task_running ? _stopTask(true, authRepository) : _startTask(authRepository);
                    }else{
                      _showInvalidTimeDialog(context);
                    }
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color?>((inBetRoom  && !isAdmin && !betStarted)|| (inBetRoom && joined_users < 2 && !betStarted) ? Colors.grey : primary[500]),
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
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween(begin: 45.0, end: 60.0)
        .animate(_animationTextSize);

    ///fading animation
    fadinganimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Duration of the animation
    );
    _fadingAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(fadinganimationController);

    ///appearing animation
    appearanimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Duration of the animation
    );
    _appearAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(appearanimationController);
  }

  void showTutorial2(){
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ShowCaseWidget.of(myContext!).startShowCase([_keySlider,_keyRemainingTime,_keyBet,_keyInvitations, _keyStartButton]);

    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(ScreenLifecycleObserver(this));
    super.dispose();
  }

  Future<void> leaveBetRoomDialog() async{
    final user = Provider.of<AuthRepository>(context, listen: false);
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState)
          {
            return AlertDialog(
              title: const Text('Leave Room'),
              content: const Text('Are you sure you want to leave?'),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Proceed'),
                  onPressed: () async {
                    var bet_room = bettingRoomID;
                    Navigator.of(context).pop();
                    reintilizeTask();
                    await user.leaveBet(bet_room);
                  },
                ),
              ],
            );
          }
          );
        }
    );

  }

  void reintilizeTask(){
    widget.updateInBetRoom(false);
    widget.updateStartTask(false);
    setState(() {
      betStarted = false;
      inBetRoom = false;
      isAdmin = false;
      bettingRoomID = '-1';
      _task_running = false;
      initialBet = true;
      selectedCoins = 0;
      _duration = 0;
      _hours = 0;
      _minutes = 0;
      _seconds = 0;
      //friendBetList = {'me':profile.toString()};
      friends = [];
    });
    fadinganimationController.reverse();
  }

  Future<void> showInvitationsDialog(AuthRepository authRepository) async {
    final Stream<Map<dynamic, dynamic>> betInviteStream = Provider.of<AuthRepository>(context, listen: false).getBetInvites(); // Replace with your Firebase stream

    await showDialog<Friend>(
      context: context,
      builder: (BuildContext context) {
        return StreamBuilder<Map<dynamic, dynamic>>(
          stream: betInviteStream,
          builder: (BuildContext context, AsyncSnapshot<Map<dynamic, dynamic>> snapshot) {
            if (snapshot.hasData) {
              final betInvite = snapshot.data ?? {};
              final bets = betInvite.keys.toList();

              return SimpleDialog(
                title: Text(betInvite.isEmpty ? 'No Bet invitations yet.' : 'Bet invitations:'),
                children: [
                  SingleChildScrollView(
                    child: Column(
                      children: bets.map((id) {
                        return SimpleDialogOption(
                          onPressed: () {},
                          child: Row(
                            children: [
                              Column(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: NetworkImage(betInvite[id]['url']),
                                    radius: 20,
                                  ),
                                  Text(betInvite[id]['admin'].toString()),
                                ],
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Column(
                                children: [
                                  Text('coins: ${betInvite[id]['coins']}'),
                                  Text('time : ${betInvite[id]['duration']}'),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.start_rounded, color: Colors.green),
                                onPressed: () async {
                                  await showJoinBetDialog(betInvite, id, authRepository);
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return const CircularProgressIndicator();
            }
          },
        );
      },
    );
  }

  void showErrorDialog(){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Future.delayed(Duration(seconds: 2), () {
        //   Navigator.of(context).pop();
        // });
        return const AlertDialog(
          title: Text('Error :('),
          content: Text('Unowned Error has occurred'),
        );
      },
    );
  }

  Future<void> showJoinBetDialog(Map betInvite,String id,AuthRepository authRepository) async{
    final user = Provider.of<AuthRepository>(context, listen: false);
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, StateSetter setState)
          {
            return AlertDialog(
              title: const Text('joining Room'),
              content:Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Column(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(
                                (betInvite[id])['url']),
                            radius: 30,
                          ),
                          Text((betInvite[id])['admin'].toString()),
                        ],
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Column(
                        children: [
                          Text('coins: ${(betInvite[id])['coins']}'),
                          Text('time : ${(betInvite[id])['duration']}'),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Proceed'),
                  onPressed: () async {
                    bool out = await user.acceptBetInvitation(id);
                    Navigator.of(context).pop();
                    if(!out) {
                      showErrorDialog();
                    }else{
                      joinBet((betInvite[id])['duration'], id, authRepository);
                    }
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          }
          );
        }
    );
  }

  void waitForGameStatusChange(AuthRepository authRepository) {
    final gameStatusStreamController = StreamController<String>();
    String previousGameStatus = 'waiting';

    FirebaseFirestore.instance
        .collection('Betting_Rooms')
        .doc(bettingRoomID)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        final gameStatus = snapshot.get('game_status');

        // Check if the game status has changed
        if (gameStatus != previousGameStatus) {
          // Emit the new game status through the stream
          gameStatusStreamController.add(gameStatus);
          previousGameStatus = gameStatus; // Update the previous game status
        }
      }
    });

    // Wait for the game status to change
    gameStatusStreamController.stream.listen((gameStatus) {
      // Perform tasks based on how the game status changed
      if (gameStatus == 'started') {
        setState(() {
          //_task_running = true;
          betStarted = true;
        });
        _startTask(authRepository);
      } else if (gameStatus == 'canceled') {
        reintilizeTask();
      }
    });
  }

  void waitForUsersToJoin(AuthRepository authRepository){
    final gameStatusStreamController = StreamController<int>();
    StreamSubscription<int>? subscription;
    int previous = 1;

    FirebaseFirestore.instance
        .collection('Betting_Rooms')
        .doc(bettingRoomID)
        .snapshots()
        .listen((DocumentSnapshot snapshot) {
      if (snapshot.exists) {
        final current = snapshot.get('joined_users').length;
        if (current != previous) {
          gameStatusStreamController.add(current);
          previous = current;
        }
      }
    });
    subscription = gameStatusStreamController.stream.listen((current) {
      if (!inBetRoom) {
        subscription?.cancel(); // Stop listening to the stream
        return;
      }
      setState(() {
        joined_users = current;
      });
    });
  }

  void joinBet(int duration, String id,AuthRepository authRepository){

    widget.updateInBetRoom(true);
    setState(() {
      inBetRoom = true;
      bettingRoomID = id;

      //values for the slider
      _duration = duration.toInt();
      _hours = _duration ~/ 60;
      _minutes = _duration% 60;
      _seconds = (_duration ~/ 60) ~/ 60;

    });
    fadinganimationController.forward();
    waitForGameStatusChange(authRepository);
  }

  Future<void> showCreateBetDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        if(user_coins >= 10) {
          return StatefulBuilder(builder: (context, StateSetter setState)
          {
            return AlertDialog(
              title: const Text('Starting Room'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'Starting Focus Room on: ${_duration.toString()} minutes.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Proceed'),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await showBetCoinsDialog();
                  },
                ),
              ],
            );
          }
          );
        }
        else{
          // Future.delayed(Duration(seconds: 3), () {
          //   Navigator.of(context).pop();
          // });
          return const AlertDialog(
            title: Text("Sorry, You Don't Have Enough Coins :("),
            content: Text('The minimum is 10 coins to start a bet'),
          );
        }
      },
    );
  }

  Future<void> showBetCoinsDialog() async{
    final user = Provider.of<AuthRepository>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        if(user_coins >= 10) {
          return StatefulBuilder(builder: (context, StateSetter setState)
          {
            return AlertDialog(
              title: const Text('Select Betting Coins'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      // Customize the label style
                      overlayColor: primary[500]!.withOpacity(0.2),
                      activeTrackColor: primary[500],
                      inactiveTrackColor: primary[100],
                      thumbColor: primary[500],
                      valueIndicatorColor: primary[500],
                      valueIndicatorTextStyle: TextStyle(
                        color: primary[100],
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: Slider(
                      value: selectedCoins.toDouble(),
                      min: 0,
                      max: user_coins.toDouble(),
                      divisions: (user_coins.toDouble() ~/ 5).toInt(),
                      label: '${selectedCoins.toString()} coins',
                      onChanged: (double value) {
                        setState(() {
                          selectedCoins = value.toInt();
                        });
                      },
                    ),
                  ),
                  Text(
                    'Bet On:${selectedCoins.toString()}',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Proceed'),
                  onPressed: () async {
                    if(selectedCoins > 0) {
                      Stream<List<Friend>> friendsStream = Provider.of<AuthRepository>(context,listen: false).getFriendsStream(false);
                      List<Friend> fetchedFriends = await friendsStream.first;
                      if(!checkFriendList(fetchedFriends)) {
                        showFriendErrorDialog(2);
                        //Navigator.of(context).pop();
                      }
                      else{
                        String id = await user.createBettingRoom(_duration,selectedCoins,user.userName, profile.toString());
                        widget.updateInBetRoom(true);
                        setState(() {
                          bettingRoomID = id;
                          initialBet = false;
                          isAdmin = true;
                          inBetRoom = true;
                          fetchedFriends.forEach((friend) {
                            if(friend.coins >= selectedCoins)
                              friends.add(friend);
                          });
                        });
                        Navigator.of(context).pop();
                        await _showBetFriendDialog();
                        waitForUsersToJoin(user);
                      }
                    }
                  },
                ),
              ],
            );
          }
          );
        }
        else{
          return const AlertDialog(
            title: Text("Sorry, You Don't Have Enough Coins :("),
            content: Text('The minimum is 10 coins to start a bet'),
          );
        }
      },
    );
  }

  bool checkFriendList(List<Friend> fetchedFriends){
    int check = 0;
    fetchedFriends.forEach((friend) {
      if(friend.coins >= selectedCoins) {
        check ++;
      }
    });
    return check > 0 ? true : false;
  }

  Future<bool> checkIfHasFriends() async{
    Stream<List<Friend>> friendsStream = Provider.of<AuthRepository>(context,listen: false).getFriendsStream(false);
    List<Friend> fetchedFriends = await friendsStream.first;
    return fetchedFriends.isNotEmpty;
  }

  void showFriendErrorDialog(int opt){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Future.delayed(Duration(seconds: 2), () {
        //   Navigator.of(context).pop();
        // });
        return  AlertDialog(
          title: const Text('Error:('),
          content: opt == 1 ? const Text('Friend list is empty\nAdd your friends so you can invite them')
              :const Text('None of your friends have enough coins'),
        );
      },
    );
  }

  void _showInvalidTimeDialog(BuildContext context){
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AlertDialog(
          title: Text('Invalid Time'),
          content: Text('Please set the Timer first'),
        );
      },
    );
  }

  void _startTask(AuthRepository authRepository ) async{

    runningInBackground.run_in_background();

    if(isAdmin) {
      await authRepository.startBet(bettingRoomID);
    }
    if (!_task_running) {
      int totalSeconds = _duration * 60;
      //_profit_coins = (_duration / 5).toInt();
      _profit_coins = _duration;
      if(_duration == 60){
        _profit_coins += 15;
      }
      if(_duration == 120){
        _profit_coins += 30;
      }
      if(_duration > 60){
        _profit_coins +=3;
      }
      if(totalSeconds == 0){
        return;
      }
      widget.updateStartTask(true);
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if(inBetRoom && isAdmin){
          betStarted = true;
        }
        setState(() {
          if(_seconds % 2 == 0){
            authRepository.sync_time(bettingRoomID);
          }
          if (totalSeconds > 0) {
            _task_running = true;
            totalSeconds--;
            _hours = totalSeconds ~/ 3600;
            _minutes = (totalSeconds % 3600) ~/ 60;
            _seconds = totalSeconds % 60;
          } else {
            _timer?.cancel();
            _stopTask(true, authRepository);
            if(inBetRoom){
              authRepository.endBet(bettingRoomID);
              reintilizeTask();
            }else {
              authRepository.updateCoins(authRepository.user!.uid, user_coins+_profit_coins);
              showTaskCompletedDialog(_profit_coins);
            }
            updateCoinCount(authRepository.userCoins);
            return;
          }
        });
      });
      _animationTextSize.forward();
      _animationController.forward();
      fadinganimationController.forward();
      appearanimationController.forward();
      //showTaskStartedDialog(_profit_coins);
    }
  }

  void showTaskCompletedDialog(int _profit_coins) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Task Completed!'),
          content: Text('You Earned ${_profit_coins.toString()} coins!\n GOOD JOB:)' ),
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

  void _stopTask(bool showDialog,AuthRepository authRepository) {

    if (_task_running) {
      if(showDialog && (_hours > 0 || _minutes > 0 || _seconds > 0) ) {
        showStopTaskDialog();
      }else{
        widget.updateStartTask(false);
        _timer?.cancel();
        update_statistics(authRepository);
        setState(() {
          _task_running = false;
          _hours = 0;
          _minutes = 0;
          _seconds = 0;
          _duration = 0;
        });
        fadinganimationController.reverse();
        appearanimationController.reverse();
        _animationTextSize.reverse();
        _animationController.reverse();
      }
    }
  }

  void showStopTaskDialog(){
    setState(() {
      _isDialogShown = true;
    });
    stopTaskDialog();
  }

  void dismissDialog() {
    setState(() {
      _isDialogShown = false;
    });
    Navigator.of(context).pop();
  }

  void stopTaskDialog() {
    final user = Provider.of<AuthRepository>(context, listen: false);
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
                update_statistics(user);
                setState(() {
                  _task_running = false;
                  _hours = 0;
                  _minutes = 0;
                  _seconds = 0;
                  _duration = 0;
                  _isDialogShown = false;
                });
                if(inBetRoom) {
                  var bet_room = bettingRoomID;
                  reintilizeTask();
                  await user.leaveBet(bet_room);
                }
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
        return const AlertDialog(
          title: Text('Task Stopped!'),
          content: Text('Sorry the task has been stopped because you left the app.' ),
        );
      },
    );
  }

  Future<void> _showBetFriendDialog() async {
    final user = Provider.of<AuthRepository>(context, listen: false);
    await showDialog<Friend>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
            title:  Text('Select Friend to Bet on: ${selectedCoins} Coins'),
            children: [
              SingleChildScrollView(
                child: Column(
                  children: friends.map((friend) {
                    return SimpleDialogOption(
                      onPressed: () {
                        setState(() {
                          user.sendInvitiation(friend.name,friend.imageURl,_duration,selectedCoins,bettingRoomID);
                          friends.remove(friend);
                          Navigator.of(context).pop();
                        });
                      },
                      child: Row(
                          children: [
                            CircleAvatar(
                              backgroundImage: NetworkImage(friend.imageURl.toString()),
                              radius: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(friend.name),
                          ]
                      ),
                    );
                  }).toList(),
                ),
              ),]
        );
      },
    );
  }

  Future<void> update_statistics(AuthRepository authRepository) async{

    if((_hours > 0 || _minutes > 0 || _seconds > 0)){
      if(inBetRoom){
        authRepository.add_failed_bet(bettingRoomID);
      }else{
        authRepository.add_failed_task(_duration);
      }
    }else{
      if(inBetRoom){
        authRepository.add_successfull_bet(bettingRoomID);
      }else{
        authRepository.add_successfull_task(_duration, _profit_coins);
      }
    }

  }
}