import 'dart:math' as math;

import 'package:carparking/pages/login_signup/loginPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  ProfilePage({required this.userId});
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  List<String> carRegistrations = [];
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchCarRegistrations();
  }

  Future<void> fetchUserData() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (userDoc.exists) {
        setState(() {
          userData = userDoc.data();
        });
      } else {
        print('User document does not exist');
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _updateEmail(String newEmail) async {
    try {
      // Update email in Firebase Authentication
      await FirebaseAuth.instance.currentUser!
          .verifyBeforeUpdateEmail(newEmail);

      // Update email in Firestore's 'users' collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'email': newEmail});

      print('Email updated successfully');
    } catch (e) {
      print('Error updating email: $e');
    }
  }

  Future<void> fetchCarRegistrations() async {
    try {
      QuerySnapshot<Map<String, dynamic>> carDocs = await FirebaseFirestore
          .instance
          .collection('véhicule')
          .where('userId', isEqualTo: widget.userId)
          .get();
      List<String> registrations = carDocs.docs.map((doc) => doc.id).toList();
      setState(() {
        carRegistrations = registrations;
      });
    } catch (e) {
      print('Error fetching car registrations: $e');
    }
  }

  Future<void> updateUserData() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'name': userData!['name'],
        'email': userData!['email'],
        'familyName': userData!['familyName'],
        'phoneNumber': userData!['phoneNumber'],
        'driverLicense': userData!['driverLicense'],
        'idCard': userData!['idCard'],
        'age': userData!['age'],
        'desactiveparmoi': userData!['desactiveparmoi'],
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User data updated successfully'),
        ),
      );
    } catch (e) {
      print('Error updating user data: $e');
    }
  }

  void _showEditDialog(String field) {
    TextEditingController controller =
        TextEditingController(text: userData![field]);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    style: GoogleFonts.poppins(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Entrer une nouvelle valeur',
                      hintStyle: GoogleFonts.poppins(fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                          textStyle: GoogleFonts.poppins(
                            fontSize: 16,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Annuler'),
                      ),
                      SizedBox(width: 8),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                          textStyle: GoogleFonts.poppins(
                            fontSize: 16,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            userData![field] = controller.text;
                          });
                          updateUserData();
                          if (field == 'email') {
                            _updateEmail(controller.text);
                          }
                          Navigator.of(context).pop();
                        },
                        child: Text('Confirmer'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> signOutAndNavigateToLogin(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({'desactiveparmoi': true});

      await FirebaseAuth.instance.signOut();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoginPage(),
        ),
      );
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  Widget topWidget(double screenWidth) {
    return Positioned(
      top: -50,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        child: Icon(
          Icons.person,
          size: 60,
          color: Colors.blue,
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

  void _showAddCarDialog() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    style: GoogleFonts.poppins(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Entrez matricule du véhicule',
                      hintStyle: GoogleFonts.poppins(fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                          textStyle: GoogleFonts.poppins(
                            fontSize: 16,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Cancel'),
                      ),
                      SizedBox(width: 8),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                          textStyle: GoogleFonts.poppins(
                            fontSize: 16,
                          ),
                        ),
                        onPressed: () async {
                          if (controller.text.isNotEmpty) {
                            await FirebaseFirestore.instance
                                .collection('véhicule')
                                .doc(controller.text)
                                .set({
                              'userId': widget.userId,
                            });
                            fetchCarRegistrations();
                          }
                          Navigator.of(context).pop();
                        },
                        child: Text('Ajouter'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
          'Mes informations',
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
            bottom: -0.4 * screenHeight,
            right: -0.4 * screenWidth,
            child: bottomWidget(screenWidth),
          ),
          Stack(
            children: [
              topWidget(screenWidth),
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
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          userData == null
                              ? Center(child: CircularProgressIndicator())
                              : Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.family_restroom),
                                                SizedBox(width: 5),
                                                Text(
                                                    'Nom: ${userData!['familyName']}'),
                                              ],
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.edit),
                                              onPressed: () =>
                                                  _showEditDialog('familyName'),
                                            ),
                                          ],
                                        ),
                                        Divider(),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.person),
                                                SizedBox(width: 5),
                                                Text(
                                                    'Prénom: ${userData!['name']}'),
                                              ],
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.edit),
                                              onPressed: () =>
                                                  _showEditDialog('name'),
                                            ),
                                          ],
                                        ),
                                        Divider(),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.email),
                                                SizedBox(width: 5),
                                                Text(
                                                    'Email: ${userData!['email']}'),
                                              ],
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.edit),
                                              onPressed: () =>
                                                  _showEditDialog('email'),
                                            ),
                                          ],
                                        ),
                                        Divider(),
                                        Row(
                                          children: [
                                            Icon(Icons.phone),
                                            SizedBox(width: 5),
                                            Expanded(
                                              child: Text(
                                                  'Numéro de téléphone: ${userData!['phoneNumber']}'),
                                            ),
                                            SizedBox(
                                                width:
                                                    8), // ou Flexible(child: SizedBox())
                                            IconButton(
                                              icon: Icon(Icons.edit),
                                              onPressed: () => _showEditDialog(
                                                  'phoneNumber'),
                                            ),
                                          ],
                                        ),
                                        Divider(),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.credit_card),
                                                SizedBox(width: 5),
                                                Text(
                                                  'Carte d\'identité: ${userData!['idCard']}',
                                                ),
                                              ],
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.edit),
                                              onPressed: () =>
                                                  _showEditDialog('idCard'),
                                            ),
                                          ],
                                        ),
                                        Divider(),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.calendar_today),
                                                SizedBox(width: 5),
                                                Text(
                                                  'Age: ${userData!['age']}',
                                                ),
                                              ],
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.edit),
                                              onPressed: () =>
                                                  _showEditDialog('age'),
                                            ),
                                          ],
                                        ),
                                        Divider(),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                'Matricule du véhicule:',
                                                style: GoogleFonts.poppins(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            Flexible(
                                              child: FloatingActionButton(
                                                onPressed: _showAddCarDialog,
                                                child: Icon(Icons.add,
                                                    color: Colors.white),
                                                backgroundColor:
                                                    const Color.fromARGB(
                                                        255, 212, 227, 240),
                                                mini: true,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),
                                        for (var carRegistration
                                            in carRegistrations)
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons
                                                      .car_rental), // Icône de voiture
                                                  SizedBox(width: 8),
                                                  Text(carRegistration),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: Icon(Icons.edit),
                                                    onPressed: () =>
                                                        _showEditCarDialog(
                                                            carRegistration), // Modifier l'immatriculation
                                                  ),
                                                  IconButton(
                                                    icon: Icon(Icons.delete),
                                                    onPressed: () =>
                                                        _deleteCarRegistration(
                                                            carRegistration), // Supprimer l'immatriculation
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        Divider(),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('Désactiver le compte'),
                                            Switch(
                                              value: userData![
                                                      'desactiveparmoi'] ??
                                                  false,
                                              onChanged: (value) async {
                                                bool confirmed =
                                                    await showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return Dialog(
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(16),
                                                      ),
                                                      child: Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(16),
                                                        ),
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(16.0),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: [
                                                              Text(
                                                                'Confirmer la désactivation du compte',
                                                                style:
                                                                    GoogleFonts
                                                                        .poppins(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 18,
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                  height: 16),
                                                              Text(
                                                                'Êtes-vous sûr de vouloir désactiver votre compte ?',
                                                                style:
                                                                    GoogleFonts
                                                                        .poppins(
                                                                  fontSize: 16,
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                  height: 24),
                                                              Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .end,
                                                                children: [
                                                                  TextButton(
                                                                    style: TextButton
                                                                        .styleFrom(
                                                                      foregroundColor:
                                                                          Colors
                                                                              .blue,
                                                                      textStyle:
                                                                          GoogleFonts
                                                                              .poppins(
                                                                        fontSize:
                                                                            16,
                                                                      ),
                                                                    ),
                                                                    child: Text(
                                                                        'Annuler'),
                                                                    onPressed: () =>
                                                                        Navigator.of(context)
                                                                            .pop(false),
                                                                  ),
                                                                  SizedBox(
                                                                      width: 8),
                                                                  TextButton(
                                                                    style: TextButton
                                                                        .styleFrom(
                                                                      foregroundColor:
                                                                          Colors
                                                                              .blue,
                                                                      textStyle:
                                                                          GoogleFonts
                                                                              .poppins(
                                                                        fontSize:
                                                                            16,
                                                                      ),
                                                                    ),
                                                                    child: Text(
                                                                        'Confirmer'),
                                                                    onPressed: () =>
                                                                        Navigator.of(context)
                                                                            .pop(true),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );

                                                if (confirmed) {
                                                  await FirebaseFirestore
                                                      .instance
                                                      .collection('users')
                                                      .doc(widget.userId)
                                                      .update({
                                                    'desactiveparmoi': true
                                                  });

                                                  await FirebaseAuth.instance
                                                      .signOut();

                                                  Navigator.pushReplacement(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          LoginPage(),
                                                    ),
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditCarDialog(String carRegistration) {
    TextEditingController controller =
        TextEditingController(text: carRegistration);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    style: GoogleFonts.poppins(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Modifier matricule',
                      hintStyle: GoogleFonts.poppins(fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                          textStyle: GoogleFonts.poppins(
                            fontSize: 16,
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Annuler'),
                      ),
                      SizedBox(width: 8),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.blue,
                          textStyle: GoogleFonts.poppins(
                            fontSize: 16,
                          ),
                        ),
                        onPressed: () async {
                          if (controller.text.isNotEmpty) {
                            await FirebaseFirestore.instance
                                .collection('véhicule')
                                .doc(carRegistration)
                                .delete();
                            await FirebaseFirestore.instance
                                .collection('véhicule')
                                .doc(controller.text)
                                .set({
                              'userId': widget.userId,
                            });
                            fetchCarRegistrations();
                          }
                          Navigator.of(context).pop();
                        },
                        child: Text('Modifier'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteCarRegistration(String carRegistration) async {
    bool confirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Row(
                        children: [
                          SizedBox(width: 8),
                          Text(
                            'Confirmer la suppression',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Voulez-vous vraiment supprimer cette immatriculation ?',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
                              textStyle: GoogleFonts.poppins(
                                fontSize: 16,
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text('Annuler'),
                          ),
                          SizedBox(width: 8),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
                              textStyle: GoogleFonts.poppins(
                                fontSize: 16,
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text('Supprimer'),
                          ),
                        ],
                      )
                    ]))));
      },
    );

    if (confirmed) {
      try {
        await FirebaseFirestore.instance
            .collection('véhicule')
            .doc(carRegistration)
            .delete();
        fetchCarRegistrations();
      } catch (e) {
        print('Error deleting car registration: $e');
      }
    }
  }
}
