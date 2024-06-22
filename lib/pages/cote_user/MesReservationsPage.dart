import 'package:carparking/pages/cote_user/reservation/afficherticket.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class MesReservationsPage extends StatefulWidget {
  @override
  _MesReservationsPageState createState() => _MesReservationsPageState();
}

class _MesReservationsPageState extends State<MesReservationsPage> {
  late String userId;
  String searchQuery = '';

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
      DocumentSnapshot reservationDoc = await FirebaseFirestore.instance
          .collection('reservation')
          .doc(reservationId)
          .get();

      if (!reservationDoc.exists) {
        print('Réservation non trouvée');
        return;
      }

      String idPlace = reservationDoc['idPlace'];
      String idParking = reservationDoc['idParking'];

      await FirebaseFirestore.instance
          .collection('reservation')
          .doc(reservationId)
          .delete();

      if (idPlace.isNotEmpty && idParking.isNotEmpty) {
        final placeDoc = await FirebaseFirestore.instance
            .collection('place')
            .doc(idPlace)
            .get();

        if (placeDoc.exists) {
          final reservations =
              List.from(placeDoc.data()?['reservations'] ?? []);
          final updatedReservations = reservations.where((reservation) {
            final debutReservation =
                (reservation['debut'] as Timestamp).toDate();
            final finReservation = (reservation['fin'] as Timestamp).toDate();
            final reservationDebut =
                (reservationDoc['debut'] as Timestamp).toDate();
            final reservationFin =
                (reservationDoc['fin'] as Timestamp).toDate();

            return !(debutReservation == reservationDebut &&
                finReservation == reservationFin);
          }).toList();

          await FirebaseFirestore.instance
              .collection('place')
              .doc(idPlace)
              .update({'reservations': updatedReservations});
        }
      }

      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Réservation supprimée avec succès'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Erreur lors de la suppression de la réservation : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la suppression de la réservation'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _annulerReservation(String reservationId) async {
    try {
      // Mettre à jour l'état de la réservation dans la collection 'reservation'
      await FirebaseFirestore.instance
          .collection('reservation')
          .doc(reservationId)
          .update({'etat': 'Annulée'});

      // Récupérer le document de la réservation
      DocumentSnapshot reservationDoc = await FirebaseFirestore.instance
          .collection('reservation')
          .doc(reservationId)
          .get();

      if (!reservationDoc.exists) {
        print('Réservation non trouvée');
        return;
      }

      // Obtenir les champs 'idPlace' et 'idParking' de la réservation
      String idPlace = reservationDoc['idPlace'];
      String idParking = reservationDoc['idParking'];

      // Vérifier si 'idPlace' et 'idParking' ne sont pas vides
      if (idPlace.isNotEmpty && idParking.isNotEmpty) {
        // Récupérer le document de la place
        final placeDoc = await FirebaseFirestore.instance
            .collection('place')
            .doc(idPlace)
            .get();

        if (placeDoc.exists) {
          // Récupérer la liste des réservations
          final reservations =
              List.from(placeDoc.data()?['reservations'] ?? []);

          // Filtrer les réservations pour supprimer celle qui correspond
          final updatedReservations = reservations.where((reservation) {
            final debutReservation =
                (reservation['debut'] as Timestamp).toDate();
            final finReservation = (reservation['fin'] as Timestamp).toDate();
            final reservationDebut =
                (reservationDoc['debut'] as Timestamp).toDate();
            final reservationFin =
                (reservationDoc['fin'] as Timestamp).toDate();

            return !(debutReservation == reservationDebut &&
                finReservation == reservationFin);
          }).toList();

          // Mettre à jour le document de la place avec les réservations mises à jour
          await FirebaseFirestore.instance
              .collection('place')
              .doc(idPlace)
              .update({'reservations': updatedReservations});
        }
      }

      // Rechercher le ticket correspondant en utilisant l'ID de la réservation
      QuerySnapshot ticketQuery = await FirebaseFirestore.instance
          .collection('ticket')
          .where('reservationId', isEqualTo: reservationId)
          .get();

      if (ticketQuery.docs.isNotEmpty) {
        // Mettre à jour le document du ticket avec timestampAnnulation
        await FirebaseFirestore.instance
            .collection('ticket')
            .doc(ticketQuery.docs.first.id)
            .update({'timestampAnnulation': Timestamp.now()});
      } else {
        print('Aucun ticket trouvé pour cette réservation');
      }

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Réservation annulée avec succès'),
          duration: Duration(seconds: 2),
        ),
      );

