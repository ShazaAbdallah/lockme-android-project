import 'package:flutter/material.dart';
import 'colors.dart';
import 'package:lock_me/userInfo.dart';
import 'package:provider/provider.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {

  @override
  Widget build(BuildContext context) {
    final authRepository = Provider.of<AuthRepository>(context);
    final username = authRepository.userName;
    final imageUrl = authRepository.userImage;
    return Drawer(
      backgroundColor: primary[100],
      child: ListView(
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: primary[100],
            ),
            child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                CircleAvatar(
                  radius: 40,
                    backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : const AssetImage('assets/images/defult_profilePic.png')as ImageProvider<Object>?,
                    backgroundColor: primary[500]
                ),
                const SizedBox(height:10),
                Text(
                  username,
                  style: TextStyle(
                    fontSize: 18,
                    color: primary[50],
                  ),
                ),
              ],
            ),
          ),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text('Profile', style: TextStyle(color: primary[50],)),
            onTap: () {
              // Handle profile navigation
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.pushNamed(context, '/profile');// Close the drawer
            },
          ),

          ListTile(
            leading: const Icon(Icons.assignment),
            title: Text('Focus Challenge', style: TextStyle(color: primary[50]),),
            onTap: () {
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.pushNamed(context, '/task');// Close the drawer
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: Text('Achievements', style: TextStyle(color: primary[50]),),
            onTap: () {
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.pushNamed(context, '/achievements');// Close the drawer
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: Text('Friends', style: TextStyle(color: primary[50],),),
            onTap: () {
            Navigator.pop(context);
            Navigator.pop(context);
            Navigator.pushNamed(context, '/friends');// Close the drawer
            },
          ),

          ListTile(
            leading: const Icon(Icons.video_collection),
            title: Text('Collection', style: TextStyle(color: primary[50]),),
            onTap: () {
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.pushNamed(context, '/collection');// Close the drawer
            },
          ),

          ListTile(
            leading: const Icon(Icons.store),
            title: Text('Store', style: TextStyle(color: primary[50]),),
            onTap: () {
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.pushNamed(context, '/store');// Close the drawer
            },
          ),


          ListTile(
            leading: const Icon(Icons.info),
            title: Text('Info', style: TextStyle(color: primary[50],)),
            onTap: () {
              Navigator.pop(context);
              showAboutDialog(context: context);
            },
          ),

        ],
      ),
    );
  }
}