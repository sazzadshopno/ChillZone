import 'package:chillzone/model/user.dart';
import 'package:chillzone/pages/chat.dart';
import 'package:flutter/material.dart';
import 'package:chillzone/pages/login.dart';
import 'package:chillzone/util/searchFriend.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Dashboard extends StatefulWidget {
  final currentUserId;
  Dashboard({
    this.currentUserId,
  });
  @override
  _DashboardState createState() =>
      _DashboardState(currentUserId: currentUserId);
}

class _DashboardState extends State<Dashboard> {
  final currentUserId;
  _DashboardState({this.currentUserId});

  bool isLoading = false;
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  Future<Null> _signOut() async {
    setState(() {
      isLoading = true;
    });

    await firebaseAuth.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();

    setState(() {
      isLoading = false;
    });
    Fluttertoast.showToast(msg: 'Logged Out');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => Login(
          title: 'Login',
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text('ChillZone'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: SearchFriend(
                  id: currentUserId,
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: Firestore.instance
            .collection('users')
            .document(currentUserId)
            .collection('chattingWith')
            .orderBy(
              'timestamp',
              descending: true,
            )
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.green,
              ),
            );
          }
          final data = snapshot.data.documents;

          List<dynamic> chattingWith = data;

          return Center(
            child: chattingWith.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        'You did not chat with anyone through this app.',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                      FlatButton(
                        onPressed: () {},
                        child: Text(
                          'Chat with Friends?',
                          style: TextStyle(
                            color: Colors.blue,
                          ),
                        ),
                      ),
                      FlatButton(
                        onPressed: _signOut,
                        child: Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    itemCount: chattingWith.length,
                    itemBuilder: (_, int index) {
                      String chatID = chattingWith[index]['chatID'];
                      String lastMessage = chattingWith[index]['message'];
                      String lastSender = chattingWith[index]['senderid'];
                      String otherUserId = chatID
                          .split(currentUserId)
                          .where((element) => element.length > 0)
                          .toList()
                          .first;
                      return StreamBuilder(
                        stream: Firestore.instance
                            .collection('users')
                            .document(otherUserId)
                            .snapshots(),
                        builder: (_, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(
                              child: CircularProgressIndicator(
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                          final data = snapshot.data;
                          User _user = User.fromJSON(data);
                          String subtitle = lastMessage == ''
                              ? 'Start conversation..'
                              : lastSender == currentUserId
                                  ? 'You: $lastMessage'
                                  : '${_user.name.split(' ').toList().first}: $lastMessage';
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(_user.photoUrl),
                            ),
                            title: Text(
                              _user.name,
                            ),
                            subtitle: Text(
                              subtitle,
                            ),
                            trailing: FlatButton(
                              onPressed: _signOut,
                              child: Text(
                                'Logout',
                                style: TextStyle(
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => Chat(
                                    senderUserId: currentUserId,
                                    chatID: chatID,
                                    receiverId: _user.id,
                                    receiverName: _user.name,
                                    receiverPhotoUrl: _user.photoUrl,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}
