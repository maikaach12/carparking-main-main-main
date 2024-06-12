import 'package:carparking/pages/cote_user/MesReservationsPage.dart';
import 'package:carparking/pages/cote_user/reservation/paiement.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TicketPage extends StatefulWidget {
  final String userId;
  final String reservationId;

  TicketPage({
    required this.userId,
    required this.reservationId,
  });

  @override
  _TicketPageState createState() => _TicketPageState();
}

class _TicketPageState extends State<TicketPage> {
  Map<String, dynamic>? userData;
  Map<String, dynamic>? reservationData;
  Map<String, dynamic>? parkingData;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // Fetch user data
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      userData = userDoc.data() as Map<String, dynamic>?;

      if (userData == null) {
        setState(() {
          errorMessage = 'User data not found';
        });
        return;
      }

      // Fetch reservation data
      DocumentSnapshot reservationDoc = await FirebaseFirestore.instance
          .collection('reservation')
          .doc(widget.reservationId)
          .get();
      reservationData = reservationDoc.data() as Map<String, dynamic>?;

      if (reservationData == null) {
        setState(() {
          errorMessage = 'Reservation data not found';
        });
        return;
      }

      // Fetch parking data
      String parkingId = reservationData!['idParking'];
      DocumentSnapshot parkingDoc = await FirebaseFirestore.instance
          .collection('parking')
          .doc(parkingId)
          .get();
      parkingData = parkingDoc.data() as Map<String, dynamic>?;

      if (parkingData == null) {
        setState(() {
          errorMessage = 'Parking data not found';
        });
        return;
      }

      // Save data to the ticket collection
      DocumentReference ticketRef =
          await FirebaseFirestore.instance.collection('ticket').add({
        'userId': widget.userId,
        'reservationId': widget.reservationId,
        'name': userData!['name'],
        'familyName': userData!['familyName'],
        'email': userData!['email'],
        'debut': reservationData!['debut'],
        'fin': reservationData!['fin'],
        'idParking': reservationData!['idParking'],
        'idPlace': reservationData!['idPlace'],
        'matricule': reservationData!['matricule'],
        'prix': reservationData!['prix'],
        'typePlace': reservationData!['typePlace'],
        'parkingName': parkingData!['nom'],
        'parkingPlace': parkingData!['place'],
        'dateTime': DateTime.now(),
      });

      // Update the reservation document with the ticket ID
      await FirebaseFirestore.instance
          .collection('reservation')
          .doc(widget.reservationId)
          .update({
        'ticketId': ticketRef.id,
      });

      setState(() {}); // Trigger UI update
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching data: $e';
      });
      print('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ticket de réservation'),
      ),
      body: errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : userData == null || reservationData == null || parkingData == null
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4.0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              QrImageView(
                                data:
                                    'userId=${widget.userId},reservationId=${widget.reservationId}',
                                version: QrVersions.auto,
                                size: 80.0,
                              ),
                              SizedBox(width: 16.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Ticket de réservation',
                                      style: TextStyle(
                                        fontSize: 20.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8.0),
                                    Text(
                                      'Date et Heure: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24.0),
                          Text(
                            'Détails de la réservation',
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8.0),
                          _buildDetailRow('Nom', userData!['name']),
                          _buildDetailRow('Prénom', userData!['familyName']),
                          _buildDetailRow('Email', userData!['email']),
                          _buildDetailRow(
                              'Début',
                              DateFormat('dd/MM/yyyy HH:mm').format(
                                  (reservationData!['debut'] as Timestamp)
                                      .toDate())),
                          _buildDetailRow(
                              'Fin',
                              DateFormat('dd/MM/yyyy HH:mm').format(
                                  (reservationData!['fin'] as Timestamp)
                                      .toDate())),
                          _buildDetailRow(
                              'Type de place', reservationData!['typePlace']),
                          _buildDetailRow(
                              'ID de la place', reservationData!['idPlace']),
                          _buildDetailRow('Date d\'aujourd\'hui',
                              DateFormat('dd/MM/yyyy').format(DateTime.now())),
                          _buildDetailRow(
                              'Nom du parking', parkingData!['nom']),
                          _buildDetailRow('Place', parkingData!['place']),
                          SizedBox(height: 16.0),
                          Container(
                            padding: EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6.0,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Prix',
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${reservationData!['prix']} DA',
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.0),
                          BarcodeWidget(
                            barcode: Barcode.code128(),
                            data:
                                'userId=${widget.userId},reservationId=${widget.reservationId}',
                            width: double.infinity,
                            height: 80,
                            drawText: false,
                          ),
                          SizedBox(height: 16.0),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => PaiementPage(
                                    userId: widget.userId,
                                  ),
                                ),
                              );
                            },
                            child: Text('Payer maintenant'),
                          ),
                          SizedBox(height: 8.0),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MesReservationsPage(),
                                ),
                              );
                            },
                            child: Text('Payer au niveau du parking'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 16.0),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
