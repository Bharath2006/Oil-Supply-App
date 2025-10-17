import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';  
import 'package:url_launcher/url_launcher.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

import '../firebase_config.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  Future<void> _downloadCSV(Map<String, dynamic> orderData) async {
    final csvData = [
      [
        'Token', 'Plan', 'Start Date', 'End Date', 'Meals', 
        'UPI ID', 'UPI Name', 'TXN ID', 'Price'
      ],
      [
        orderData['token'],
        orderData['plan'],
        orderData['start_date'],
        orderData['end_date'],
        (orderData['meals'] as List).join(','),
        orderData['upi_id'],
        orderData['upi_name'],
        orderData['txn_id'],
        '₹${orderData['price']}'
      ]
    ];
    
    final csvString = const ListToCsvConverter().convert(csvData);
    final directory = await getDownloadsDirectory();
    final filePath = '${directory?.path}/order_${orderData['token']}.csv';
    final file = File(filePath);
    
    await file.writeAsString(csvString);
    
    await FirebaseConfig.firestore
        .collection('orders')
        .doc(orderData['token'])
        .update({'csv_downloaded': true});
  }

  Future<void> _contactSupport(String email, String token) async {
    final url = 'https://wa.me/91XXXXXXXXXX?text=Hi%20Admin,%20I%20need%20help%20with%20my%20order.%0AEmail:%20$email%0AToken:%20$token';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view dashboard')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseConfig.firestore
            .collection('orders')
            .where('email', isEqualTo: user.email)
            .orderBy('created_at', descending: true)
            .limit(4)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data?.docs ?? [];

          if (orders.isEmpty) {
            return const Center(child: Text('No orders found'));
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              final startDate = DateTime.parse(order['start_date']);
              final endDate = DateTime.parse(order['end_date']);
              final meals = (order['meals'] as List).join(', ');
              
              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Token: ${order['token']}', 
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('₹${order['price']}', 
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Plan: ${order['plan']}'),
                      Text('Meals: $meals'),
                      Text('Dates: ${DateFormat('dd MMM').format(startDate)} - ${DateFormat('dd MMM yyyy').format(endDate)}'),
                      Text('Address: ${order['address']}'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          ElevatedButton(
                            onPressed: order['csv_downloaded'] == true 
                                ? null 
                                : () => _downloadCSV(order),
                            child: const Text('Download CSV'),
                          ),
                          ElevatedButton(
                            onPressed: () => _contactSupport(user.email ?? '', order['token']),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text('WhatsApp Support'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}