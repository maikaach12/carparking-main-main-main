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
  String? userId;
  Map<String, dynamic>? userData;
  List<String> predefinedMessages = [
    "Merci pour votre réclamation. Nous installons des panneaux de signalisation bien visibles pour améliorer l'accès au parking.",
    "Merci pour votre réclamation. Nous planifions des inspections régulières des feux de signalisation et utilisons des panneaux temporaires en cas de besoin, en coordination avec les autorités locales pour des réparations rapides.",
    "Merci pour votre réclamation. Nous informons les utilisateurs à l'avance des travaux, proposons des itinéraires alternatifs et planifions les travaux hors des heures de pointe.",
    "Merci pour votre retour. Nous avons pris des mesures pour améliorer la circulation interne, notamment en mettant en place un marquage au sol clair, en utilisant des flèches et des panneaux, et en ayant du personnel disponible pour réguler le flux.",
  ];

  @override
  void initState() {
    super.initState();
    userId = widget.reclamationData['userId'];
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (userId != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      if (userDoc.exists) {
        setState(() {
          userData = userDoc.data() as Map<String, dynamic>?;
        });
      }
    }
  }

  void _sendNotification(String userId) {
    FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'timestamp': Timestamp.now(),
      'isRead': false,
      'type': 'Réclamation',
      'description':
          'Votre réclamation a été résolue. Veuillez vérifier votre page "Mes réclamations" pour plus de détails.',
    });
  }

  Future<void> _updateReclamation(String reclamationId, String message) async {
    try {
      await FirebaseFirestore.instance
          .collection('reclamations')
          .doc(reclamationId)
          .update({
        'response': message,
        'responseTimestamp': Timestamp.now(),
      });
    } catch (error) {
      print('Erreur lors de la mise à jour de la réclamation: $error');
    }
  }

  void _closeReclamation() {
    FirebaseFirestore.instance
        .collection('reclamations')
        .doc(widget.reclamationId)
        .update({
      'status': 'terminée',
      'response': reponse,
      'responseTimestamp': Timestamp.now(),
    }).then((_) {
      _sendNotification(widget.reclamationData['userId']);
      Navigator.pop(context);
    }).catchError((error) {
      print('Erreur lors de la mise à jour de la réclamation: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Détails de la réclamation - Accès',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informations de la réclamation',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
              SizedBox(height: 16.0),
              _buildInfoCard(
                'Type',
                widget.reclamationData['type'] ?? '',
                icon: Icons.category,
              ),
              _buildInfoCard(
                'Description',
                widget.reclamationData['description'] ?? '',
                icon: Icons.description,
              ),
              _buildInfoCard(
                'Statut',
                widget.reclamationData['status'] ?? '',
                icon: Icons.info,
              ),
              if (userData != null) ...[
                SizedBox(height: 16.0),
                Text(
                  'Informations client',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18.0,
                  ),
                ),
                _buildInfoCard(
                  'Nom',
                  userData!['name'] ?? '',
                  icon: Icons.person,
                ),
                _buildInfoCard(
                  'Prénom',
                  userData!['familyName'] ?? '',
                  icon: Icons.person,
                ),
                _buildInfoCard(
                  'Email',
                  userData!['email'] ?? '',
                  icon: Icons.email,
                ),
                _buildInfoCard(
                  'Numéro de téléphone',
                  userData!['phoneNumber'] ?? '',
                  icon: Icons.phone,
                ),
              ],
              SizedBox(height: 16.0),
              Text(
                'Messages prédéfinis',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18.0,
                ),
              ),
              SizedBox(height: 8.0),
              ...predefinedMessages.map((message) => Card(
                    child: ListTile(
                      title: Text(message),
                      onTap: () {
                        setState(() {
                          reponse = message;
                        });
                      },
                      tileColor: reponse == message
                          ? Colors.blue.withOpacity(0.3)
                          : null,
                    ),
                  )),
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
                onPressed: _closeReclamation,
                child: Text('Clôturer la réclamation'),
                style: ElevatedButton.styleFrom(
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

  Widget _buildInfoCard(String title, String subtitle,
      {required IconData icon}) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.blue,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14.0,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 12.0,
        ),
      ),
    );
  }
}
