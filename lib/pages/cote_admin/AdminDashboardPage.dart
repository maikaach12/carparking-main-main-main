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
                    accountName: Text(widget.userEmail),
                    accountEmail: Text(widget.userId),
                    currentAccountPicture: CircleAvatar(
                      child: Icon(
                        Icons.person,
                        size: 40,
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
                  ),
                  ListTile(
                    leading: Icon(Icons.local_parking),
                    title: Text('Gérer Parking'),
                    onTap: () {
                      _navigateToPage(context, GererParkingPage());
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.error),
                    title: Text('Gérer Réclamation'),
                    onTap: () {
                      _navigateToPage(context, ReclamationAdminPage());
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.place),
                    title: Text('Gérer Place'),
                    onTap: () {
                      _navigateToPage(context, GererPlacePage());
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.book),
                    title: Text('Réservation'),
                    onTap: () {
                      _navigateToPage(context, reservationPage());
                    },
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
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
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

  Navbar({
    required this.onMenuTap,
    required this.onHomeTap,
    required this.onStatisticsTap,
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
        ],
      ),
    );
  }
}

class GererParkingPage extends StatefulWidget {
  @override
  _GererParkingPageState createState() => _GererParkingPageState();
}

class _GererParkingPageState extends State<GererParkingPage> {
  Future<void> _ajouterPromotion(String parkingId) async {
    // Ouvrir une boîte de dialogue ou une page séparée pour saisir les détails de la promotion
    final remiseEnPourcentage = await showDialog<double>(
      context: context,
      builder: (context) => PromotionDialog(
        parkingId: parkingId,
      ),
    );

    if (remiseEnPourcentage != null) {
      final dateDebutPromotion = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2100),
      );

      if (dateDebutPromotion != null) {
        final dateFinPromotion = await showDatePicker(
          context: context,
          initialDate: dateDebutPromotion
              .add(Duration(days: 30)), // Durée par défaut de 30 jours
          firstDate: dateDebutPromotion,
          lastDate: DateTime(2100),
        );

        if (dateFinPromotion != null) {
          // Ajouter la promotion au document de parking
          await FirebaseFirestore.instance
              .collection('parking')
              .doc(parkingId)
              .update({
            'promotion': {
              'remiseEnPourcentage': remiseEnPourcentage,
              'dateDebutPromotion': Timestamp.fromDate(dateDebutPromotion),
              'dateFinPromotion': Timestamp.fromDate(dateFinPromotion),
            },
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gérer Parking'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('parking').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Une erreur s\'est produite');
          }

          if (!snapshot.hasData) {
            return CircularProgressIndicator();
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final parkingDoc = snapshot.data!.docs[index];
              final parkingId = parkingDoc.id;

              return ListTile(
                title: Text(parkingDoc['nom']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        // Code pour modifier le parking
                      },
                      icon: Icon(Icons.edit),
                    ),
                    IconButton(
                      onPressed: () => _ajouterPromotion(parkingId),
                      icon: Icon(Icons.add_box),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
