import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PromotionuserDialog extends StatefulWidget {
  final String userId;

  PromotionuserDialog({required this.userId});

  @override
  _PromotionuserDialogState createState() => _PromotionuserDialogState();
}

class _PromotionuserDialogState extends State<PromotionuserDialog> {
  final _formKey = GlobalKey<FormState>();
  double _remiseEnPourcentage = 0.0;
  DateTime? _dateDebutPromotion;
  DateTime? _dateFinPromotion;
  bool _isSubmitting = false;

  Future<DateTime?> _showDateTimePicker(
      BuildContext context, DateTime? initialDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDate ?? DateTime.now()),
      );

      if (time != null) {
        return DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: SingleChildScrollView(
        // Utilisation de SingleChildScrollView ici
        child: contentBox(context),
      ),
    );
  }

  Widget contentBox(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.0,
            offset: Offset(0.0, 10.0),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCouponCard(),
            SizedBox(height: 20),
            _buildDateTimeSelector(
              'Date et heure de début',
              _dateDebutPromotion,
              (selectedDateTime) {
                setState(() {
                  _dateDebutPromotion = selectedDateTime;
                });
              },
            ),
            SizedBox(height: 20),
            _buildDateTimeSelector(
              'Date et heure de fin',
              _dateFinPromotion,
              (selectedDateTime) {
                setState(() {
                  _dateFinPromotion = selectedDateTime;
                });
              },
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: _submitPromotion,
                  child: Text('Valider'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 124, 178, 202),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
              ],
            ),
            SizedBox(
                height: screenHeight * 0.1), // Espacement supplémentaire en bas
          ],
        ),
      ),
    );
  }

  Widget _buildCouponCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 124, 178, 202),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            'PROMOTION',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          SizedBox(height: 10),
          Text(
            '${_remiseEnPourcentage.toStringAsFixed(0)}%',
            style: TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'OFF',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          SizedBox(height: 10),
          TextFormField(
            decoration: InputDecoration(
              hintText: 'Entrez le pourcentage',
              hintStyle: TextStyle(color: Colors.white70),
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
            style: TextStyle(color: Colors.white),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer un pourcentage de remise';
              }
              final remise = double.tryParse(value);
              if (remise == null || remise < 0 || remise > 100) {
                return 'Veuillez entrer un pourcentage valide entre 0 et 100';
              }
              return null;
            },
            onChanged: (value) {
              setState(() {
                _remiseEnPourcentage = double.tryParse(value) ?? 0.0;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeSelector(
      String label, DateTime? dateTime, Function(DateTime?) onSelect) {
    return InkWell(
      onTap: () async {
        final selectedDateTime = await _showDateTimePicker(context, dateTime);
        onSelect(selectedDateTime);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              dateTime != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(dateTime)
                  : label,
              style: TextStyle(fontSize: 16),
            ),
            Icon(Icons.calendar_today, size: 20),
          ],
        ),
      ),
    );
  }

  void _submitPromotion() async {
    if (_isSubmitting) return; // Empêcher les soumissions multiples
    if (_formKey.currentState!.validate() &&
        _dateDebutPromotion != null &&
        _dateFinPromotion != null) {
      setState(() {
        _isSubmitting = true;
      });
      final promotion = {
        'dateDebutPromotiontop': Timestamp.fromDate(_dateDebutPromotion!),
        'dateFinPromotiontop': Timestamp.fromDate(_dateFinPromotion!),
        'remiseEnPourcentagetop': _remiseEnPourcentage,
        'topuserId': widget.userId, // Ajouter l'ID utilisateur sélectionné
      };
      try {
        // Ajoute la sous-collection 'promotiontop' dans le document de l'utilisateur spécifié
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('promotiontop')
            .add(promotion);

        // Envoi de notification à l'utilisateur spécifique
        final dateFinPromotionFormatted =
            DateFormat('dd/MM/yyyy HH:mm').format(_dateFinPromotion!);
        final notificationDescription =
            "Ne manquez pas notre offre exceptionnelle ! Profitez dès maintenant de notre promotion exclusive valable jusqu'au $dateFinPromotionFormatted";

        await FirebaseFirestore.instance.collection('notifications').add({
          'timestamp': Timestamp.now(),
          'isRead': false,
          'description': notificationDescription,
          'type': 'Offre',
          'userId': widget.userId,
        });

        // Ajouter la promotion dans la collection 'promotions' pour chaque parking
        QuerySnapshot parkingSnapshot =
            await FirebaseFirestore.instance.collection('parking').get();

        for (var doc in parkingSnapshot.docs) {
          await FirebaseFirestore.instance.collection('promotions').add({
            'dateDebut': Timestamp.fromDate(_dateDebutPromotion!),
            'dateFin': Timestamp.fromDate(_dateFinPromotion!),
            'remiseEnPourcentage': _remiseEnPourcentage,
            'userId': widget.userId,
            'parkingId': doc.id,
          });
        }

        setState(() {
          _isSubmitting = false;
        });
        Navigator.pop(context);
      } catch (e) {
        print('Erreur lors de la validation de la promotion: $e');
        setState(() {
          _isSubmitting = false;
        });
        // Afficher un message d'erreur à l'utilisateur si nécessaire
      }
    }
  }
}
