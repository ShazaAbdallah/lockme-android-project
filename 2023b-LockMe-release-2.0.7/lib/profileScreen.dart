import 'package:flutter/material.dart';
import 'colors.dart';
import 'package:lock_me/userInfo.dart';
import 'package:provider/provider.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:lock_me/appDrawer.dart';
import 'package:permission_handler/permission_handler.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  SnappingSheetController snappingSheetController = SnappingSheetController();
  late AuthRepository firebaseUser;

  double screenHeight = 0;
  double screenWidth = 0;

  @override
  Widget build(BuildContext context) {
    firebaseUser = Provider.of<AuthRepository>(context);
    screenHeight = MediaQuery
        .of(context)
        .size
        .height;
    screenWidth = MediaQuery
        .of(context)
        .size
        .width;

    return Scaffold(
      backgroundColor: primary[500],
      drawer: const AppDrawer(),
      appBar: buildAppBar(context),
      body: ListView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Center(
            child: Stack(
              children: [
                GestureDetector(
                  // onTap: () {
                  //   showModalBottomSheet(
                  //       context: context,
                  //       builder: (BuildContext context) {
                  //         return bottomSheet(context);
                  //       });
                  // },
                  onTap: () async {
                    PermissionStatus status = await Permission.storage.status;
                    if (!status.isGranted) {
                      print("status.is not Granted#####################");
                      try{
                        print("status.is not Granted#####################");
                        status = await Permission.storage.request();
                      }
                      catch(e){
                        print(e);
                      }
                    }
                    if (status.isGranted) {
                      print("status.isGranted#####################");
                      FilePickerResult? picked =
                      await FilePicker.platform.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: [
                          'png',
                          'jpg',
                          'gif',
                          'bmp',
                          'jpeg',
                          'webp'
                        ],
                      );
                      if (picked != null) {
                        File file = File(picked.files.single.path!);
                        firebaseUser.uploadNewImage(file);
                      } else {
                        const noSelectedImage = SnackBar(
                            content: Text('No  image  selected'));
                        ScaffoldMessenger.of(context).
                        showSnackBar(noSelectedImage);
                      }
                    }
                    else{
                      print("Permission denied");
                    }
                  },
                  child: FutureBuilder(
                    future: firebaseUser.getImageUrl(),
                    builder: (BuildContext context,
                        AsyncSnapshot<String> snapshot) {
                      return Container(
                        padding: const EdgeInsets.all(5),
                        child: CircleAvatar(
                          radius: 80.0,
                          backgroundImage: (snapshot.data == null)
                              ? null
                              : NetworkImage(snapshot.data!),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 4,
                  child: buildEditIcon(Theme
                      .of(context)
                      .colorScheme
                      .primary),
                ),
              ],
            ),
          ),
          SizedBox(height: screenHeight*0.0125),
          buildName(),
          SizedBox(height: screenHeight*0.04),
          buildButtons(context),
        ],
      ),
    );
  }

  Widget buildName() =>
      Column(
        children: [
          Text(
            firebaseUser.getUsername().toString(),
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 35, color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text (
            firebaseUser.getCoins().toString(),
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 24, color: Colors.white),
          ),
          const SizedBox(height: 1),
          const Text(
            'Coins',
            style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
          )
        ],
      );

  Widget buildButtons(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      color: primary[300],
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text(
            'Account',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: screenWidth,
            height: screenHeight * 0.06, // Adjusted to 6% of the screen height
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/change_password');
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color?>(
                  primary[500],
                ),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(1.0),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.key, color: Colors.white),
                  SizedBox(width: screenWidth * 0.05),
                  Text(
                    'Change Password',
                    style: TextStyle(
                      color: primary[100],
                      fontWeight: FontWeight.bold,
                      fontSize: screenHeight * 0.025, // Adjusted to 2.5% of the screen height
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_right, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: screenWidth,
            height: screenHeight * 0.06, // Adjusted to 6% of the screen height
            child: ElevatedButton(
              onPressed: () async {
                final authRepository =
                Provider.of<AuthRepository>(context, listen: false);
                await authRepository.signOut();
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color?>(
                  primary[500],
                ),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(1.0),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.logout, color: Colors.white),
                  SizedBox(width: screenWidth * 0.05),
                  Text(
                    'Log Out',
                    style: TextStyle(
                      color: primary[100],
                      fontWeight: FontWeight.bold,
                      fontSize: screenHeight * 0.025, // Adjusted to 2.5% of the screen height
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_right, color: Colors.white),
                ],
              ),
            ),
          ),
           SizedBox(height: screenHeight * 0.5), // Adjusted to 27% of the screen height
        ],
      ),
    );
  }



  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      iconTheme: IconThemeData(
        color: primary[100],),
      title: const Text('My Profile',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20.0,
        ),
      ),
      backgroundColor: primary[500],
      elevation: 0,
    );
  }

  //currently not in use
  Widget bottomSheet(BuildContext context) {
    return Container(
      height: 100.0,
      width: MediaQuery
          .of(context)
          .size
          .width,
      margin: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 20,
      ),
      child: Column(
        children: [
          const Text(
            "Choose profile photo",
            style: TextStyle(
              fontSize: 20.0,
            ),
          ),
          const SizedBox(
            height: 20.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.camera),
                  label: const Text("Camera")),
              TextButton.icon(
                  onPressed: () async {
                    FilePickerResult? picked =
                    await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: [
                        'png',
                        'jpg',
                        'gif',
                        'bmp',
                        'jpeg',
                        'webp'
                      ],
                    );
                    if (picked != null) {
                      File file = File(picked.files.single.path!);
                      firebaseUser.uploadNewImage(file);
                    }else{
                      const noSelectedImage = SnackBar(
                          content: Text('No  image  selected'));
                      ScaffoldMessenger.of(context).
                      showSnackBar(noSelectedImage);
                    }
                  },
                  icon: const Icon(Icons.image),
                  label: const Text("Gallery"))
            ],
          )
        ],
      ),
    );
  }

  Widget buildEditIcon(Color color) =>
      buildCircle(
        color: Colors.white,
        all: 3,
        child: buildCircle(
          color: Colors.blue,
          all: 8,
          child: const Icon(
            Icons.edit,
            color: Colors.white,
            size: 20,
          ),
        ),
      );

  Widget buildCircle({
    required Widget child,
    required double all,
    required Color color,
  }) =>
      ClipOval(
        child: Container(
          padding: EdgeInsets.all(all),
          color: color,
          child: child,
        ),
      );

}
