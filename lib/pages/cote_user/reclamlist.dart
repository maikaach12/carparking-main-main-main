import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReclamationListPage extends StatefulWidget {
  final String userId;
  ReclamationListPage({required this.userId});

  @override
  _ReclamationListPageState createState() => _ReclamationListPageState();
}

class _ReclamationListPageState extends State<ReclamationListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mes réclamations', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reclamations')
            .where('userId', isEqualTo: widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Une erreur s\'est produite'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('Aucune réclamation trouvée'));
          }
          return ListView.builder(
            padding: EdgeInsets.all(16.0),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot document = snapshot.data!.docs[index];
              Map<String, dynamic> data =
                  document.data() as Map<String, dynamic>;
              String status = data['statut'] ?? 'en attente';
              return Container(
                margin: EdgeInsets.only(bottom: 16.0),
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['type'],
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      data['description'],
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Status: $status',
                          style: TextStyle(
                            color: status == 'terminée'
                                ? Colors.green
                                : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.remove_red_eye,
                                  color: Colors.blue),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Détails de la réclamation'),
                                      content: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text('IdPlace: ${data['idPlace']}'),
                                          Text(
                                              'Matricule: ${data['matricule']}'),
                                          Text(
                                              'ReservationId: ${data['reservationId']}'),
                                          Row(
                                            children: [
                                              Text('Timestamp: '),
                                              Text(
                                                formatTimestamp(
                                                    data['timestamp']),
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      actions: <Widget>[
                                        TextButton(
                                          child: Text('Fermer'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            ),
                            if (status == 'envoyé')
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Confirmer la suppression'),
                                        content: Text(
                                            'Êtes-vous sûr de vouloir supprimer cette réclamation ?'),
                                        actions: <Widget>[
                                          TextButton(
                                            child: Text('Annuler'),
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                          TextButton(
                                            child: Text('Supprimer'),
                                            onPressed: () {
                                              document.reference.delete();
                                              Navigator.of(context).pop();
                                            },
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              ),
                          ],
                        ),
                      ],
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

  String formatTimestamp(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    final String formattedTime =
        "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    return formattedTime;
  }
}

class ModifierReclamationPage extends StatelessWidget {
  final String userId;
  final String reclamationId;
  final String typeProblem;
  final String description;

  ModifierReclamationPage({
    required this.userId,
    required this.reclamationId,
    required this.typeProblem,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    // Page pour modifier la réclamation (à implémenter)
    return Scaffold(
      appBar: AppBar(
        title: Text('Modifier Réclamation'),
      ),
      body: Center(
        child: Text('Modifier la réclamation ici'),
      ),
    );
  }
}
