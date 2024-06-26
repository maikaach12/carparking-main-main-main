import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ReclamationDetailsPage extends StatefulWidget {
  final String reclamationId;
  final Map<String, dynamic> reclamationData;

  ReclamationDetailsPage({
    required this.reclamationId,
    required this.reclamationData,
  });

  @override
  _ReclamationDetailsPageState createState() => _ReclamationDetailsPageState();
}

class _ReclamationDetailsPageState extends State<ReclamationDetailsPage> {
  String reponse = '';
  String? userId;
  Map<String, dynamic>? userData;
  List<String> predefinedMessages = [
    "Nous avons bien reçu votre réclamation et nous travaillons à résoudre le problème.",
    "Nous vous prions de nous excuser pour le désagrément. Notre équipe examine la situation.",
    "Votre réclamation a été prise en compte. Nous vous tiendrons informé de son évolution.",
  ];

  @override
  void initState() {
    super.initState();
    userId = widget.reclamationData['userId'];
    _fetchUserData();
    _fetchUserIdFromMatricule();
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

  void _fetchUserIdFromMatricule() async {
    String matricule = widget.reclamationData['matricule'];
    DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
        .collection('véhicule')
        .doc(matricule)
        .get();

    if (documentSnapshot.exists) {
      setState(() {
        userId = documentSnapshot.get('userId');
      });
    }
  }

  void _signalerPersonneResponsable() async {
    if (userId != null) {
      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        int nbrSignal = userSnapshot.get('nbrSignal') ?? 0;
        nbrSignal++;

        await userSnapshot.reference.update({'nbrSignal': nbrSignal});

        if (nbrSignal == 4) {
          await userSnapshot.reference.update({'active': false});
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Personne responsable signalée')),
        );
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
        title: Text('Détails de la réclamation'),
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
              _buildInfoCard(
                'Date',
                widget.reclamationData['timestamp'] != null
                    ? (widget.reclamationData['timestamp'] as Timestamp)
                        .toDate()
                        .toString()
                    : '',
                icon: Icons.calendar_today,
              ),
              _buildInfoCard(
                'Matricule concerné',
                widget.reclamationData['matricule'] ?? '',
                icon: Icons.car_rental,
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
              if (widget.reclamationData['type'] ==
                  'Place réservée non disponible')
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton(
                    onPressed: _signalerPersonneResponsable,
                    child: Text('Signaler la personne responsable'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
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
