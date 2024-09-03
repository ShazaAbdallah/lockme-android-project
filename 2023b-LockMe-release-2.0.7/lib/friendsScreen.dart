import 'package:flutter/material.dart';
import 'package:lock_me/appDrawer.dart';
import 'colors.dart';
import 'package:lock_me/userInfo.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;


class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  _FriendsScreenState createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {

  late List<Friend> friends = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Friends',
            style: TextStyle(color: Colors.white)
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt_sharp),
            color: Colors.white,
            onPressed: () {
              Navigator.pushNamed(context, '/search_friend');
            },
          ),
          IconButton(
            icon: badges.Badge(
              badgeContent: StreamBuilder<List<Friend>>(
                stream: Provider.of<AuthRepository>(context)
                    .getFriendRequestsStream(),
                builder: (context, snapshot) {
                  final friendRequests = snapshot.data ?? [];
                  final notificationCount = friendRequests.length;
                  return Text(
                    notificationCount.toString(),
                    style: const TextStyle(color: Colors.white),
                  );
                },
              ),
              child: const Icon(Icons.notifications),
            ),
            color: Colors.white,
            onPressed: () async {
              // Stream<List<Friend>> friendsStream = Provider.of<AuthRepository>(
              //     context, listen: false).getFriendRequestsStream();
              // List<Friend> fetchedFriends = await friendsStream.first;
              // setState(() {
              //   friends = fetchedFriends;
              // });
              await _showRequestDialog();
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Container(
        color: primary[300],
        child: StreamBuilder<List<Friend>>(
          stream: Provider.of<AuthRepository>(context).getFriendsStream(true),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final friendsList = snapshot.data!;
              return ListView.builder(
                itemCount: friendsList.length,
                itemBuilder: (context, index) {
                  final friend = friendsList[index];
                  return Card(
                    color: primary[100],
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                            friend.imageURl.toString()),
                        backgroundColor: primary[500],
                      ),
                      title: Text(
                        _getFriendNameWithRank(friend, index, friendsList),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Coins: ${friend.coins}'),
                    ),
                  );
                },
              );
            } else if (snapshot.hasError) {
              return Container(
                alignment: Alignment.center,
                child: const Text(
                  'You have not added friends yet',
                  style: TextStyle(fontSize: 20, color: Colors.white),
                ),
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(), // Show a loading indicator while data is being fetched
              );
            }
          },
        ),
      ),
    );
  }

  String _getFriendNameWithRank(Friend friend, int index,
      List<Friend> friendsList) {
    String rankHashtag = '';
    if (Provider
        .of<AuthRepository>(context)
        .userName == friend.name) {
      rankHashtag += '=> me ';
    }

    int rank = 1;
    for(int i=1; i <= index; i++) {
        if(friendsList[i-1].coins != friendsList[i].coins)
          {
            rank++;
          }
    }

    rankHashtag += '#$rank';
    return '${friend.name} $rankHashtag';
  }

  Future<void> _showRequestDialog() async {

    Stream<List<Friend>> friendsStream = Provider.of<AuthRepository>(context, listen: false).getFriendRequestsStream();
    await showDialog<Friend>(
      context: context,
      builder: (BuildContext context) {
        return StreamBuilder<List<Friend>>(
          stream: friendsStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return SimpleDialog(
                title: Text('No friend offers available.'),
              );
            }

            return SimpleDialog(
              title: Text('Friend Offers'),
              children: [
                SingleChildScrollView(
                  child: Column(
                    children: snapshot.data!.map((friend) {
                      return SimpleDialogOption(
                        onPressed: () {},
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundImage:
                              NetworkImage(friend.imageURl.toString()),
                              radius: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(friend.name),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check,
                                        color: Colors.green),
                                    onPressed: () async {
                                      Provider.of<AuthRepository>(context,
                                          listen: false)
                                          .acceptFriendRequest(friend.name);
                                    },
                                  ),
                                  IconButton(
                                    icon:
                                    const Icon(Icons.close, color: Colors.red),
                                    onPressed: () async {
                                      Provider.of<AuthRepository>(context,
                                          listen: false)
                                          .rejectFriendRequest(friend.name);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                )
              ],
            );
          },
        );
      },
    );


    // await showDialog<Friend>(
    //     context: context,
    //     builder: (BuildContext context) {
    //       return SimpleDialog(
    //         title: Text(friends.isEmpty ? 'No friend offers available.' : 'Friend Offers'),
    //         children: [
    //         SingleChildScrollView(
    //         child: Column(
    //         children: friends.map((friend) {
    //           return SimpleDialogOption(
    //             onPressed: () {},
    //             child: Row(
    //                 children: [
    //                   CircleAvatar(
    //                     backgroundImage: NetworkImage(
    //                         friend.imageURl.toString()),
    //                     radius: 20,
    //                   ),
    //                   const SizedBox(width: 10),
    //                   Text(friend.name),
    //                   Align(
    //                     alignment: Alignment.centerRight,
    //                     child: Row(
    //                     children: [
    //                       IconButton(
    //                         icon: const Icon(Icons.check, color: Colors.green),
    //                         onPressed: () async {
    //                           Provider.of<AuthRepository>(context, listen: false)
    //                               .acceptFriendRequest(friend.name);
    //                         },
    //                       ),
    //                       IconButton(
    //                         icon: const Icon(Icons.close, color: Colors.red),
    //                         onPressed: () async {
    //                           Provider.of<AuthRepository>(context, listen: false)
    //                               .rejectFriendRequest(friend.name);
    //                         },
    //                       ),
    //                      ],
    //                     ),
    //                   ),
    //                 ]
    //             ),
    //           );
    //         }
    //         ).toList()
    //       ),
    //       )]
    //       );
    //     }
    // );
  }


}
