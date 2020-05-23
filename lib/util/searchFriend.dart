import 'package:flutter/material.dart';
import 'package:chillzone/pages/showProfile.dart';
import 'package:chillzone/model/user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchFriend extends SearchDelegate<String> {
  String id;
  SearchFriend({@required this.id});

  @override
  String get searchFieldLabel => 'Search';

  @override
  TextInputAction textInputAction = TextInputAction.none;

  @override
  ThemeData appBarTheme(BuildContext context) {
    return Theme.of(context);
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      query.isNotEmpty
          ? IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                query = '';
              },
            )
          : Container(),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return query.isEmpty
        ? Container()
        : StreamBuilder(
            stream: Firestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Colors.green,
                  ),
                );
              }
              final data = snapshot.data.documents;
              List<User> users = [];
              for (var d in data) {
                String name = d['name'];
                String userID = d['id'];
                if (name.toLowerCase().startsWith(query.toLowerCase()) && userID != this.id) {
                  users.add(
                    User.fromJSON(d),
                  );
                }
              }
              return users.length == 0
                  ? Center(
                      child: Text(
                        'No profile with name: $query',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          onTap: () async {
                            SharedPreferences preferences = await SharedPreferences.getInstance();
                            String currentUserId = preferences.getString('id');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ShowProfile(user: users[index], currentUserId: currentUserId),
                              ),
                            );
                          },
                          leading: CircleAvatar(
                            child: Image.network(
                              users[index].photoUrl,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            users[index].name,
                          ),
                          subtitle: Text(
                            users[index].email,
                          ),
                        );
                      },
                    );
            },
          );
  }
}
