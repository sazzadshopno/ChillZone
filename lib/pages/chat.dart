import 'package:chillzone/model/message.dart';
import 'package:chillzone/model/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Chat extends StatefulWidget {
  final String senderUserId, chatID;
  final User receiver;
  Chat({
    @required this.senderUserId,
    @required this.receiver,
    @required this.chatID,
  });
  @override
  _ChatState createState() => _ChatState(
        senderUserId: senderUserId,
        receiver: receiver,
        chatID: chatID,
      );
}

class _ChatState extends State<Chat> {
  final String senderUserId, chatID;
  final User receiver;
  _ChatState({
    @required this.senderUserId,
    @required this.receiver,
    @required this.chatID,
  });
  TextEditingController _textEditingController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          receiver.name,
        ),
        centerTitle: true,
      ),
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Flexible(
              child: StreamBuilder(
                stream: Firestore.instance
                    .collection('chat')
                    .document(chatID)
                    .collection('messages')
                    .orderBy(
                      'timestamp',
                      descending: true,
                    )
                    .snapshots(),
                builder: (_, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                  final messagesDocs = snapshot.data.documents;
                  List<Message> messages = [];
                  for (var message in messagesDocs) {
                    messages.add(Message.fromJSON(message));
                  }
                  print(messages);
                  return ListView.builder(
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (_, index) {
                      return Text(
                        messages[index].senderID +
                            ': ' +
                            messages[index].message,
                      );
                    },
                  );
                },
              ),
            ),
            Container(
              width: double.infinity,
              height: 50,
              padding: EdgeInsets.all(10),
              child: Row(
                children: [
                  Flexible(
                    child: Container(
                      child: TextField(
                        controller: _textEditingController,
                        decoration: InputDecoration.collapsed(
                          hintText: 'Type your message..',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Material(
                    child: Container(
                      child: IconButton(
                        icon: Icon(Icons.send),
                        onPressed: () {
                          //send message
                          if (_textEditingController.text.length > 0) {
                            String now = DateTime.now()
                                .millisecondsSinceEpoch
                                .toString();
                            Firestore.instance
                                .collection('chat')
                                .document(chatID)
                                .collection('messages')
                                .add(
                              {
                                'senderid': senderUserId,
                                'receiverid': receiver.id,
                                'message': _textEditingController.text,
                                'timestamp': now,
                              },
                            );
                            Firestore.instance
                                .collection('users')
                                .document(senderUserId)
                                .collection('chattingWith')
                                .document(chatID)
                                .updateData(
                              {
                                'senderid': senderUserId,
                                'receiverid': receiver.id,
                                'message': _textEditingController.text,
                                'timestamp': now,
                              },
                            );
                            Firestore.instance
                                .collection('users')
                                .document(receiver.id)
                                .collection('chattingWith')
                                .document(chatID)
                                .updateData(
                              {
                                'senderid': senderUserId,
                                'receiverid': receiver.id,
                                'message': _textEditingController.text,
                                'timestamp': now,
                              },
                            );
                            _textEditingController.text = '';
                          } else {
                            Fluttertoast.showToast(msg: 'Nothing to send.');
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
