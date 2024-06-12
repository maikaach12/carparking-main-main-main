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
    return AlertDialog(
      title: Text('Ajouter une promotion'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: InputDecoration(
                labelText: 'Remise en pourcentage',
                suffixText: '%',
              ),
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
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Date et heure de début'),
                ElevatedButton(
                  onPressed: () async {
                    final selectedDateTime =
                        await _showDateTimePicker(context, _dateDebutPromotion);
                    if (selectedDateTime != null) {
                      setState(() {
                        _dateDebutPromotion = selectedDateTime;
                      });
                    }
                  },
                  child: Text(_dateDebutPromotion != null
                      ? DateFormat('dd/MM/yyyy HH:mm')
                          .format(_dateDebutPromotion!)
                      : 'Sélectionner'),
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Date et heure de fin'),
                ElevatedButton(
                  onPressed: () async {
                    final selectedDateTime =
                        await _showDateTimePicker(context, _dateFinPromotion);
                    if (selectedDateTime != null) {
                      setState(() {
                        _dateFinPromotion = selectedDateTime;
                      });
                    }
                  },
                  child: Text(_dateFinPromotion != null
                      ? DateFormat('dd/MM/yyyy HH:mm')
                          .format(_dateFinPromotion!)
                      : 'Sélectionner'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate() &&
                _dateDebutPromotion != null &&
                _dateFinPromotion != null) {
              final promotion = {
                'remiseEnPourcentage': _remiseEnPourcentage,
                'dateDebutPromotion': Timestamp.fromDate(_dateDebutPromotion!),
                'dateFinPromotion': Timestamp.fromDate(_dateFinPromotion!),
              };
              FirebaseFirestore.instance
                  .collection('parking')
                  .doc(widget.parkingId)
                  .update({'promotion': promotion}).then((_) {
                Navigator.pop(context);
              });
            }
          },
          child: Text('Valider'),
        ),
      ],
    );
  }
}
