import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationPage extends StatefulWidget {
  final String userId;
  NotificationPage({required this.userId});

  @override
  _NotificationPageState createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    _markAllNotificationsAsRead();
  }

  void _markAllNotificationsAsRead() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: widget.userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (DocumentSnapshot doc in snapshot.docs) {
        await doc.reference.update({'isRead': true});
      }

      QuerySnapshot globalSnapshot = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isNull: true)
          .where('isRead', isEqualTo: false)
          .get();

      for (DocumentSnapshot doc in globalSnapshot.docs) {
        await doc.reference.update({'isRead': true});
      }
    } catch (e) {
      print('Error marking notifications as read: $e');
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications',
            style: GoogleFonts.roboto(
                color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              // Action pour le bouton de menu
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .orderBy('timestamp',
                descending: true) // Trier par timestamp en ordre décroissant
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erreur: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['userId'] == widget.userId || data['userId'] == null;
          }).toList();

          if (notifications.isEmpty) {
            return Center(
                child: Text('Aucune notification',
                    style: GoogleFonts.roboto(fontSize: 18)));
          }

          return ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey[300]),
            itemBuilder: (context, index) {
              final notification =
                  notifications[index].data() as Map<String, dynamic>;
              final notificationId = notifications[index].id;
              final type = notification['type'];
              final description = notification['description'];
              final timestamp = notification['timestamp'] as Timestamp;
              final formattedTime =
                  DateFormat('HH:mm').format(timestamp.toDate());
              final formattedDate = _getFormattedDate(timestamp.toDate());

              Color iconColor = Colors.purple;
              IconData iconData = Icons.notifications;

              // Définir l'icône et la couleur en fonction du type de notification
              switch (type) {
                case 'Rappel':
                  iconColor = Colors.orange;
                  iconData = Icons.notifications;
                  break;
                case 'Annulation de réservation':
                  iconColor = Colors.red;
                  iconData = Icons.cancel;
                  break;
                case 'Réservation':
                  iconColor = Colors.orange;
                  iconData = Icons.hotel;
                  break;
                case 'réclamation':
                  iconColor = Colors.blue;
                  iconData = Icons.report;
                  break;
                case 'Offre':
                  iconColor = Colors.green;
                  iconData = Icons.local_offer;
                  break;
              }

              return Dismissible(
                key: Key(notificationId),
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20.0),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  _deleteNotification(notificationId);
                },
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: iconColor.withOpacity(0.2),
                    child: Icon(iconData, color: iconColor),
                  ),
                  title: Text(type,
                      style: GoogleFonts.roboto(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Text(description, style: GoogleFonts.roboto()),
                      SizedBox(height: 4),
                      Text(formattedDate,
                          style: GoogleFonts.roboto(
                              color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  trailing: Text(formattedTime,
                      style: GoogleFonts.roboto(color: Colors.grey[600])),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getFormattedDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE').format(date);
    } else {
      return DateFormat('d MMM y').format(date);
    }
  }
}
