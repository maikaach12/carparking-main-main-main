import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: PaiementPage(userId: '123', prix: 1000.0),
    );
  }
}

class PaiementPage extends StatefulWidget {
  final String userId;
  final double prix;

  PaiementPage({required this.userId, required this.prix});

  @override
  _PaiementPageState createState() => _PaiementPageState();
}

class _PaiementPageState extends State<PaiementPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final _nameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cvvController = TextEditingController();

  // Expiration date fields
  String? _selectedMonth;
  String? _selectedYear;

  final List<String> _months = [
    '01',
    '02',
    '03',
    '04',
    '05',
    '06',
    '07',
    '08',
    '09',
    '10',
    '11',
    '12'
  ];

  final List<String> _years = List<String>.generate(
      20, (index) => (DateTime.now().year + index).toString());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10.0,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Paiement',
                        style: GoogleFonts.lato(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent,
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildTextField(
                          'Nom du titulaire de la carte', _nameController),
                      _buildCardNumberField(),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdownField(
                                'Mois', _months, _selectedMonth, (value) {
                              setState(() {
                                _selectedMonth = value;
                              });
                            }),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _buildDropdownField(
                                'Année', _years, _selectedYear, (value) {
                              setState(() {
                                _selectedYear = value;
                              });
                            }),
                          ),
                        ],
                      ),
                      _buildTextField('CVV', _cvvController, isNumeric: true),
                      SizedBox(height: 20),
                      _buildSummary(),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _submitForm,
                        child: Text('Valider',
                            style: GoogleFonts.lato(fontSize: 18)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle continue shopping
                    },
                    child: Text('Continuer vos achats',
                        style: GoogleFonts.lato(fontSize: 18)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController? controller,
      {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          labelText: label,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Ce champ est obligatoire';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildCardNumberField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextFormField(
        controller: _cardNumberController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          labelText: 'Numéro de carte',
          prefixIcon: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'lib/images/baridi.png', // Adjust the path based on your project structure
                  width: 30, // Adjust width and height as needed
                  height: 30,
                ),
              ],
            ),
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Ce champ est obligatoire';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdownField(String label, List<String> items,
      String? selectedItem, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          labelText: label,
        ),
        value: selectedItem,
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Ce champ est obligatoire';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSummaryRow('Sous-total', '${widget.prix.toStringAsFixed(2)} DA'),
        Divider(color: Colors.grey),
        _buildSummaryRow('Total', '${widget.prix.toStringAsFixed(2)} DA',
            isBold: true),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: GoogleFonts.lato(
                  fontSize: 16,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Enregistrer les données dans Firestore
        CollectionReference payements =
            FirebaseFirestore.instance.collection('payement');

        await payements.add({
          'userId': widget.userId,
          'prix': widget.prix,
          'nom': _nameController.text,
          'numéro de carte': _cardNumberController.text,
          'mois d\'expiration': _selectedMonth,
          'année d\'expiration': _selectedYear,
          'cvv': _cvvController.text,
          'timestamp': Timestamp.now(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Paiement réussi')),
        );

        // Rediriger vers la page de paiement externe
        const url = 'https://app.chargily.com/secure/payments';
        if (await canLaunch(url)) {
          await launch(url);
        } else {
          throw 'Impossible d\'ouvrir $url';
        }
      } catch (e) {
        // Handle and log the error
        print('Error during payment: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du paiement: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Veuillez remplir tous les champs obligatoires.')),
      );
    }
  }
}
