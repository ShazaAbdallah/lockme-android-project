import 'dart:ffi';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'dart:async';
import 'package:http/http.dart' as http;

//todo: if we want to use _friends we need to notifyListener();

enum Status { Uninitialized, Authenticated, Authenticating, Unauthenticated }

class AuthRepository with ChangeNotifier {
  final FirebaseAuth _auth;
  User? _user;
  Status _status = Status.Uninitialized;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  int _userCoins = 0;
  String _userImage = '';
  String _userName ='';
  List<Friend> _friends = [];
  List<Friend> _friendRequests = [];
  List<String> _myAvatars =[];
  List<String>_myAvatarsLocalPath = [];
  List<String> _myStaticAvatars=[];
  List<String>_myStaticAvatarsLocalPath = [];
  List<String> _myMusic =[];
  List<String>_myMusicLocalPath = [];
  Map _statistics = {};
  String? _selectedAvatar = "";
  String? _selectedMusic = "";

  AuthRepository.instance() : _auth = FirebaseAuth.instance {
    _auth.authStateChanges().listen(_onAuthStateChanged);
    _user = _auth.currentUser;
    _onAuthStateChanged(_user);
  }

  Map get statistics => _statistics;
  Status get status => _status;
  User? get user => _user;
  String get userImage => _userImage;
  int get userCoins => _userCoins;
  bool get isAuthenticated => status == Status.Authenticated;
  String get userName => _userName;
  String? get selectedAvatar => _selectedAvatar;
  String? get selectedMusic => _selectedMusic;
  List<Friend> get friends => _friends;
  List<Friend> get friendRequests => _friendRequests;
  List<String> get myAvatars => _myAvatars;
  List<String> get myMusic => _myMusic;
  List<String> get myAvatarsLocalPath => _myAvatarsLocalPath;
  List<String> get myStaticAvatars => _myStaticAvatars;
  List<String> get myStaticAvatarsLocalPath => _myStaticAvatarsLocalPath;
  List<String> get myMusicLocalPath => _myMusicLocalPath;



