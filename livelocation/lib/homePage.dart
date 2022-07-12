import 'dart:core';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import 'package:livelocation/my_header.dart';
import 'package:livelocation/constants.dart';
import 'package:livelocation/search.dart';
import 'package:location/location.dart';
import 'package:livelocation/map.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);
  static String id = 'home_screen';

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final controller = ScrollController();
  double offset = 0;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  Future<void> _getUser() async {
    user = _auth.currentUser!;
  }

  String name = '';
  String username = '';
  String groupname = '';
  List<String>? users;
  Future<void> _getData() async {
    final DocumentSnapshot ds = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.email)
        .get();
    name = ds.get('username');
    username = ds.get('username');
  }

  Location location = new Location();
  LocationData? _locationData;
  Future<dynamic> _getLoctaion() async {
    bool _serviceEnabled;
    PermissionStatus _permissionGranted;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
    _locationData = await location.getLocation();
    location.enableBackgroundMode(enable: true);
    FirebaseFirestore.instance.collection('locations').doc(username).set({
      'username': username,
      'lat': _locationData!.latitude,
      'long': _locationData!.longitude,
    });
  }

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Group'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                TextField(
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: "Group Name",
                    hintText: "Family",
                    prefixIcon: Icon(
                      Icons.account_circle,
                    ),
                  ),
                  onChanged: (value) {
                    groupname = value;
                    print(groupname);
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Approve'),
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('groups')
                    .doc(groupname)
                    .set({
                  'groupname': groupname,
                  'users': '',
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  int num = 0;

  @override
  void initState() {
    super.initState();
    _getUser();
    _getData();
    _getLoctaion();
    controller.addListener(onScroll);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void onScroll() {
    setState(() {
      offset = (controller.hasClients) ? controller.offset : 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    Stream<QuerySnapshot> ds =
        FirebaseFirestore.instance.collection('groups').snapshots();
    return Scaffold(
      body: SingleChildScrollView(
        controller: controller,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            MyHeader(
              image: "images/3855345.png",
              textTop: "Hello",
              offset: offset,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    "Groups",
                    style: kHeadingTextStyle,
                  ),
                  SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: Column(children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.45,
                        child: StreamBuilder<QuerySnapshot>(
                          stream: ds,
                          builder:
                              (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                            if (!snapshot.hasData) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.connectionState ==
                                ConnectionState.active) {
                              List<QueryDocumentSnapshot<Object?>> groupdata =
                                  snapshot.data!.docs;
                              if (groupdata.length != 0) {
                                return ListView.builder(
                                    itemCount: groupdata.length,
                                    itemBuilder: (context, index) {
                                      groupname = groupdata[index]['groupname'];
                                      return PreventCard(
                                        image: 'images/images-2.jpg',
                                        title: groupname,
                                        text: 'text',
                                        username: username,
                                        groupname: groupname,
                                        userlat: _locationData!.latitude!,
                                        userlong: _locationData!.longitude!,
                                      );
                                    });
                              } else {
                                return Center(
                                  child: Container(
                                    padding: EdgeInsets.all(40.0),
                                    child: Text(
                                        "Create a group by clicking on the '+' button",
                                        textAlign: TextAlign.center),
                                  ),
                                );
                              }
                            } else {
                              return Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                          },
                        ),
                      ),
                    ]),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          num++;
          _showMyDialog();
        },
        backgroundColor: Color(0xFF3383CD),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PreventCard extends StatelessWidget {
  final String image;
  final String title;
  final String text;
  final String username;
  final String groupname;
  final double userlat;
  final double userlong;
  PreventCard({
    Key? key,
    required this.image,
    required this.title,
    required this.text,
    required this.username,
    required this.groupname,
    required this.userlat,
    required this.userlong,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: <Widget>[
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(80),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        offset: Offset(0, 8),
                        blurRadius: 24,
                        color: kShadowColor,
                      ),
                    ],
                  ),
                ),
                Image.asset(image),
                Positioned(
                  left: 155,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      color: Colors.grey,
                    ),
                    height: 160,
                    width: MediaQuery.of(context).size.width - 170,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          title,
                          style: kTitleTextstyle.copyWith(
                            fontSize: 24,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => SearchPage(
                                          username: username,
                                          groupname: groupname)),
                                );
                              },
                              icon: Icon(Icons.person_add_alt),
                            ),
                            Text('Add Members')
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Locate(
                                        username: username,
                                        groupname: groupname,
                                        userlat: userlat,
                                        userlong: userlong),
                                  ),
                                );
                              },
                              icon: Icon(Icons.my_location),
                            ),
                            Text('Show Location')
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
