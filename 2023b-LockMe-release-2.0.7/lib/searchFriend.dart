import 'package:flutter/material.dart';
import 'package:lock_me/userInfo.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'colors.dart';

class SearchFriend extends StatefulWidget {
  const SearchFriend({Key? key}) : super(key: key);

  @override
  _SearchFriendState createState() => _SearchFriendState();
}

class _SearchFriendState extends State<SearchFriend> {
  String name = '';
  List<String> requestedFriends = [];

  @override
  Widget build(BuildContext context) {
    AuthRepository userInfo = Provider.of<AuthRepository>(context);
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        title: Card(
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search...',
            ),
            onChanged: (value) {
              setState(() {
                name = value;
              });
            },
          ),
        ),
      ),

      body: Container(
        color: primary[100],
        child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          final docs = snapshot.data?.docs ?? [];
          final matchingDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final username = data['username'] as String?;
            return username != null && username.toLowerCase().startsWith(name.toLowerCase());
          }).toList();

          if(name.isEmpty){
            return Container();
          }

          return ListView.builder(
            itemCount: matchingDocs.length,
            itemBuilder: (context, index) {
              final data = matchingDocs[index].data() as Map<String, dynamic>;
              final username = data['username'] as String?;
              final url = data['imageURL'] as String?;
              if (username == null || username == Provider.of<AuthRepository>(context, listen: false).userName) {
                return Container();
              }
              final isRequestSent = requestedFriends.contains(username);

              return ListTile(
                title: Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(url.toString()),
                  backgroundColor: primary[500],
                ),

                trailing: StreamBuilder<List<Friend>>(
                  stream: Provider.of<AuthRepository>(context, listen: false).getFriendsStream(false),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final friends = snapshot.data!;
                      final isFriend = friends.any((friend) => friend.name == username);

                      if (isFriend) {
                        return const Icon(
                          Icons.check,
                          color: Colors.green,
                        );
                      }
                    }

                    return StreamBuilder<List<Friend>>(
                      stream: Provider.of<AuthRepository>(context, listen: false).getFriendRequestsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          final friendRequests = snapshot.data!;
                          final isRequestSent = friendRequests.any((request) => request.name == username);

                          if (isRequestSent) {
                            return const Icon(
                              Icons.pending,
                              color: Colors.yellow,
                            );
                          }
                        }

                        return IconButton(
                          icon: isRequestSent
                              ? Icon(
                            Icons.schedule_send,
                            color: primary [50],
                          )
                              : Icon(
                            Icons.person_add,
                            color: primary[50],
                          ),
                          onPressed: () async {
                            if (!isRequestSent) {
                              await userInfo.sendFriendRequest(username);
                              setState(() {
                                requestedFriends.add(username);
                              });
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      )
    );
  }
}
