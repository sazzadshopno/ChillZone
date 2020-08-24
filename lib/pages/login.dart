import 'package:chillzone/pages/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  Login({Key key, @required this.title}) : super(key: key);
  final String title;
  @override
  _LoginState createState() => _LoginState(title: title);
}

class _LoginState extends State<Login> {
  final String title;
  _LoginState({this.title});

  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  SharedPreferences sharedPreferences;
  bool isLoading = false;
  bool isLoggedIn = false;
  User currentUser;

  Future<Null> _handleSignIn() async {
    sharedPreferences = await SharedPreferences.getInstance();
    this.setState(() {
      isLoading = true;
    });

    GoogleSignInAccount googleUser = await googleSignIn.signIn();
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    User firebaseUser =
        (await firebaseAuth.signInWithCredential(credential)).user;

    if (firebaseUser != null) {
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isEqualTo: firebaseUser.uid)
          .get();

      final List<DocumentSnapshot> documents = result.docs;
      if (documents.length == 0) {
        FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set(
          {
            'name': firebaseUser.displayName,
            'email': firebaseUser.email,
            'photoUrl': firebaseUser.photoURL,
            'id': firebaseUser.uid,
            'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
            'friends': [],
            'requests': [],
            'sentRequests': [],
          },
        );
        currentUser = firebaseUser;
        await sharedPreferences.setString('id', currentUser.uid);
        await sharedPreferences.setString('name', currentUser.displayName);
        await sharedPreferences.setString('email', currentUser.email);
        await sharedPreferences.setString('photoUrl', currentUser.photoURL);
      } else {
        await sharedPreferences.setString('id', documents[0].data()['id']);
        await sharedPreferences.setString('name', documents[0].data()['name']);
        await sharedPreferences.setString(
            'email', documents[0].data()['email']);
        await sharedPreferences.setString(
            'photoUrl', documents[0].data()['photoUrl']);
      }
      String name = sharedPreferences.getString('name');
      Fluttertoast.showToast(msg: 'Welcome! $name');
      this.setState(
        () {
          isLoading = false;
        },
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Dashboard(
            currentUserId: sharedPreferences.getString('id'),
          ),
        ),
      );
    } else {
      Fluttertoast.showToast(msg: 'Sign in failed');
      this.setState(
        () {
          isLoading = false;
        },
      );
    }
  }

  _isSignedIn() async {
    this.setState(() {
      isLoading = true;
    });

    sharedPreferences = await SharedPreferences.getInstance();
    isLoggedIn = await googleSignIn.isSignedIn();

    if (isLoggedIn) {
      print('Logged in');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Dashboard(
            currentUserId: sharedPreferences.getString('id'),
          ),
        ),
      );
    } else {
      this.setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _isSignedIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ListTile(
              onTap: _handleSignIn,
              leading: FaIcon(
                FontAwesomeIcons.google,
              ),
              title: Text(
                'Signin using Google',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
