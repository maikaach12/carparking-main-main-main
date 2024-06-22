import 'dart:async';
import 'dart:math' as math;

import 'package:carparking/pages/cote_user/MesReservationsPage.dart';
import 'package:carparking/pages/cote_user/reservation/paiement.dart';
import 'package:carparking/pages/cote_user/reservation/ticket.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class ReservationPage extends StatefulWidget {
  final String parkingId;
  ReservationPage({required this.parkingId});

  @override
  _ReservationPageState createState() => _ReservationPageState();
}

class _ReservationPageState extends State<ReservationPage> {
  final _formKey = GlobalKey<FormState>();
  Timestamp? _debutReservation;
  Timestamp? _finReservation;
  String _typePlace = 'standard';
  String? _selectedMatricule;
  List<String> _matricules = [];
  String? reservationId;
  List<bool> _isSelected = [
    true,
    false
  ]; // Initialisé pour sélectionner "Standard" par défaut
  Timer? _notificationTimer;

  void _showReservationNotification() {
    // Implement your notification logic here
  }

  Future<void> _selectDebutReservation(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.grey.shade800,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child ?? const SizedBox(),
        );
      },
    );
    if (picked != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: Colors.blue,
                onPrimary: Colors.white,
                onSurface: Colors.grey.shade800,
              ),
              dialogBackgroundColor: Colors.white,
            ),
            child: child ?? const SizedBox(),
          );
        },
      );
      if (pickedTime != null) {
        setState(() {
          _debutReservation = Timestamp.fromDate(DateTime(
            picked.year,
            picked.month,
            picked.day,
            pickedTime.hour,
            pickedTime.minute,
          ));
        });
      }
    }
  }

  Future<void> _fetchMatricules() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('véhicule')
          .where('userId', isEqualTo: userId)
          .get();
      _matricules =
          querySnapshot.docs.map((doc) => doc.id).toList().cast<String>();
    }
    setState(() {});
  }

  Future<void> _selectFinReservation(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _debutReservation?.toDate() ?? DateTime.now(),
      firstDate: _debutReservation?.toDate() ?? DateTime.now(),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.grey.shade800,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child ?? const SizedBox(),
        );
      },
    );
    if (picked != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: Colors.blue,
                onPrimary: Colors.white,
                onSurface: Colors.grey.shade800,
              ),
              dialogBackgroundColor: Colors.white,
            ),
            child: child ?? const SizedBox(),
          );
        },
      );
      if (pickedTime != null) {
        setState(() {
          _finReservation = Timestamp.fromDate(DateTime(
            picked.year,
            picked.month,
            picked.day,
            pickedTime.hour,
            pickedTime.minute,
          ));
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error,
                  color: Colors.red,
                  size: 50,
                ),
                SizedBox(height: 10),
                Text(
                  message,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'OK',
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _reserverPlace() async {
    String? placesAttribueId;

    try {
      // Get the current user ID
      String? userId = FirebaseAuth.instance.currentUser?.uid;

      // Get the places of the specified type in the parking
      final querySnapshot = await FirebaseFirestore.instance
          .collection('place')
          .where('id_parking', isEqualTo: widget.parkingId)
          .where('type', isEqualTo: _typePlace)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        bool chevauchementTotal = false;
        bool reservationEffectuee = false;

        for (final placesDoc in querySnapshot.docs) {
          placesAttribueId = placesDoc.id;

          final reservationsExistantes = placesDoc.data()['reservations'] ?? [];
          chevauchementTotal = false;
          for (final reservation in reservationsExistantes) {
            final debutExistante = reservation['debut'] != null
                ? reservation['debut'].toDate()
                : null;
            final finExistante =
                reservation['fin'] != null ? reservation['fin'].toDate() : null;
            final etat = reservation['etat'] ?? '';

            // Ignorer les réservations dont l'état est "Terminé" ou "Annulée"
            if (etat == 'Terminé' || etat == 'Annulée') {
              continue;
            }

            if (debutExistante == null || finExistante == null) {
              continue;
            }
            if ((_debutReservation!.toDate().isBefore(finExistante) &&
                    _debutReservation!.toDate().isAfter(debutExistante)) ||
                (_finReservation!.toDate().isBefore(finExistante) &&
                    _finReservation!.toDate().isAfter(debutExistante)) ||
                (_debutReservation!.toDate().isAtSameMomentAs(debutExistante) &&
                    _finReservation!.toDate().isAtSameMomentAs(finExistante)) ||
                (_debutReservation!.toDate().isBefore(debutExistante) &&
                    _finReservation!.toDate().isAfter(finExistante))) {
              chevauchementTotal = true;
              break;
            }
          }

          if (!chevauchementTotal) {
            await placesDoc.reference.update({
              'reservations': FieldValue.arrayUnion([
                {
                  'debut': _debutReservation,
                  'fin': _finReservation,
                  'userId': userId,
                  'etat': 'en cours' // Ajoutez l'état de la réservation ici
                }
              ])
            });

            await FirebaseFirestore.instance.collection('reservation').add({
              'idParking': widget.parkingId,
              'debut': _debutReservation,
              'fin': _finReservation,
              'typePlace': _typePlace,
              'idPlace': placesAttribueId,
              'decrementPlacesDisponible': false,
              'userId': userId,
              'matricule': _selectedMatricule,
              'etat': 'en cours',
              'evaluation': 0
            }).then((documentRef) async {
              reservationId = documentRef.id;

              // Calculer le prix ici
              final dureeTotale = _finReservation!
                  .toDate()
                  .difference(_debutReservation!.toDate());
              final dureeMinutes = dureeTotale.inMinutes;

              final reservationDoc = await documentRef.get();
              final idPlace = reservationDoc.data()?['idPlace'];

              final placeDoc = await FirebaseFirestore.instance
                  .collection('place')
                  .doc(idPlace)
                  .get();
              final type = placeDoc.data()?['type'];

              final idParking = reservationDoc.data()?['idParking'];
              final parkingDoc = await FirebaseFirestore.instance
                  .collection('parking')
                  .doc(idParking)
                  .get();

              int prixParTranche;
              if (type == 'handicapé' &&
                  parkingDoc.data()?['prixParTrancheHandi'] != null) {
                prixParTranche = parkingDoc.data()?['prixParTrancheHandi'];
              } else if (type == 'standard' &&
                  parkingDoc.data()?['prixParTranche'] != null) {
                prixParTranche = parkingDoc.data()?['prixParTranche'];
              } else {
                return;
              }

              final nombreTranches = (dureeMinutes / 10).ceil();
              int prix = (nombreTranches * prixParTranche).toInt();

              final promotion = parkingDoc.data()?['promotion'];
              if (promotion != null) {
                final DateTime dateDebutPromotion =
                    promotion['dateDebutPromotion'].toDate();
                final DateTime dateFinPromotion =
                    promotion['dateFinPromotion'].toDate();
                final double remiseEnPourcentage =
                    promotion['remiseEnPourcentage'];

                final DateTime now = DateTime.now();
                if (now.isAfter(dateDebutPromotion) &&
                    now.isBefore(dateFinPromotion)) {
                  prix = (prix * (1 - (remiseEnPourcentage / 100))).toInt();
                }
              }

              await documentRef.update({'prix': prix});

              setState(() {});

              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.blue.shade300,
                            Colors.blue.shade600,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 50,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Réservation effectuée',
                            style: GoogleFonts.montserrat(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'La place attribuée est :',
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.event_seat,
                                color: Colors.white,
                                size: 32,
                              ),
                              SizedBox(width: 10),
                              Text(
                                placesAttribueId!,
                                style: GoogleFonts.montserrat(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.yellow.shade300,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 10.0,
                                      color: Colors.black45,
                                      offset: Offset(2.0, 2.0),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 30),
                          Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.monetization_on,
                                  color: Colors.green,
                                  size: 32,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  '$prix DA',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.blue.shade800,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: () {
                                  // Naviguer vers la page MesReservationsPage
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => TicketPage(
                                        userId: userId!,
                                        reservationId: reservationId!,
                                      ),
                                    ),
                                  );
                                },
                                icon: Icon(Icons.done),
                                label: Text(
                                  'voir ticket',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
              reservationEffectuee = true;

              return;
            });
          }
          if (reservationEffectuee) {
            break;
          }
        }

        if (!reservationEffectuee) {
          _showErrorDialog(
            'Désolé, aucune place n\'est actuellement disponible pour la période sélectionnée sans chevauchement de réservation',
          );
        }
      } else {
        _showErrorDialog('Aucune place de type "$_typePlace" disponible');
      }
    } catch (e) {
      // Gérer l'erreur ici
      _showErrorDialog(
          'Une erreur s\'est produite lors de la réservation : $e');
    }
  }

  Future<void> _updateReservationStatus() async {
    try {
      // Récupérer l'heure actuelle
      DateTime currentTime = DateTime.now().toUtc();

      // Interroger les réservations en cours
      QuerySnapshot reservations = await FirebaseFirestore.instance
          .collection('reservation')
          .where('debut', isLessThanOrEqualTo: Timestamp.fromDate(currentTime))
          .get();

      for (QueryDocumentSnapshot reservation in reservations.docs) {
        DateTime debutReservation = reservation.get('debut').toDate();
        DateTime finReservation = reservation.get('fin').toDate();
        String etatReservation = reservation.get('etat');

        // Ignorer les réservations annulées
        if (etatReservation == 'Annulée') {
          continue;
        }

        // Afficher les heures de début et de fin de la réservation

        // Mettre à jour l'état de la réservation
        if (currentTime.isAfter(finReservation)) {
          await reservation.reference.update({'etat': 'terminée'});
        } else if (currentTime.isAfter(debutReservation) &&
            currentTime.isBefore(finReservation)) {
          await reservation.reference.update({'etat': 'en cours'});
        }
      }
    } catch (e) {}
  }

  Future<void> _gererPlacesDisponibles() async {
    try {
      // Obtenir l'heure actuelle
      DateTime currentTime = DateTime.now().toUtc();

      // Interroger les réservations en cours pour le parking actuel
      QuerySnapshot ongoingReservations = await FirebaseFirestore.instance
          .collection('reservation')
          .where('idParking', isEqualTo: widget.parkingId)
          .where('debut', isLessThanOrEqualTo: Timestamp.fromDate(currentTime))
          .where('fin', isGreaterThan: Timestamp.fromDate(currentTime))
          .where('etat', isNotEqualTo: 'Annulée')
          .get();

      // Obtenir le nombre de réservations en cours pour le parking actuel
      int ongoingReservationsCount = ongoingReservations.docs.length;

      // Obtenir le document de parking de la collection parkingu
      final parkingDoc = await FirebaseFirestore.instance
          .collection('parking')
          .doc(widget.parkingId)
          .get();

      // Vérifier si le document existe et a une valeur de capacite
      if (parkingDoc.exists && parkingDoc.data()!.containsKey('capacite')) {
        int capacite = parkingDoc.data()!['capacite'];
        int placesDisponible = capacite - ongoingReservationsCount;

        // Mettre à jour placesDisponible pour le parking actuel
        await FirebaseFirestore.instance
            .collection('parking')
            .doc(widget.parkingId)
            .update({
          'placesDisponible': placesDisponible,
        });

        // Vérifier si la fin de la réservation est atteinte
        QuerySnapshot endedReservations = await FirebaseFirestore.instance
            .collection('reservation')
            .where('idParking', isEqualTo: widget.parkingId)
            .where('fin', isLessThanOrEqualTo: Timestamp.fromDate(currentTime))
            .where('etat', isEqualTo: 'en cours')
            .get();

        if (endedReservations.docs.isNotEmpty) {
          int endedReservationsCount = endedReservations.docs.length;
          placesDisponible += endedReservationsCount;

          await FirebaseFirestore.instance
              .collection('parking')
              .doc(widget.parkingId)
              .update({
            'placesDisponible': placesDisponible,
          });
        }
      }
    } catch (e) {}
  }

  Future<void> _gererFinReservation() async {
    try {
      // Obtenir l'heure actuelle
      DateTime currentTime = DateTime.now().toUtc();

      // Interroger les réservations qui se terminent pour tous les parkings
      QuerySnapshot endedReservations = await FirebaseFirestore.instance
          .collection('reservation')
          .where('fin', isLessThanOrEqualTo: Timestamp.fromDate(currentTime))
          .where('etat', isEqualTo: 'en cours')
          .get();

      // Utiliser une carte pour regrouper les réservations par parkingId
      Map<String, List<QueryDocumentSnapshot>> reservationsParParking = {};
      for (QueryDocumentSnapshot reservation in endedReservations.docs) {
        String parkingId = reservation.get('idParking');
        if (!reservationsParParking.containsKey(parkingId)) {
          reservationsParParking[parkingId] = [];
        }
        reservationsParParking[parkingId]!.add(reservation);
      }

      // Traiter chaque parkingId séparément
      for (String parkingId in reservationsParParking.keys) {
        // Exécuter une transaction pour assurer la cohérence des données
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          // Obtenir le document de parking
          DocumentSnapshot parkingDoc = await transaction.get(
              FirebaseFirestore.instance.collection('parking').doc(parkingId));

          // Vérifier si le document existe et a les valeurs nécessaires
          Map<String, dynamic>? parkingData =
              parkingDoc.data() as Map<String, dynamic>?;

          if (parkingData != null &&
              parkingData.containsKey('placesDisponible') &&
              parkingData.containsKey('capacite')) {
            int placesDisponible = parkingData['placesDisponible'];
            int capacite = parkingData['capacite'];
            // Calculer le nombre de réservations qui se terminent pour ce parking
            int reservationsCount = reservationsParParking[parkingId]!.length;

            // Calculer les nouvelles places disponibles en veillant à ne pas dépasser la capacité maximale
            placesDisponible =
                (placesDisponible + reservationsCount).clamp(0, capacite);

            // Mettre à jour placesDisponible pour le parking actuel
            transaction.update(parkingDoc.reference, {
              'placesDisponible': placesDisponible,
            });

            // Mettre à jour l'état de chaque réservation à "terminée"
            for (QueryDocumentSnapshot reservation
                in reservationsParParking[parkingId]!) {
              transaction.update(reservation.reference, {'etat': 'terminée'});
            }
          }
        });
      }
    } catch (e) {}
  }

  @override
  void initState() {
    super.initState();
    _fetchMatricules();

    Timer.periodic(Duration(seconds: 1), (timer) {
      _gererPlacesDisponibles();
      _updateReservationStatus();
      _gererFinReservation();
    });
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
        body: Stack(children: [
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
              image: AssetImage(
                  'lib/images/blue.png'), // Replace with your background image path
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
                  child: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    FittedBox(
                      child: Text(
                        "Parking.dz",
                        style: GoogleFonts.montserrat(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    FittedBox(
                      child: Text(
                        "Réserver une place",
                        style: GoogleFonts.montserrat(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    SizedBox(height: 50),
                    Form(
                        key: _formKey,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Début réservation',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        _selectDebutReservation(context),
                                    child: Text(
                                      _debutReservation != null
                                          ? DateFormat('dd/MM/yyyy HH:mm')
                                              .format(
                                                  _debutReservation!.toDate())
                                          : 'Selectionner',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color.fromRGBO(33, 150, 243, 1)
                                              .withOpacity(0.5),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Fin réservation',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  ElevatedButton(
                                    onPressed: () =>
                                        _selectFinReservation(context),
                                    child: Text(
                                      _finReservation != null
                                          ? DateFormat('dd/MM/yyyy HH:mm')
                                              .format(_finReservation!.toDate())
                                          : 'Séléctionner',
                                      style: GoogleFonts.montserrat(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          Colors.blue.withOpacity(0.5),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 10),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Type de place',
                                    style: GoogleFonts.montserrat(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  ToggleButtons(
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: Text(
                                          'Standard',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8.0),
                                        child: Text(
                                          'handicapé',
                                          style: GoogleFonts.montserrat(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                    isSelected: _isSelected,
                                    onPressed: (int index) {
                                      setState(() {
                                        for (int buttonIndex = 0;
                                            buttonIndex < _isSelected.length;
                                            buttonIndex++) {
                                          if (buttonIndex == index) {
                                            _isSelected[buttonIndex] = true;
                                            _typePlace = buttonIndex == 0
                                                ? 'standard'
                                                : 'handicapé';
                                          } else {
                                            _isSelected[buttonIndex] = false;
                                          }
                                        }
                                      });
                                    },
                                    renderBorder: false,
                                    selectedColor: Colors.blue.withOpacity(0.5),
                                    fillColor: Colors.blue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedMatricule,
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedMatricule = value;
                                      });
                                    },
                                    items: _matricules.isNotEmpty
                                        ? _matricules.map((matriculeId) {
                                            return DropdownMenuItem<String>(
                                              value: matriculeId,
                                              child: Text(matriculeId),
                                            );
                                          }).toList()
                                        : [
                                            DropdownMenuItem<String>(
                                              value: null,
                                              child: Text(
                                                  'Aucune matricule disponible'),
                                            ),
                                          ],
                                    decoration: InputDecoration(
                                      labelText: 'Sélectionnez une matricule',
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    _reserverPlace();
                                  }
                                },
                                child: Text(
                                  'Réserver',
                                  style: GoogleFonts.montserrat(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.withOpacity(0.5),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 40, vertical: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                              ),
                            ]))
                  ])))))
    ]));
  }
}
