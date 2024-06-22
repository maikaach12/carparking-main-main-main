import 'package:carparking/pages/cote_user/MesReservationsPage.dart';
import 'package:carparking/pages/cote_user/NotificationPage.dart';
import 'package:carparking/pages/cote_user/profilepage.dart';
import 'package:carparking/pages/cote_user/reclamationuser.dart';
import 'package:carparking/pages/cote_user/reservation/listeParking.dart';
import 'package:carparking/pages/cote_user/reservation/reservation.dart';
import 'package:carparking/pages/login_signup/firstPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;

class MapPage extends StatefulWidget {
  final String userId;
  final bool showUserLocation;

  MapPage({this.userId = '', required this.showUserLocation});
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late String _userId;
  int _newNotifications = 0;

  MapController _mapController = MapController();
  int _selectedIndex = 0;
  List<Marker> _markers = [];
  LatLng _fixedLocation = LatLng(36.7516900469276, 3.469945612377954);
  List<LatLng> _routePoints = [];
  double _distance = 0.0;
  int _duration = 0;
  PolylineLayer? _routeLayer;
  String?
      _hoveredParkingName; // Variable to store the name of the hovered parking

  @override
  void initState() {
    super.initState();
    _fetchPlacesFromFirebase();
    _userId = widget.userId;
    _getNewNotifications();
  }

