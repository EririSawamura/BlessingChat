import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chatapp/main.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'chatapp',
      theme: ThemeData(primaryColor: Colors.blue,),
      home: LoginScreen(title: 'chatapp: Chat with friends!'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class LoginScreen extends StatefulWidget {
  LoginScreen({Key key, this.title}) : super(key: key);
  final String title;

  @override
  LoginScreenState createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  SharedPreferences prefs;

  bool isLoading = false;
  bool isLoggedIn = false;
  FirebaseUser currentUser;

  @override
  void initState() {
    super.initState();
    isSignedIn();
  }

  //Check if user has signed in. If yes, go to friend page
  void isSignedIn() async {
    this.setState(() {
      isLoading = true;
    });

    prefs = await SharedPreferences.getInstance();
    if (await googleSignIn.isSignedIn()) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MainScreen(id: prefs.getString('id'))),
      );
    }

    this.setState(() {
      isLoading = false;
    });
  }

  //Sign in to Google account
  Future<Null> handleSignIn() async {
    prefs = await SharedPreferences.getInstance();
    this.setState(() { isLoading = true;});
    String id, nickname, photoUrl;

    //Sign in to Google
    GoogleSignInAccount googleUser = await googleSignIn.signIn();
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    FirebaseUser firebaseUser = await firebaseAuth.signInWithCredential(credential);
    if (firebaseUser != null) {
      //Already sign in
      final QuerySnapshot result = await Firestore.instance.collection('users').
        where('id', isEqualTo: firebaseUser.uid).
        getDocuments();
      final List<DocumentSnapshot> documents = result.documents;
      if (documents.length == 0) {
        // Update data to server if new user
        Firestore.instance
            .collection('users')
            .document(firebaseUser.uid)
            .setData({'nickname': firebaseUser.displayName, 'photoUrl': firebaseUser.photoUrl, 'id': firebaseUser.uid});

        // Write data to local
        currentUser = firebaseUser;
        id = currentUser.uid;
        nickname = currentUser.displayName;
        photoUrl = currentUser.photoUrl;
      } else {
        // Write data to local
        id = documents[0]['id'];
        nickname = documents[0]['nickname'];
        photoUrl = documents[0]['photoUrl'];
        await prefs.setString('aboutMe', documents[0]['aboutMe']);
      }
      await prefs.setString('id', id);
      await prefs.setString('nickname', nickname);
      await prefs.setString('photoUrl', photoUrl);
      Fluttertoast.showToast(msg: "Welcome to the friend page");
      Navigator.push(context,
        MaterialPageRoute(builder: (context) => MainScreen(id: firebaseUser.uid,)),
      );
    } else {
      Fluttertoast.showToast(msg: "Please sign in again!");
    }

    this.setState(() { isLoading = false;});
  }

  //Build Scaffold of main body
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
            key: Key("MainPage"),
            style: TextStyle(color: Color(0xff203152), fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body:
          Column(
            children: <Widget>[
              Container(
                margin: const EdgeInsets.only(top: 60, bottom: 40),
                alignment: Alignment.center,
                child: Image.asset('images/icon.png',
                  height: 200,
                ),
              ),
              Stack(
                children: <Widget>[
                  Container(
                    margin: const EdgeInsets.only(top: 130),
                    alignment: Alignment.center,
                    child: FlatButton(
                        onPressed: handleSignIn,
                        child: Text(
                          'Sign in with Google account',
                          style: TextStyle(fontSize: 16.0),
                        ),
                        color: Colors.blue,
                        highlightColor: Colors.blue,
                        splashColor: Colors.transparent,
                        textColor: Colors.white,
                        padding: EdgeInsets.fromLTRB(30.0, 15.0, 30.0, 15.0)),
                  ),
                  Positioned(
                    child: isLoading
                        ? Container(
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                      color: Colors.white.withOpacity(0.8),
                    )
                        : Container(),
                  ),
                ],)
            ],
          ),
    );
  }
}
