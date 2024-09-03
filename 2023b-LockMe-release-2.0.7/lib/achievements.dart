import 'package:flutter/material.dart';
import 'package:circular_chart_flutter/circular_chart_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lock_me/userInfo.dart';
import 'package:provider/provider.dart';
import 'colors.dart';
import 'package:lock_me/appDrawer.dart';

class Achievements extends StatefulWidget {
  final GlobalKey<AnimatedCircularChartState> _tasksKey = new GlobalKey<AnimatedCircularChartState>();
  final GlobalKey<AnimatedCircularChartState> _timeKey = new GlobalKey<AnimatedCircularChartState>();
  final GlobalKey<AnimatedCircularChartState> _coinstKey = new GlobalKey<AnimatedCircularChartState>();

  Achievements({Key? key});

  @override
  _AchievementsScreen createState() => _AchievementsScreen();
}

class _AchievementsScreen extends State<Achievements> {

  late AuthRepository authRepository;
  var height = 0.0;
  var width = 0.0;
  int failed_tasks = 0;
  int succ_tasks = 0;
  int failed_bets = 0;
  int succ_bets = 0;
  List<CircularStackEntry> tasks_duraion = [];
  List<CircularStackEntry> tasks = [CircularStackEntry(<CircularSegmentEntry>[CircularSegmentEntry(1, Colors.grey),],),CircularStackEntry(<CircularSegmentEntry>[CircularSegmentEntry(1, Colors.grey),],)];
  List<CircularStackEntry> bets = [CircularStackEntry(<CircularSegmentEntry>[CircularSegmentEntry(1, Colors.grey),CircularSegmentEntry(0, Colors.grey)],)];
  List<CircularStackEntry> bet_duration = [CircularStackEntry(<CircularSegmentEntry>[CircularSegmentEntry(1, Colors.grey),CircularSegmentEntry(0, Colors.grey)],)];
  List<CircularStackEntry> coins = [];

