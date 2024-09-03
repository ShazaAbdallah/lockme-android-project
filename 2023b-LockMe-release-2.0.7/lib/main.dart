import 'package:flutter/material.dart';
import 'package:lock_me/searchFriend.dart';
import 'colors.dart';
import 'logInScreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:lock_me/userInfo.dart';
import 'task.dart';
import 'friendsScreen.dart';
import 'changePasswordScreen.dart';
import 'profileScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'store.dart';
import 'package:showcaseview/showcaseview.dart';
import 'achievements.dart';
import 'myCollectionScreen.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class App extends StatelessWidget {

  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(
                  child: Text(snapshot.error.toString(),
                      textDirection: TextDirection.ltr)));
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return const MyApp();
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (_) => AuthRepository.instance(),
        child: MaterialApp(
            theme: ThemeData(
              primarySwatch: primary,
            ),
            routes: {
              //'/': (context) => const store(),
              '/': (context) =>  const MyHomePage(title: 'Lock Me Home Page'),
              '/login' : (context) => const LogInScreen(),
              '/task' : (context) => ShowCaseWidget(
                                      builder: Builder(
                                        builder: (context) => task(),
                                        ),
                                      ),
              '/friends' : (context) => const FriendsScreen(),
              '/change_password' : (context) => ChangePasswordScreen(),
              '/profile' : (context) => const ProfilePage(),
              '/search_friend': (context) => const SearchFriend(),
              '/store': (context) => const store(),
              '/achievements': (context) => Achievements(),
              '/collection': (context) => const collection(),
            }
        )
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  User? user;
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    //Listen to Auth State changes

    FirebaseAuth.instance
        .authStateChanges()
        .listen((event) => updateUserState(event));
  }
  //Updates state when user state changes in the app
  updateUserState(event) {
    setState(() {
      user = event;
      if (user != null) {
        autoSignIn();
      }
    });
  }

  Future<void> autoSignIn() async {
    final authRepository = Provider.of<AuthRepository>(context, listen: false);
    await authRepository.autoSignIn();
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double unitHeightValue = MediaQuery
        .of(context)
        .size
        .height;

    if (user == null) {
      return Scaffold(
        backgroundColor: primary[300],

        body: Center(
          child: Column(

            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[

              Stack(
                children: [

                  Container(
                    height: unitHeightValue,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/homePage.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  Column(
                      children: <Widget>[
                        Container(
                          height: unitHeightValue * 0.75,
                        ),
                        Container(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Text('WELCOME',
                            style: TextStyle(fontSize: unitHeightValue * 0.05,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: const [
                                Shadow(
                                  color: Colors.black,
                                  offset: Offset(0, 0),
                                  blurRadius: 30.0,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,

                          ),
                        ),

                        Container(
                          child: Text(
                              'Embrace a world free of distractions\nWhere productivity and motivation thrive.',
                              style: TextStyle(
                                fontSize: unitHeightValue * 0.023,
                                color: Colors.white,
                                shadows: const[
                                  Shadow(
                                    color: Colors.black,
                                    offset: Offset(0, 0),
                                    blurRadius: 20.0,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center),
                        ),
                        Container(
                          height: unitHeightValue * 0.015,
                        ),
                        SizedBox(
                          width: 300.0,
                          height: unitHeightValue * 0.06,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/login');
                            },
                            style: ButtonStyle(
                              backgroundColor: MaterialStateProperty.all<
                                  Color?>(primary[500]),
                              shape: MaterialStateProperty.all<
                                  RoundedRectangleBorder>(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18.0),
                                ),
                              ),
                            ),
                            child: Text('SIGN IN',
                              style: TextStyle(
                                color: primary[100],
                                fontWeight: FontWeight.bold,
                                fontSize: 20.0,
                              ),
                            ),
                          ),
                        ),
                      ]
                  ),
                ],
              ),
              //),
            ],
          ),
        ),
      );
    }
    // else{
    //   final authRepository = Provider.of<AuthRepository>(context,  listen : false);
    //   print("in main ----------------------------------------------------");
    //   await authRepository.autoSignIn();
    //   return ShowCaseWidget(
    //     builder: Builder(
    //       builder: (context) => task(),
    //     ),
    //   );
    // }

    else {
      if (isLoading) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Container(
            width: double.infinity, // Set width to fill the entire screen
            height: double.infinity, // Set height to fill the entire screen
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/homePage.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        );
      } else {
        return ShowCaseWidget(
          builder: Builder(
            builder: (context) => task(),
          ),
        );
      }
    }
  }
}