      // Mettre à jour l'état de l'interface utilisateur
      setState(() {});
    } catch (e) {
      print('Erreur lors de l\'annulation de la réservation : $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'annulation de la réservation'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _afficherDialogueConfirmation(
      BuildContext context, String reservationId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Confirmation',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          content: Text(
            'Êtes-vous sûr de vouloir annuler cette réservation ?',
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Annuler',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(
                'OK',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _annulerReservation(reservationId);
              },
            ),
          ],
        );
      },
    );
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Annulée':
        return Colors.orange;
      case 'En cours':
        return Colors.blue;
      case 'Terminé':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Function to update search query
  void updateSearchQuery(String newQuery) {
    setState(() {
      searchQuery = newQuery;
    });
  }

  // Function to check if reservation matches search criteria
  bool doesReservationMatchSearch(
      DocumentSnapshot reservation, String searchQuery) {
    final data = reservation.data() as Map<String, dynamic>;
    final idPlace = data['idPlace'].toLowerCase();
    final debutTimestamp = data['debut'] as Timestamp;
    final finTimestamp = data['fin'] as Timestamp;

    // Convert timestamps to formatted date strings
    final debutDate =
        DateFormat('dd/MM/yyyy HH:mm').format(debutTimestamp.toDate());
    final finDate =
        DateFormat('dd/MM/yyyy HH:mm').format(finTimestamp.toDate());

    // Check if reservation matches search criteria
    return idPlace.contains(searchQuery.toLowerCase()) ||
        debutDate.contains(searchQuery.toLowerCase()) ||
        finDate.contains(searchQuery.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Mes Réservations',
          style: GoogleFonts.montserrat(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: updateSearchQuery,
              decoration: InputDecoration(
                hintText: 'Rechercher par ID de place ou date',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
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
                final reservations = snapshot.data!.docs.where((reservation) {
                  if (searchQuery.isEmpty) {
                    return true; // No search query, show all reservations
                  } else {
                    return doesReservationMatchSearch(reservation, searchQuery);
                  }
                }).toList();

                return ListView.builder(
                  itemCount: reservations.length,
                  itemBuilder: (context, index) {
                    final reservation = reservations[index];
                    final debutTimestamp = reservation['debut'];
                    final finTimestamp = reservation['fin'];
                    final idParking = reservation['idParking'];
                    final etat = reservation['etat'];
                    final reservationStatus = _getReservationStatus(
                        debutTimestamp, finTimestamp, etat);

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('parking')
                          .doc(idParking)
                          .get(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator());
                        }
                        final parkingData =
                            snapshot.data!.data() as Map<String, dynamic>;
                        final nomParking =
                            parkingData['nom'] ?? 'Parking inconnu';

                        return AnimatedContainer(
                          duration: Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          margin: EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7.0),
                              side: BorderSide(
                                  color: Colors.grey.shade300, width: 1),
                            ),
                            color: Colors.white,
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16.0, vertical: 8.0),
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
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(
                                                reservationStatus),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            reservationStatus,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16.0),
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
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 16.0),
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                      padding:
                                          EdgeInsets.symmetric(vertical: 8.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              _afficherDialogueConfirmation(
                                                  context, reservation.id);
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Color.fromRGBO(
                                                  55, 125, 196, 1),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14.0),
                                              ),
                                            ),
                                            child: Text(
                                              'Annuler',
                                              style: TextStyle(
                                                  color: Colors.white),
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
                                            _supprimerReservation(
                                                reservation.id);
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
          ),
        ],
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
