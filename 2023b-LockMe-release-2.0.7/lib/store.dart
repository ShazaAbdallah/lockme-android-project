import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'colors.dart';
import 'appDrawer.dart';
import 'userInfo.dart';
import 'package:audioplayers/audioplayers.dart' as audio;

class store extends StatefulWidget {
  const store({super.key});

  @override
  _StoreHomePageState createState() => _StoreHomePageState();
}

class _StoreHomePageState extends State<store> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Avatar & Music Store', style: TextStyle(color: Colors.white,)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white, // Set the desired color for the selected tab text
          unselectedLabelColor: Colors.white, // Set the color for the unselected tab text
          tabs: const [
            Tab(text: 'Avatars'),
            Tab(text: 'Music'),
          ],
        ),
      ),
      backgroundColor: primary[100],
      body: TabBarView(
        controller: _tabController,
        children: const [
          AvatarList(),
          MusicList(),
        ],
      ),
    );
  }
}


class AvatarList extends StatefulWidget {
  const AvatarList({Key? key}) : super(key: key);

  @override
  _AvatarListState createState() => _AvatarListState();
}

class _AvatarListState extends State<AvatarList> {

  @override
  Widget build(BuildContext context) {
    var authUser = Provider.of<AuthRepository>(context, listen: false);
    var ownedAvatars = Provider.of<AuthRepository>(context, listen: false).myAvatars;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('avatars').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final avatars = snapshot.data!.docs;

        return SingleChildScrollView(
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // Disable GridView scrolling
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Display two cards per row
              childAspectRatio: 0.75, // Adjust the aspect ratio to your liking
            ),
            itemCount: avatars.length,
            itemBuilder: (context, index) {
              final avatar = avatars[index];
              final avatarData = avatar.data() as Map<String, dynamic>;

              final imageUrl = avatarData['imageUrl'] as String;
              final staticUrl = avatarData['staticUrl'] as String;
              final isOwned = context.watch<AuthRepository>().myAvatars.contains(imageUrl);

              return Card(
                child: Column(
                  children: [
                    Expanded(
                      child: Image.network(
                        avatarData['imageUrl'],
                        fit: BoxFit.contain,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            avatarData['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                                const Text(
                                'Price:',
                                style:  TextStyle(
                                  fontWeight: FontWeight.normal,
                                  fontSize: 14,
                                ),
                              ),
                              Image.asset('assets/images/coin.png', width: 16, height: 16,),
                              Text('${avatarData['price']}'),
                            ],
                          )
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Align(
                        alignment: Alignment.center,
                        child: ElevatedButton(
                          onPressed: isOwned
                              ? null // Disable button if already owned
                              : () async {
                            var price = avatarData['price'] as int;
                            var coins = await authUser.getUserCoins();
                            var username = await authUser.getUsernameAsDatabase();
                            print("username_____________");
                            print(username);
                            final uId = await authUser.getUserIdByUsername(username);
                            if (coins >= price && uId != null) {
                              print("before owned ----------------------");
                              print(ownedAvatars);
                              await authUser.updateCoins(uId, coins - price);
                              await authUser.addToMyAvatars(imageUrl, staticUrl);
                              // setState(() {
                              //   ownedAvatars.add(imageUrl);
                              // });
                              print("after owned ----------------------");
                              print(ownedAvatars);
                            } else {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text('Insufficient Coins'),
                                    content: Text('You don\'t have enough money! Go focus'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text('OK'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            }
                          },
                          child: Text(
                            isOwned ? 'Owned' : 'Buy',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class MusicList extends StatefulWidget {
  const MusicList({Key? key}) : super(key: key);

  @override
  _MusicListState createState() => _MusicListState();
}

class _MusicListState extends State<MusicList> with WidgetsBindingObserver {
  late audio.AudioPlayer audioPlayer;
  bool isAudioPlaying = false;
  String? currentPlayingUrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
    audioPlayer = audio.AudioPlayer();
    audioPlayer.onPlayerStateChanged.listen((audio.PlayerState state) {
      if (state == audio.PlayerState.stopped) {
        setState(() {
          isAudioPlaying = false;
          currentPlayingUrl = null;
        });
      }
    });
  }

  @override
  void dispose() {
    audioPlayer.dispose();
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Paused state, stop the audio player
      audioPlayer.stop();
      setState(() {
        isAudioPlaying = false;
        currentPlayingUrl = null;
      });
    }
  }

  void toggleAudioPlayback(String audioUrl) async {
    if (isAudioPlaying) {
      await audioPlayer.pause();
    } else {
      await audioPlayer.play(audio.UrlSource(audioUrl));
    }
    setState(() {
      isAudioPlaying = !isAudioPlaying;
      currentPlayingUrl = isAudioPlaying ? audioUrl : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    var authUser = Provider.of<AuthRepository>(context, listen: false);
    var ownedMusic = Provider.of<AuthRepository>(context, listen: false).myMusic;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('audio').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final musicItems = snapshot.data!.docs;

        return ListView.builder(
          itemCount: musicItems.length,
          itemBuilder: (context, index) {
            final musicItem = musicItems[index];
            final musicItemData = musicItem.data() as Map<String, dynamic>;
            final musicUrl = musicItemData['musicUrl'];
            final isOwned = context.watch<AuthRepository>().myMusic.contains(musicUrl);

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                  currentPlayingUrl == musicUrl ? primary[50] : primary[300],
                  child: IconButton(
                    icon: Icon(
                      currentPlayingUrl == musicUrl
                          ? Icons.stop
                          : Icons.play_arrow,
                      color: Colors.white,
                    ),
                    onPressed: (){
                   toggleAudioPlayback(musicUrl);
                  },
                  ),
                ),
                title: Text(musicItemData['name']),
                subtitle: Row(
                  children: [
                    Text('Price: '),
                    Image.asset('assets/images/coin.png', width: 16, height: 16,),
                    Text('${musicItemData['price']}'),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: isOwned
                      ? null // Disable button if already owned
                      : () async {
                    var price = musicItemData['price'] as int;
                    var coins = await authUser.getUserCoins();
                    var username = await authUser.getUsernameAsDatabase();
                    print("username_____________");
                    print(username);
                    final uId = await authUser.getUserIdByUsername(username);
                    if (coins >= price && uId != null) {
                      await authUser.updateCoins(uId, coins - price);
                      await authUser.addToMyMusic(musicUrl);
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: Text('Insufficient Coins'),
                            content: Text('You don\'t have enough money! Go focus'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    }
                  },
                  child: Text( isOwned ? 'Owned' : 'Buy',
                    style: const TextStyle(color: Colors.white),),
                ),
              ),
            );
          },
        );
      },
    );
  }
}



