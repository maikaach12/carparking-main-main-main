import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReclamationDetailsAccessPage extends StatefulWidget {
  final String reclamationId;
  final Map<String, dynamic> reclamationData;

  ReclamationDetailsAccessPage({
    required this.reclamationId,
    required this.reclamationData,
  });

  @override
  _ReclamationDetailsAccessPageState createState() =>
      _ReclamationDetailsAccessPageState();
}

class _ReclamationDetailsAccessPageState
    extends State<ReclamationDetailsAccessPage> {
  String reponse = '';
  List<String> predefinedMessages = [
    "Merci pour votre réclamation. Nous installons des panneaux de signalisation bien visibles pour améliorer l'accès au parking.",
    "Merci pour votre réclamation. Nous planifions des inspections régulières des feux de signalisation et utilisons des panneaux temporaires en cas de besoin, en coordination avec les autorités locales pour des réparations rapides.",
    "Merci pour votre réclamation. Nous informons les utilisateurs à l'avance des travaux, proposons des itinéraires alternatifs et planifions les travaux hors des heures de pointe.",
    "Merci pour votre retour. Nous avons pris des mesures pour améliorer la circulation interne, notamment en mettant en place un marquage au sol clair, en utilisant des flèches et des panneaux, et en ayant du personnel disponible pour réguler le flux.",
  ];

  void _sendNotification(String userId, String message) {
    FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'message': message,
      'timestamp': Timestamp.now(),
      'isRead': false,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Détails de la réclamation - Accès'),
        actions: [
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              if (reponse.isNotEmpty) {
                _sendNotification(widget.reclamationData['userId'], reponse);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: ListTile(
                  title: Text('Type'),
                  subtitle: Text(widget.reclamationData['type'] ?? ''),
                ),
              ),
              Card(
                child: ListTile(
                  title: Text('Description'),
                  subtitle: Text(widget.reclamationData['description'] ?? ''),
                ),
              ),
              Card(
                child: ListTile(
                  title: Text('Statut'),
                  subtitle: Text(widget.reclamationData['status'] ?? ''),
                ),
              ),
              SizedBox(height: 16.0),
              Text('Messages prédéfinis :'),
              for (var message in predefinedMessages)
                ListTile(
                  title: Text(message),
                  onTap: () {
                    setState(() {
                      reponse = message;
                    });
                  },
                  tileColor:
                      reponse == message ? Colors.blue.withOpacity(0.3) : null,
                ),
              SizedBox(height: 16.0),
              TextField(
                onChanged: (value) {
                  setState(() {
                    reponse = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Réponse personnalisée',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: () {
                  FirebaseFirestore.instance
                      .collection('reclamations')
                      .doc(widget.reclamationId)
                      .update({
                    'status': 'terminée',
                  });
                  Navigator.pop(context);
                },
                child: Text('Clôturer la réclamation'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
