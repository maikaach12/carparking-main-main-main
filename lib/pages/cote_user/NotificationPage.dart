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

class _NotificationPageState extends State<NotificationPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking notification as read: $e');
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
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Tous'),
            Tab(text: 'Non lues'),
          ],
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.black,
          indicatorColor: Colors.blue,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationList(false),
          _buildNotificationList(true),
        ],
      ),
    );
  }

  Widget _buildNotificationList(bool unreadOnly) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .orderBy('timestamp', descending: true)
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

        if (unreadOnly) {
          notifications.removeWhere((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['isRead'] as bool;
          });
        }

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
            final notificationDoc = notifications[index];
            final notification = notificationDoc.data() as Map<String, dynamic>;
            final notificationId = notificationDoc.id;
            final type = notification['type'];
            final description = notification['description'];
            final timestamp = notification['timestamp'] as Timestamp;
            bool isRead = notification['isRead'] as bool;
            final formattedTime =
                DateFormat('HH:mm').format(timestamp.toDate());
            final formattedDate = _getFormattedDate(timestamp.toDate());

            Color iconColor = Colors.purple;
            IconData iconData = Icons.notifications;

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
              case 'Réclamation':
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
              child: StatefulBuilder(
                builder:
                    (BuildContext context, StateSetter setStateNotification) {
                  return GestureDetector(
                    onTap: () {
                      if (!isRead) {
                        setStateNotification(() {
                          isRead = true;
                        });
                        _markNotificationAsRead(notificationId);
                      }
                    },
                    child: Container(
                      color: isRead ? Colors.white : Colors.blue[50],
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: iconColor.withOpacity(0.2),
                          child: Icon(iconData, color: iconColor),
                        ),
                        title: Text(type,
                            style: GoogleFonts.roboto(
                                fontWeight: FontWeight.bold)),
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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isRead)
                              Container(
                                margin: EdgeInsets.only(right: 8.0),
                                width: 8.0,
                                height: 8.0,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Text(formattedTime,
                                style: GoogleFonts.roboto(
                                    color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
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
