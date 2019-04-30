import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chatapp/chat.dart';
import 'package:chatapp/login.dart';
import 'package:chatapp/settings.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() => runApp(MyApp());

class MainScreen extends StatefulWidget {
  final String id;

  MainScreen({Key key, @required this.id}) : super(key: key);

  @override
  State createState() => MainScreenState(id: id);
}

class MainScreenState extends State<MainScreen> {
  MainScreenState({Key key, @required this.id});

  final String id;
  final String _copyLink = "https://drive.google.com/file/d/1-aFUk9HFi1v_-GTAZ_ywaQtN7DE0MJVo/view?usp=sharing";
  bool load = false;

  List<Choice> choices = const <Choice>[
    const Choice(title: 'Settings', icon: Icons.settings),
    const Choice(title: 'Log out', icon: Icons.exit_to_app),
    const Choice(title: 'Share', icon: Icons.share),
  ];

  //Handle the back press
  Future<bool> onBackPress() {
    openDialog();
    return Future.value(false);
  }

  //The dialog for exiting the application
  Future<Null> openDialog() async {
    switch (await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding: EdgeInsets.all(0),
            children: <Widget>[
              Container(
                color: Colors.blue,
                margin: EdgeInsets.all(0.0),
                padding: EdgeInsets.only(bottom: 10.0, top: 10.0),
                height: 100.0,
                child: Column(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.exit_to_app,
                        size: 30.0,
                        color: Colors.white,
                      ),
                      margin: EdgeInsets.only(bottom: 10.0),
                    ),
                    Text(
                      'Are you sure to exit chat app?',
                      style: TextStyle(color: Colors.white70, fontSize: 18.0),
                    ),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () { Navigator.pop(context, 1); },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(Icons.cancel),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text('No', style: TextStyle(color: Color(0xff203152),
                        fontWeight: FontWeight.bold),)
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () { Navigator.pop(context, 0); },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(Icons.check_circle,),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text('Yes', key: Key('dialog'), style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),)
                  ],
                ),
              ),
            ],
          );
        })) {
      case 1:
        break;
      case 0:
        exit(0);
        break;
    }
  }

  //The dialog for sharing the application
  Future<Null> shareDialog() async{
    switch (await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding: EdgeInsets.all(0),
            children: <Widget>[
              Container(
                color: Colors.blue,
                margin: EdgeInsets.all(0.0),
                padding: EdgeInsets.only(bottom: 10.0, top: 10.0),
                height: 100.0,
                child: Column(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.mobile_screen_share,
                        size: 30.0,
                        color: Colors.white,
                      ),
                      margin: EdgeInsets.only(bottom: 10.0),
                    ),
                    Text(
                      'Share chatapp with friends!',
                      style: TextStyle(color: Colors.white70, fontSize: 18.0),
                    ),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Clipboard.setData(new ClipboardData(text: _copyLink));
                  Fluttertoast.showToast(msg: "Share link has been copied");
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(Icons.insert_link,),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text('Copy link', key: Key('dialog'), style: TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold),)
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () { Navigator.pop(context, 1); },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(Icons.cancel),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text('Close', style: TextStyle(color: Color(0xff203152),
                        fontWeight: FontWeight.bold),)
                  ],
                ),
              ),
            ],
          );
        })) {
      case 1:
        break;
    }
  }

  //Build each individual friend list
  Widget buildItem(BuildContext context, DocumentSnapshot document) {
    if (document['id'] == id) {
      return Container();
    } else {
      return Container(
        child: OutlineButton(
          child: Row(
            children: <Widget>[
              Material(
                child: CachedNetworkImage(
                  placeholder: (context, url) => Container(
                        child: CircularProgressIndicator(
                          strokeWidth: 1.0,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                        width: 60.0,
                        height: 60.0,
                      ),
                  imageUrl: document['photoUrl'],
                  width: 60.0,
                  height: 60.0,
                  fit: BoxFit.cover,
                ),
                //borderRadius: BorderRadius.all(Radius.circular(25.0)),
                clipBehavior: Clip.hardEdge,
              ),
              Flexible(
                child: Container(
                  child: Column(
                    children: <Widget>[
                      Container(
                        child: Text(
                          '${document['nickname']}',
                          style: TextStyle(color: Color(0xff203152)),
                        ),
                        alignment: Alignment.centerLeft,
                        margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                      ),
                      Container(
                        child: Text(
                          'Signature: ${document['aboutMe'] ?? 'Not available'}',
                          style: TextStyle(color: Color(0xff203152)),
                        ),
                        alignment: Alignment.centerLeft,
                        margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                      )
                    ],
                  ),
                  margin: EdgeInsets.only(left: 20.0),
                ),
              ),
            ],
          ),
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Chat(
                          peerId: document.documentID,
                          peerAvatar: document['photoUrl'],
                        )));
          },
          color: Colors.white,
          borderSide: BorderSide(color: Colors.black),
          padding: EdgeInsets.fromLTRB(25.0, 10.0, 25.0, 10.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
        margin: EdgeInsets.only(bottom: 10.0, left: 2.0, right: 2.0),
      );
    }
  }

  final GoogleSignIn googleSignIn = GoogleSignIn();

  //Handle the press action in the right-top menu
  void onItemMenuPress(Choice choice) {
    if (choice.title == 'Log out') {
      handleSignOut();
    } else if (choice.title == 'Share'){
      shareDialog();
    }
    else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => Settings()));
    }
  }

  //Sign out Google account
  Future<Null> handleSignOut() async {
    this.setState(() {
      load = true;
    });

    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();

    this.setState(() {
      load = false;
    });

    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MyApp()),
            (Route<dynamic> route) => false);
  }

  //Build Scaffold of main body
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //Navigation bar
      appBar: AppBar(
        title: Text(
          'Friend Page',
          key: Key("FriendPage"),
          style: TextStyle(color: Color(0xff203152), fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        actions: <Widget>[
          PopupMenuButton<Choice>(
            onSelected: onItemMenuPress,
            itemBuilder: (BuildContext context) {
              return choices.map((Choice choice) {
                return PopupMenuItem<Choice>(
                    value: choice,
                    child: Row(
                      children: <Widget>[
                        Icon(
                          choice.icon,
                          color: Color(0xff203152),
                        ),
                        Container(
                          width: 10.0,
                        ),
                        Text(
                          choice.title,
                          style: TextStyle(color: Color(0xff203152)),
                        ),
                      ],
                    ));
              }).toList();
            },
          ),
        ],
      ),
      body: WillPopScope(
        child: Stack(
          children: <Widget>[
            // List of friends
            Container(
              child: StreamBuilder(
                stream: Firestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    );
                  } else {
                    return ListView.builder(
                      padding: EdgeInsets.all(10.0),
                      itemBuilder: (context, index) => buildItem(context, snapshot.data.documents[index]),
                      itemCount: snapshot.data.documents.length,
                    );
                  }
                },
              ),
            ),

            // Loading
            Positioned(
              child: load
                  ? Container(
                      child: Center(
                        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)),
                      ),
                      color: Colors.white.withOpacity(0.8),
                    )
                  : Container(),
            )
          ],
        ),
        onWillPop: onBackPress,
      ),
    );
  }
}

class Choice {
  const Choice({this.title, this.icon});
  final String title;
  final IconData icon;
}
