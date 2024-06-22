import 'dart:async';
import 'dart:math' as math;
import 'package:carparking/pages/cote_user/reclamlist.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ReclamationPage extends StatefulWidget {
  final String userId;

  ReclamationPage({required this.userId});

  @override
  _ReclamationPageState createState() => _ReclamationPageState();
}

class _ReclamationPageState extends State<ReclamationPage> {
  int _currentIndex = 0;
  late PageController _pageController;

  final Map<String, List<String>> typeProblemDescriptions = {
    'Place réservée non disponible': [
      "Ma place réservée est occupée.",
    ],
    'Problème de paiement': [
      "Erreur lors de la transaction",
    ],
    'Problème de sécurité': [
      "Éclairage insuffisant",
      "Absence de caméras de surveillance.",
      "Présence de personnes suspectes",
      "problème de vols dans le parking",
    ],
    'Difficulté daccès': [
      "Feux de signalisation qui ne fonctionnent pas.",
      "L'entrée est bloquée à cause de travaux.",
      "Des embouteillages à l'intérieur du parking"
    ],
    'Problème de réservation de handicap': [
      "Place de parking réservée occupée par un véhicule non autorisé.",
    ],
  };

  String? selectedTypeProblem;
  String? selectedDescription;
  String? otherDescription;
  String? selectedReservation;
  String? selectedMatricule;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String? theftLocation;
  String? theftDescription;
  String? theftPlaceId;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  Future<List<String>> getReservationsForUser(String userId) async {
    List<String> reservations = [];
    QuerySnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection('reservation')
        .where('userId', isEqualTo: userId)
        .get();

    snapshot.docs.forEach((doc) {
      reservations.add(doc.id);
    });

    return reservations;
  }

  Future<String> getPlaceNumberFromReservation(String reservationId) async {
    DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
        .instance
        .collection('reservation')
        .doc(reservationId)
        .get();

    if (snapshot.exists) {
      Map<String, dynamic>? data = snapshot.data();
      if (data != null && data.containsKey('idPlace')) {
        return data['idPlace'];
      }
    }

    return 'Identifiant de place non disponible';
  }

