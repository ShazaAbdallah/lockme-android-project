import 'package:flutter/material.dart';
import 'colors.dart';
import 'appDrawer.dart';
import 'package:lock_me/AvatarSelectionScreen.dart';
import 'musicSelectionScreen.dart';

class collection extends StatefulWidget {
  const collection({super.key});

  @override
  _collectionState createState() => _collectionState();
}

class _collectionState extends State<collection> with SingleTickerProviderStateMixin {
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
        title: const Text('Avatar & Music Collection', style: TextStyle(color: Colors.white,)),
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
        children: [
          AvatarSelectionScreen(),
          musicSelectionScreen(),
        ],
      ),
    );
  }
}