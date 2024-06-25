import 'package:carparking/pages/cote_user/reservation/reservation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ListeParkingPage extends StatefulWidget {
  @override
  _ListeParkingPageState createState() => _ListeParkingPageState();
}

class _ListeParkingPageState extends State<ListeParkingPage> {
  final List<String> _sortOptions = [
    'Trier par alphabet',
    'Trier par distance'
  ];
  String _selectedSort = 'Trier par alphabet';
  String _searchQuery = '';

  Future<Map<String, dynamic>> isPromotionActive(
      Map<String, dynamic> parkingData, String parkingId, String userId) async {
    bool hasGeneralPromotion = false;
    double generalPromotionPercentage = 0;
    double userSpecificPromotionPercentage = 0;

    // Vérifier la promotion générale dans la collection 'parking'
    if (parkingData['promotion'] != null) {
      DateTime now = DateTime.now();
      DateTime dateDebut =
          (parkingData['promotion']['dateDebutPromotion'] as Timestamp)
              .toDate();
      DateTime dateFin =
          (parkingData['promotion']['dateFinPromotion'] as Timestamp).toDate();

      if (now.isAfter(dateDebut) && now.isBefore(dateFin)) {
        hasGeneralPromotion = true;
        generalPromotionPercentage =
            parkingData['promotion']['remiseEnPourcentage'] ?? 0;
      }
    }

    // Vérifier toutes les promotions spécifiques à l'utilisateur dans la collection 'promotions'
    QuerySnapshot userPromoSnapshot = await FirebaseFirestore.instance
        .collection('promotions')
        .where('userId', isEqualTo: userId)
        .where('parkingId', isEqualTo: parkingId)
        .get();

    DateTime now = DateTime.now();

    for (var doc in userPromoSnapshot.docs) {
      Map<String, dynamic> userPromoData = doc.data() as Map<String, dynamic>;
      DateTime dateDebut = userPromoData['dateDebut'].toDate();
      DateTime dateFin = userPromoData['dateFin'].toDate();

      if (now.isAfter(dateDebut) && now.isBefore(dateFin)) {
        userSpecificPromotionPercentage +=
            userPromoData['remiseEnPourcentage'] ?? 0;
      }
    }

    // Calculer la remise totale
    double totalRemise =
        generalPromotionPercentage + userSpecificPromotionPercentage;

    return {
      'isActive': hasGeneralPromotion || userSpecificPromotionPercentage > 0,
      'totalRemise': totalRemise,
    };
  }

  Future<Map<String, double>> _getRatings() async {
    QuerySnapshot<Map<String, dynamic>> ratingsSnapshot =
        await FirebaseFirestore.instance.collection('ratings').get();

    Map<String, double> ratings = {};

    for (var doc in ratingsSnapshot.docs) {
      ratings[doc['idParking']] = doc['moyenne']?.toDouble() ?? 0.0;
    }

    return ratings;
  }

  Query<Map<String, dynamic>> _parkingsQuery() {
    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection('parking').withConverter(
              fromFirestore: (snapshot, _) => snapshot.data()!,
              toFirestore: (data, _) => data,
            );

    if (_selectedSort == 'Trier par alphabet') {
      query = query.orderBy('nom');
    } else {
      query = query.orderBy('distance', descending: false);
    }

    if (_searchQuery.isNotEmpty) {
      query = query.where('nom', isEqualTo: _searchQuery.toLowerCase().trim());
    }

    return query;
  }

  @override
  Widget build(BuildContext context) {
    String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Nos parkings',
          style: GoogleFonts.montserrat(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.sort),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (BuildContext context) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      color: Colors.white,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: _sortOptions.map((option) {
                        return ListTile(
                          title: Text(
                            option,
                            style: GoogleFonts.montserrat(
                              fontSize: 16,
                              color: _selectedSort == option
                                  ? const Color.fromRGBO(33, 150, 243, 1)
                                  : Colors.black,
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _selectedSort = option;
                            });
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
                    ),
                  );
                },
              );
            },
          ),
          SizedBox(width: 12),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher par nom',
                fillColor: Colors.white,
                filled: true,
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase().trim();
                });
              },
            ),
          ),
        ),
      ),
      body: FutureBuilder<Map<String, double>>(
        future: _getRatings(),
        builder: (context, ratingSnapshot) {
          if (ratingSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (ratingSnapshot.hasError) {
            return Center(child: Text('Erreur de chargement des notes.'));
          }

          final ratings = ratingSnapshot.data ?? {};

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _parkingsQuery().snapshots(),
            builder: (BuildContext context,
                AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
              if (snapshot.hasError) {
                return Text('Une erreur s\'est produite : ${snapshot.error}');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              return ListView.separated(
                itemCount: snapshot.data!.docs.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.grey.shade300,
                ),
                itemBuilder: (BuildContext context, int index) {
                  DocumentSnapshot<Map<String, dynamic>> document =
                      snapshot.data!.docs[index];
                  Map<String, dynamic> data = document.data()!;
                  String parkingId = document.id;
                  double? moyenne = ratings[parkingId];
                  String imageFileName = data['image'] ?? 'default.jpg';

                  return FutureBuilder<Map<String, dynamic>>(
                    future: isPromotionActive(data, parkingId, currentUserId),
                    builder: (context, promoSnapshot) {
                      if (promoSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }

                      bool isPromoActive =
                          promoSnapshot.data?['isActive'] ?? false;
                      double totalRemise =
                          promoSnapshot.data?['totalRemise'] ?? 0;

                      return Stack(
                        children: [
                          Container(
                            padding: EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.5),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8.0),
                                    image: DecorationImage(
                                      image: AssetImage(
                                          'lib/images/$imageFileName'),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16.0),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        data['nom'],
                                        style: GoogleFonts.montserrat(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4.0),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on,
                                            color: Colors.grey.shade600,
                                            size: 20.0,
                                          ),
                                          SizedBox(width: 4.0),
                                          Text(
                                            data['place'],
                                            style: GoogleFonts.montserrat(
                                              fontSize: 14,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8.0),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.directions_car,
                                            color: Colors.grey.shade600,
                                            size: 20.0,
                                          ),
                                          SizedBox(width: 4.0),
                                          Text(
                                            'Capacité: ${data['capacite']}',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 4.0),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.event_available,
                                            color: Colors.grey.shade600,
                                            size: 20.0,
                                          ),
                                          SizedBox(width: 4.0),
                                          Text(
                                            'Places Disponibles: ${data['placesDisponible']}',
                                            style: GoogleFonts.montserrat(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8.0),
                                      moyenne != null
                                          ? _buildRatingStars(moyenne)
                                          : Container(),
                                      SizedBox(height: 16.0),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ReservationPage(
                                                  parkingId: document.id,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            'Réserver',
                                            style: GoogleFonts.montserrat(
                                              color: Colors.white,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color.fromRGBO(
                                                    33, 150, 243, 1),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(20.0),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isPromoActive)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.only(
                                    topRight: Radius.circular(8),
                                    bottomLeft: Radius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'PROMO - ${totalRemise.toStringAsFixed(0)}%',
                                  style: GoogleFonts.montserrat(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    int fullStars = rating.floor();
    bool halfStar = (rating - fullStars) >= 0.5;

    return Row(
      children: List.generate(5, (index) {
        if (index < fullStars) {
          return Icon(Icons.star, color: Colors.orange, size: 20);
        } else if (index == fullStars && halfStar) {
          return Icon(Icons.star_half, color: Colors.orange, size: 20);
        } else {
          return Icon(Icons.star_border, color: Colors.orange, size: 20);
        }
      }),
    );
  }
}
