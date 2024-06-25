import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:carparking/pages/cote_admin/stat/promouser.dart'; // Importez le fichier promotion.dart si nécessaire

class TopUserWidget extends StatelessWidget {
  const TopUserWidget({Key? key}) : super(key: key);

  Future<Map<String, dynamic>> _fetchTopUser() async {
    try {
      QuerySnapshot reservationSnapshot =
          await FirebaseFirestore.instance.collection('reservation').get();
      Map<String, int> userReservationCounts = {};

      reservationSnapshot.docs.forEach((reservation) {
        String userId = reservation['userId'];
        userReservationCounts[userId] =
            userReservationCounts.containsKey(userId)
                ? userReservationCounts[userId]! + 1
                : 1;
      });

      String topUserId = '';
      int maxReservations = 0;
      userReservationCounts.forEach((userId, count) {
        if (count > maxReservations) {
          topUserId = userId;
          maxReservations = count;
        }
      });

      DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(topUserId)
          .get();
      String userName = userSnapshot['name'];

      return {
        'userId': topUserId,
        'name': userName,
        'reservations': maxReservations
      };
    } catch (e) {
      print("Error fetching top user: $e");
      throw e;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchTopUser(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SpinKitCircle(
              color: Colors.pink,
              size: 50.0,
            ),
          );
        } else if (snapshot.hasError) {
          print("Error in FutureBuilder: ${snapshot.error}");
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        } else {
          String topUserName = snapshot.data?['name'] ?? '';
          int topUserReservations = snapshot.data?['reservations'] ?? 0;
          String topUserId = snapshot.data?['userId'] ?? '';

          return Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade300,
                  Color.fromARGB(255, 157, 207, 225)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 4,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conducteur VIP',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage('lib/images/avatar.png'),
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topUserName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '$topUserReservations Réservations',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        TextButton(
                          onPressed: () => showDialog(
                            context: context,
                            builder: (BuildContext context) =>
                                PromotionuserDialog(
                              userId: topUserId,
                            ),
                          ),
                          child: Text('Appliquer promotion'),
                        ),
                      ],
                    ),
                    Spacer(),
                    Icon(
                      Icons.star,
                      color: Colors.yellow,
                      size: 30,
                    ),
                  ],
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
