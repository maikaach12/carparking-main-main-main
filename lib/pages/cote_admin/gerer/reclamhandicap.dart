import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
  String? userId;
  Map<String, dynamic>? userData;
  List<String> predefinedMessages = [
    "Bonjour, nous avons bien reçu votre réclamation concernant le problème de réservation de handicap. Nous travaillons activement pour résoudre cette situation au plus vite. Merci pour votre patience.",
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

  Future<void> _updateReclamation(String reclamationId, String message) async {
    await FirebaseFirestore.instance
        .collection('reclamations')
        .doc(reclamationId)
        .update({
      'response': message,
      'responseTimestamp': Timestamp.now(),
    });

    _sendNotification(widget.reclamationData['userId'], message);
  }

  void _sendNotification(String userId, String message) {
    FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'description': message,
      'timestamp': Timestamp.now(),
      'isRead': false,
      'type': 'Réclamation',
    });
  }

  Future<void> _downloadPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Détails de la réclamation - Handicap',
                style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 16),
            pw.Text('Type: ${widget.reclamationData['type']}'),
            pw.Text('Description: ${widget.reclamationData['description']}'),
            pw.Text('Statut: ${widget.reclamationData['status']}'),
            if (userData != null) ...[
              pw.Text('Nom: ${userData!['name']}'),
              pw.Text('Prénom: ${userData!['familyName']}'),
              pw.Text('Email: ${userData!['email']}'),
              pw.Text('Numéro de téléphone: ${userData!['phoneNumber']}'),
            ],
          ],
        ),
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Détails de la réclamation - Handicap',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.send),
            onPressed: () {
              if (reponse.isNotEmpty) {
                _updateReclamation(widget.reclamationId, reponse);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.download),
            onPressed: _downloadPDF,
          ),
        ],
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
                onPressed: () {
                  _updateReclamation(widget.reclamationId, reponse);
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
