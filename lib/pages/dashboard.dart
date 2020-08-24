import 'dart:convert';
import 'dart:io';

import 'package:chillzone/model/chat_user.dart';
import 'package:chillzone/pages/chat.dart';
import 'package:flutter/material.dart';
import 'package:chillzone/pages/login.dart';
import 'package:chillzone/util/searchFriend.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

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
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
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
  void initState() {
    super.initState();
    registerNotification();
    configLocalNotification();
  }

  void showNotification(message) async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
      Platform.isAndroid ? 'com.example.chillzone' : 'com.example.chillzone',
      'ChillZone',
      'No Description',
      playSound: true,
      enableVibration: true,
      importance: Importance.Max,
      priority: Priority.High,
    );
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    print(message);
    await flutterLocalNotificationsPlugin.show(0, message['title'].toString(),
        message['body'].toString(), platformChannelSpecifics,
        payload: json.encode(message));
  }

  void configLocalNotification() {
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void registerNotification() {
    firebaseMessaging.requestNotificationPermissions();

    firebaseMessaging.configure(onMessage: (Map<String, dynamic> message) {
      print('onMessage: $message');
      Platform.isAndroid
          ? showNotification(message['notification'])
          : showNotification(message['aps']['alert']);
      return;
    }, onResume: (Map<String, dynamic> message) {
      print('onResume: $message');
      return;
    }, onLaunch: (Map<String, dynamic> message) {
      print('onLaunch: $message');
      return;
    });

    firebaseMessaging.getToken().then((token) {
      print('token: $token');
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({'pushToken': token});
    }).catchError((err) {
      Fluttertoast.showToast(msg: err.message.toString());
    });
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
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserId)
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
                      String chatID = chattingWith[index].data()['chatID'];
                      String lastMessage =
                          chattingWith[index].data()['message'];
                      String lastSender =
                          chattingWith[index].data()['senderid'];
                      String otherUserId = chatID
                          .split(currentUserId)
                          .where((element) => element.length > 0)
                          .toList()
                          .first;
                      return StreamBuilder(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(otherUserId)
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
                          ChatUser _user = ChatUser.fromJSON(data);
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
