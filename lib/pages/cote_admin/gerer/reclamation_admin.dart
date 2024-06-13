import 'package:carparking/pages/cote_admin/gerer/acces.dart';
import 'package:carparking/pages/cote_admin/gerer/reclamationadmindetail.dart';

import 'package:carparking/pages/cote_admin/gerer/reclamhandicap.dart';
import 'package:carparking/pages/cote_admin/gerer/reclampay.dart';
import 'package:carparking/pages/cote_admin/gerer/secur.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReclamationAdminPage extends StatefulWidget {
  @override
  _ReclamationAdminPageState createState() => _ReclamationAdminPageState();
}

class _ReclamationAdminPageState extends State<ReclamationAdminPage> {
  String adminEmail = 'admin@example.com';

  Future<String> getUserEmail(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      final userData = userDoc.data();
      if (userData != null && userData.containsKey('email')) {
        return userData['email'];
      }
    }
    return 'Email inconnu';
  }

  void navigateToDetailPage(BuildContext context, String type, String docId,
      Map<String, dynamic> reclamationData) {
    switch (type) {
      case 'Problème de paiement':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReclamationDetailsPaymentPage(
              reclamationId: docId,
              reclamationData: reclamationData,
            ),
          ),
        );
        break;
      case 'Problème de sécurité':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReclamationDetailsSecurityPage(
              reclamationId: docId,
              reclamationData: reclamationData,
            ),
          ),
        );
        break;
      case 'Difficulté daccès':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReclamationDetailsAccessPage(
              reclamationId: docId,
              reclamationData: reclamationData,
            ),
          ),
        );
        break;
      case 'Problème de réservation de handicap':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReclamationDetailsHandicapPage(
              reclamationId: docId,
              reclamationData: reclamationData,
            ),
          ),
        );
        break;
      default:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReclamationDetailsPage(
              reclamationId: docId,
              reclamationData: reclamationData,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Réclamations Admin'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance.collection('reclamations').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text('Une erreur s\'est produite');
          }
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final reclamations = snapshot.data!.docs;
          final userIds = reclamations.map((doc) => doc.get('userId')).toSet();

          return ListView.builder(
            itemCount: userIds.length,
            itemBuilder: (context, index) {
              final userId = userIds.elementAt(index);
              final userReclamations =
                  reclamations.where((doc) => doc.get('userId') == userId);

              final termineeCount = userReclamations
                  .where((doc) => doc.get('status') == 'terminée')
                  .length;
              final envoyeCount = userReclamations
                  .where((doc) => doc.get('status') == 'envoyé')
                  .length;

              return FutureBuilder<String>(
                future: getUserEmail(userId),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final userEmail = snapshot.data!;
                    return Container(
                      padding: EdgeInsets.only(right: 16.0),
                      child: ExpansionTile(
                        title: Row(
                          children: [
                            Text('$userEmail '),
                            Spacer(),
                            Row(
                              children: [
                                Text('Terminées: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text('$termineeCount',
                                    style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            SizedBox(width: 16),
                            Row(
                              children: [
                                Text('Envoyées: ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                Text('$envoyeCount',
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                        children: userReclamations.map((doc) {
                          final reclamationData =
                              doc.data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text(reclamationData['type'] ?? ''),
                            subtitle:
                                Text(reclamationData['description'] ?? ''),
                            tileColor: reclamationData['status'] == 'terminée'
                                ? Colors.green.withOpacity(0.3)
                                : null,
                            onTap: () => navigateToDetailPage(
                                context,
                                reclamationData['type'],
                                doc.id,
                                reclamationData),
                          );
                        }).toList(),
                      ),
                    );
                  } else {
                    return CircularProgressIndicator();
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
