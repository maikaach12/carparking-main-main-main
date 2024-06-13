import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReclamationDetailsSecurityPage extends StatefulWidget {
  final String reclamationId;
  final Map<String, dynamic> reclamationData;

  ReclamationDetailsSecurityPage({
    required this.reclamationId,
    required this.reclamationData,
  });

  @override
  _ReclamationDetailsSecurityPageState createState() =>
      _ReclamationDetailsSecurityPageState();
}

class _ReclamationDetailsSecurityPageState
    extends State<ReclamationDetailsSecurityPage> {
  String reponse = '';
  List<String> predefinedMessages = [
    "Bonjour, nous prenons note de votre préoccupation concernant la sécurité dans le parking. Nous sommes en train d'évaluer la situation et de mettre en place des mesures pour garantir votre sécurité. Merci de votre vigilance.",
    "Bonjour, votre signalement de vol est pris très au sérieux. Nous avons immédiatement lancé une enquête et pris des mesures pour renforcer la sécurité. Nous vous tiendrons informé de tout développement. Merci de votre coopération.",
    "Bonjour, nous sommes conscients de la présence de personnes suspectes dans le parking. Nous avons alerté nos équipes de sécurité et sommes en train de prendre les mesures nécessaires pour assurer votre sécurité. Merci de votre compréhension et de votre collaboration.",
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
        title: Text('Détails de la réclamation - Sécurité'),
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