  @override
  Widget build(BuildContext context) {
    authRepository = Provider.of<AuthRepository>(context);
    height = MediaQuery.of(context).size.height;
    width = MediaQuery.of(context).size.width;
    var size = height*0.45 - 100;
    creat_chart_data();
    return Scaffold(
        backgroundColor: primary[100],

        appBar: AppBar(
          iconTheme: const  IconThemeData(
            color: Colors.white,
          ),
          title:  Text(
            "My Achievements",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),),
        ),

        drawer: const AppDrawer(),

        body:  SingleChildScrollView(

          child: Column(
            children: [

              Container(
                height: height*0.45,
                width: width,
                //margin: EdgeInsets.all(3.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 0.0),
                    child:
                    Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child:Text("Focusing Tasks", style: TextStyle(
                            color: primary[500],
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                          ),
                        ),

                        SizedBox(
                          height: 10,
                        ),

                        Row(
                          children: [
                            Container(
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 12.0,
                                        height: 12.0,
                                        color: primary[500],
                                      ),
                                      SizedBox(width: 4.0),
                                      Text("Completed Timer Tasks",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                        ),),
                                    ]
                                  ),
                                  Row(
                                      children: [
                                        Container(
                                          width: 12.0,
                                          height: 12.0,
                                          color: primary[100],
                                        ),
                                        SizedBox(width: 4.0),
                                        Text("Failed Timer Tasks",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                          ),),
                                      ]
                                  )
                                ],
                               ),
                              ),
                              SizedBox(
                                width: 10
                              ),
                              Container(
                                child: Column(
                                  children: [
                                  Row(
                                      children: [
                                        Container(
                                          width: 12.0,
                                          height: 12.0,
                                          color: Colors.amber[600],
                                        ),
                                        SizedBox(width: 4.0),
                                        Text("Completed Bets",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                          ),),
                                      ]
                                  ),
                                  Row(
                                      children: [
                                        Container(
                                          width: 12.0,
                                          height: 12.0,
                                          color: Colors.grey[300],
                                        ),
                                        SizedBox(width: 4.0),
                                        Text("Failed Bets",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                          ),),
                                      ]
                                  )
                                ],
                              ),

                            )
                          ],
                        ),

                        AnimatedCircularChart(
                          key: widget._tasksKey,
                          size:  Size(size, size),
                          initialChartData: tasks,
                          chartType: CircularChartType.Radial,
                          holeRadius: 50,
                          edgeStyle: SegmentEdgeStyle.round,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Container(
                height: height*0.22,
                width: width,
                //margin: EdgeInsets.all(3.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child:
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Align(
                                  alignment: Alignment.topLeft,
                                  child:Text("Focusing Time", style: TextStyle(
                                    color: primary[500],
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  ),
                                ),
                                SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Column(
                                        children: [

                                          Row(
                                            children: [
                                              Container(
                                                width: 12.0,
                                                height: 12.0,
                                                color: primary[200],
                                              ),
                                              SizedBox(width: 4.0),
                                              Text("Completed Timer Task",
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 15,
                                                ),),
                                            ],
                                          ),

                                          Row(
                                            children: [
                                              Container(
                                                width: 12.0,
                                                height: 12.0,
                                                color: primary[500],
                                              ),
                                              SizedBox(width: 4.0),
                                              Text("Completed Bet",
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 15,
                                                ),),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Container(
                                                width: 12.0,
                                                height: 12.0,
                                                color: primary[900],
                                              ),
                                              SizedBox(width: 4.0),
                                              Text("Stop-Watch Time",
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 15,
                                                ),),

                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Container(
                                                width: 12.0,
                                                height: 12.0,
                                                color: Colors.redAccent[100],
                                              ),
                                              SizedBox(width: 4.0),
                                              Text("Failed Timer Task",
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 15,
                                                ),),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Container(
                                                width: 12.0,
                                                height: 12.0,
                                                color: Colors.red[100],
                                              ),
                                              SizedBox(width: 4.0),
                                              Text("Failed Bet",
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 15,
                                                ),),
                                            ],
                                          ),
                                        ]
                                    ),
                                  ],
                                )
                              ],
                            ),

                            Align(
                              alignment: Alignment.centerRight,
                              child:AnimatedCircularChart(
                                key: widget._timeKey,
                                size:  Size(150, 150),
                                initialChartData: tasks_duraion,
                                chartType: CircularChartType.Pie,
                              ),
                            )
                          ],
                        ),

                  ),
                ),
              ),

              Container(
                height: height*0.2,
                width: width,
                //margin: EdgeInsets.all(1.0),
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child:
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.topLeft,
                              child:Text("Coins Manager", style: TextStyle(
                                color: primary[500],
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              ),
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Column(
                                    children: [

                                      Row(
                                        children: [
                                          Container(
                                            width: 12.0,
                                            height: 12.0,
                                            color: primary[500],
                                          ),
                                          SizedBox(width: 4.0),
                                          Text("Profit from Timer",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 15,
                                            ),),
                                        ],
                                      ),

                                      Row(
                                        children: [
                                          Container(
                                            width: 12.0,
                                            height: 12.0,
                                            color: primary[200],
                                          ),
                                          SizedBox(width: 4.0),
                                          Text("Profit from Bets",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 15,
                                            ),),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            width: 12.0,
                                            height: 12.0,
                                            color: primary[900],
                                          ),
                                          SizedBox(width: 4.0),
                                          Text("Stop-Watch Coins",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 15,
                                            ),),

                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            width: 12.0,
                                            height: 12.0,
                                            color: Colors.redAccent[100],
                                          ),
                                          SizedBox(width: 4.0),
                                          Text("Lost Bet Coins",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 15,
                                            ),),
                                        ],
                                      ),
                                    ]
                                ),
                              ],
                            )
                          ],
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child:AnimatedCircularChart(
                            key: widget._coinstKey,
                            size:  Size(150, 150),
                            initialChartData: coins,
                            chartType: CircularChartType.Pie,
                          ),
                        )
                      ],
                    ),

                  ),
                ),
              ),

            ],
          ),

        )

    );
  }

  void creat_chart_data() {
    var statistics =  authRepository.statistics;

    var check = statistics['failed_tasks_duration'] + statistics['failed_bet_duration'] + statistics['successfull_tasks_duration'] + statistics['successfull_bet_duration'] + statistics['stopper_time'];
    if(check > 0){
      print("duration\n");
      tasks_duraion = <CircularStackEntry>[
        CircularStackEntry(
          <CircularSegmentEntry>[
            CircularSegmentEntry(statistics['failed_tasks_duration'].toDouble(), Colors.redAccent[100]),
            CircularSegmentEntry(statistics['failed_bet_duration'].toDouble(), Colors.red[100]),
            CircularSegmentEntry(statistics['successfull_tasks_duration'].toDouble(), primary[200]),
            CircularSegmentEntry(statistics['successfull_bet_duration'].toDouble(), primary[500]),
            CircularSegmentEntry(statistics['stopper_time'].toDouble(), primary[900]),
          ],
        ),
      ];
      widget._timeKey.currentState?.updateData(tasks_duraion);
    }

    check = statistics['successfull_tasks'] + statistics['failed_tasks'] + statistics['successfull_bet'] + statistics['failed_bet'];
    if(check > 0){
      print("tasks\n");
      var check1 =  statistics['successfull_tasks'] + statistics['failed_tasks'];
      var check2 = statistics['successfull_bet'] + statistics['failed_bet'];
      var ring1 = CircularStackEntry(<CircularSegmentEntry>[CircularSegmentEntry(1, Colors.grey),],);
      var ring2 = CircularStackEntry(<CircularSegmentEntry>[CircularSegmentEntry(1, Colors.grey),],);
      if(check1 > 0){
        ring1 = CircularStackEntry(
          <CircularSegmentEntry>[
            CircularSegmentEntry(statistics['successfull_tasks'].toDouble(), primary[500]),
            CircularSegmentEntry(statistics['failed_tasks'].toDouble(), primary[100]),
          ],
        );
      }
      if(check2 > 0){
        ring2 = CircularStackEntry(
          <CircularSegmentEntry>[
            CircularSegmentEntry(statistics['successfull_bet'].toDouble(), Colors.amber[600]),
            CircularSegmentEntry(statistics['failed_bet'].toDouble(), Colors.grey[300]),
          ],
        );
      }
      tasks = <CircularStackEntry>[ring1, ring2];
      widget._tasksKey.currentState?.updateData(tasks);
    }

    check = statistics['failed_bet_coins'] + statistics['successfull_bet_coins'] + statistics['tasks_coins'] + statistics['stopper_coins'];
    if(check > 0){
      print("coins\n");
      coins = <CircularStackEntry>[
        CircularStackEntry(
          <CircularSegmentEntry>[
            CircularSegmentEntry(statistics['failed_bet_coins'].toDouble(), Colors.redAccent[100]),
            CircularSegmentEntry(statistics['successfull_bet_coins'].toDouble(), primary[200]),
            CircularSegmentEntry(statistics['tasks_coins'].toDouble(), primary[500]),
            CircularSegmentEntry(statistics['stopper_coins'].toDouble(), primary[900]),
          ],
        ),
      ];
      widget._coinstKey.currentState?.updateData(coins);
    }
  }

}