import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Chat extends StatelessWidget {
  final String peerId;
  final String peerAvatar;

  Chat({Key key, @required this.peerId, @required this.peerAvatar}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(
          'Chat room',
          style: TextStyle(color: Color(0xff203152), fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: new ChatScreen(
        peerId: peerId,
        peerAvatar: peerAvatar,
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerAvatar;

  ChatScreen({Key key, @required this.peerId, @required this.peerAvatar}) : super(key: key);

  @override
  State createState() => new ChatScreenState(peerId: peerId, peerAvatar: peerAvatar);
}

class ChatScreenState extends State<ChatScreen> {
  ChatScreenState({Key key, @required this.peerId, @required this.peerAvatar});

  String peerId, peerAvatar, id, imageUrl;

  File imageFile;

  var listMessage;
  String groupChatId;

  //SharedPreferences stores user information in the storage
  SharedPreferences prefs;

  bool isLoad, isSticker;

  //Controller for text editing and scrolling
  final TextEditingController textEditingController = new TextEditingController();
  final ScrollController scrollController = new ScrollController();

  //Check if user is editing message
  final FocusNode focusNode = new FocusNode();

  //Build stack of main body
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              buildListMessage(),  // List of messages
              buildInput(),        // Input content
              (isSticker ? buildSticker() : Container()), // Sticker
            ],
          ),
          buildLoading() // Loading
        ],
      ),
      onWillPop: onBackPress,
    );
  }

  @override
  void initState() {
    super.initState();
    focusNode.addListener(onFocusChange);
    groupChatId = '';
    isLoad = false;
    isSticker = false;
    readLocal();
  }

  // Hide sticker when editing
  void onFocusChange() {
    if (focusNode.hasFocus) {  // Keyboard is showing
      setState(() {
        isSticker = false;
      });
    }
  }

  //Read preference and get group chat id
  readLocal() async {
    prefs = await SharedPreferences.getInstance();
    id = prefs.getString('id') ?? '';
    if (id.hashCode <= peerId.hashCode) {
      groupChatId = '$id-$peerId';
    } else {
      groupChatId = '$peerId-$id';
    }

    setState(() {});
  }

  //Get sticker
  void getSticker() {
    focusNode.unfocus(); // Hide keyboard when sticker appear
    setState(() {
      isSticker = !isSticker; //Show sticker
    });
  }

  //Get text from editor and send text
  void sendMsg(String content, int type) {
    // type: 0 = text, 1 = photo, 2 = sticker
    //Cannot send empty message or message with only space
    if (content.trim() != '') {
      textEditingController.clear();

      var documentReference = Firestore.instance
          .collection('messages')
          .document(groupChatId)
          .collection(groupChatId)
          .document(DateTime.now().millisecondsSinceEpoch.toString());

      Firestore.instance.runTransaction((transaction) async {
        await transaction.set(
          documentReference,
          {
            'idFrom': id,
            'idTo': peerId,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            'content': content,
            'type': type
          },
        );
      });

      scrollController.animateTo(0.0, duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Fluttertoast.showToast(msg: 'Nothing to send');
    }
  }

  //Create Message
  Widget createMsg(int index, DocumentSnapshot document) {
    if (document['idFrom'] == id) {
      // Right (my message)
      return Row(
        children: <Widget>[
          document['type'] == 0
              // Text
              ? Container(
                  child: Text(
                    document['content'],
                    style: TextStyle(color: Color(0xff203152)),
                  ),
                  padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                  width: 200.0,
                  decoration: BoxDecoration(color: Color(0xffE8E8E8), borderRadius: BorderRadius.circular(8.0)),
                  margin: EdgeInsets.only(bottom: isLastMsg(index, "right") ? 20.0 : 10.0, right: 10.0),
                )
              : document['type'] == 1
                  // Image
                  ? Container(
                      child: Material(
                        child: CachedNetworkImage(
                          placeholder: (context, url) => Container(
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                ),
                                width: 200.0,
                                height: 200.0,
                                padding: EdgeInsets.all(70.0),
                                decoration: BoxDecoration(
                                  color: Color(0xffE8E8E8),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(8.0),
                                  ),
                                ),
                              ),
                          errorWidget: (context, url, error) => Material(
                                child: Image.asset(
                                  'images/img_not_available.jpeg',
                                  width: 200.0,
                                  height: 200.0,
                                  fit: BoxFit.cover,
                                ),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(8.0),
                                ),
                                clipBehavior: Clip.hardEdge,
                              ),
                          imageUrl: document['content'],
                          width: 200.0,
                          height: 200.0,
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(8.0)),
                        clipBehavior: Clip.hardEdge,
                      ),
                      margin: EdgeInsets.only(bottom: isLastMsg(index, "right") ? 20.0 : 10.0, right: 10.0),
                    )
                  // Sticker
                  : Container(
                      child: new Image.asset(
                        'images/${document['content']}.gif',
                        width: 100.0,
                        height: 100.0,
                        fit: BoxFit.cover,
                      ),
                      margin: EdgeInsets.only(bottom: isLastMsg(index, "right") ? 20.0 : 10.0, right: 10.0),
                    ),
        ],
        mainAxisAlignment: MainAxisAlignment.end,
      );
    } else {
      // Left (peer message)
      return Container(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                isLastMsg(index,"left")
                    ? Material(
                        child: CachedNetworkImage(
                          placeholder: (context, url) => Container(
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.0,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                ),
                                width: 35.0,
                                height: 35.0,
                                padding: EdgeInsets.all(10.0),
                              ),
                          imageUrl: peerAvatar,
                          width: 35.0,
                          height: 35.0,
                          fit: BoxFit.cover,
                        ),
                        clipBehavior: Clip.hardEdge,
                      )
                    : Container(width: 35.0),
                document['type'] == 0
                    ? Container(
                        child: Text(
                          document['content'],
                          style: TextStyle(color: Colors.white),
                        ),
                        padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                        width: 200.0,
                        decoration: BoxDecoration(color: Color(0xff203152), borderRadius: BorderRadius.circular(8.0)),
                        margin: EdgeInsets.only(left: 10.0),
                      )
                    : document['type'] == 1
                        ? Container(
                            child: Material(
                              child: CachedNetworkImage(
                                placeholder: (context, url) => Container(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                      ),
                                      width: 200.0,
                                      height: 200.0,
                                      padding: EdgeInsets.all(70.0),
                                      decoration: BoxDecoration(
                                        color: Color(0xffE8E8E8),
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(8.0),
                                        ),
                                      ),
                                    ),
                                errorWidget: (context, url, error) => Material(
                                      child: Image.asset(
                                        'images/img_not_available.jpeg',
                                        width: 200.0,
                                        height: 200.0,
                                        fit: BoxFit.cover,
                                      ),
                                      borderRadius: BorderRadius.all(
                                        Radius.circular(8.0),
                                      ),
                                      clipBehavior: Clip.hardEdge,
                                    ),
                                imageUrl: document['content'],
                                width: 200.0,
                                height: 200.0,
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.all(Radius.circular(8.0)),
                              clipBehavior: Clip.hardEdge,
                            ),
                            margin: EdgeInsets.only(left: 10.0),
                          )
                        : Container(
                            child: new Image.asset(
                              'images/${document['content']}.gif',
                              width: 100.0,
                              height: 100.0,
                              fit: BoxFit.cover,
                            ),
                            margin: EdgeInsets.only(bottom: isLastMsg(index, "right") ? 20.0 : 10.0, right: 10.0, left: 10),
                          ),
              ],
            ),

            // Time
            isLastMsg(index,"left")
                ? Container(
                    child: Text(
                      DateFormat('dd MMM kk:mm')
                          .format(DateTime.fromMillisecondsSinceEpoch(int.parse(document['timestamp']))),
                      style: TextStyle(color: Color(0xffaeaeae), fontSize: 12.0, fontStyle: FontStyle.italic),
                    ),
                    margin: EdgeInsets.only(left: 50.0, top: 5.0, bottom: 5.0),
                  )
                : Container()
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        margin: EdgeInsets.only(bottom: 10.0),
      );
    }
  }

  //Find if it is the last message of user or peer
  bool isLastMsg(int index, String pos) {
    if(pos == "left")
      return ((index > 0 && listMessage != null && listMessage[index - 1]['idFrom'] == id) || index == 0);
    else
      return ((index > 0 && listMessage != null && listMessage[index - 1]['idFrom'] != id) || index == 0);
  }

  //Get image from gallery
  Future getImage() async {
    imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (imageFile != null) {
      setState(() { isLoad = true; });
      uploadFile();
    }
  }

  //Upload image file to firebase
  Future uploadFile() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putFile(imageFile);
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
    storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
      imageUrl = downloadUrl;
      setState(() {
        isLoad = false;
        sendMsg(imageUrl, 1);
      });
    }, onError: (err) {
      setState(() {
        isLoad = false;
      });
      Fluttertoast.showToast(msg: 'This file is not an image');
    });
  }

  //Handle back press for hide sticker or come to friend page
  Future<bool> onBackPress() {
    if (isSticker) {
      setState(() {
        isSticker = false;
      });
    } else {
      Navigator.pop(context);
    }

    return Future.value(false);
  }

  //The widget for Stickers
  Widget buildSticker() {
    return Container(
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => sendMsg('bb1', 2),
                child: new Image.asset('images/bb1.gif', width: 50.0,
                  height: 50.0, fit: BoxFit.cover,),
              ),
              FlatButton(
                onPressed: () => sendMsg('bb2', 2),
                child: new Image.asset('images/bb2.gif', width: 50.0,
                  height: 50.0, fit: BoxFit.cover,),
              ),
              FlatButton(
                onPressed: () => sendMsg('bb3', 2),
                child: new Image.asset('images/bb3.gif', width: 50.0,
                  height: 50.0, fit: BoxFit.cover,),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => sendMsg('bb4', 2),
                child: new Image.asset('images/bb4.gif', width: 50.0,
                  height: 50.0, fit: BoxFit.cover,),
              ),
              FlatButton(
                onPressed: () => sendMsg('bb5', 2),
                child: new Image.asset('images/bb5.gif', width: 50.0,
                  height: 50.0, fit: BoxFit.cover,),
              ),
              FlatButton(
                onPressed: () => sendMsg('bb6', 2),
                child: new Image.asset('images/bb6.gif', width: 50.0,
                  height: 50.0, fit: BoxFit.cover,),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          ),
          Row(
            children: <Widget>[
              FlatButton(
                onPressed: () => sendMsg('bb7', 2),
                child: new Image.asset('images/bb7.gif', width: 50.0,
                  height: 50.0, fit: BoxFit.cover,),
              ),
              FlatButton(
                onPressed: () => sendMsg('bb8', 2),
                child: new Image.asset('images/bb8.gif', width: 50.0,
                  height: 50.0, fit: BoxFit.cover,),
              ),
              FlatButton(
                onPressed: () => sendMsg('bb9', 2),
                child: new Image.asset('images/bb9.gif', width: 50.0,
                  height: 50.0, fit: BoxFit.cover,),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          )
        ],
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      ),
      decoration: new BoxDecoration(
          border: new Border(top: new BorderSide(color: Color(0xffE8E8E8), width: 0.5)), color: Colors.white),
      padding: EdgeInsets.all(5.0),
      height: 240.0,
    );
  }

  //The widget for Loading
  Widget buildLoading() {
    return Positioned(
      child: isLoad
          ? Container(
              child: Center(
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)),
              ),
              color: Colors.white.withOpacity(0.8),
            )
          : Container(),
    );
  }

  //The input bar at the bottom of the chatting page, including the button:
  //Sticker, edit, message
  Widget buildInput() {
    return Container(
      child: Row(
        children: <Widget>[
          //Send image
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 1.0),
              child: new IconButton(
                icon: new Icon(Icons.image),
                onPressed: getImage,
                color: Color(0xff203152),
              ),
            ),
            color: Colors.white,
          ),

          //Button: Sticker
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 1.0),
              child: new IconButton(
                icon: new Icon(Icons.face),
                onPressed: getSticker,
                color: Color(0xff203152),
              ),
            ),
            color: Colors.white,
          ),

          //Textarea: Edit
          Flexible(
            child: Container(
              child: TextField(
                style: TextStyle(color: Color(0xff203152), fontSize: 15.0),
                controller: textEditingController,
                decoration: InputDecoration.collapsed(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: Color(0xffaeaeae)),
                ),
                focusNode: focusNode,
              ),
            ),
          ),

          //Button: send message
          Material(
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 8.0),
              child: new IconButton(
                icon: new Icon(Icons.send),
                onPressed: () => sendMsg(textEditingController.text, 0),
                color: Color(0xff203152),
              ),
            ),
            color: Colors.blue,
          ),
        ],
      ),
      width: double.infinity,
      height: 50.0,
      decoration: new BoxDecoration(
          border: new Border(top: new BorderSide(color: Color(0xffE8E8E8), width: 0.5)), color: Colors.white),
    );
  }

  //The widget for list of messages
  Widget buildListMessage() {
    return Flexible(
      child: groupChatId == ''
          ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)))
          : StreamBuilder(
              stream: Firestore.instance
                  .collection('messages')
                  .document(groupChatId)
                  .collection(groupChatId)
                  .orderBy('timestamp', descending: true)
                  .limit(20)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.blue)));
                } else {
                  listMessage = snapshot.data.documents;
                  return ListView.builder(
                    padding: EdgeInsets.all(10.0),
                    itemBuilder: (context, index) => createMsg(index, snapshot.data.documents[index]),
                    itemCount: snapshot.data.documents.length,
                    reverse: true,
                    controller: scrollController,
                  );
                }
              },
            ),
      );
  }
}
