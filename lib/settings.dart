import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Settings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title:
          new Text('Setting', style: TextStyle(color: Color(0xff203152), fontWeight: FontWeight.bold),),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: new SettingsScreen(),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  @override
  State createState() => new SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> {
  TextEditingController controllerNickname;
  TextEditingController controllerAboutMe;

  //SharedPreferences stores user information in the storage
  SharedPreferences prefs;

  String id = '', nickname = '', aboutMe = '', photoUrl = '';

  bool isLoad = false;
  File avatar;

  final FocusNode focusNodeNickname = new FocusNode();
  final FocusNode focusNodeAboutMe = new FocusNode();

  @override
  void initState() {
    super.initState();
    readLocal();
  }

  //Read preference and get attribute of a user
  void readLocal() async {
    //Get information from the persistent storage
    prefs = await SharedPreferences.getInstance();
    id = prefs.getString('id') ?? '';
    nickname = prefs.getString('nickname') ?? '';
    aboutMe = prefs.getString('aboutMe') ?? '';
    photoUrl = prefs.getString('photoUrl') ?? '';

    controllerNickname = new TextEditingController(text: nickname);
    controllerAboutMe = new TextEditingController(text: aboutMe);

    // Force refresh input
    setState(() {});
  }

  //Get image from gallery
  Future getImage() async {
    File image = await ImagePicker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        avatar = image;
        isLoad = true;
      });
    }
    uploadFile();
  }

  //Upload photos to the personal profile
  Future uploadFile() async {
    String fileName = id;
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putFile(avatar);
    StorageTaskSnapshot storageTaskSnapshot;
    uploadTask.onComplete.then((value) {
      if (value.error == null) {
        storageTaskSnapshot = value;
        storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
          photoUrl = downloadUrl;
          Firestore.instance
              .collection('users')
              .document(id)
              .updateData({'nickname': nickname, 'aboutMe': aboutMe, 'photoUrl': photoUrl}).then((data) async {
            await prefs.setString('photoUrl', photoUrl);
            Fluttertoast.showToast(msg: "Upload success");
          }).catchError((err) {
            Fluttertoast.showToast(msg: err.toString());
          });
        }, onError: (err) {
          Fluttertoast.showToast(msg: 'This file is not an image');
        });
      } else {
        Fluttertoast.showToast(msg: 'This file is not an image');
      }
    }, onError: (err) {
      Fluttertoast.showToast(msg: err.toString());
    });
    setState(() {
      isLoad = false;
    });
  }

  //Upload other personal information to firebase
  void handleUpdateData() {
    focusNodeNickname.unfocus();
    focusNodeAboutMe.unfocus();

    setState(() {
      isLoad = true;
    });

    Firestore.instance
        .collection('users')
        .document(id)
        .updateData({'nickname': nickname, 'aboutMe': aboutMe, 'photoUrl': photoUrl}).then((data) async {
      await prefs.setString('nickname', nickname);
      await prefs.setString('aboutMe', aboutMe);
      await prefs.setString('photoUrl', photoUrl);
      Fluttertoast.showToast(msg: "Update success");
    }).catchError((err) {
      Fluttertoast.showToast(msg: err.toString());
    });
    setState(() {
      isLoad = false;
    });
  }

  //Build stack of main body
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        SingleChildScrollView(
          child: Column(
            children: <Widget>[
              //The profile photo
              Container(
                child: Center(
                  child: Stack(
                    children: <Widget>[
                      (avatar == null) ?
                        (photoUrl != '' ?
                          Material(
                            child: CachedNetworkImage(
                              placeholder: (context, url) => Container(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                    ),
                                    width: 90.0,
                                    height: 90.0,
                                    padding: EdgeInsets.all(20.0),
                                  ),
                              imageUrl: photoUrl,
                              width: 90.0,
                              height: 90.0,
                              fit: BoxFit.cover,
                            ),
                            clipBehavior: Clip.hardEdge,
                          ) :
                          Icon(
                            Icons.account_circle,
                            size: 90.0,
                            color: Color(0xffaeaeae),
                          ))
                      : Material(
                        child: Image.file(
                          avatar,
                          width: 90.0,
                          height: 90.0,
                          fit: BoxFit.cover,
                        ),
                        clipBehavior: Clip.hardEdge,
                      ),
                      IconButton(
                        icon: Icon(Icons.camera_alt,),
                        onPressed: getImage,
                        iconSize: 0.0,
                      ),
                    ],
                  ),
                ),
                width: double.infinity,
                margin: EdgeInsets.all(20.0),
              ),

              // Input
              Column(
                children: <Widget>[
                  // Nickname
                  Container(
                    child: Text(
                      'Nickname',
                      style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, color: Color(0xff203152)),
                    ),
                    margin: EdgeInsets.only(left: 10.0, bottom: 5.0, top: 10.0),
                  ),
                  Container(
                    child: Theme(
                      data: Theme.of(context).copyWith(primaryColor: Color(0xff203152)),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Write your nickname!',
                          contentPadding: new EdgeInsets.all(5.0),
                          hintStyle: TextStyle(color: Color(0xff203152)),
                        ),
                        controller: controllerNickname,
                        onChanged: (value) {
                          nickname = value;
                        },
                        focusNode: focusNodeNickname,
                      ),
                    ),
                    margin: EdgeInsets.only(left: 30.0, right: 30.0),
                  ),

                  // About me
                  Container(
                    child: Text(
                      'About me',
                      style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, color: Color(0xff203152)),
                    ),
                    margin: EdgeInsets.only(left: 10.0, top: 30.0, bottom: 5.0),
                  ),
                  Container(
                    child: Theme(
                      data: Theme.of(context).copyWith(primaryColor: Color(0xff203152)),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Write something to introduce yourself!',
                          contentPadding: EdgeInsets.all(5.0),
                          hintStyle: TextStyle(color: Color(0xffaeaeae)),
                        ),
                        controller: controllerAboutMe,
                        onChanged: (value) {
                          aboutMe = value;
                        },
                        focusNode: focusNodeAboutMe,
                      ),
                    ),
                    margin: EdgeInsets.only(left: 30.0, right: 30.0),
                  ),
                ],
                crossAxisAlignment: CrossAxisAlignment.start,
              ),

              // Update button
              Container(
                child: FlatButton(
                  onPressed: handleUpdateData,
                  child: Text(
                    'UPDATE',
                    style: TextStyle(fontSize: 16.0),
                  ),
                  color: Color(0xff203152),
                  highlightColor: new Color(0xff8d93a0),
                  splashColor: Colors.transparent,
                  textColor: Colors.white,
                  padding: EdgeInsets.fromLTRB(30.0, 10.0, 30.0, 10.0),
                ),
                margin: EdgeInsets.only(top: 50.0, bottom: 50.0),
              ),
            ],
          ),
          padding: EdgeInsets.only(left: 15.0, right: 15.0),
        ),

        // Loading
        Positioned(
          child: isLoad
              ? Container(
                  child: Center(
                    child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)),
                  ),
                  color: Colors.white.withOpacity(0.8),
                )
              : Container(),
        ),
      ],
    );
  }
}
