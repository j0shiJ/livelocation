import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class Locate extends StatefulWidget {
  static final String id = 'locate';
  final String username;
  final String groupname;
  double userlat;
  double userlong;
  Locate(
      {Key? key,
      required this.username,
      required this.groupname,
      required this.userlat,
      required this.userlong})
      : super(key: key);

  @override
  _LocateState createState() => _LocateState();
}

class _LocateState extends State<Locate> {
  @override
  void initState() {
    super.initState();
  }

  late GoogleMapController mapController;
  CollectionReference ds = FirebaseFirestore.instance.collection('locations');
  void _getData() {
    FirebaseFirestore.instance
        .collection('groups')
        .doc('Family')
        .get()
        .then((doc) {
      for (var us in doc['users']) {
        ds.doc(us).get().then((value) {
          _addMarker(value['username'], value['lat'], value['long']);
        });
      }
    });
  }

  List<Marker> markers = [];
  void _addMarker(String user, double la, double lo) {
    var _marker = Marker(
        markerId: MarkerId(user),
        position: LatLng(la, lo),
        icon: user == widget.username
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        infoWindow: InfoWindow(title: user, snippet: '$la,$lo'));
    setState(() {
      markers.add(_marker);
    });
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
    FirebaseFirestore.instance
        .collection('locations')
        .doc(widget.username)
        .set({
      'username': widget.username,
      'lat': _locationData!.latitude,
      'long': _locationData!.longitude,
    });
  }

  void onMapCreate(controller) {
    setState(() {
      mapController = controller;
    });
  }

  @override
  Widget build(BuildContext context) {
    _getData();
    location.onLocationChanged.listen((LocationData current) {
      _getLoctaion();
      widget.userlat = current.latitude!;
      widget.userlong = current.longitude!;
      _getData();
    });
    return Scaffold(
      appBar: AppBar(
        title: Text("Track Location"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Stack(
            children: [
              Container(
                height: MediaQuery.of(context).size.height - 90,
                width: double.infinity,
                child: GoogleMap(
                  onMapCreated: onMapCreate,
                  initialCameraPosition: CameraPosition(
                      target: LatLng(widget.userlat, widget.userlong),
                      zoom: 15),
                  markers: markers.toSet(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
