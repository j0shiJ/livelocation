import 'package:flutter/material.dart';
import 'package:livelocation/constants.dart';
import 'package:livelocation/loginPage.dart';
import 'package:livelocation/welcomePage.dart';
import 'package:livelocation/signup.dart';
import 'package:livelocation/forgotPassword.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:livelocation/editProfile.dart';
import 'package:location/location.dart';
import 'package:livelocation/homePage.dart';
import 'map.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Location location = new Location();
  Future<dynamic> _getPermission() async {
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
    location.enableBackgroundMode(enable: true);
  }

  @override
  void initState() {
    super.initState();
    _getPermission();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Live Location',
      theme: ThemeData(
        primaryColor: MyTheme.kPrimaryColor,
        accentColor: MyTheme.kAccentColor,
        primarySwatch: Colors.orange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: WelcomePage.id,
      routes: {
        WelcomePage.id: (context) => WelcomePage(),
        LoginPage.id: (context) => LoginPage(),
        SignupPage.id: (context) => SignupPage(),
        ForgotPage.id: (context) => ForgotPage(),
        EditProfilePage.id: (context) => EditProfilePage(),
        HomePage.id: (context) => HomePage(),
      },
    );
  }
}
