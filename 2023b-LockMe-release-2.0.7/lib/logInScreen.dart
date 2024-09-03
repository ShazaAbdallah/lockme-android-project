import 'package:flutter/material.dart';
import 'colors.dart';
import 'package:lock_me/userInfo.dart';
import 'package:provider/provider.dart';

class LogInScreen extends StatefulWidget  {
  const LogInScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LogInScreen> with SingleTickerProviderStateMixin{

  GlobalKey textFieldKey = GlobalKey();
  FocusNode emailFocusNode = FocusNode();
  final ScrollController scrollController = ScrollController();
  late AnimationController animationController;
  late Animation<double> _animation;
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();
  bool validate = true;
  final snackBarDiffPass = const SnackBar(
    content: Text( 'Error signing up: passwords do not match'),
  );
  final snackBarSignUpSuccess = const SnackBar(
    content: Text( 'You\'ve singed up successfully'),
  );
  bool _isLogin = true;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primary[300],
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: primary[100],),
        title:  Text('Login',
            style: TextStyle(
              color: primary[100],)),
      ),

      body:SingleChildScrollView(
        controller: scrollController,
        child: Center(
            child: Stack(
                children: <Widget>[
                  Column(
                      children: <Widget>[

                        Container(
                          height: MediaQuery.of(context).size.height * 0.05,
                        ),

                        Container(
                          width: 150.0,
                          height: 150.0,
                          decoration: const BoxDecoration(
                            image:  DecorationImage(
                              image:  AssetImage('assets/images/defult_profilePic.png'),
                              fit: BoxFit.fill,
                            ),
                          ),
                        ),

                        Container(
                          width: 300.0,
                          padding: const EdgeInsets.only(top: 50.0),
                          child: TextFormField(
                            key: textFieldKey,
                            focusNode: emailFocusNode,
                            controller: userNameController,
                            decoration:   InputDecoration(
                              filled: true,
                              fillColor: primary[100],
                              labelText: 'Username',
                              labelStyle:  TextStyle(color: primary[500], fontSize: 24),
                              prefixIcon:  Icon(Icons.person, color: primary[500],  size: 30),
                              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                              enabledBorder:  UnderlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide(color: primary[500]!),
                              ),
                            ),
                            onEditingComplete: () {
                              FocusScope.of(context).nextFocus(); // Move focus to the next field
                            },
                          ),
                        ),

                        Container(
                          width: 300.0,
                          padding: const EdgeInsets.only(top: 10.0),
                          child: TextFormField(
                              keyboardType: TextInputType.visiblePassword,
                              controller: passwordController,
                              obscureText: true,
                              decoration:   InputDecoration(
                                filled: true,
                                fillColor: primary[100],
                                labelText: 'Password',
                                labelStyle:  TextStyle(color: primary[500], fontSize: 24),
                                prefixIcon:  Icon(Icons.password, color: primary[500], size: 30),
                                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                enabledBorder:  UnderlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                  borderSide: BorderSide(color: primary[500]!),
                                ),
                              ),
                              onEditingComplete: () async {
                                _isLogin? await _perform_Repository() : FocusScope.of(context).nextFocus();
                              }
                          ),
                        ),

                        Visibility(
                          visible: !_isLogin,
                          child:FadeTransition(
                            opacity: _animation,
                            child: Container(
                              width: 300.0,
                              padding: const EdgeInsets.only(top: 10.0),
                              child: TextFormField(
                                  keyboardType: TextInputType.visiblePassword,
                                  controller: confirmController,
                                  obscureText: true,
                                  decoration:   InputDecoration(
                                    filled: true,
                                    fillColor: primary[100],
                                    labelText: 'Verify Password',
                                    labelStyle:  TextStyle(color: primary[500], fontSize: 24),
                                    prefixIcon:  Icon(Icons.password, color: primary[500], size: 30),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                                    enabledBorder:  UnderlineInputBorder(
                                      borderRadius: BorderRadius.circular(10.0),
                                      borderSide: BorderSide(color: primary[500]!),
                                    ),
                                  ),
                                  onEditingComplete: () async {
                                    await _perform_Repository();
                                  }
                              ),
                            ),
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.only(top: 50.0),
                          child: SizedBox(
                            width: 300.0,
                            height: 55.0,
                            child: ElevatedButton(
                              onPressed: () async {
                                _scrollToTextField();
                                await _perform_Repository();
                              },
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all<Color?>(primary[500]),
                                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18.0),
                                  ),
                                ),
                              ),
                              child:  Text(_isLogin ? 'Log In' : 'Sign Up',
                                style: TextStyle(
                                  color: primary[100],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22.0,
                                ),
                              ),
                            ),
                          ),
                        ),

                        Container(
                          padding: const EdgeInsets.only(top: 15.0),
                          child: SizedBox(
                            width: 300.0,
                            height: 55.0,
                            child: ElevatedButton(
                              onPressed: () {
                                _scrollToTextField();
                                setState(() {
                                  _isLogin = !_isLogin;
                                  if (_isLogin) {
                                    animationController.reverse();
                                  } else {
                                    animationController.forward();
                                  }
                                });
                              },
                              style: ButtonStyle(
                                backgroundColor: MaterialStateProperty.all<Color?>(primary[100]),
                                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18.0),
                                  ),
                                ),
                              ),
                              child: Text(_isLogin
                                  ? 'Don\'t have an account? Sign up'
                                  : 'Already have an account? Login',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: primary[500],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 22.0,
                                ),
                              ),

                            ),
                          ),
                        ),

                        Container(
                          height: MediaQuery.of(context).size.height * 0.05,
                        ),
                      ]
                  ),

                  if (_isLoading)
                    SizedBox(
                      height: MediaQuery.of(context).size.height / 1.3,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                ]
            )
        ),
      ),
    );
  }

  String removeSquareBracketSections(String input) {
    RegExp regex = RegExp(r'\[.*?\]');
    return input.replaceAll(regex, '');
  }


  Future<void> _perform_Repository() async {
    final authRepository = Provider.of<AuthRepository>(context,  listen : false);

    if (!_isLogin) {
      /// sign up
      if (confirmController.text == passwordController.text) {
        setState(() {
          _isLoading = true;
        });
        try {
          var isSuccess = await authRepository.signUp(
            userNameController.text.trim(),
            passwordController.text,
          );
          if (!mounted) return;
          if (isSuccess != null) {
            ScaffoldMessenger.of(context).showSnackBar(snackBarSignUpSuccess);
            // After successful sign up, directly log in the user.
            await authRepository.signIn(
              userNameController.text.trim(),
              passwordController.text,
            );
            setState(() {
              _isLoading = false;
            });
            _pushTaskPage();
            return;
          }
        }
        catch (e) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(removeSquareBracketSections(e.toString())),
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(snackBarDiffPass);
        setState(() {
          validate = false;
          FocusScope.of(context).unfocus();
          return;
        });
      }
    }else{
      setState(() {
        _isLoading = true;
      });
      try {
        await authRepository.signIn(
          userNameController.text.trim(),
          passwordController.text,
        );
        setState(() {
          _isLoading = false;
        });
        _pushTaskPage();
        return;
      }
      catch (e) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(removeSquareBracketSections(e.toString())),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }

  }

  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Duration of the animation
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(animationController);
    emailFocusNode.addListener(_scrollToTextField);
  }

  @override
  void dispose() {
    emailFocusNode.removeListener(_scrollToTextField);
    emailFocusNode.dispose();
    animationController.dispose();
    super.dispose();
  }

  void _scrollToTextField() {
    if (textFieldKey.currentContext != null || emailFocusNode.hasFocus) {
      final RenderBox textFieldRenderBox = textFieldKey.currentContext!.findRenderObject() as RenderBox;
      final textFieldPosition = textFieldRenderBox.localToGlobal(Offset.zero);
      scrollController.animateTo(
        textFieldPosition.dy,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _pushTaskPage() {
    //Todo:
    Navigator.of(context).pushNamed('/task');
  }


}
