import 'package:flutter/material.dart';
import 'dart:io';
import 'package:lock_me/userInfo.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import 'colors.dart';

String getLastElementFromPath(String filePath) {
  return path.basename(filePath);
}

class AvatarSelectionScreen extends StatefulWidget {
  @override
  _AvatarSelectionScreenState createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends State<AvatarSelectionScreen> {
  late AuthRepository authRepository;
  late String? selectedAvatar = authRepository.selectedAvatar;
  Map<String, String> myMap = {
    'avatar4.gif': 'Hip-Tab Trotter',
    'avatar2.gif': 'Porky Pom Runner',
    'avatar10.gif': 'Pilliphant Pharm',
    'avatar12.gif': 'Bubble Gorilla',
    'avatar14.gif': 'Wise Wing Recycler',
    'avatar1.gif': 'Piggy Platter Dasher',
    'avatar5.gif': 'Cow Surprise',
    'avatar3.gif': 'Heartful Hambone',
    'avatar8.gif': 'Croco-Ball Catcher',
    'avatar15.gif': 'Piggybucks Soar',
    'avatar9.gif': 'Pizza Pachyderm',
    'avatar11.gif': 'Elephant Brew',
    'avatar13.gif': 'Burgerbird Bonanza',
    'avatar6.gif': 'Meaty Mooer',

  };


  @override
  void initState() {
    super.initState();
  }

  void selectAvatar(String avatarPath) {
    setState(() {
      selectedAvatar = avatarPath;
    });
  }

  Widget buildAvatarItem(String avatarPath) {
    final isSelected = avatarPath == selectedAvatar;
    //final avatarName = getLastElementFromPath(avatarPath);
    final avatarName = myMap[getLastElementFromPath(avatarPath)]!;

    return GestureDetector(
      onTap: () {
        selectAvatar(avatarPath);
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
          child: Column(
            children: [
              Expanded(
                child: Image.file(File(avatarPath)),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      avatarName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.check_circle_outline_outlined,
                      color: Colors.white, // Set icon color to white
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void setAsAvatar() {
    authRepository.updateSelectedAvatar(selectedAvatar!);
  }

  @override
  Widget build(BuildContext context) {
    authRepository = Provider.of<AuthRepository>(context);

    return Scaffold(
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
        ),
        itemCount: authRepository.myAvatarsLocalPath.length,
        itemBuilder: (BuildContext context, int index) {
          final avatarPath = authRepository.myAvatarsLocalPath[index];
          return buildAvatarItem(avatarPath);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:() {
          try {
            setAsAvatar();
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${e.toString()}'),
              ),
            );
          }
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Avatar changed  successfully'),
              ),
          );
        },
        child: const Icon(Icons.check_circle_outline_outlined, color: Colors.white,),
      ),
    );
  }
}
