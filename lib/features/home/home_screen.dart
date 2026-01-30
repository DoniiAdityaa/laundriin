import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/typography.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _shopName = 'laundriin'; // default name
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _loadShopName();
  }

  Future<void> _loadShopName() async {
    try {
      final doc = await _firestore.collection('users').doc(_userId).get();
      if (doc.exists && doc.data() != null) {
        final shopInfo = doc.data()!['shopInfo'] ?? {};
        final shopName = shopInfo['shopName']?.toString().trim();

        setState(() {
          _shopName = (shopName != null && shopName.isNotEmpty)
              ? shopName
              : 'laundriin';
        });

        print('[LOAD] Shop name: $_shopName');
      }
    } catch (e) {
      print('[ERROR] Loading shop name: $e');
      // Keep default 'laundriin' if error occurs
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgApp,
      body: SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_shopName, style: lBold),
          ],
        ),
      )),
    );
  }
}
