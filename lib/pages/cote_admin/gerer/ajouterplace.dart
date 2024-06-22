import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';

class AjouterPlacePage extends StatefulWidget {
  @override
  _AjouterPlacePageState createState() => _AjouterPlacePageState();
}

class _AjouterPlacePageState extends State<AjouterPlacePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formKey = GlobalKey<FormState>();
  String? _selectedParkingId;
  String? _selectedType;
  List<String> _parkingNames = [];
  List<String> _placeTypes = ['standard', 'handicapé'];
  Map<String, String> _parkingIdMap = {};

  @override
  void initState() {
    super.initState();
    _fetchParkingNamesAndIds();
  }

  Future<void> _fetchParkingNamesAndIds() async {
    QuerySnapshot querySnapshot = await _firestore.collection('parking').get();
    List<String> parkingNames = [];
    Map<String, String> parkingIdMap = {};
    for (QueryDocumentSnapshot document in querySnapshot.docs) {
      String parkingName = document['nom'];
      String parkingId = document.id;
      parkingNames.add(parkingName);
      parkingIdMap[parkingName] = parkingId;
    }
    setState(() {
      _parkingNames = parkingNames;
      _parkingIdMap = parkingIdMap;
    });
  }

  Future<String> _generateCustomId() async {
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const numbers = '0123456789';
    Random random = Random();

    while (true) {
      String letter = letters[random.nextInt(letters.length)];
      String number = numbers[random.nextInt(numbers.length)];
      String customId = '$letter$number';

      QuerySnapshot querySnapshot = await _firestore
          .collection('place')
          .where('id', isEqualTo: customId)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return customId;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ajouter une place',
          style: GoogleFonts.montserrat(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          Image.asset(
            'lib/images/blue.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Container(
                  padding: const EdgeInsets.all(15.0),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 250, 248, 248),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'Ajouter une place',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Sélectionnez un parking : ',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        LayoutBuilder(
                          builder: (BuildContext context,
                              BoxConstraints constraints) {
                            return Container(
                              width: constraints.maxWidth,
                              child: DropdownButtonFormField<String>(
                                value: _selectedParkingId,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedParkingId = value;
                                  });
                                },
                                isExpanded: true,
                                items: _parkingNames.map((name) {
                                  return DropdownMenuItem<String>(
                                    value: _parkingIdMap[name],
                                    child: Text(
                                      name,
                                      style: TextStyle(
                                        fontFamily: 'Montserrat',
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 16.0),
                        Text(
                          'Sélectionnez le type de place :',
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        DropdownButtonFormField<String>(
                          value: _selectedType,
                          onChanged: (value) {
                            setState(() {
                              _selectedType = value;
                            });
                          },
                          items: _placeTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(
                                type,
                                style: TextStyle(
                                  fontFamily: 'Montserrat',
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        SizedBox(height: 24.0),
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                _addPlace();
                              }
                            },
                            child: Text(
                              'Ajouter',
                              style: TextStyle(
                                fontFamily: 'Montserrat',
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
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addPlace() async {
    String customId = await _generateCustomId();

    await _firestore.collection('place').doc(customId).set({
      'id': customId,
      'id_parking': _selectedParkingId,
      'type': _selectedType,
    });

    DocumentReference parkingRef =
        _firestore.collection('parking').doc(_selectedParkingId);

    DocumentSnapshot parkingSnapshot = await parkingRef.get();
    int currentCapacite = parkingSnapshot.get('capacite') ?? 0;
    int currentPlacesDisponibles = parkingSnapshot.get('placesDisponible') ?? 0;

    int newCapacite = currentCapacite + 1;
    int newPlacesDisponibles = currentPlacesDisponibles + 1;

    await parkingRef.update({
      'capacite': newCapacite,
      'placesDisponible': newPlacesDisponibles,
    });

    _showConfirmationDialog(customId);
  }

  void _showConfirmationDialog(String customId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          content: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  radius: 30,
                  child: Icon(Icons.check, color: Colors.white, size: 40),
                ),
                SizedBox(height: 20),
                Text(
                  'La place $customId a été ajoutée avec succès',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      Navigator.pop(context);
    });
  }
}
