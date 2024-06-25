import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PromotionDialog extends StatefulWidget {
  final String parkingId;

  PromotionDialog({required this.parkingId});

  @override
  _PromotionDialogState createState() => _PromotionDialogState();
}

class _PromotionDialogState extends State<PromotionDialog> {
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
      child: contentBox(context),
    );
  }

  Widget contentBox(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return SingleChildScrollView(
      child: Container(
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
                      padding:
                          EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                  ),
                ],
              ),
              SizedBox(
                  height:
                      screenHeight * 0.1), // Espacement supplémentaire en bas
            ],
          ),
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
        'remiseEnPourcentage': _remiseEnPourcentage,
        'dateDebutPromotion': Timestamp.fromDate(_dateDebutPromotion!),
        'dateFinPromotion': Timestamp.fromDate(_dateFinPromotion!),
      };
      try {
        await FirebaseFirestore.instance
            .collection('parking')
            .doc(widget.parkingId)
            .update({'promotion': promotion});

        // Envoi de notification à tous les utilisateurs
        final users =
            await FirebaseFirestore.instance.collection('users').get();
        final dateFinPromotionFormatted =
            DateFormat('dd/MM/yyyy HH:mm').format(_dateFinPromotion!);
        final notificationDescription =
            "Ne manquez pas nos offres exceptionnelles ! Profitez dès maintenant de nos promotions exclusives valables jusqu'au $dateFinPromotionFormatted";

        for (final userDoc in users.docs) {
          await FirebaseFirestore.instance.collection('notifications').add({
            'timestamp': Timestamp.now(),
            'isRead': false,
            'description': notificationDescription,
            'type': 'Offre',
            'userId': userDoc.id,
          });
        }

        await _addNotification();
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

  Future<void> _addNotification() async {
    // Vous pouvez implémenter la logique d'ajout de notification ici si nécessaire
  }
}