  Future<List<String>> getMatriculesForUser(String userId) async {
    List<String> matricules = [];
    QuerySnapshot<Map<String, dynamic>> snapshot =
        await FirebaseFirestore.instance.collection('véhicule').get();

    snapshot.docs.forEach((doc) {
      matricules.add(doc.id);
    });

    return matricules;
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate)
      setState(() {
        selectedDate = picked;
      });
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != selectedTime)
      setState(() {
        selectedTime = picked;
      });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Reclamation',
          style: GoogleFonts.montserrat(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
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
              child: Column(
                children: [
                  SizedBox(height: 40), // Space for status bar
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      children: [
                        SingleChildScrollView(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, 250, 248, 248),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: EdgeInsets.all(20),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sélectionnez le type de réclamation',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    child: DropdownButtonFormField<String>(
                                      isExpanded:
                                          true, // Set isExpanded to true
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        border: InputBorder.none,
                                      ),
                                      value: selectedTypeProblem,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedTypeProblem = value;
                                          selectedDescription = null;
                                          otherDescription = null;
                                          selectedReservation = null;
                                          selectedMatricule = null;
                                          selectedDate = null;
                                          selectedTime = null;
                                          theftLocation = null;
                                          theftDescription = null;
                                          theftPlaceId = null;
                                        });
                                      },
                                      items: typeProblemDescriptions.keys
                                          .map((type) {
                                        return DropdownMenuItem<String>(
                                          value: type,
                                          child: Text(
                                            type,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  AnimatedOpacity(
                                    opacity:
                                        selectedTypeProblem != null ? 1.0 : 0.0,
                                    duration: Duration(milliseconds: 300),
                                    child: selectedTypeProblem != null
                                        ? Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '2. Sélectionnez une description',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                              Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                                child: DropdownButtonFormField<
                                                    String>(
                                                  isExpanded: true,
                                                  decoration: InputDecoration(
                                                    contentPadding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8,
                                                    ),
                                                    border: InputBorder.none,
                                                  ),
                                                  value: selectedDescription,
                                                  onChanged: (value) {
                                                    setState(() {
                                                      selectedDescription =
                                                          value;
                                                      otherDescription = null;
                                                    });
                                                  },
                                                  items: typeProblemDescriptions[
                                                          selectedTypeProblem]!
                                                      .map((description) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: description,
                                                      child: Text(
                                                        description,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                              SizedBox(height: 16),
                                              if (selectedDescription == null)
                                                Container(
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    border: Border.all(
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                  child: TextField(
                                                    onChanged: (value) {
                                                      setState(() {
                                                        otherDescription =
                                                            value;
                                                      });
                                                    },
                                                    decoration: InputDecoration(
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 8,
                                                      ),
                                                      hintText:
                                                          'Entrez une description personnalisée',
                                                      border: InputBorder.none,
                                                    ),
                                                  ),
                                                ),
                                              SizedBox(height: 16),
                                              if (selectedTypeProblem ==
                                                  'Place réservée non disponible')
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '3. Sélectionnez une réservation',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    SizedBox(height: 8),
                                                    FutureBuilder<List<String>>(
                                                      future:
                                                          getReservationsForUser(
                                                              widget.userId),
                                                      builder:
                                                          (context, snapshot) {
                                                        if (snapshot
                                                                .connectionState ==
                                                            ConnectionState
                                                                .waiting) {
                                                          return CircularProgressIndicator();
                                                        } else if (snapshot
                                                            .hasError) {
                                                          return Text(
                                                              'Erreur: ${snapshot.error}');
                                                        } else {
                                                          List<String>?
                                                              reservations =
                                                              snapshot.data;
                                                          return Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                              border:
                                                                  Border.all(
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                            ),
                                                            child:
                                                                DropdownButtonFormField<
                                                                    String>(
                                                              decoration:
                                                                  InputDecoration(
                                                                contentPadding:
                                                                    EdgeInsets
                                                                        .symmetric(
                                                                  horizontal:
                                                                      16,
                                                                  vertical: 8,
                                                                ),
                                                                border:
                                                                    InputBorder
                                                                        .none,
                                                              ),
                                                              value:
                                                                  selectedReservation,
                                                              onChanged:
                                                                  (value) {
                                                                setState(() {
                                                                  selectedReservation =
                                                                      value;
                                                                });
                                                              },
                                                              items: reservations
                                                                      ?.map(
                                                                          (reservation) {
                                                                    return DropdownMenuItem<
                                                                        String>(
                                                                      value:
                                                                          reservation,
                                                                      child: Text(
                                                                          reservation),
                                                                    );
                                                                  }).toList() ??
                                                                  [],
                                                            ),
                                                          );
                                                        }
                                                      },
                                                    ),
                                                    SizedBox(height: 16),
                                                    if (selectedReservation !=
                                                        null)
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          FutureBuilder<String>(
                                                            future: getPlaceNumberFromReservation(
                                                                selectedReservation!),
                                                            builder: (context,
                                                                snapshot) {
                                                              if (snapshot
                                                                      .connectionState ==
                                                                  ConnectionState
                                                                      .waiting) {
                                                                return CircularProgressIndicator();
                                                              } else if (snapshot
                                                                  .hasError) {
                                                                return Text(
                                                                    'Erreur: ${snapshot.error}');
                                                              } else {
                                                                String
                                                                    placeNumber =
                                                                    snapshot
                                                                        .data!;
                                                                return Text(
                                                                  'ID de la place : $placeNumber',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    color: Colors
                                                                        .red,
                                                                  ),
                                                                );
                                                              }
                                                            },
                                                          ),
                                                          SizedBox(height: 16),
                                                          Text(
                                                            '4. Sélectionnez une matricule',
                                                            style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          SizedBox(height: 8),
                                                          FutureBuilder<
                                                              List<String>>(
                                                            future:
                                                                getMatriculesForUser(
                                                                    widget
                                                                        .userId),
                                                            builder: (context,
                                                                snapshot) {
                                                              if (snapshot
                                                                      .connectionState ==
                                                                  ConnectionState
                                                                      .waiting) {
                                                                return CircularProgressIndicator();
                                                              } else if (snapshot
                                                                  .hasError) {
                                                                return Text(
                                                                    'Erreur: ${snapshot.error}');
                                                              } else {
                                                                List<String>?
                                                                    matricules =
                                                                    snapshot
                                                                        .data;
                                                                return Container(
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            10),
                                                                    border:
                                                                        Border
                                                                            .all(
                                                                      color: Colors
                                                                          .grey,
                                                                    ),
                                                                  ),
                                                                  child:
                                                                      DropdownButtonFormField<
                                                                          String>(
                                                                    isExpanded:
                                                                        true,
                                                                    value:
                                                                        selectedMatricule,
                                                                    onChanged:
                                                                        (value) {
                                                                      setState(
                                                                          () {
                                                                        selectedMatricule =
                                                                            value;
                                                                      });
                                                                    },
                                                                    items: matricules
                                                                            ?.map((matricule) {
                                                                          return DropdownMenuItem<
                                                                              String>(
                                                                            value:
                                                                                matricule,
                                                                            child:
                                                                                Text(
                                                                              matricule,
                                                                              overflow: TextOverflow.ellipsis,
                                                                            ),
                                                                          );
                                                                        }).toList() ??
                                                                        [],
                                                                  ),
                                                                );
                                                              }
                                                            },
                                                          ),
                                                          SizedBox(height: 8),
                                                        ],
                                                      ),
                                                  ],
                                                ),
                                              if (selectedTypeProblem ==
                                                  'Problème de réservation de handicap')
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    SizedBox(height: 16),
                                                    Text(
                                                      '3. Sélectionnez la matricule du véhicule non autorisé',
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    SizedBox(height: 8),
                                                    FutureBuilder<List<String>>(
                                                      future:
                                                          getMatriculesForUser(
                                                              widget.userId),
                                                      builder:
                                                          (context, snapshot) {
                                                        if (snapshot
                                                                .connectionState ==
                                                            ConnectionState
                                                                .waiting) {
                                                          return CircularProgressIndicator();
                                                        } else if (snapshot
                                                            .hasError) {
                                                          return Text(
                                                              'Erreur: ${snapshot.error}');
                                                        } else {
                                                          List<String>?
                                                              matricules =
                                                              snapshot.data;
                                                          return Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                              border:
                                                                  Border.all(
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                            ),
                                                            child:
                                                                DropdownButtonFormField<
                                                                    String>(
                                                              isExpanded: true,
                                                              value:
                                                                  selectedMatricule, // Corrected here
                                                              onChanged:
                                                                  (value) {
                                                                setState(() {
                                                                  selectedMatricule =
                                                                      value;
                                                                });
                                                              },
                                                              items: matricules
                                                                      ?.map(
                                                                          (matricule) {
                                                                    return DropdownMenuItem<
                                                                        String>(
                                                                      value:
                                                                          matricule,
                                                                      child:
                                                                          Text(
                                                                        matricule,
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    );
                                                                  }).toList() ??
                                                                  [],
                                                            ),
                                                          );
                                                        }
                                                      },
                                                    ),
                                                    SizedBox(height: 8),
                                                  ],
                                                ),
                                              if (selectedDescription ==
                                                  "problème de vols dans le parking")
                                                Card(
                                                  elevation: 4,
                                                  shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              15)),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            16.0),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          '3. Détails du vol',
                                                          style: TextStyle(
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold),
                                                        ),
                                                        SizedBox(height: 16),
                                                        Row(
                                                          children: [
                                                            Expanded(
                                                              child:
                                                                  ElevatedButton
                                                                      .icon(
                                                                icon: Icon(Icons
                                                                    .calendar_today),
                                                                label: Text(selectedDate ==
                                                                        null
                                                                    ? 'Date'
                                                                    : '${selectedDate!.toLocal()}'
                                                                        .split(
                                                                            ' ')[0]),
                                                                onPressed: () =>
                                                                    _selectDate(
                                                                        context),
                                                                style: ElevatedButton
                                                                    .styleFrom(
                                                                  foregroundColor:
                                                                      Colors.blue[
                                                                          800],
                                                                  backgroundColor:
                                                                      Colors.blue[
                                                                          100],
                                                                  shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              10)),
                                                                ),
                                                              ),
                                                            ),
                                                            SizedBox(width: 16),
                                                            Expanded(
                                                              child:
                                                                  ElevatedButton
                                                                      .icon(
                                                                icon: Icon(Icons
                                                                    .access_time),
                                                                label: Text(selectedTime ==
                                                                        null
                                                                    ? 'Heure'
                                                                    : selectedTime!
                                                                        .format(
                                                                            context)),
                                                                onPressed: () =>
                                                                    _selectTime(
                                                                        context),
                                                                style: ElevatedButton
                                                                    .styleFrom(
                                                                  foregroundColor:
                                                                      Colors.blue[
                                                                          800],
                                                                  backgroundColor:
                                                                      Colors.blue[
                                                                          100],
                                                                  shape: RoundedRectangleBorder(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              10)),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        SizedBox(height: 16),
                                                        CustomTextField(
                                                          icon:
                                                              Icons.location_on,
                                                          hint: 'Lieu du vol',
                                                          onChanged: (value) =>
                                                              setState(() =>
                                                                  theftLocation =
                                                                      value),
                                                        ),
                                                        SizedBox(height: 16),
                                                        CustomTextField(
                                                          icon: Icons
                                                              .confirmation_number,
                                                          hint:
                                                              'ID de la place',
                                                          onChanged: (value) =>
                                                              setState(() =>
                                                                  theftPlaceId =
                                                                      value),
                                                        ),
                                                        SizedBox(height: 16),
                                                        CustomTextField(
                                                          icon:
                                                              Icons.description,
                                                          hint:
                                                              'Description du vol',
                                                          maxLines: 3,
                                                          onChanged: (value) =>
                                                              setState(() =>
                                                                  theftDescription =
                                                                      value),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              SizedBox(height: 32),
                                              ElevatedButton(
                                                onPressed: submitReclamation,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.blue,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                  ),
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: 15,
                                                    horizontal: 30,
                                                  ),
                                                ),
                                                child: Text(
                                                    'Soumettre la réclamation'),
                                              ),
                                            ],
                                          )
                                        : SizedBox.shrink(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Placeholder for the second page
                        Placeholder(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ReclamationListPage(userId: widget.userId),
              ),
            );
          } else {
            _pageController.jumpToPage(index);
            setState(() {
              _currentIndex = index;
            });
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Nouvelle réclamation',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Mes réclamations',
          ),
        ],
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
      ),
    );
  }

  void submitReclamation() async {
    Map<String, dynamic> reclamationData = {
      'type': selectedTypeProblem,
      'description': selectedDescription ?? otherDescription,
      'userId': widget.userId,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'envoyé',
    };

    if (selectedTypeProblem == 'Place réservée non disponible') {
      reclamationData['reservationId'] = selectedReservation;
      reclamationData['idPlace'] =
          await getPlaceNumberFromReservation(selectedReservation!);
      reclamationData['matricule'] = selectedMatricule;
    }

    if (selectedTypeProblem == 'Problème de réservation de handicap') {
      reclamationData['matricule'] = selectedMatricule;
    }

    if (selectedDescription == "problème de vols dans le parking") {
      reclamationData['date'] = selectedDate;
      reclamationData['heure'] = selectedTime != null
          ? "${selectedTime!.hour}:${selectedTime!.minute}"
          : null;
      reclamationData['lieu'] = theftLocation;
      reclamationData['idPlace'] = theftPlaceId;
      reclamationData['descriptionVol'] = theftDescription;
    }

    await FirebaseFirestore.instance
        .collection('reclamations')
        .add(reclamationData);

    setState(() {
      selectedTypeProblem = null;
      selectedDescription = null;
      otherDescription = null;
      selectedReservation = null;
      selectedMatricule = null;
      selectedDate = null;
      selectedTime = null;
      theftLocation = null;
      theftDescription = null;
      theftPlaceId = null;
      _currentIndex = 0;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Réclamation enregistrée avec succès'),
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final IconData icon;
  final String hint;
  final Function(String) onChanged;
  final int maxLines;

  const CustomTextField({
    Key? key,
    required this.icon,
    required this.hint,
    required this.onChanged,
    this.maxLines = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        onChanged: onChanged,
        maxLines: maxLines,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.blue[800]),
          hintText: hint,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}
