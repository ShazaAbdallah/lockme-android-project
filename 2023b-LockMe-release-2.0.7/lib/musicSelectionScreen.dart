import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:lock_me/userInfo.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'colors.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'colors.dart';
import 'appDrawer.dart';
import 'userInfo.dart';
import 'package:audioplayers/audioplayers.dart' as audio;

String getLastElementFromPath(String filePath) {
  return path.basename(filePath);
}

class musicSelectionScreen extends StatefulWidget {
  @override
  _musicSelectionScreenState createState() => _musicSelectionScreenState();
}

class _musicSelectionScreenState extends State<musicSelectionScreen> with WidgetsBindingObserver {
  late AuthRepository authRepository;
  late String? selectedMusic = authRepository.selectedMusic;
  late audio.AudioPlayer audioPlayer;
  bool isAudioPlaying = false;
  String? currentPlayingUrl;
  Map<String, String> myMap = {
    'audio2.mp3': 'Fleeting Glance',
    'audio6.mp3': 'White Mountain',
    'audio5.mp3': 'Space',
    'audio1.mp3': 'Soft Piano',
    'audio8.mp3': 'Relaxation Piano',
    'audio3.mp3': 'Violet Night',
    'audio7.mp3': 'Meditation',
    'audio9.mp3': 'Mystery Dawn',
    'audio4.mp3': 'Inspiring Piano',
  };

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
  void dispose() {
    audioPlayer.dispose();
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  void selectMusic(String musicPath) {
    setState(() {
      selectedMusic = musicPath;
    });
  }

  Widget buildAvatarItem(String musicPath) {
    final isSelected = musicPath == selectedMusic;
    final musicName = myMap[getLastElementFromPath(musicPath)];

    return GestureDetector(
      onTap: () {
        selectMusic(musicPath);
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? primary : Colors.transparent,
            width: 5.0,
          ),
          color: primary[100], // Set background color to primary[100]
        ),
        child: Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor:
              currentPlayingUrl == musicPath ? primary[50] : primary[300],
              child: IconButton(
                icon: Icon(
                  currentPlayingUrl == musicPath
                      ? Icons.stop
                      : Icons.play_arrow,
                  color: Colors.white,
                ),
                onPressed: (){
                  toggleAudioPlayback(musicPath);
                },
              ),
            ),
            title: Text(musicName!),
          ),
        ),
      ),
    );
  }

  void setAsMusic() {
    authRepository.updateSelectedMusic(selectedMusic!);
  }

  @override
  Widget build(BuildContext context) {
    authRepository = Provider.of<AuthRepository>(context);

    return Scaffold(
      body: ListView.builder(
        itemCount: authRepository.myMusicLocalPath.length,
        itemBuilder: (BuildContext context, int index) {
          final musicPath = authRepository.myMusicLocalPath[index];
          return buildAvatarItem(musicPath);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:() {
          try {
            setAsMusic();
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${e.toString()}'),
              ),
            );
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Music changed  successfully'),
            ),
          );
        },
        child: const Icon(Icons.check_circle_outline_outlined, color: Colors.white,),
      ),
    );
  }
}
