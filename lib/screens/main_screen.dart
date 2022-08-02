import 'dart:async';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:riders_app/assistants/assistant_methods.dart';
import 'package:riders_app/infoHandler/app_info.dart';
import 'package:riders_app/screens/search_places_screen.dart';
import 'package:riders_app/widgets/my_drawer.dart';
import '../assistants/geofire_assistant.dart';
import '../global/global.dart';
import '../models/active_nearby_available_drivers.dart';
import '../widgets/pay_fare_amount_dialog.dart';
import '../widgets/progress_dialog.dart';
import 'rate_driver_screen.dart';
import 'select_nearest_active_driver_screen.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();
  GoogleMapController? _newGoogleMapController;

  static const CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(12.9716, 77.5946),
    zoom: 14.4746,
  );

  GlobalKey<ScaffoldState> _sKey = GlobalKey<ScaffoldState>();
  double _searchLocationContainerHeight = 220;
  double _waitingResponseFromDriverContainerHeight = 0;
  double _assignedDriverInfoContainerHeight = 0;

  Position? _userCurrentPosition;
  var _geoLocator = Geolocator();

  LocationPermission? _locationPermission;
  double _bottomPaddingOfMap = 0;

  List<LatLng> _pLineCoOrdinatesList = [];
  Set<Polyline> _polyLineSet = {};

  // the pin marker in the map (origion marker and destination marker)
  Set<Marker> _markersSet = {};
  // the circle marker in the map (circle for origion and circle for destination)
  Set<Circle> _circlesSet = {};

  // used to avoid null check operator error that may occur duo to bad connection
  String _userName = 'Your name';
  String _userEmail = 'Your email';

  bool _openNavigationDrawer = true;
  bool _activeNearbyDriverKeysLoaded = false;

  List<ActiveNearbyAvailableDrivers> onlineNearByAvailableDriversList = [];
  BitmapDescriptor? _activeNearbyIcon;

  DatabaseReference? _referenceRideRequest;
  String _driverRideStatus = "Driver is Coming";
  StreamSubscription<DatabaseEvent>?
      _tripRideRequestInfoStreamSubscription; // L114
  String _userRideRequestStatus = '';
  bool _requestPositionInfo = true;

  _blackThemeGoogleMap() {
    _newGoogleMapController!.setMapStyle('''
                    [
                      {
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#242f3e"
                          }
                        ]
                      },
                      {
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#746855"
                          }
                        ]
                      },
                      {
                        "elementType": "labels.text.stroke",
                        "stylers": [
                          {
                            "color": "#242f3e"
                          }
                        ]
                      },
                      {
                        "featureType": "administrative.locality",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#d59563"
                          }
                        ]
                      },
                      {
                        "featureType": "poi",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#d59563"
                          }
                        ]
                      },
                      {
                        "featureType": "poi.park",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#263c3f"
                          }
                        ]
                      },
                      {
                        "featureType": "poi.park",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#6b9a76"
                          }
                        ]
                      },
                      {
                        "featureType": "road",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#38414e"
                          }
                        ]
                      },
                      {
                        "featureType": "road",
                        "elementType": "geometry.stroke",
                        "stylers": [
                          {
                            "color": "#212a37"
                          }
                        ]
                      },
                      {
                        "featureType": "road",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#9ca5b3"
                          }
                        ]
                      },
                      {
                        "featureType": "road.highway",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#746855"
                          }
                        ]
                      },
                      {
                        "featureType": "road.highway",
                        "elementType": "geometry.stroke",
                        "stylers": [
                          {
                            "color": "#1f2835"
                          }
                        ]
                      },
                      {
                        "featureType": "road.highway",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#f3d19c"
                          }
                        ]
                      },
                      {
                        "featureType": "transit",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#2f3948"
                          }
                        ]
                      },
                      {
                        "featureType": "transit.station",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#d59563"
                          }
                        ]
                      },
                      {
                        "featureType": "water",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#17263c"
                          }
                        ]
                      },
                      {
                        "featureType": "water",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#515c6d"
                          }
                        ]
                      },
                      {
                        "featureType": "water",
                        "elementType": "labels.text.stroke",
                        "stylers": [
                          {
                            "color": "#17263c"
                          }
                        ]
                      }
                    ]
                ''');
  }

  _checkIfLocationPermissionAllowed() async {
    // ask user for permission
    _locationPermission = await Geolocator.requestPermission();
    // if not granted ask again
    if (_locationPermission == LocationPermission.denied) {
      _locationPermission = await Geolocator.requestPermission();
    }
  }

  _locateUserPosition() async {
    Position cPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    _userCurrentPosition = cPosition;

    LatLng latLngPosition =
        LatLng(_userCurrentPosition!.latitude, _userCurrentPosition!.longitude);
    CameraPosition cameraPosition =
        CameraPosition(target: latLngPosition, zoom: 14);

    _newGoogleMapController!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    String humanReadableAddress =
        await AssistantMethods.searchAddressForGeographicCoOrdinates(
            _userCurrentPosition!, context);
    print('This is your address = ' + humanReadableAddress);

    _userName = userModelCurrentInfo!.name!;
    _userEmail = userModelCurrentInfo!.email!;

    initializeGeoFireListener();

    // L122
    AssistantMethods.readTripsKeysForOnlineUser(context);
  }

  @override
  void initState() {
    super.initState();
    _checkIfLocationPermissionAllowed();
  }

  _saveRideRequestInformation() {
    //1. save the RideRequest Information
    // .push() generate a unique id
    _referenceRideRequest =
        FirebaseDatabase.instance.ref().child('All Ride Requests').push();

    var originLocation =
        Provider.of<AppInfo>(context, listen: false).userPickUpLocation;
    var destinationLocation =
        Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    Map originLocationMap = {
      'latitude': originLocation!.locationLatitude.toString(),
      'longitude': originLocation.locationLongitude.toString(),
    };

    Map destinationLocationMap = {
      'latitude': destinationLocation!.locationLatitude.toString(),
      'longitude': destinationLocation.locationLongitude.toString(),
    };

    Map userInformationMap = {
      'origin': originLocationMap,
      'destination': destinationLocationMap,
      'time': DateTime.now().toString(),
      'userName': userModelCurrentInfo!.name,
      'userPhone': userModelCurrentInfo!.phone,
      'originAddress': originLocation.locationName,
      'destinationAddress': destinationLocation.locationName,
      'driverId': 'waiting',
    };

    _referenceRideRequest!.set(userInformationMap);

    // s34
    // onValue.listen listen for any change on 'All Ride Requests' node in firebase
    _tripRideRequestInfoStreamSubscription =
        _referenceRideRequest!.onValue.listen((eventSnap) async {
      if (eventSnap.snapshot.value == null) {
        return;
      }

      if ((eventSnap.snapshot.value as Map)['car_details'] != null) {
        setState(() {
          driverCarDetails =
              (eventSnap.snapshot.value as Map)['car_details'].toString();
        });
      }

      if ((eventSnap.snapshot.value as Map)['driverPhone'] != null) {
        setState(() {
          driverPhone =
              (eventSnap.snapshot.value as Map)['driverPhone'].toString();
        });
      }

      if ((eventSnap.snapshot.value as Map)['driverName'] != null) {
        setState(() {
          driverName =
              (eventSnap.snapshot.value as Map)['driverName'].toString();
        });
      }

      if ((eventSnap.snapshot.value as Map)['status'] != null) {
        _userRideRequestStatus =
            (eventSnap.snapshot.value as Map)['status'].toString();
      }

      if ((eventSnap.snapshot.value as Map)['driverLocation'] != null) {
        double driverCurrentPositionLat = double.parse(
            (eventSnap.snapshot.value as Map)['driverLocation']['latitude']
                .toString());
        double driverCurrentPositionLng = double.parse(
            (eventSnap.snapshot.value as Map)['driverLocation']['longitude']
                .toString());

        LatLng driverCurrentPositionLatLng =
            LatLng(driverCurrentPositionLat, driverCurrentPositionLng);

        //status = accepted
        if (_userRideRequestStatus == 'accepted') {
          updateArrivalTimeToUserPickupLocation(driverCurrentPositionLatLng);
        }

        //status = arrived
        if (_userRideRequestStatus == 'arrived') {
          setState(() {
            _driverRideStatus = 'Driver has Arrived';
          });
        }

        ////status = ontrip
        if (_userRideRequestStatus == 'ontrip') {
          updateReachingTimeToUserDropOffLocation(driverCurrentPositionLatLng);
        }

        // s35
        //status = ended
        if (_userRideRequestStatus == 'ended') {
          if ((eventSnap.snapshot.value as Map)['fareAmount'] != null) {
            double fareAmount = double.parse(
                (eventSnap.snapshot.value as Map)['fareAmount'].toString());

            var response = await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext c) => PayFareAmountDialog(
                fareAmount: fareAmount,
              ),
            );

            if (response == 'cashPayed') {
              //user can rate the driver now
              if ((eventSnap.snapshot.value as Map)['driverId'] != null) {
                String assignedDriverId =
                    (eventSnap.snapshot.value as Map)['driverId'].toString();

                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (c) => RateDriverScreen(
                              assignedDriverId: assignedDriverId,
                            )));

                _referenceRideRequest!.onDisconnect();
                _tripRideRequestInfoStreamSubscription!.cancel();
              }
            }
          }
        }
      }
    });

    // --------------------------
    onlineNearByAvailableDriversList =
        GeoFireAssistant.activeNearbyAvailableDriversList;
    _searchNearestOnlineDrivers();
  }

  updateArrivalTimeToUserPickupLocation(driverCurrentPositionLatLng) async {
    if (_requestPositionInfo == true) {
      _requestPositionInfo = false;

      LatLng userPickUpPosition = LatLng(
          _userCurrentPosition!.latitude, _userCurrentPosition!.longitude);

      var directionDetailsInfo =
          await AssistantMethods.obtainOriginToDestinationDirectionDetails(
        driverCurrentPositionLatLng,
        userPickUpPosition,
      );

      if (directionDetailsInfo == null) {
        return;
      }

      setState(() {
        _driverRideStatus = "Driver is Coming :: " +
            directionDetailsInfo.durationText.toString();
      });

      _requestPositionInfo = true;
    }
  }

  updateReachingTimeToUserDropOffLocation(driverCurrentPositionLatLng) async {
    if (_requestPositionInfo == true) {
      _requestPositionInfo = false;

      var dropOffLocation =
          Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

      LatLng userDestinationPosition = LatLng(
          dropOffLocation!.locationLatitude!,
          dropOffLocation.locationLongitude!);

      var directionDetailsInfo =
          await AssistantMethods.obtainOriginToDestinationDirectionDetails(
        driverCurrentPositionLatLng,
        userDestinationPosition,
      );

      if (directionDetailsInfo == null) {
        return;
      }

      setState(() {
        _driverRideStatus = "Going towards Destination :: " +
            directionDetailsInfo.durationText.toString();
      });

      _requestPositionInfo = true;
    }
  }

  _searchNearestOnlineDrivers() async {
    //no active driver available
    if (onlineNearByAvailableDriversList.length == 0) {
      //cancel/delete the RideRequest Information
      _referenceRideRequest!.remove();

      setState(() {
        _polyLineSet.clear();
        _markersSet.clear();
        _circlesSet.clear();
        _pLineCoOrdinatesList.clear();
      });

      Fluttertoast.showToast(
          msg:
              'No Online Nearest Driver Available. Search Again after some time, Restarting App Now.',
          backgroundColor: Colors.white,
          textColor: Colors.black);

      Future.delayed(const Duration(milliseconds: 4000), () {
        // MyApp.restartApp(context);
        Phoenix.rebirth(context); // restart the app
        // SystemNavigator.pop();
      });

      return;
    }

    //active driver available
    await _retrieveOnlineDriversInformation(onlineNearByAvailableDriversList);

    var response = await Navigator.of(context).push(MaterialPageRoute(
        builder: (c) => SelectNearestActiveDriversScreen(
            referenceRideRequest: _referenceRideRequest)));
    if (response == 'driverChoosed') {
      FirebaseDatabase.instance
          .ref()
          .child('drivers')
          .child(chosenDriverId!)
          .once()
          .then((snap) {
        if (snap.snapshot.value != null) {
          //send notification to that specific driver
          _sendNotificationToDriverNow(chosenDriverId!);

          //Display Waiting Response UI from a Driver
          _showWaitingResponseFromDriverUI();

          // .onValue.listen() L111
          //Response from a Driver
          FirebaseDatabase.instance
              .ref()
              .child("drivers")
              .child(chosenDriverId!)
              .child("newRideStatus")
              .onValue
              .listen((eventSnapshot) {
            //1. driver has cancel the rideRequest :: Push Notification
            // (newRideStatus = idle)
            if (eventSnapshot.snapshot.value == "idle") {
              Fluttertoast.showToast(
                  msg:
                      "The driver has cancelled your request. Please choose another driver.");

              Future.delayed(const Duration(milliseconds: 3000), () {
                Fluttertoast.showToast(msg: "Please Restart App Now.");

                SystemNavigator.pop();
              });
            }

            //2. driver has accept the rideRequest :: Push Notification
            // (newRideStatus = accepted)
            if (eventSnapshot.snapshot.value == "accepted") {
              //design and display ui for displaying assigned driver information
              _showUIForAssignedDriverInfo();
            }
          });
        } else {
          Fluttertoast.showToast(
              msg: 'This driver is not online anymore. Try again');
        }
      });
    }
  }

  _showUIForAssignedDriverInfo() {
    setState(() {
      _waitingResponseFromDriverContainerHeight = 0;
      _searchLocationContainerHeight = 0;
      _assignedDriverInfoContainerHeight = 240;
    });
  }

  _showWaitingResponseFromDriverUI() {
    setState(() {
      _searchLocationContainerHeight = 0;
      _waitingResponseFromDriverContainerHeight = 220;
    });
  }

  _sendNotificationToDriverNow(String chosenDriverId) {
    //assign/SET rideRequestId to newRideStatus in
    // Drivers Parent node for that specific choosen driver
    FirebaseDatabase.instance
        .ref()
        .child('drivers')
        .child(chosenDriverId)
        .child('newRideStatus')
        .set(_referenceRideRequest!.key);

    //automate the push notification service
    FirebaseDatabase.instance
        .ref()
        .child('drivers')
        .child(chosenDriverId)
        .child('token')
        .once()
        .then((snap) {
      if (snap.snapshot.value != null) {
        String deviceRegistrationToken = snap.snapshot.value.toString();

        //send Notification Now
        AssistantMethods.sendNotificationToDriverNow(
          deviceRegistrationToken,
          _referenceRideRequest!.key.toString(),
          context,
        );

        Fluttertoast.showToast(msg: 'Notification sent Successfully.');
      } else {
        // L108
        Fluttertoast.showToast(msg: 'Please choose another driver.');
        return;
      }
    });
  }

  _retrieveOnlineDriversInformation(List onlineNearestDriversList) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref().child('drivers');
    for (int i = 0; i < onlineNearestDriversList.length; i++) {
      await ref
          .child(onlineNearestDriversList[i].driverId.toString())
          .once()
          .then((dataSnapshot) {
        var driverKeyInfo = dataSnapshot.snapshot.value;
        dList.add(driverKeyInfo);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _createActiveNearByDriverIconMarker();
    // Notification bar height
    var statusBarHeight = MediaQuery.of(context).viewPadding.top;
    return Scaffold(
      key: _sKey,
      drawer: Container(
        width: 260,
        child: Theme(
          data: Theme.of(context).copyWith(canvasColor: Colors.black),
          child: MyDrawer(
            name: _userName,
            email: _userEmail,
          ),
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(
                bottom: _bottomPaddingOfMap, top: statusBarHeight),
            mapType: MapType.normal,
            rotateGesturesEnabled: false,
            myLocationEnabled: true,
            zoomGesturesEnabled: true,
            zoomControlsEnabled: true,
            initialCameraPosition: _kGooglePlex,
            polylines: _polyLineSet,
            markers: _markersSet,
            circles: _circlesSet,
            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              _newGoogleMapController = controller;

              // for black theme google map
              _blackThemeGoogleMap();

              setState(() {
                _bottomPaddingOfMap = 240;
              });

              _locateUserPosition();
            },
          ),

          //custom hamburger button for drawer
          Positioned(
            top: 50,
            left: 25,
            child: GestureDetector(
              onTap: () {
                if (_openNavigationDrawer) {
                  _sKey.currentState!.openDrawer();
                } else {
                  //restart-refresh-minimize app progmatically
                  SystemNavigator.pop();
                }
              },
              child: CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(
                  _openNavigationDrawer ? Icons.menu : Icons.close,
                  color: Colors.black54,
                ),
              ),
            ),
          ),

          //ui for searching location
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedSize(
              curve: Curves.easeIn,
              duration: const Duration(milliseconds: 120),
              child: Container(
                height: _searchLocationContainerHeight,
                decoration: const BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    topLeft: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Column(
                    children: [
                      //from
                      GestureDetector(
                        onTap: () {
                          // update user current location when clicked
                          _locateUserPosition();
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.add_location_alt_outlined,
                              color: Colors.grey,
                            ),
                            const SizedBox(
                              width: 12.0,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'From',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                ),
                                Text(
                                  Provider.of<AppInfo>(context)
                                              .userPickUpLocation !=
                                          null
                                      ? '${(Provider.of<AppInfo>(context).userPickUpLocation!.locationName!).substring(0, 25)}...'
                                      : 'Not getting your address',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10.0),

                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey,
                      ),

                      const SizedBox(height: 16.0),

                      //to
                      GestureDetector(
                        onTap: () async {
                          // go to search places screen
                          var responseFromSearchScreen = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => SearchPlacesScreen(),
                              ));

                          if (responseFromSearchScreen == 'obtainedDropoff') {
                            setState(() {
                              _openNavigationDrawer = false;
                            });
                            //draw routes - draw polyline
                            await _drawPolyLineFromOriginToDestination();
                          }
                        },
                        child: Row(
                          children: [
                            const Icon(
                              Icons.add_location_alt_outlined,
                              color: Colors.grey,
                            ),
                            const SizedBox(
                              width: 12.0,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'To',
                                  style: TextStyle(
                                      color: Colors.grey, fontSize: 12),
                                ),
                                Text(
                                  Provider.of<AppInfo>(context)
                                              .userDropOffLocation !=
                                          null
                                      ? Provider.of<AppInfo>(context)
                                          .userDropOffLocation!
                                          .locationName!
                                      : 'Where to go?',
                                  style: const TextStyle(
                                      color: Colors.grey, fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10.0),

                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey,
                      ),

                      const SizedBox(height: 16.0),

                      ElevatedButton(
                        child: const Text(
                          'Request a Ride',
                        ),
                        onPressed: () {
                          if (Provider.of<AppInfo>(context, listen: false)
                                  .userDropOffLocation !=
                              null) {
                            _saveRideRequestInformation();
                          } else {
                            Fluttertoast.showToast(
                                msg: 'Please select destination location',
                                backgroundColor: Colors.white,
                                textColor: Colors.black);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                            primary: Colors.green,
                            textStyle: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          //ui for waiting response from driver
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: _waitingResponseFromDriverContainerHeight,
              decoration: const BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  topLeft: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: AnimatedTextKit(
                    animatedTexts: [
                      FadeAnimatedText(
                        'Waiting for Response\nfrom Driver',
                        duration: const Duration(seconds: 6),
                        textAlign: TextAlign.center,
                        textStyle: const TextStyle(
                            fontSize: 30.0,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      ScaleAnimatedText(
                        'Please wait...',
                        duration: const Duration(seconds: 10),
                        textAlign: TextAlign.center,
                        textStyle: const TextStyle(
                            fontSize: 32.0,
                            color: Colors.white,
                            fontFamily: 'Canterbury'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          //ui for displaying assigned driver information
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: _assignedDriverInfoContainerHeight,
              decoration: const BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  topLeft: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //status of ride
                    Center(
                      child: Text(
                        _driverRideStatus,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white54,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 20.0,
                    ),

                    const Divider(
                      height: 2,
                      thickness: 2,
                      color: Colors.white54,
                    ),

                    const SizedBox(
                      height: 20.0,
                    ),

                    //driver vehicle details
                    Text(
                      driverCarDetails,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white54,
                      ),
                    ),

                    const SizedBox(
                      height: 2.0,
                    ),

                    //driver name
                    Text(
                      driverName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white54,
                      ),
                    ),

                    const SizedBox(
                      height: 20.0,
                    ),

                    const Divider(
                      height: 2,
                      thickness: 2,
                      color: Colors.white54,
                    ),

                    const SizedBox(
                      height: 20.0,
                    ),

                    //call driver button
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          primary: Colors.green,
                        ),
                        icon: const Icon(
                          Icons.phone_android,
                          color: Colors.black54,
                          size: 22,
                        ),
                        label: const Text(
                          "Call Driver",
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _drawPolyLineFromOriginToDestination() async {
    var originPosition =
        Provider.of<AppInfo>(context, listen: false).userPickUpLocation;
    var destinationPosition =
        Provider.of<AppInfo>(context, listen: false).userDropOffLocation;

    var originLatLng = LatLng(
        originPosition!.locationLatitude!, originPosition.locationLongitude!);
    var destinationLatLng = LatLng(destinationPosition!.locationLatitude!,
        destinationPosition.locationLongitude!);

    showDialog(
      context: context,
      builder: (BuildContext context) => ProgressDialog(
        message: 'Please wait...',
      ),
    );

    var directionDetailsInfo =
        await AssistantMethods.obtainOriginToDestinationDirectionDetails(
            originLatLng, destinationLatLng);

    setState(() {
      // to use it with calculateFareAmountFromOriginToDestination() in select_nearest_active_driver_screen.dart
      tripDirectionDetailsInfo = directionDetailsInfo;
    });

    Navigator.pop(context);

    print('These are points = ');
    print(directionDetailsInfo!.encodedPoints);

    PolylinePoints pPoints = PolylinePoints();
    List<PointLatLng> decodedPolyLinePointsResultList =
        pPoints.decodePolyline(directionDetailsInfo.encodedPoints!);

    // clear the list of _polylineCoordinates before adding a new instance to it.
    _pLineCoOrdinatesList.clear();

    if (decodedPolyLinePointsResultList.isNotEmpty) {
      decodedPolyLinePointsResultList.forEach((PointLatLng pointLatLng) {
        _pLineCoOrdinatesList
            .add(LatLng(pointLatLng.latitude, pointLatLng.longitude));
      });
    }
    _polyLineSet.clear();

    setState(() {
      Polyline polyline = Polyline(
        color: Colors.purpleAccent,
        polylineId: const PolylineId('PolylineID'), // polylineId can be any id
        jointType: JointType.round,
        points: _pLineCoOrdinatesList,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        geodesic: true,
      );

      _polyLineSet.add(polyline);
    });

    LatLngBounds boundsLatLng;
    if (originLatLng.latitude > destinationLatLng.latitude &&
        originLatLng.longitude > destinationLatLng.longitude) {
      boundsLatLng =
          LatLngBounds(southwest: destinationLatLng, northeast: originLatLng);
    } else if (originLatLng.longitude > destinationLatLng.longitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(originLatLng.latitude, destinationLatLng.longitude),
        northeast: LatLng(destinationLatLng.latitude, originLatLng.longitude),
      );
    } else if (originLatLng.latitude > destinationLatLng.latitude) {
      boundsLatLng = LatLngBounds(
        southwest: LatLng(destinationLatLng.latitude, originLatLng.longitude),
        northeast: LatLng(originLatLng.latitude, destinationLatLng.longitude),
      );
    } else {
      boundsLatLng =
          LatLngBounds(southwest: originLatLng, northeast: destinationLatLng);
    }

    _newGoogleMapController!
        .animateCamera(CameraUpdate.newLatLngBounds(boundsLatLng, 65));

    Marker originMarker = Marker(
      markerId: const MarkerId('originID'),
      infoWindow:
          InfoWindow(title: originPosition.locationName, snippet: 'Origin'),
      position: originLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
    );

    Marker destinationMarker = Marker(
      markerId: const MarkerId('destinationID'),
      infoWindow: InfoWindow(
          title: destinationPosition.locationName, snippet: 'Destination'),
      position: destinationLatLng,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
    );

    setState(() {
      _markersSet.add(originMarker);
      _markersSet.add(destinationMarker);
    });

    Circle originCircle = Circle(
      circleId: const CircleId('originID'),
      fillColor: Colors.green,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white, // border of the circle
      center: originLatLng,
    );

    Circle destinationCircle = Circle(
      circleId: const CircleId('destinationID'),
      fillColor: Colors.red,
      radius: 12,
      strokeWidth: 3,
      strokeColor: Colors.white,
      center: destinationLatLng,
    );

    setState(() {
      _circlesSet.add(originCircle);
      _circlesSet.add(destinationCircle);
    });
  }

  initializeGeoFireListener() {
    Geofire.initialize('activeDrivers');

    // third arg of queryAtLocation() represnets distance in km
    Geofire.queryAtLocation(_userCurrentPosition!.latitude,
            _userCurrentPosition!.longitude, 10)!
        .listen((map) {
      print(map);
      if (map != null) {
        var callBack = map['callBack'];

        //latitude will be retrieved from map['latitude']
        //longitude will be retrieved from map['longitude']

        switch (callBack) {
          //whenever any driver become active/online
          case Geofire.onKeyEntered:
            ActiveNearbyAvailableDrivers activeNearbyAvailableDriver =
                ActiveNearbyAvailableDrivers();
            activeNearbyAvailableDriver.locationLatitude = map['latitude'];
            activeNearbyAvailableDriver.locationLongitude = map['longitude'];
            activeNearbyAvailableDriver.driverId = map['key'];
            GeoFireAssistant.activeNearbyAvailableDriversList
                .add(activeNearbyAvailableDriver);
            if (_activeNearbyDriverKeysLoaded == true) {
              _displayActiveDriversOnUsersMap();
            }
            break;

          //whenever any driver become non-active/offline
          case Geofire.onKeyExited:
            GeoFireAssistant.deleteOfflineDriverFromList(map['key']);
            _displayActiveDriversOnUsersMap();
            break;

          //whenever driver moves - update driver location
          case Geofire.onKeyMoved:
            ActiveNearbyAvailableDrivers activeNearbyAvailableDriver =
                ActiveNearbyAvailableDrivers();
            activeNearbyAvailableDriver.locationLatitude = map['latitude'];
            activeNearbyAvailableDriver.locationLongitude = map['longitude'];
            activeNearbyAvailableDriver.driverId = map['key'];
            GeoFireAssistant.updateActiveNearbyAvailableDriverLocation(
                activeNearbyAvailableDriver);
            _displayActiveDriversOnUsersMap();
            break;

          //display those online/active drivers on user's map
          case Geofire.onGeoQueryReady:
            _activeNearbyDriverKeysLoaded = true;
            _displayActiveDriversOnUsersMap();
            break;
        }
      }

      setState(() {});
    });
  }

  _displayActiveDriversOnUsersMap() {
    setState(() {
      _markersSet.clear();
      _circlesSet.clear();

      Set<Marker> driversMarkerSet = Set<Marker>();

      for (ActiveNearbyAvailableDrivers eachDriver
          in GeoFireAssistant.activeNearbyAvailableDriversList) {
        LatLng eachDriverActivePosition =
            LatLng(eachDriver.locationLatitude!, eachDriver.locationLongitude!);

        Marker marker = Marker(
          markerId: MarkerId('driver${eachDriver.driverId!}'),
          position: eachDriverActivePosition,
          icon: _activeNearbyIcon!,
          rotation: 360,
        );

        driversMarkerSet.add(marker);
      }

      setState(() {
        _markersSet = driversMarkerSet;
      });
    });
  }

  _createActiveNearByDriverIconMarker() {
    if (_activeNearbyIcon == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: const Size(2, 2));
      BitmapDescriptor.fromAssetImage(
              imageConfiguration, 'assets/images/car.png')
          .then((value) {
        _activeNearbyIcon = value;
      });
    }
  }
}
