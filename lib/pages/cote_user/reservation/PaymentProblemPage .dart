import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PaymentProblemPage extends StatefulWidget {
  final String reclamationId;
  final Map<String, dynamic> reclamationData;

  PaymentProblemPage({
    required this.reclamationId,
    required this.reclamationData,
  });

  @override
  _PaymentProblemPageState createState() => _PaymentProblemPageState();
}

class _PaymentProblemPageState extends State<PaymentProblemPage> {
  String? selectedMessage;
  final List<String> predefinedMessages = [
    "Réclamation reçue concernant un problème de paiement. Nous étudions la situation pour résoudre le problème rapidement. Nous vous tiendrons informés.",
    "Après vérification, le problème de paiement était dû à une erreur technique. Correction apportée.",
    "Problème de paiement lié à la connexion Internet. Réseau renforcé.",
    "Vous pouvez payer plus tard au niveau du parking.",
  ];

  void _sendNotification(String userId, String message) {
    FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'type': 'Problème de paiement',
      'description': message,
      'timestamp': Timestamp.now(),
      'isRead': false,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Problème de paiement'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sélectionnez un message prédéfini :',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: predefinedMessages.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedMessage = predefinedMessages[index];
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(16.0),
                      margin: EdgeInsets.only(bottom: 8.0),
                      decoration: BoxDecoration(
                        color: selectedMessage == predefinedMessages[index]
                            ? Colors.blue.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(predefinedMessages[index]),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: selectedMessage != null
                  ? () {
                      _sendNotification(
                          widget.reclamationData['userId'], selectedMessage!);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Notification envoyée'),
                        ),
                      );
                    }
                  : null,
              child: Text('Envoyer la notification'),
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
    );
  }
}
