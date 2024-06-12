import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;

class AfficherTicketPage extends StatefulWidget {
  final String userId;
  final String reservationId;

  AfficherTicketPage({
    required this.userId,
    required this.reservationId,
  });

  @override
  _AfficherTicketPageState createState() => _AfficherTicketPageState();
}

class _AfficherTicketPageState extends State<AfficherTicketPage> {
  Map<String, dynamic>? ticketData;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchTicketData();
  }

  Future<void> _fetchTicketData() async {
    try {
      // Fetch reservation data to get the ticket ID
      DocumentSnapshot reservationDoc = await FirebaseFirestore.instance
          .collection('reservation')
          .doc(widget.reservationId)
          .get();
      Map<String, dynamic>? reservationData =
          reservationDoc.data() as Map<String, dynamic>?;

      if (reservationData == null) {
        setState(() {
          errorMessage = 'Reservation data not found';
        });
        return;
      }

      String ticketId = reservationData['ticketId'];

      // Fetch ticket data
      DocumentSnapshot ticketDoc = await FirebaseFirestore.instance
          .collection('ticket')
          .doc(ticketId)
          .get();
      ticketData = ticketDoc.data() as Map<String, dynamic>?;

      if (ticketData == null) {
        setState(() {
          errorMessage = 'Ticket data not found';
        });
        return;
      }

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
        title: Text('Afficher Ticket'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () {
              if (ticketData != null) {
                _downloadPdf();
              }
            },
          ),
        ],
      ),
      body: errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : ticketData == null
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
                                    'userId=${ticketData!['userId']},reservationId=${ticketData!['reservationId']}',
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
                          _buildDetailRow('Nom', ticketData!['name']),
                          _buildDetailRow('Prénom', ticketData!['familyName']),
                          _buildDetailRow('Email', ticketData!['email']),
                          _buildDetailRow(
                              'Début',
                              DateFormat('dd/MM/yyyy HH:mm').format(
                                  (ticketData!['debut'] as Timestamp)
                                      .toDate())),
                          _buildDetailRow(
                              'Fin',
                              DateFormat('dd/MM/yyyy HH:mm').format(
                                  (ticketData!['fin'] as Timestamp).toDate())),
                          _buildDetailRow(
                              'Type de place', ticketData!['typePlace']),
                          _buildDetailRow(
                              'ID de la place', ticketData!['idPlace']),
                          _buildDetailRow('Date d\'aujourd\'hui',
                              DateFormat('dd/MM/yyyy').format(DateTime.now())),
                          _buildDetailRow(
                              'Nom du parking', ticketData!['parkingName']),
                          _buildDetailRow('Place', ticketData!['parkingPlace']),
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
                                  '${ticketData!['prix']} DA',
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
                                'userId=${ticketData!['userId']},reservationId=${ticketData!['reservationId']}',
                            width: double.infinity,
                            height: 80,
                            drawText: false,
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

  void _downloadPdf() {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 80.0,
                    height: 80.0,
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data:
                          'userId=${ticketData!['userId']},reservationId=${ticketData!['reservationId']}',
                    ),
                  ),
                  pw.SizedBox(width: 16.0),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Ticket de réservation',
                          style: pw.TextStyle(
                            fontSize: 20.0,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 8.0),
                        pw.Text(
                          'Date et Heure: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                          style: pw.TextStyle(
                            fontSize: 16.0,
                            fontWeight: pw.FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 24.0),
              pw.Text(
                'Détails de la réservation',
                style: pw.TextStyle(
                  fontSize: 20.0,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8.0),
              _buildPdfDetailRow('Nom', ticketData!['name']),
              _buildPdfDetailRow('Prénom', ticketData!['familyName']),
              _buildPdfDetailRow('Email', ticketData!['email']),
              _buildPdfDetailRow(
                  'Début',
                  DateFormat('dd/MM/yyyy HH:mm')
                      .format((ticketData!['debut'] as Timestamp).toDate())),
              _buildPdfDetailRow(
                  'Fin',
                  DateFormat('dd/MM/yyyy HH:mm')
                      .format((ticketData!['fin'] as Timestamp).toDate())),
              _buildPdfDetailRow('Type de place', ticketData!['typePlace']),
              _buildPdfDetailRow('ID de la place', ticketData!['idPlace']),
              _buildPdfDetailRow('Date d\'aujourd\'hui',
                  DateFormat('dd/MM/yyyy').format(DateTime.now())),
              _buildPdfDetailRow('Nom du parking', ticketData!['parkingName']),
              _buildPdfDetailRow('Place', ticketData!['parkingPlace']),
              pw.SizedBox(height: 16.0),
              pw.Container(
                padding: pw.EdgeInsets.all(16.0),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFFE0E0E0),
                  borderRadius: pw.BorderRadius.circular(8.0),
                  boxShadow: [
                    pw.BoxShadow(
                      color: PdfColor.fromInt(0x40000000),
                      blurRadius: 6.0,
                      offset: PdfPoint(0, 2),
                    ),
                  ],
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Prix',
                      style: pw.TextStyle(
                        fontSize: 18.0,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text(
                      '${ticketData!['prix']} DA',
                      style: pw.TextStyle(
                        fontSize: 18.0,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromInt(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16.0),
              pw.Container(
                width: double.infinity,
                height: 80.0,
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(),
                  data:
                      'userId=${ticketData!['userId']},reservationId=${ticketData!['reservationId']}',
                  drawText: false,
                ),
              ),
            ],
          );
        },
      ),
    );

    Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  pw.Widget _buildPdfDetailRow(String label, String value) {
    return pw.Padding(
      padding: pw.EdgeInsets.symmetric(vertical: 4.0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(fontSize: 16.0),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                  fontSize: 16.0, fontWeight: pw.FontWeight.normal),
              textAlign: pw.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
