import 'package:flutter/material.dart';
import 'package:chillzone/model/chat_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:chillzone/util/setOneToOneCode.dart';
import 'package:firebase_core/firebase_core.dart';

class ShowProfile extends StatefulWidget {
  final ChatUser user;
  final String currentUserId;
  ShowProfile({@required this.user, @required this.currentUserId});
  @override
  _ShowProfileState createState() =>
      _ShowProfileState(user: this.user, currentUserId: this.currentUserId);
}

class _ShowProfileState extends State<ShowProfile> {
  final ChatUser user;
  final String currentUserId;
  bool isFriend = false;
  bool issentRequests = false;
  bool isPending = false;
  _ShowProfileState({this.user, this.currentUserId});

  void removeData(
      String collectionID, String documentID, String field, String data) {
    FirebaseFirestore.instance.collection(collectionID).doc(documentID).update(
      {
        field: FieldValue.arrayRemove(
          [data],
        ),
      },
    );
  }

  void addData(
      String collectionID, String documentID, String field, String data) {
    FirebaseFirestore.instance.collection(collectionID).doc(documentID).update(
      {
        field: FieldValue.arrayUnion(
          [data],
        ),
      },
    );
  }

  void unfriend() {
    removeData('users', currentUserId, 'friends', user.id);
    removeData('users', user.id, 'friends', currentUserId);
    String chatID = oneTooneCode(user.id, currentUserId);
    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('chattingWith')
        .doc(chatID)
        .delete();
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.id)
        .collection('chattingWith')
        .doc(chatID)
        .delete();

    Fluttertoast.showToast(msg: 'Removed from friend list.');
  }

  void acceptRequest() {
    removeData('users', currentUserId, 'requests', user.id);
    addData('users', currentUserId, 'friends', user.id);
    removeData('users', user.id, 'sentRequests', currentUserId);
    addData('users', user.id, 'friends', currentUserId);
    String chatID = oneTooneCode(user.id, currentUserId);
    String now = DateTime.now().millisecondsSinceEpoch.toString();
    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserId)
        .collection('chattingWith')
        .doc(chatID)
        .set(
      {
        'chatID': chatID,
        'message': '',
        'senderid': '',
        'timestamp': now,
      },
    );
    FirebaseFirestore.instance
        .collection('users')
        .doc(user.id)
        .collection('chattingWith')
        .doc(chatID)
        .set(
      {
        'chatID': chatID,
        'message': '',
        'senderid': '',
        'timestamp': now,
      },
    );
    Fluttertoast.showToast(msg: 'Friend request accepted.');
  }

  void rejectRequest() {
    removeData('users', currentUserId, 'requests', user.id);
    removeData('users', user.id, 'sentRequests', currentUserId);
    Fluttertoast.showToast(msg: 'Friend request rejected.');
  }

  void cancelRequest() {
    removeData('users', currentUserId, 'sentRequests', user.id);
    removeData('users', user.id, 'requests', currentUserId);
    Fluttertoast.showToast(msg: 'Friend request canceled.');
  }

  void sendRequest() {
    addData('users', currentUserId, 'sentRequests', user.id);
    addData('users', user.id, 'requests', currentUserId);
    Fluttertoast.showToast(msg: 'Friend request sent.');
  }

  @override
  void initState() {
    super.initState();
    Firebase.initializeApp().whenComplete(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Profile: ${user.name}'),
      ),
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Center(
              child: Text(user.name),
            ),
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
                DocumentSnapshot docs = snapshot.data;
                List<dynamic> friends = docs.data()['friends'];
                List<dynamic> sentRequests = docs.data()['sentRequests'];
                List<dynamic> requests = docs.data()['requests'];

                isFriend = friends.isNotEmpty && friends.contains(user.id);
                issentRequests =
                    sentRequests.isNotEmpty && sentRequests.contains(user.id);
                isPending = requests.isNotEmpty && requests.contains(user.id);

                if (isFriend) {
                  return Center(
                    child: IconButton(
                      icon: Icon(Icons.delete_forever),
                      onPressed: unfriend,
                    ),
                  );
                } else if (isPending) {
                  return Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        IconButton(
                          icon: Icon(Icons.done),
                          onPressed: acceptRequest,
                        ),
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: rejectRequest,
                        ),
                      ],
                    ),
                  );
                } else {
                  return Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        issentRequests
                            ? IconButton(
                                icon: Icon(Icons.cancel),
                                onPressed: cancelRequest,
                              )
                            : IconButton(
                                icon: Icon(Icons.group_add),
                                onPressed: sendRequest,
                              ),
                      ],
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
