import 'package:carparking/pages/cote_user/modifier_reservation_page.dart';
import 'package:carparking/pages/cote_user/reservation/afficherticket.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MesReservationsPage extends StatefulWidget {
  @override
  _MesReservationsPageState createState() => _MesReservationsPageState();
}

class _MesReservationsPageState extends State<MesReservationsPage> {
  late String userId;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser!.uid;
  }

  String _getReservationStatus(
      Timestamp debutTimestamp, Timestamp finTimestamp, String etat) {
    if (etat == 'Annulée') {
      return 'Annulée';
    }

    DateTime currentTime = DateTime.now();
    DateTime debutTime = debutTimestamp.toDate();
    DateTime finTime = finTimestamp.toDate();

    if (currentTime.isBefore(debutTime) ||
        currentTime.isAtSameMomentAs(debutTime)) {
      return 'En cours';
    } else if (currentTime.isAfter(finTime)) {
      return 'Terminé';
    } else {
      return 'En cours';
    }
  }

  Future<void> _supprimerReservation(String reservationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('reservation')
          .doc(reservationId)
          .delete();
      setState(() {});
    } catch (e) {
      print('Erreur lors de la suppression de la réservation : $e');
    }
  }

  Future<void> _annulerReservation(String reservationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('reservation')
          .doc(reservationId)
          .update({'etat': 'Annulée'});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Réservation annulée avec succès'),
          duration: Duration(seconds: 2),
        ),
      );

      setState(() {});
    } catch (e) {
      print('Erreur lors de l\'annulation de la réservation : $e');
    }
  }

  Future<void> _mettreAJourMoyenneEvaluation(
      String idParking, int evaluation) async {
    try {
      DocumentSnapshot ratingSnapshot = await FirebaseFirestore.instance
          .collection('ratings')
          .doc(idParking)
          .get();

      Map<String, dynamic>? ratingData =
          ratingSnapshot.data() as Map<String, dynamic>?;

      double ancienneMoyenne = ratingData?['moyenne'] ?? 0.0;
      int nombreVotes = ratingData?['nombreVotes'] ?? 0;

      double nouvelleMoyenne =
          ((ancienneMoyenne * nombreVotes) + evaluation) / (nombreVotes + 1);
      int nouveauNombreVotes = nombreVotes + 1;

      await FirebaseFirestore.instance
          .collection('ratings')
          .doc(idParking)
          .set({
        'moyenne': nouvelleMoyenne,
        'nombreVotes': nouveauNombreVotes,
        'idParking': idParking,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Erreur lors de la mise à jour de la moyenne d\'évaluation : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes Réservations', textAlign: TextAlign.center),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reservation')
            .where('userId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          final reservations = snapshot.data!.docs;
          return ListView.builder(
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final reservation = reservations[index];
              final debutTimestamp = reservation['debut'];
              final finTimestamp = reservation['fin'];
              final idParking = reservation['idParking'];
              final etat = reservation['etat'];
              final reservationStatus =
                  _getReservationStatus(debutTimestamp, finTimestamp, etat);

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('parking')
                    .doc(idParking)
                    .get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  final parkingData =
                      snapshot.data!.data() as Map<String, dynamic>;
                  final nomParking = parkingData['nom'] ?? 'Parking inconnu';
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    margin: EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7.0),
                        side: BorderSide(color: Colors.grey.shade300, width: 1),
                      ),
                      color: Colors.white,
                      child: Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 8.0,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.receipt),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              AfficherTicketPage(
                                            userId: userId,
                                            reservationId: reservation.id,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  Expanded(
                                    child: Text(
                                      nomParking,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18.0,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    reservationStatus,
                                    style: TextStyle(
                                      color: reservationStatus == 'En cours'
                                          ? Colors.blue
                                          : (reservationStatus == 'Annulée'
                                              ? Colors.orange
                                              : Colors.red),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'Place: ${reservation['idPlace']}',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            SizedBox(height: 8.0),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                'ID Reservation: ${reservation.id}',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            ListTile(
                              title: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: Colors.blue,
                                    size: 16.0,
                                  ),
                                  SizedBox(width: 4.0),
                                  Text(
                                    ' ${DateFormat('dd/MM/yyyy HH:mm').format(debutTimestamp.toDate())}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16.0,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.timer_off,
                                        color: Colors.red,
                                        size: 16.0,
                                      ),
                                      SizedBox(width: 4.0),
                                      Text(
                                        ' ${DateFormat('dd/MM/yyyy HH:mm').format(finTimestamp.toDate())}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 4.0),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.directions_car,
                                        color: Colors.blue,
                                        size: 16.0,
                                      ),
                                      SizedBox(width: 4.0),
                                      Text(
                                        reservation['matricule'],
                                        style: TextStyle(
                                          fontSize: 14.0,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            if (reservationStatus == 'En cours')
                              Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ModifierReservationPage(
                                              reservation: reservation,
                                            ),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Color.fromARGB(255, 97, 154, 210),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14.0),
                                        ),
                                      ),
                                      child: Text(
                                        'Modifier',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 16.0),
                                    ElevatedButton(
                                      onPressed: () {
                                        _annulerReservation(reservation.id);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            Color.fromRGBO(55, 125, 196, 1),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14.0),
                                        ),
                                      ),
                                      child: Text(
                                        'Annuler',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (reservationStatus == 'Annulée' ||
                                reservationStatus == 'Terminé')
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: IconButton(
                                    onPressed: () {
                                      _supprimerReservation(reservation.id);
                                    },
                                    icon: Icon(
                                      Icons.close,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            if (reservationStatus == 'Terminé')
                              Column(
                                children: [
                                  EvaluationWidget(
                                    reservationId: reservation.id,
                                    idParking: idParking,
                                    initialEvaluation:
                                        reservation['evaluation'] ?? 0,
                                    mettreAJourMoyenneEvaluation:
                                        _mettreAJourMoyenneEvaluation,
                                  ),
                                  SizedBox(height: 8.0),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class EvaluationWidget extends StatefulWidget {
  final String reservationId;
  final String idParking;
  final int initialEvaluation;
  final Function(String, int) mettreAJourMoyenneEvaluation;

  EvaluationWidget({
    required this.reservationId,
    required this.idParking,
    required this.initialEvaluation,
    required this.mettreAJourMoyenneEvaluation,
  });

  @override
  _EvaluationWidgetState createState() => _EvaluationWidgetState();
}

class _EvaluationWidgetState extends State<EvaluationWidget> {
  late int _evaluation;

  @override
  void initState() {
    super.initState();
    _evaluation = widget.initialEvaluation;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        5,
        (index) => IconButton(
          onPressed: () {
            setState(() {
              _evaluation = index + 1;
            });

            FirebaseFirestore.instance
                .collection('reservation')
                .doc(widget.reservationId)
                .update({'evaluation': _evaluation});

            widget.mettreAJourMoyenneEvaluation(widget.idParking, _evaluation);
          },
          icon: Icon(
            Icons.star,
            color: index < _evaluation ? Colors.orange : Colors.grey,
          ),
        ),
      ),
    );
  }
}
