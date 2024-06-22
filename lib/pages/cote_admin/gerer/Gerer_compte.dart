import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class ManageAccountsPage extends StatefulWidget {
  @override
  _ManageAccountsPageState createState() => _ManageAccountsPageState();
}

class _ManageAccountsPageState extends State<ManageAccountsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  List<DocumentSnapshot> _allUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'user')
        .get();
    setState(() {
      _allUsers = snapshot.docs;
    });
  }

  Future<void> _toggleAccountStatus(String userId, bool active) async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      DocumentSnapshot adminSnapshot =
          await _firestore.collection('users').doc(currentUser.uid).get();
      if (!adminSnapshot.exists || adminSnapshot['role'] != 'admin') {
        throw Exception(
            'Error updating account status: Current user is not an admin');
      }

      await _firestore.collection('users').doc(userId).update({
        'active': active,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'User account ${active ? 'activated' : 'deactivated'} successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating account status: $e')),
      );
    }
  }

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  List<DocumentSnapshot> get _filteredUsers {
    if (_searchQuery.isEmpty) {
      return _allUsers;
    } else {
      return _allUsers.where((user) {
        String email = user['email'].toLowerCase();
        return email.contains(_searchQuery);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Accounts',
          style: GoogleFonts.montserrat(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.0),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _performSearch,
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher par email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _allUsers.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _filteredUsers.length,
              itemBuilder: (BuildContext context, int index) {
                DocumentSnapshot doc = _filteredUsers[index];
                String userId = doc.id;
                String userEmail = doc['email'];
                bool isActive = doc['active'];

                return Card(
                  color: Colors.white.withOpacity(1.0),
                  margin:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                  elevation: 5.0,
                  child: ListTile(
                    leading: Icon(
                      isActive ? Icons.check_circle : Icons.block,
                      color: isActive ? Colors.green : Colors.red,
                      size: 30.0,
                    ),
                    title: Text(userEmail),
                    trailing: IconButton(
                      icon: Icon(
                        isActive ? Icons.block : Icons.check_circle,
                        color: isActive ? Colors.red : Colors.blue,
                      ),
                      onPressed: () async {
                        await _toggleAccountStatus(userId, !isActive);
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }
}
