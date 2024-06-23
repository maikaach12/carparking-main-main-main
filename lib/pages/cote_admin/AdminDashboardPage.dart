import 'package:carparking/pages/cote_admin/gerer/Gerer_compte.dart';
import 'package:carparking/pages/cote_admin/gerer/Gerer_parking.dart';
import 'package:carparking/pages/cote_admin/promotion.dart';
import 'package:carparking/pages/cote_admin/stat/ReclamationStatistics.dart';
import 'package:carparking/pages/cote_admin/stat/ReservationFrequencyPage.dart';
import 'package:carparking/pages/cote_admin/stat/UserStatistics.dart';
import 'package:carparking/pages/cote_admin/gerer/gererplace.dart';
import 'package:carparking/pages/cote_admin/stat/carstat.dart';
import 'package:carparking/pages/cote_admin/stat/navbar.dart';
import 'package:carparking/pages/cote_admin/stat/parkinglistviewadmin.dart';
import 'package:carparking/pages/cote_admin/gerer/reclamation_admin.dart';
import 'package:carparking/pages/cote_admin/gerer/reservationadmin.dart';
import 'package:carparking/pages/cote_admin/stat/parkingstat.dart';
import 'package:carparking/pages/cote_admin/stat/placeStat.dart';
import 'package:carparking/pages/cote_admin/stat/reservStati.dart';
import 'package:carparking/pages/cote_admin/stat/reservationchart.dart';
import 'package:carparking/pages/cote_admin/stat/topUser.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDashboardPage extends StatefulWidget {
  final String userId;
  final String userEmail;

  AdminDashboardPage({required this.userId, required this.userEmail});

  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _showSidebar = false;
  Widget _currentPage = ParkingListView(
    parkingsCollection: FirebaseFirestore.instance.collection('parking'),
  );

  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  void _navigateToReservationFrequencyPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Chart(
          reservationsCollection:
              FirebaseFirestore.instance.collection('reservation'),
        ),
      ),
    );
  }

  void _showNotificationForm() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return NotificationForm();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AnimatedContainer(
            duration: Duration(milliseconds: 300),
            width: _showSidebar ? 250 : 0,
            child: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  UserAccountsDrawerHeader(
                    accountName: Text(
                      widget.userEmail,
                      style: TextStyle(color: Colors.white),
                    ),
                    accountEmail: Text(
                      widget.userId,
                      style: TextStyle(color: Colors.white),
                    ),
                    currentAccountPicture: CircleAvatar(
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.blue,
                      ),
                      backgroundColor: Colors.white,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                    ),
                  ),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Gérer Compte'),
                    onTap: () {
                      _navigateToPage(context, ManageAccountsPage());
                    },
                    hoverColor: Colors.grey[100],
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.local_parking),
                    title: Text('Gérer Parking'),
                    onTap: () {
                      _navigateToPage(context, GererParkingPage());
                    },
                    hoverColor: Colors.grey[100],
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.error),
                    title: Text('Gérer Réclamation'),
                    onTap: () {
                      _navigateToPage(context, ReclamationAdminPage());
                    },
                    hoverColor: Colors.grey[100],
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.place),
                    title: Text('Gérer Place'),
                    onTap: () {
                      _navigateToPage(context, GererPlacePage());
                    },
                    hoverColor: Colors.grey[100],
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.book),
                    title: Text('Réservation'),
                    onTap: () {
                      _navigateToPage(context, reservationPage());
                    },
                    hoverColor: Colors.grey[100],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Navbar(
                  onMenuTap: () {
                    setState(() {
                      _showSidebar = !_showSidebar;
                    });
                  },
                  onHomeTap: () {
                    setState(() {
                      _currentPage = ParkingListView(
                        parkingsCollection:
                            FirebaseFirestore.instance.collection('parking'),
                      );
                    });
                  },
                  onStatisticsTap: () =>
                      _navigateToReservationFrequencyPage(context),
                  onNotificationTap: _showNotificationForm,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (!_showSidebar)
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: TopUserWidget(),
                          ),
                        Wrap(
                          spacing: 10.0,
                          runSpacing: 10.0,
                          children: [
                            UserStatistics(),
                            ReclamationStatistics(),
                            PlaceStatistics(),
                            CarStatistics(),
                            ParkingStatistics(),
                            ReservationStatistics(),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.all(20),
                          child: _currentPage,
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

class Navbar extends StatelessWidget {
  final VoidCallback onMenuTap;
  final VoidCallback onHomeTap;
  final VoidCallback onStatisticsTap;
  final VoidCallback onNotificationTap;

  Navbar({
    required this.onMenuTap,
    required this.onHomeTap,
    required this.onStatisticsTap,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: Colors.grey[200],
      child: Row(
        children: [
          IconButton(
            onPressed: onMenuTap,
            icon: Icon(Icons.menu),
          ),
          Spacer(),
          IconButton(
            onPressed: onHomeTap,
            icon: Icon(Icons.home),
          ),
          IconButton(
            onPressed: onStatisticsTap,
            icon: Icon(Icons.bar_chart),
          ),
          IconButton(
            onPressed: onNotificationTap,
            icon: Icon(Icons.notifications),
          ),
        ],
      ),
    );
  }
}

class NotificationForm extends StatefulWidget {
  @override
  _NotificationFormState createState() => _NotificationFormState();
}

class _NotificationFormState extends State<NotificationForm> {
  final _formKey = GlobalKey<FormState>();
  String _description = '';

  void _sendNotification() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      for (var userDoc in usersSnapshot.docs) {
        await FirebaseFirestore.instance.collection('notifications').add({
          'type': 'Rappel',
          'description': _description,
          'userId': userDoc.id,
          'timestamp': Timestamp.now(),
          'isRead': false,
        });
      }

      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Envoyer une Notification'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: 'Rappel',
              enabled: false,
              decoration: InputDecoration(labelText: 'Type'),
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Description'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer une description';
                }
                return null;
              },
              onSaved: (value) {
                _description = value!;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('Annuler', style: TextStyle(color: Colors.blue)),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: Text('OK', style: TextStyle(color: Colors.blue)),
          onPressed: _sendNotification,
        ),
      ],
    );
  }
}