  void _getNewNotifications() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('notifications')
        .where('userId', isEqualTo: _userId)
        .where('isRead', isEqualTo: false)
        .get();
    setState(() {
      _newNotifications = snapshot.docs.length;
    });
  }

  void _fetchPlacesFromFirebase() async {
    QuerySnapshot snapshot =
        await FirebaseFirestore.instance.collection('parking').get();
    List<Marker> markers = [];

    snapshot.docs.forEach((doc) {
      String name = doc['nom'];
      String place = doc['place'];
      String parkingId = doc.id;

      GeoPoint position = doc['position'];
      LatLng latLng = LatLng(position.latitude, position.longitude);

      markers.add(
        Marker(
          width: 80,
          height: 80,
          point: latLng,
          child: MouseRegion(
            onEnter: (_) {
              setState(() {
                _hoveredParkingName = name;
              });
            },
            onExit: (_) {
              setState(() {
                _hoveredParkingName = null;
              });
            },
            child: GestureDetector(
              onTap: () {
                _showPlaceInfo(name, place, latLng, parkingId);
              },
              child: Column(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Color.fromARGB(255, 95, 87, 182),
                    size: 36,
                  ),
                  if (_hoveredParkingName == name)
                    Container(
                      color: Colors.white,
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    });

    setState(() {
      _markers = markers;
    });
  }

  void _showPlaceInfo(String namePark, String place, LatLng placeLatLng,
      String parkingId) async {
    _calculateRouteAndDrawLine(placeLatLng);

    final parkingDoc = await FirebaseFirestore.instance
        .collection('parking')
        .doc(parkingId)
        .get();

    final ratingDoc = await FirebaseFirestore.instance
        .collection('ratings')
        .doc(parkingId)
        .get();

    if (parkingDoc.exists &&
        parkingDoc.data()!.containsKey('placesDisponible')) {
      int placesDisponible = parkingDoc.data()!['placesDisponible'];
      double averageRating =
          ratingDoc.exists ? ratingDoc.data()!['moyenne'] : 0.0;

      double distance =
          calculateDistance(placeLatLng.latitude, placeLatLng.longitude);

      await _updateParkingDistance(parkingId, distance);

      int duration = calculateDuration(distance);

      bool isPromotionActive = false;
      String? promotionText;
      DateTime now = DateTime.now();

      if (parkingDoc.data()!.containsKey('promotion') &&
          parkingDoc.data()!['promotion'] is Map) {
        var promotion = parkingDoc.data()!['promotion'];

        if (promotion['dateDebutPromotion'] != null &&
            promotion['dateFinPromotion'] != null &&
            promotion['remiseEnPourcentage'] != null) {
          DateTime dateDebutPromotion =
              (promotion['dateDebutPromotion'] as Timestamp).toDate();
          DateTime dateFinPromotion =
              (promotion['dateFinPromotion'] as Timestamp).toDate();

          if (now.isAfter(dateDebutPromotion) &&
              now.isBefore(dateFinPromotion)) {
            isPromotionActive = true;
            promotionText = 'Promo - ${promotion['remiseEnPourcentage']}%';
          }
        }
      }

      showModalBottomSheet(
        context: context,
        builder: (context) {
          final double distanceInKm = distance / 1000;
          String imageFileName = parkingDoc.data()!['image'];
          return Stack(
            children: [
              Container(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        image: DecorationImage(
                          image: AssetImage('lib/images/$imageFileName'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            namePark,
                            style: TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            place,
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 16.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  RatingBarIndicator(
                                    rating: averageRating,
                                    itemBuilder: (context, index) => Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                    ),
                                    itemCount: 5,
                                    itemSize: 20.0,
                                    direction: Axis.horizontal,
                                  ),
                                  SizedBox(width: 8.0),
                                  Text('${averageRating.toStringAsFixed(1)}'),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 8.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.navigation,
                                      color: Colors.blueAccent),
                                  SizedBox(width: 4.0),
                                  Text('${distanceInKm.toStringAsFixed(2)} km'),
                                  SizedBox(width: 16.0),
                                  Icon(Icons.access_time,
                                      color: Colors.blueAccent),
                                  SizedBox(width: 4.0),
                                  Text('$duration min'),
                                  SizedBox(width: 8.0),
                                  Container(
                                    child: Row(
                                      children: [
                                        Icon(Icons.event_available,
                                            color: Colors.blueAccent),
                                        SizedBox(width: 4.0),
                                        Text(
                                          '$placesDisponible',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 16.0),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ReservationPage(
                                      parkingId: parkingId,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                'Réserver',
                                style: TextStyle(color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isPromotionActive)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      promotionText!,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }
  }

  void _calculateRouteAndDrawLine(LatLng destination) {
    setState(() {
      _routePoints = [_fixedLocation, destination];
      _distance =
          calculateDistance(destination.latitude, destination.longitude);
      _duration = calculateDuration(_distance);
    });
  }

  void _drawRoute() {
    if (_routePoints.isNotEmpty) {
      setState(() {
        _routeLayer = PolylineLayer(
          polylines: [
            Polyline(
              points: _routePoints,
              color: Colors.blue,
              strokeWidth: 4,
            ),
          ],
        );
      });
    }
  }

  Future<void> _updateParkingDistance(String parkingId, double distance) async {
    await FirebaseFirestore.instance
        .collection('parking')
        .doc(parkingId)
        .update({
      'distance': distance,
    });
  }

  double calculateDistance(double lat, double lon) {
    double distance = Geolocator.distanceBetween(
      _fixedLocation.latitude,
      _fixedLocation.longitude,
      lat,
      lon,
    );
    return distance;
  }

  int calculateDuration(double distance) {
    double averageSpeed = 50.0;
    double distanceInKm = distance / 1000.0;
    double timeInHours = distanceInKm / averageSpeed;
    int timeInMinutes = (timeInHours * 60).round();
    return timeInMinutes;
  }

  Widget topWidget(double screenWidth) {
    return Transform.rotate(
      angle: -35 * math.pi / 180,
      child: Container(
        width: 1.2 * screenWidth,
        height: 1.2 * screenWidth,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(150),
          gradient: const LinearGradient(
            begin: Alignment(-0.2, -0.8),
            end: Alignment.bottomCenter,
            colors: [
              Color(0x007CBFCF),
              Color(0xB316BFC4),
            ],
          ),
        ),
      ),
    );
  }

  Widget bottomWidget(double screenWidth) {
    return Container(
      width: 1.5 * screenWidth,
      height: 1.5 * screenWidth,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment(0.6, -1.1),
          end: Alignment(0.7, 0.8),
          colors: [
            Color(0xDB4BE8CC),
            Color(0x005CDBCF),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.logout, color: Colors.black),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => FirstPage()),
              (Route<dynamic> route) => false,
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.local_parking, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ListeParkingPage()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.report, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ReclamationPage(
                          userId: _userId,
                        )),
              );
            },
          ),
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.notifications, color: Colors.black),
                if (_newNotifications > 0)
                  Positioned(
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 12,
                        minHeight: 12,
                      ),
                      child: Text(
                        '$_newNotifications',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NotificationPage(userId: _userId),
                ),
              );
              _getNewNotifications();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -0.2 * screenHeight,
            left: -0.2 * screenWidth,
            child: topWidget(screenWidth),
          ),
          Positioned(
            bottom: -0.4 * screenHeight,
            right: -0.4 * screenWidth,
            child: bottomWidget(screenWidth),
          ),
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/images/blue.png'),
                fit: BoxFit.cover,
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 13, vertical: 3),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 250, 248, 248),
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: EdgeInsets.all(20),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: _fixedLocation,
                    zoom: 15.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    if (widget.showUserLocation)
                      MarkerLayer(
                        markers: _markers,
                      ),
                    if (widget.showUserLocation)
                      MarkerLayer(
                        markers: [
                          Marker(
                            width: 80,
                            height: 80,
                            point: _fixedLocation,
                            child: Icon(
                              Icons.my_location,
                              color: Colors.red,
                              size: 36,
                            ),
                          ),
                        ],
                      ),
                    if (_routeLayer != null) _routeLayer!,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Réservations',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => MesReservationsPage()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfilePage(userId: _userId),
        ),
      );
    }
  }

  @override
  void didUpdateWidget(covariant MapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _mapController.move(_fixedLocation, 20.0);
  }
}
