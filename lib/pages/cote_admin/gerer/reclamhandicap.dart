import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReclamationDetailsHandicapPage extends StatefulWidget {
  final String reclamationId;
  final Map<String, dynamic> reclamationData;

  ReclamationDetailsHandicapPage({
    required this.reclamationId,
    required this.reclamationData,
  });

  @override
  _ReclamationDetailsHandicapPageState createState() =>
      _ReclamationDetailsHandicapPageState();
}

class _ReclamationDetailsHandicapPageState
    extends State<ReclamationDetailsHandicapPage> {
  String reponse = '';
  List<String> predefinedMessages = [
    "Bonjour, nous avons bien reçu votre réclamation concernant le problème de réservation de handicap. Nous travaillons activement pour résoudre cette situation au plus vite. Merci pour votre patience.",
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
        title: Text('Détails de la réclamation - Handicap'),
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