  Future<UserCredential?> signUp(String username, String password) async {
    try {
      _status = Status.Authenticating;
      final email ='$username@example.com';
      notifyListeners();
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password);

      final defaultImageFile = await convert_into_file();
      _userName = username;
      // final appDirectory = await getApplicationDocumentsDirectory();
      // final avatarsDirectory = Directory('${appDirectory.path}/avatars');
      // await avatarsDirectory.create(recursive: true);
      await _db.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'coins' : 20,
        'imageURL' : defaultImageFile.toString(),
        'friends': [],
        'friendRequests': [],
        'bettingInvitations': {},
        'myAvatars': ["https://firebasestorage.googleapis.com/v0/b/lockme-92bf1.appspot.com/o/avatars%2Favatar4.gif?alt=media&token=122f0b74-1deb-4663-893d-a9afe44a3acd"],
        'myStaticAvatars': ["https://firebasestorage.googleapis.com/v0/b/lockme-92bf1.appspot.com/o/staticAvatars%2Favatar4.png?alt=media&token=09b3bccb-37b7-49f0-932a-65c113147437"],
        'myMusic': ["https://firebasestorage.googleapis.com/v0/b/lockme-92bf1.appspot.com/o/audio%2Faudio1.mp3?alt=media&token=023f10be-c880-4bce-a6a0-849625336972"],
        'selectedAvatar':'',
        'selectedMusic':'',
      });
      await uploadNewImage(defaultImageFile);
      _myAvatarsLocalPath = await getMyAvatars();
      _myMusicLocalPath = await getMyMusic();
      await updateSelectedAvatar(_myAvatarsLocalPath[0]);
       await updateSelectedMusic(_myMusicLocalPath[0]);
      // print("in sign up -----------------------------");
      // print("avatars -----------------------------");
      // print(_myAvatars);
      // print(_myAvatarsLocalPath);
      // print("music -----------------------------");
      // print(_myMusic);
      // print(_myMusicLocalPath);
      notifyListeners();
      return userCredential;
    } catch (e) {
      print(e);
      _status = Status.Unauthenticated;
      notifyListeners();
      throw 'Error signing up: $e'; // Throw the error message
    }
  }

  Future<File> convert_into_file() async{
    var bytes = await rootBundle.load('assets/images/defult_profilePic.png');
    String tempPath = (await getTemporaryDirectory()).path;
    File file = File('$tempPath/profile.png');
    await file.writeAsBytes(bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
    return file;
  }

  Future<bool> signIn(String username, String password) async {
    try {
      _status = Status.Authenticating;
      notifyListeners();
      String email = '$username@example.com';
      await _auth.signInWithEmailAndPassword(
          email: email,
          password: password);
      _userCoins = await getUserCoins();
      _userImage = await getImageUrl();
      _userName = await getUsernameAsDatabase();
      //print("pleassseeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee");
      _myAvatarsLocalPath = await getMyAvatars();
      _myMusicLocalPath = await getMyMusic();
      _statistics = await get_Statistics();
      _selectedAvatar = await getSelectedAvatar();
      _selectedMusic = await getSelectedMusic();
      //print("in sign inp -----------------------------");
      //print("avatars -----------------------------");
      // print(_myAvatars);
      // print(_myAvatarsLocalPath);
      // print("music -----------------------------");
      // print(_myMusic);
      // print(_myMusicLocalPath);
      notifyListeners();
      return true;
    } catch (e) {
      print(e);
      _status = Status.Unauthenticated;
      notifyListeners();
      throw 'Error signing in: $e'; // Throw the error message
    }
  }

  Future<void> autoSignIn( ) async {
    _userCoins = await getUserCoins();
    _userImage = await getImageUrl();
    _userName = getUsername();
    _myAvatarsLocalPath = await getMyAvatars();
    _myMusicLocalPath = await getMyMusic();
    _statistics = await get_Statistics();
    _selectedAvatar = await getSelectedAvatar();
    _selectedMusic = await getSelectedMusic();
    // print("in auto sign in -----------------------------");
    // print("avatars -----------------------------");
    // print(_myAvatars);
    // print(_myAvatarsLocalPath);
    // print("music -----------------------------");
    // print(_myMusic);
    // print(_myMusicLocalPath);
    notifyListeners();
  }

  Future signOut() async {
    try {
      // Delete avatars directory
      final appDirectory = await getApplicationDocumentsDirectory();
      final avatarsDirectory = Directory('${appDirectory.path}/avatars');
      if (avatarsDirectory.existsSync()) {
        await avatarsDirectory.delete(recursive: true);
      }
      final StaticAvatarsDirectory = Directory('${appDirectory.path}/avatars');
      if (StaticAvatarsDirectory.existsSync()) {
        await StaticAvatarsDirectory.delete(recursive: true);
      }
      final musicDirectory = Directory('${appDirectory.path}/audio');
      if (musicDirectory.existsSync()) {
        await musicDirectory.delete(recursive: true);
      }
      _auth.signOut();
      _status = Status.Unauthenticated;
      notifyListeners();
      return Future.delayed(Duration.zero );

    } catch (e) {
      print(e);
      throw 'Error signing out: $e';
    }
  }

  String changeLastFolderToStaticAvatars(String path) {
    List<String> pathParts = path.split('/');

    if (pathParts.isNotEmpty) {
      pathParts[pathParts.length - 2] = 'staticAvatars';
    }

    return pathParts.join('/');
  }

  String replaceGifWithPng(String input) {
    if (input.endsWith('.gif')) {
      return input.replaceAll('.gif', '.png');
    } else {
      return input;
    }
  }

  String getStaticAvatarPath(String gifPath){
    return  replaceGifWithPng(changeLastFolderToStaticAvatars(gifPath));
  }

  Future<String?> getSelectedAvatar( ) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(_user!.uid);

    final userSnapshot = await userDoc.get();
    if (userSnapshot.exists) {
      final userData = userSnapshot.data();
      final selectedAvatar = userData?['selectedAvatar'] as String?;
      return selectedAvatar;
    }

    return null;
  }

  Future<void> updateSelectedAvatar(String selectedAvatar) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(_user!.uid);

    await userDoc.update({
      'selectedAvatar': selectedAvatar,
    });
    _selectedAvatar = selectedAvatar;
  }

  Future<String?> getSelectedMusic( ) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(_user!.uid);

    final userSnapshot = await userDoc.get();
    if (userSnapshot.exists) {
      final userData = userSnapshot.data();
      final selectedMusic = userData?['selectedMusic'] as String?;
      return selectedMusic;
    }

    return null;
  }

  Future<void> updateSelectedMusic(String selectedMusic) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(_user!.uid);

    await userDoc.update({
      'selectedMusic': selectedMusic,
    });
    _selectedMusic = selectedMusic;

  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _user = null;
      _status = Status.Unauthenticated;
    } else {
      _user = firebaseUser;
      _status = Status.Authenticated;
    }
    notifyListeners();
  }

  String? getUserEmail(){
    return _user!.email;
  }

  Future<String> getImageUrl() async {
    _userImage = await _storage.ref('images').child(_user!.uid).getDownloadURL();
    return _userImage;
  }

  Future<void> uploadNewImage(File file) async {
    if (file.existsSync()) {
      await _storage.ref('images').child(_user!.uid).putFile(file);
      final new_url = await getImageUrl();
      await _db.collection('users').doc(_user!.uid).update({
        'imageURL' : new_url.toString(),
      });
      notifyListeners();
    } else {
      print('File does not exist: ${file.path}');
    }
  }

  String extractUsername(String? email) {
    // Find the index of the '@' symbol
    final atIndex = email!.indexOf('@');
    // Extract the substring from the start of the email to the '@' symbol
    final username = email.substring(0, atIndex);
    return username;
  }

  String getUsername(){
    return extractUsername(_user!.email);
  }

  int getCoins(){
      return _userCoins;
  }

  Future<String> getUsernameAsDatabase( ) async {
    final DocumentSnapshot userSnapshot =
    await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
    if (userSnapshot.exists) {
      final username = (userSnapshot.data() as Map)['username'] as String? ?? "";
      return username;
    }
    // If the user document doesn't exist or doesn't have the 'coins' field, return a default value.
    return "";
  }

  Future<int> getUserCoins( ) async {
    final DocumentSnapshot userSnapshot =
    await FirebaseFirestore.instance.collection('users').doc(_user!.uid).get();
    if (userSnapshot.exists) {
      final coins = (userSnapshot.data() as Map)['coins'] as int? ?? 0;
      return coins;
    }
    // If the user document doesn't exist or doesn't have the 'coins' field, return a default value.
    return 0;
  }

  Future<void> updateCoins( String userId, int newCoins) async {
    try {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'coins': newCoins});
    _userCoins = await getUserCoins();
    notifyListeners();
    //print('Coins updated successfully!');
    } catch (e) {
    print('Error updating coins: $e');
    }
  }


  /// methods for statistics:
  Future<void> add_successfull_task(int time, int profit) async{

    var docRef = await _db.collection('users').doc(user!.uid).get();
    var statistics = (docRef.data() as Map)["statistics"] ?? {} as Map;

    statistics['successfull_tasks'] = (statistics['successfull_tasks'] ?? 0) + 1;
    statistics['successfull_tasks_duration'] = (statistics['successfull_tasks_duration'] ?? 0) + time;
    statistics['tasks_coins'] = (statistics['tasks_coins'] ?? 0) + profit;

    await _db.collection('users').doc(user!.uid).set({
      "statistics": statistics
    }, SetOptions(merge: true));

    _statistics = await get_Statistics();
  }

  Future<void> add_failed_task(int time) async{

    var docRef = await _db.collection('users').doc(user!.uid).get();
    var statistics = (docRef.data() as Map)["statistics"] ?? {} as Map;

    statistics['failed_tasks'] = (statistics['failed_tasks'] ?? 0) + 1;
    statistics['failed_tasks_duration'] = (statistics['failed_tasks_duration'] ?? 0) + time;

    await _db.collection('users').doc(user!.uid).set({
      "statistics": statistics
    }, SetOptions(merge: true));
    _statistics = await get_Statistics();

  }

  Future<void> add_successfull_bet(String id) async{

    var betDoc = await _db.collection('Betting_Rooms').doc(id).get();
    int bet_duration = (betDoc.data() as Map)["duration"];

    var docRef = await _db.collection('users').doc(user!.uid).get();
    var statistics = (docRef.data() as Map)["statistics"] ?? {} as Map;

    statistics['successfull_bet'] = (statistics['successfull_bet'] ?? 0) + 1;
    statistics['successfull_bet_duration'] = (statistics['successfull_bet_duration'] ?? 0) + bet_duration;

    await _db.collection('users').doc(user!.uid).set({
      "statistics": statistics
    }, SetOptions(merge: true));
    //adding coins will be in give rewards
    _statistics = await get_Statistics();

  }

  Future<void> add_failed_bet(String id) async{

    var betDoc = await _db.collection('Betting_Rooms').doc(id).get();
    int bet_coins = (betDoc.data() as Map)["coins"];
    int bet_duration = (betDoc.data() as Map)["duration"];

    var docRef = await _db.collection('users').doc(user!.uid).get();
    var statistics = (docRef.data() as Map)["statistics"] ?? {} as Map;

    statistics['failed_bet'] = (statistics['failed_bet'] ?? 0) + 1;
    statistics['failed_bet_duration'] = (statistics['failed_bet_duration'] ?? 0) + bet_duration;
    statistics['failed_bet_coins'] = (statistics['failed_bet_coins'] ?? 0) + bet_coins;

    await _db.collection('users').doc(user!.uid).set({
      "statistics": statistics
    }, SetOptions(merge: true));
    _statistics = await get_Statistics();

  }

  Future<void> add_stopper_time(int time, int profit) async{

    var docRef = await _db.collection('users').doc(user!.uid).get();
    var statistics = (docRef.data() as Map)["statistics"] ?? {} as Map;

    statistics['stopper_time'] = (statistics['stopper_time'] ?? 0) + time;
    statistics['stopper_coins'] = (statistics['stopper_coins'] ?? 0) + profit;

    await _db.collection('users').doc(user!.uid).set({
      "statistics": statistics
    }, SetOptions(merge: true));
    _statistics = await get_Statistics();

  }

  Future<Map> get_Statistics()async{

    var docRef = await _db.collection('users').doc(user!.uid).get();
    var statistics =  (docRef.data() as Map)["statistics"] ?? {};

    statistics['successfull_tasks'] = (statistics['successfull_tasks'] ?? 0.0);
    statistics['successfull_tasks_duration'] = (statistics['successfull_tasks_duration'] ?? 0.0);
    statistics['tasks_coins'] = (statistics['tasks_coins'] ?? 0.0);
    statistics['failed_tasks'] = (statistics['failed_tasks'] ?? 0.0);
    statistics['failed_tasks_duration'] = (statistics['failed_tasks_duration'] ?? 0.0);
    statistics['successfull_bet'] = (statistics['successfull_bet'] ?? 0.0);
    statistics['successfull_bet_duration'] = (statistics['successfull_bet_duration'] ?? 0.0);
    statistics["successfull_bet_coins"] = (statistics['successfull_bet_coins'] ?? 0.0);
    statistics['failed_bet'] = (statistics['failed_bet'] ?? 0.0);
    statistics['failed_bet_duration'] = (statistics['failed_bet_duration'] ?? 0.0);
    statistics['failed_bet_coins'] = (statistics['failed_bet_coins'] ?? 0.0);
    statistics['stopper_time'] = (statistics['stopper_time'] ?? 0.0);
    statistics['stopper_coins'] = (statistics['stopper_coins'] ?? 0.0);
    _statistics = statistics;
    return statistics;
  }


  /// methods for friends betting room:

  Future<void> sync_time(String id)async{
    DateTime currentTime = DateTime.now();
    await _db.collection('Ack').doc(userName).set(
        {"user_name": userName,
          "bet_room": id,
          "async":currentTime
        });
    return;
  }

  Stream<Map> getBetFriendStream(String id) {
    return _db
        .collection('Betting_Rooms')
        .doc(id)
        .snapshots()
        .asyncMap((snapshot) async {
      final betFriends = (snapshot.data()?['joined_users'] as Map);
      return betFriends;
    });
  }

  Future<String> createBettingRoom(int duration, int coins, String username, String url) async{

    //finding unique room id
    Random random = Random();
    int randomNumber = random.nextInt(1000);
    var doc = await _db.collection('Betting_Rooms').doc(randomNumber.toString()).get();
    while(doc.exists) {
      randomNumber = random.nextInt(1000);
      doc = await _db.collection('Betting_Rooms').doc(randomNumber.toString()).get();
    }
    await _db.collection('Betting_Rooms').doc(randomNumber.toString()).set({
      'duration': duration,
      'coins' : coins,
      'lost_coins' : 0,
      'pending_users': {},
      'joined_users': {username:url},
      'admin': username,
      //waiting/started/canceled/finished
      'game_status': 'waiting'
    });
    return randomNumber.toString();
  }

  Future<void> endBet(String id) async {
    //set status to finished and give rewards to all users

    //if the status is finished, other user already closed the room
    //to not give rewards multiple times
    var docRef = await _db.collection('Betting_Rooms').doc(id).get();
    if(docRef.exists) {
      if ((docRef.data() as Map)['game_status'] == 'finished') {
        return;
      }

      //else, update the status and give rewards
      _db.collection('Betting_Rooms').doc(id).update(
          {"game_status": "finished"});
      await giveRewards(id);
      await deleteBetRoom(id);
    }
  }

  Future<void> sendInvitiation(String username, String url, int time, int coins, String id) async{

    final docRef = await _db.collection('Betting_Rooms').doc(id.toString()).get();
    if(docRef.exists) {
      //adding new user to pending list in bet room
      final map = (docRef.data() as Map)['pending_users'] as Map? ?? {};
      map[username] = url;
      await _db.collection('Betting_Rooms').doc(id).update({
        'pending_users': map,
      });

      //update invitation list in user doc
      final uid = await getUserIdByUsername(username);
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        final invitations = (doc.data() as Map)['bettingInvitations'] as Map? ?? {};
        invitations[id] = {'duration':time, 'coins':coins, 'url':_userImage, 'admin': _userName};
        await _db.collection('users').doc(uid).update({
          'bettingInvitations': invitations,
        });
      }
    }
  }

  Stream<Map> getBetInvites() {
    return _db
        .collection('users')
        .doc(_user!.uid)
        .snapshots()
        .asyncMap((snapshot) async {
      final invitations = (snapshot.data())?['bettingInvitations'] as Map? ?? {};
      return invitations;
    });
  }

  Future<bool> acceptBetInvitation(String id) async {

    //updating room data
    final docRef = await _db.collection('Betting_Rooms').doc(id).get();
    if(docRef.exists) {
      if((docRef.data() as Map)['game_status'] != 'waiting') {
          return false;
        }

      //removing user from pending list
      final map = (docRef.data() as Map)['pending_users'] as Map? ?? {};
      map.remove(_userName);
      await _db.collection('Betting_Rooms').doc(id).update({
        'pending_users': map,
      });

      //adding to joined users list
      final map2 = (docRef.data() as Map)['joined_users'] as Map? ?? {};
      map2[_userName] = _userImage;
      await _db.collection('Betting_Rooms').doc(id).update({
        'joined_users': map2,
      });
    }else{
      return false;
    }

    //updating user data
    final doc = await _db.collection('users').doc(_user!.uid).get();
    if(doc.exists) {
      final map = (doc.data() as Map)['bettingInvitations'] as Map? ?? {};
      map.remove(id);
      await _db.collection('users').doc(_user!.uid).update({
        'bettingInvitations': map,
      });
    }

    return true;
  }

  Future<void> startBet(String gameId) async {
    //change game_status to started
    final collection = FirebaseFirestore.instance.collection('Betting_Rooms');
    final documentReference = collection.doc(gameId);
    await documentReference.update({'game_status': 'started'});

    //deleteAllInvitations for pending_users
    final docRef = await _db.collection('Betting_Rooms').doc(gameId).get();
    var invites =  (docRef.data() as Map)['pending_users'] as Map;
    await deleteAllInvitations(gameId,invites);
  }

  Future<void> deleteInvitation(String uId,String gameId) async {
    final doc = await _db.collection('users').doc(uId).get();
    if(doc.exists) {
      final map = (doc.data() as Map)['bettingInvitations'] as Map? ?? {};
      map.remove(gameId);
      await _db.collection('users').doc(uId).update({
        'bettingInvitations': map,
      });
    }
  }

  Future<void> deleteAllInvitations(String gameId, Map invites) async{
    try {
      for (final userName in invites.keys) {
        String? uId = await getUserIdByUsername(userName);
        if(uId!=null){
          deleteInvitation(uId,gameId);
        }
      }
      //print('All invites processed successfully.');
    } catch (e) {
      print('Error processing invites: $e');
    }
  }

  Future<void> deleteBetRoom(String documentId) async{
    try {
      await FirebaseFirestore.instance.collection('Betting_Rooms').doc(documentId).delete();
    } catch (error) {
      print('Error deleting document: $error');
      // Handle the error accordingly
    }
  }

  Future<void> giveRewards(String id) async{

    final docRef = await _db.collection('Betting_Rooms').doc(id.toString()).get();
    var joined =  (docRef.data() as Map)['joined_users'] as Map;
    int bet_coins = (docRef.data() as Map)['lost_coins'];
    int profit = (bet_coins / joined.length).ceil();

    for (final userName in joined.keys) {
      String? uId = await getUserIdByUsername(userName);
      if(uId!=null){
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(uId)
            .get();
        if (userSnapshot.exists) {
          int coins = (userSnapshot.data() as Map<String, dynamic>)['coins'] ?? 0;
          await updateCoins(uId, coins + profit);

          //for statistics
          var statistics = (docRef.data() as Map)['statistics'] ?? {};
          statistics["successfull_bet_coins"] = (statistics['successfull_bet_coins'] ?? 0) + profit;
          await _db.collection('users').doc(user!.uid).set({
            "statistics": statistics,
          }, SetOptions(merge: true));

        }
      }
    }
  }

  Future<void> leaveBet(String id) async{

    final docRef = await _db.collection('Betting_Rooms').doc(id.toString()).get();
    if(docRef.exists) {

      //remove user from bet room
      final map = (docRef.data() as Map)['joined_users'] as Map? ?? {};
      map.remove(_userName);
      await _db.collection('Betting_Rooms').doc(id).update({
        'joined_users': map,
      });
      //update the coins based in bet state (started or not)
      if((docRef.data() as Map)['game_status'] != 'started') {

        var invites =  (docRef.data() as Map)['pending_users'] as Map;
        if((docRef.data() as Map)['admin'] == _userName){
          //update game_status
          final documentReference = FirebaseFirestore.instance
              .collection('Betting_Rooms')
              .doc(id);
          await documentReference.update({'game_status': 'canceled'});
          await deleteBetRoom(id);
          await deleteAllInvitations(id,invites);
          //await kickEveryBodyOut(id,joined);
        }
      }else{
        //user should loos coins
        int bet_coins = (docRef.data() as Map)['coins'];
        await updateCoins(_user!.uid,userCoins - bet_coins);

        if(map.isEmpty){
          await deleteBetRoom(id);
        }else{
          //add lost_coins to bet, for winners reward
          int new_coins = (docRef.data() as Map)['lost_coins'] + bet_coins;
          await _db.collection('Betting_Rooms').doc(id).update({
            'lost_coins': new_coins,
          });
        }
      }

    }
  }

  Future<void> leaveBet2(String id, String name) async{

    final FirebaseFirestore db = FirebaseFirestore.instance;
    final docRef = await db.collection('Betting_Rooms').doc(id.toString()).get();
    if(docRef.exists) {

      //remove user from bet room
      final map = (docRef.data() as Map)['joined_users'] as Map? ?? {};
      map.remove(name);
      await db.collection('Betting_Rooms').doc(id).update({
        'joined_users': map,
      });
      //update the coins based in bet state (started or not)
      if((docRef.data() as Map)['game_status'] != 'started') {

        var invites =  (docRef.data() as Map)['pending_users'] as Map;
        if((docRef.data() as Map)['admin'] == name){
          //update game_status
          final documentReference = FirebaseFirestore.instance
              .collection('Betting_Rooms')
              .doc(id);
          await documentReference.update({'game_status': 'canceled'});
          await deleteBetRoom(id);
          await deleteAllInvitations(id,invites);
          //await kickEveryBodyOut(id,joined);
        }
      }else{
        //user should loos coins
        var uId = await getUserIdByUsername(name);
        final doc = await db.collection('users').doc(uId).get();
        int usr_coins = doc.get('coins');
        int bet_coins = (docRef.data() as Map)['coins'];
        await updateCoins(uId!,usr_coins - bet_coins);
        if(map.isEmpty){
          await deleteBetRoom(id);
        }else{
          //add lost_coins to bet, for winners reward
          int new_coins = (docRef.data() as Map)['lost_coins'] + bet_coins;
          await db.collection('Betting_Rooms').doc(id).update({
            'lost_coins': new_coins,
          });
        }
      }

    }
  }


  ///methods for friends adding feature:
  Future<void> sendFriendRequest(String friendUsername) async {
    try {
      final friendId = await getUserIdByUsername(friendUsername);
      if (friendId != null) {
        final friendDoc = _db.collection('users').doc(friendId);
        final friendSnapshot = await friendDoc.get();
        final friendData = friendSnapshot.data() as Map<String, dynamic>;

        final friendRequests = friendData['friendRequests'] as List<dynamic>;
        final friendRequestsSet = Set<String>.from(friendRequests.cast<String>());

        final friends = friendData['friends'] as List<dynamic>;
        final friendsSet = Set<String>.from(friends.cast<String>());


        if (!friendsSet.contains(userName) && !friendRequestsSet.contains(userName)) {
          await friendDoc.update({
            'friendRequests': FieldValue.arrayUnion([userName]),
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<String?> getUserIdByUsername(String username) async {
    try {
      final querySnapshot = await _db.collection('users').where('username', isEqualTo: username).get();
      final docs = querySnapshot.docs;
      if (docs.isNotEmpty) {
        return docs.first.id;
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<void> acceptFriendRequest(String friendUsername) async {
    try {
      final friendId = await getUserIdByUsername(friendUsername);
      if (friendId != null) {
        await _db.collection('users').doc(_user!.uid).update({
          'friends': FieldValue.arrayUnion([friendUsername]),
          'friendRequests': FieldValue.arrayRemove([friendUsername]),
        });

        await _db.collection('users').doc(friendId).update({
          'friends': FieldValue.arrayUnion([_userName]),
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> rejectFriendRequest(String friendUsername) async {
    try {
      final friendId = await getUserIdByUsername(friendUsername);
      if (friendId != null) {
        await _db.collection('users').doc(_user!.uid).update({
          'friendRequests': FieldValue.arrayRemove([friendUsername]),
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Stream<List<Friend>> getFriendRequestsStream() {
    return _db
        .collection('users')
        .doc(_user!.uid)
        .snapshots()
        .asyncMap((snapshot) async {
      final friendRequests = (snapshot.data()?['friendRequests'] as List<dynamic>).cast<String>();

      final requestList = <Friend>[];

      for (final friendId in friendRequests) {
        final friendQuerySnapshot = await _db
            .collection('users')
            .where('username', isEqualTo: friendId)
            .limit(1)
            .get();

        if (friendQuerySnapshot.docs.isNotEmpty) {
          final friendDoc = friendQuerySnapshot.docs.first;
          final name = friendDoc.data()['username'] as String? ?? '';
          final coins = friendDoc.data()['coins'] as int? ?? 0;
          final url = friendDoc.data()['imageURL'] as String? ?? '';

          final friend = Friend(name: name, coins: coins, imageURl: url);
          requestList.add(friend);
        }
      }


      return requestList;
    });
  }

  Stream<List<Friend>> getFriendsStream(bool includeCurrentUser) {
    final currentUserDocRef = _db.collection('users').doc(_user!.uid);

    Stream<List<Friend>> friendsStream = _db
        .collection('users')
        .doc(_user!.uid)
        .snapshots()
        .asyncMap((snapshot) async {
      final friends = (snapshot.data()?['friends'] as List<dynamic>).cast<String>();

      final friendList = <Friend>[];

      for (final friendId in friends) {
        final friendQuerySnapshot = await _db
            .collection('users')
            .where('username', isEqualTo: friendId)
            .limit(1)
            .get();

        if (friendQuerySnapshot.docs.isNotEmpty) {
          final friendDoc = friendQuerySnapshot.docs.first;
          final name = friendDoc.data()['username'] as String? ?? '';
          final coins = friendDoc.data()['coins'] as int? ?? 0;
          final url = friendDoc.data()['imageURL'] as String? ?? '';

          final friend = Friend(name: name, coins: coins, imageURl: url);
          friendList.add(friend);
        }
      }

      if (includeCurrentUser) {
        final currentUserDoc = await currentUserDocRef.get();

        if (currentUserDoc.exists) {
          final name = currentUserDoc.data()?['username'] as String? ?? '';
          final coins = currentUserDoc.data()?['coins'] as int? ?? 0;
          final url = currentUserDoc.data()?['imageURL'] as String? ?? '';

          final currentUser = Friend(name: name, coins: coins, imageURl: url);

          if (!friendList.contains(currentUser)) {
            friendList.add(currentUser);
          }
        }
      }

      friendList.sort((a, b) {
        if (b.coins != a.coins) {
          return b.coins.compareTo(a.coins); // Sort by coins in descending order
        } else {
          return a.name.compareTo(b.name); // Sort by names in ascending order
        }
      });

      return friendList;
    });

    if (includeCurrentUser) {
      // Listen to changes in the current user's document
      final currentUserListener = currentUserDocRef.snapshots().listen((snapshot) {
        final name = snapshot.data()?['username'] as String? ?? '';
        final coins = snapshot.data()?['coins'] as int? ?? 0;
        final url = snapshot.data()?['imageURL'] as String? ?? '';

        final currentUser = Friend(name: name, coins: coins, imageURl: url);

        friendsStream = friendsStream.map((friendList) {
          final updatedFriendList = List<Friend>.from(friendList);
          final currentUserIndex = updatedFriendList.indexOf(currentUser);

          if (currentUserIndex != -1) {
            // Update the current user's data in the friend list
            updatedFriendList[currentUserIndex] = currentUser;
          }

          // Sort the updated friend list
          updatedFriendList.sort((a, b) {
            if (b.coins != a.coins) {
              return b.coins.compareTo(a.coins); // Sort by coins in descending order
            } else {
              return a.name.compareTo(b.name); // Sort by names in ascending order
            }
          });

          return updatedFriendList;
        });
      });

      // Cancel the listener when the friendsStream subscription is canceled
      friendsStream = friendsStream.transform(StreamTransformer<List<Friend>, List<Friend>>.fromHandlers(
        handleDone: (sink) {
          currentUserListener.cancel();
          sink.close();
        },
      ));
    }

    return friendsStream;
  }
  ///****************************************************///
  ///helper functions to implement the store

  Future<List<String>> getMyAvatars() async {

    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

      final avatarUrls = (userSnapshot.data()?['myAvatars']  as List<dynamic>)
          .map((imageUrl) => imageUrl as String)
          .toList();

      final staticAvatarUrls = (userSnapshot.data()?['myStaticAvatars'] as List<dynamic>)
          .map((staticImageUrl) => staticImageUrl as String)
          .toList();

      final appDirectory = await getApplicationDocumentsDirectory();
      final avatarsDirectory = Directory('${appDirectory.path}/avatars');
      if (!await avatarsDirectory.exists()) {
        await avatarsDirectory.create(recursive: true);
      }

      final staticAvatarsDirectory = Directory('${appDirectory.path}/staticAvatars');
      if (!await staticAvatarsDirectory.exists()) {
        await staticAvatarsDirectory.create(recursive: true);
      }

      final savedImagePaths = <String>[];
      final staticSavedImagePaths = <String>[];

      for (final url in avatarUrls) {
        final imagePath = '${appDirectory.path}/${Uri.parse(url).pathSegments.last}';
        final imageFile = File(imagePath);
        if (!await imageFile.exists()) {
          final response = await http.get(Uri.parse(url));
          await imageFile.writeAsBytes(response.bodyBytes);
        }
        savedImagePaths.add(imagePath);
      }

      for (final url in staticAvatarUrls) {
        final imagePath = '${appDirectory.path}/${Uri.parse(url).pathSegments.last}';
        final imageFile = File(imagePath);
        if (!await imageFile.exists()) {
          final response = await http.get(Uri.parse(url));
          await imageFile.writeAsBytes(response.bodyBytes);
        }
        staticSavedImagePaths.add(imagePath);
      }

      _myAvatars = avatarUrls;
      _myStaticAvatars = staticAvatarUrls;
      // print("shazaaaaaaaaaa");
      // print(_myAvatars);
      // print(savedImagePaths);
      _myStaticAvatarsLocalPath = staticSavedImagePaths;
      return savedImagePaths;
    } catch (e) {
      print(e);
      throw 'Error retrieving avatars: $e';
    }
  }

  Future<void> addToMyAvatars(String imageUrl, String staticUrl) async {
    // Update _myAvatars list and save the image
    if (!_myAvatars.contains(imageUrl)) {
      // print("before on add avatars________________________");
      // print(_myAvatars);
      _myAvatars.add(imageUrl);
      _myStaticAvatars.add(staticUrl);
      notifyListeners();
      // print("after on add avatars________________________");
      // print(_myAvatars);
      await saveImageToDirectory(imageUrl, staticUrl);

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({'myAvatars': _myAvatars});
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({'myStaticAvatars': _myStaticAvatars});
      } catch (e) {
        print(e);
        throw 'Error updating myAvatars: $e';
      }
    }
  }

  Future<void> saveImageToDirectory(String imageUrl, String staticUrl) async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final avatarsDirectory = Directory(appDirectory.path);
    await avatarsDirectory.create(recursive: true);

    final response = await http.get(Uri.parse(imageUrl));
    final imageName = Uri.parse(imageUrl).pathSegments.last;
    final imagePath = '${avatarsDirectory.path}/$imageName';
    final file = File(imagePath);

    final staticResponse = await http.get(Uri.parse(staticUrl));
    final staticName = Uri.parse(staticUrl).pathSegments.last;
    final staticPath = '${avatarsDirectory.path}/$staticName';
    final staticFile = File(staticPath);
    // print("before saved image ___________________________");
    // print(_myAvatarsLocalPath);
    _myAvatarsLocalPath.add(imagePath);
    _myStaticAvatarsLocalPath.add(staticPath);
    // print("after saved image ______________________________");
    // print(_myStaticAvatarsLocalPath);
    // print(_myAvatarsLocalPath);
    await file.writeAsBytes(response.bodyBytes);
    await staticFile.writeAsBytes(staticResponse.bodyBytes);
  }

  Future<List<String>> getMyMusic() async {

    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.uid)
          .get();

      final musicUrls = (userSnapshot.data()?['myMusic'] as List<dynamic>)
          .map((musicUrl) => musicUrl as String)
          .toList();

      final appDirectory = await getApplicationDocumentsDirectory();
      final musicDirectory = Directory('${appDirectory.path}/audio');
      await musicDirectory.create(recursive: true);

      final savedMusicPaths = <String>[];

      for (final url in musicUrls) {
        final response = await http.get(Uri.parse(url));
        final musicPath = '${appDirectory.path}/${Uri.parse(url).pathSegments.last}';

        final file = File(musicPath);
        await file.writeAsBytes(response.bodyBytes);
        savedMusicPaths.add(musicPath);
      }
      _myMusic = musicUrls;
      // print("music_________________________");
      // print(musicUrls);
      notifyListeners();
      // print("music_________________________");
      // print(savedMusicPaths);
      return savedMusicPaths;
    } catch (e) {
      print(e);
      throw 'Error retrieving audio: $e';
    }
  }

  Future<void> addToMyMusic(String musicUrl) async {
    // Update _myMusic list and save the image
    if (!_myMusic.contains(musicUrl)) {
      _myMusic.add(musicUrl);
      await saveMusicToDirectory(musicUrl);

      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_user!.uid)
            .update({'myMusic': _myMusic});
      } catch (e) {
        print(e);
        throw 'Error updating myMusic: $e';
      }
    }
  }

  Future<void> saveMusicToDirectory(String musicUrl) async {
    final appDirectory = await getApplicationDocumentsDirectory();
    final musicDirectory = Directory(appDirectory.path);
    await musicDirectory.create(recursive: true);

    final response = await http.get(Uri.parse(musicUrl));
    final musicName = Uri.parse(musicUrl).pathSegments.last;
    final musicPath = '${musicDirectory.path}/$musicName';
    final file = File(musicPath);
    _myMusicLocalPath.add(musicPath);
    await file.writeAsBytes(response.bodyBytes);
  }

}


class Friend {
  final String name;
  final int coins;
  final String imageURl;

  Friend({required this.name, required this.coins, required this.imageURl});
}



