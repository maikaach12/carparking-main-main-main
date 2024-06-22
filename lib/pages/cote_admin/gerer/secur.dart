import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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
  String? userId;
  Map<String, dynamic>? userData;
  List<String> predefinedMessages = [];

  @override
  void initState() {
    super.initState();
    userId = widget.reclamationData['userId'];
    _fetchUserData();

    // Initialize predefined messages based on the description
    if (widget.reclamationData['description'] ==
        "problème de vols dans le parking") {
      predefinedMessages = [
        "Bonjour, votre signalement de vol est pris très au sérieux. Nous avons immédiatement lancé une enquête et pris des mesures pour renforcer la sécurité. Nous vous tiendrons informé de tout développement. Merci de votre coopération.",
      ];
    } else {
      predefinedMessages = [
        "Bonjour, nous prenons note de votre préoccupation concernant la sécurité dans le parking. Nous sommes en train d'évaluer la situation et de mettre en place des mesures pour garantir votre sécurité. Merci de votre vigilance.",
        "Bonjour, nous sommes conscients de la présence de personnes suspectes dans le parking. Nous avons alerté nos équipes de sécurité et sommes en train de prendre les mesures nécessaires pour assurer votre sécurité. Merci de votre compréhension et de votre collaboration.",
      ];
    }
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

  void _sendNotification(String userId, String message) {
    FirebaseFirestore.instance.collection('notifications').add({
      'userId': userId,
      'description': message,
      'timestamp': Timestamp.now(),
      'isRead': false,
    });
  }

  Future<void> _downloadPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Détails de la réclamation - Sécurité',
                style: pw.TextStyle(fontSize: 24)),
            pw.SizedBox(height: 16),
            pw.Text('Type: ${widget.reclamationData['type']}'),
            pw.Text('Description: ${widget.reclamationData['description']}'),
            if (widget.reclamationData['description'] ==
                "problème de vols dans le parking") ...[
              pw.Text(
                  'Date: ${DateFormat('yyyy-MM-dd').format((widget.reclamationData['date'] as Timestamp).toDate())}'),
              pw.Text('Heure: ${widget.reclamationData['heure']}'),
              pw.Text('Lieu: ${widget.reclamationData['lieu']}'),
              pw.Text('ID Place: ${widget.reclamationData['idPlace']}'),
              pw.Text(
                  'Description du vol: ${widget.reclamationData['descriptionVol']}'),
            ],
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
          'Détails de la réclamation - Sécurité',
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
                _sendNotification(widget.reclamationData['userId'], reponse);
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
              if (widget.reclamationData['description'] ==
                  "problème de vols dans le parking") ...[
                _buildInfoCard(
                  'Date',
                  DateFormat('yyyy-MM-dd').format(
                      (widget.reclamationData['date'] as Timestamp).toDate()),
                  icon: Icons.date_range,
                ),
                _buildInfoCard(
                  'Heure',
                  widget.reclamationData['heure'] ?? '',
                  icon: Icons.access_time,
                ),
                _buildInfoCard(
                  'Lieu',
                  widget.reclamationData['lieu'] ?? '',
                  icon: Icons.location_on,
                ),
                _buildInfoCard(
                  'ID Place',
                  widget.reclamationData['idPlace'] ?? '',
                  icon: Icons.confirmation_number,
                ),
                _buildInfoCard(
                  'Description du vol',
                  widget.reclamationData['descriptionVol'] ?? '',
                  icon: Icons.description,
                ),
              ],
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
      elevation: 2.0, // Ajoute une légère ombre pour un effet de relief
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0), // Bords arrondis
      ),
      margin: EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.blue, // Couleur de l'icône
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold, // Titre en gras
            fontSize: 16.0, // Taille de police du titre
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14.0, // Taille de police du sous-titre
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.0, // Espacement horizontal du contenu
          vertical: 12.0, // Espacement vertical du contenu
        ),
      ),
    );
  }
}
