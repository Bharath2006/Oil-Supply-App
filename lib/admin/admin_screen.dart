import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../firebase_config.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  String _selectedPlanFilter = 'All';
  String _selectedMealFilter = 'All';
  String _selectedAddressFilter = 'All';
  DateTime _selectedDateFilter = DateTime.now();
  String? _scannedTokenFilter;
  bool _isLoading = false;
  String? _errorMessage;
  final Map<String, DocumentSnapshot> _orderCache = {};
  final List<String> _planOptions = ['All', 'Daily', 'Weekly', 'Monthly'];
  final List<String> _mealOptions = ['All', 'Breakfast', 'Lunch', 'Dinner'];
  final List<String> _addressOptions = [
    'All',
    'Sai Ram PG',
    'Shanti Hostel',
    'Ganesh PG',
    'Krishna Hostel',
    'Other',
  ];
  MobileScannerController _scannerController = MobileScannerController();

  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
    _scannerController = MobileScannerController(
      torchEnabled: false,
      formats: [BarcodeFormat.qrCode],
    );
  }

  void _initializeControllers() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
    _scannerController = MobileScannerController(
      torchEnabled: false,
      formats: [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scannerController.dispose();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _scannerController.start();
    } else if (state == AppLifecycleState.paused) {
      _scannerController.stop();
    }
  }

  Future<void> _initializeData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final todayOrders = await _fetchOrdersForDate(_selectedDateFilter);
      if (todayOrders.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No orders found for today'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      for (var doc in todayOrders) {
        _orderCache[doc.id] = doc;
      }
    } on FirebaseException catch (e) {
      if (e.code == 'failed-precondition') {
        _handleError('Database index required. Please contact support.');
      } else {
        _handleError('Failed to initialize data: ${e.message}');
      }
    } catch (e) {
      _handleError('Failed to initialize data: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<List<DocumentSnapshot>> _fetchOrdersForDate(DateTime date) async {
    try {
      final formattedDate = _formatDate(date);
      final querySnapshot = await FirebaseConfig.firestore
          .collection('orders')
          .where('start_date', isLessThanOrEqualTo: formattedDate)
          .get();

      return querySnapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final endDate = data['end_date'] as String?;
        return endDate != null && endDate.compareTo(formattedDate) >= 0;
      }).toList();
    } catch (e) {
      _handleError('Failed to fetch orders: ${e.toString()}');
      return [];
    }
  }

  String _formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Future<void> _scanQRCode() async {
    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Colors.orange.shade50],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green, Colors.deepOrange.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.shade200.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Scan QR Code',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      MobileScanner(
                        controller: _scannerController,
                        fit: BoxFit.cover,
                        onDetect: (capture) {
                          final barcode = capture.barcodes.firstWhere(
                            (b) => b.rawValue != null,
                            orElse: () => Barcode(rawValue: null),
                          );
                          if (barcode.rawValue != null) {
                            Navigator.pop(context);
                            setState(() {
                              _scannedTokenFilter = barcode.rawValue;
                              _selectedPlanFilter = 'All';
                              _selectedMealFilter = 'All';
                              _selectedAddressFilter = 'All';
                              _selectedDateFilter = DateTime.now();
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Scanned token: ${barcode.rawValue}',
                                  style: GoogleFonts.poppins(),
                                ),
                                backgroundColor: Colors.green.shade600,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      _buildLuxuryScannerOverlay(),
                      Positioned(
                        bottom: 30,
                        right: 30,
                        child: FloatingActionButton(
                          backgroundColor: Colors.white,
                          elevation: 4,
                          child: Icon(Icons.flash_on, color: Colors.green),
                          onPressed: () => _scannerController.toggleTorch(),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Align QR code within the frame',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      _handleError('Failed to scan QR code: ${e.toString()}');
    }
  }

  Widget _buildLuxuryScannerOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const cutoutSize = 260.0;
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final cutoutOffset = Offset(
          (width - cutoutSize) / 2,
          (height - cutoutSize) / 2 - 30,
        );

        return Stack(
          children: [
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.5),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.transparent,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                    child: Container(color: Colors.black.withOpacity(0.5)),
                  ),
                  Positioned(
                    left: cutoutOffset.dx,
                    top: cutoutOffset.dy,
                    child: Container(
                      width: cutoutSize,
                      height: cutoutSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              left: cutoutOffset.dx,
              top: cutoutOffset.dy,
              child: Container(
                width: cutoutSize,
                height: cutoutSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.green, width: 3),
                ),
              ),
            ),
            Positioned.fill(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(seconds: 2),
                curve: Curves.easeInOut,
                builder: (context, value, _) {
                  return Positioned(
                    top: cutoutOffset.dy + value * (cutoutSize - 4),
                    left: cutoutOffset.dx,
                    child: Container(
                      width: cutoutSize,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade200.withOpacity(0.1),
                            Colors.green,
                            Colors.orange.shade200.withOpacity(0.1),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.shade300.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _clearScanFilter() => setState(() => _scannedTokenFilter = null);

  Future<void> _exportAllOrders() async {
    try {
      setState(() => _isLoading = true);
      final querySnapshot = await FirebaseConfig.firestore
          .collection('orders')
          .get();

      final csvData = [
        [
          'Token',
          'Email',
          'Plan',
          'Start Date',
          'End Date',
          'Meals',
          'Address',
          'UPI ID',
          'UPI Name',
          'TXN ID',
          'Price',
          'Confirmed',
        ],
        ...querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return [
            data['token'] ?? '',
            data['email'] ?? '',
            data['plan'] ?? '',
            data['start_date'] ?? '',
            data['end_date'] ?? '',
            (data['meals'] as List?)?.join(', ') ?? '',
            data['address'] ?? '',
            data['upi_id'] ?? '',
            data['upi_name'] ?? '',
            data['txn_id'] ?? '',
            data['price'] ?? '',
            data['confirmed']?.toString() ?? '',
          ];
        }),
      ];

      final csvString = const ListToCsvConverter().convert(csvData);
      final directory = await getDownloadsDirectory();
      final filePath =
          '${directory?.path}/all_orders_${_formatDate(DateTime.now())}.csv';
      final file = File(filePath);
      await file.writeAsString(csvString);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Exported to $filePath')));
      }
    } catch (e) {
      _handleError('Failed to export orders: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateDeliveryStatus(
    String token,
    String date,
    String meal,
    bool delivered,
  ) async {
    try {
      setState(() => _isLoading = true);
      await FirebaseConfig.firestore.collection('orders').doc(token).update({
        'delivery_status.$date.$meal': delivered,
      });

      final doc = await FirebaseConfig.firestore
          .collection('orders')
          .doc(token)
          .get();
      _orderCache[token] = doc;
    } catch (e) {
      _handleError('Failed to update delivery status: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    try {
      final picked = await showDatePicker(
        context: context,
        initialDate: _selectedDateFilter,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
      );
      if (picked != null && picked != _selectedDateFilter) {
        setState(() {
          _selectedDateFilter = picked;
          _scannedTokenFilter = null;
        });
        await _preCacheOrdersForDate(picked);
      }
    } catch (e) {
      _handleError('Failed to select date: ${e.toString()}');
    }
  }

  Future<void> _preCacheOrdersForDate(DateTime date) async {
    try {
      final orders = await _fetchOrdersForDate(date);
      for (var doc in orders) {
        _orderCache[doc.id] = doc;
      }
    } catch (e) {
      _handleError('Failed to cache orders: ${e.toString()}');
    }
  }

  Query _buildQuery() {
    Query query = FirebaseConfig.firestore.collection('orders');

    if (_scannedTokenFilter != null && _scannedTokenFilter!.isNotEmpty) {
      return query.where('token', isEqualTo: _scannedTokenFilter);
    }

    if (_selectedPlanFilter != 'All') {
      query = query.where('plan', isEqualTo: _selectedPlanFilter);
    }
    if (_selectedMealFilter != 'All') {
      query = query.where('mealtype', isEqualTo: _selectedMealFilter);
    }
    if (_selectedAddressFilter != 'All') {
      query = query.where('address', isEqualTo: _selectedAddressFilter);
    }

    return query.orderBy('created_at', descending: true);
  }

  void _handleError(String message) {
    if (mounted) {
      setState(() {
        _errorMessage = message;
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = GoogleFonts.poppins(
      fontSize: 13,
      color: Colors.grey[800],
    );
    final titleStyle = GoogleFonts.poppins(
      fontSize: 15,
      fontWeight: FontWeight.w600,
    );

    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: Text(
          'Admin Panel',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanQRCode,
            tooltip: 'Scan QR Code',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    if (_scannedTokenFilter != null)
                      _buildScanFilterBanner(textStyle),
                    _buildFilterCard(textStyle),
                    const SizedBox(height: 12),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: _buildQuery().snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }

                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final docs = snapshot.data?.docs ?? [];
                          final filteredDocs = _filterDocsByDate(docs);

                          return filteredDocs.isEmpty
                              ? Center(
                                  child: Text(
                                    'No orders found for ${DateFormat('MMM dd, yyyy').format(_selectedDateFilter)}',
                                    style: textStyle,
                                  ),
                                )
                              : ListView.separated(
                                  controller: _scrollController,
                                  itemCount: filteredDocs.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final doc = filteredDocs[index];
                                    final order =
                                        doc.data() as Map<String, dynamic>;
                                    return _buildOrderCard(
                                      token: order['token'] ?? '',
                                      order: order,
                                      deliveryStatus:
                                          order['delivery_status'] ?? {},
                                      textStyle: textStyle,
                                      titleStyle: titleStyle,
                                    );
                                  },
                                );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  List<DocumentSnapshot> _filterDocsByDate(List<DocumentSnapshot> docs) {
    final formattedDate = _formatDate(_selectedDateFilter);
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      try {
        final start = data['start_date'] as String?;
        final end = data['end_date'] as String?;
        return start != null &&
            end != null &&
            start.compareTo(formattedDate) <= 0 &&
            end.compareTo(formattedDate) >= 0;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  Widget _buildOrderCard({
    required String token,
    required Map<String, dynamic> order,
    required Map<String, dynamic> deliveryStatus,
    required TextStyle textStyle,
    required TextStyle titleStyle,
  }) {
    return Card(
      elevation: 4,
      shadowColor: Colors.orange.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        collapsedIconColor: Colors.grey,
        iconColor: Colors.green,
        title: Text('$token - ${order['email'] ?? ''}', style: titleStyle),
        subtitle: Text(
          '${order['plan'] ?? ''} • ${order['address'] ?? ''}',
          style: textStyle,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meals: ${(order['meals'] as List?)?.join(', ') ?? ''}',
                  style: textStyle,
                ),
                Text(
                  'Dates: ${order['start_date'] ?? ''} to ${order['end_date'] ?? ''}',
                  style: textStyle,
                ),
                Text('Price: ₹${order['price'] ?? ''}', style: textStyle),
                const SizedBox(height: 6),
                const Divider(),
                Text('Delivery Status:', style: titleStyle),
                ..._buildDeliveryStatusList(token, deliveryStatus, textStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDeliveryStatusList(
    String token,
    Map<String, dynamic> deliveryStatus,
    TextStyle textStyle,
  ) {
    return deliveryStatus.entries.map((dateEntry) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            dateEntry.key,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
          ...(dateEntry.value as Map<String, dynamic>).entries.map((mealEntry) {
            return CheckboxListTile(
              title: Text(mealEntry.key, style: textStyle),
              value: mealEntry.value as bool? ?? false,
              onChanged: (bool? value) {
                if (value != null) {
                  _updateDeliveryStatus(
                    token,
                    dateEntry.key,
                    mealEntry.key,
                    value,
                  );
                }
              },
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            );
          }),
        ],
      );
    }).toList();
  }

  Widget _buildScanFilterBanner(TextStyle textStyle) {
    return Card(
      color: Colors.orange.shade100,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Icon(Icons.filter_alt, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Filtering by scanned token: $_scannedTokenFilter',
                style: textStyle.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: Colors.green),
              onPressed: _clearScanFilter,
              tooltip: 'Clear scan filter',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard(TextStyle textStyle) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 5,
      shadowColor: Colors.orange.shade100,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_alt_rounded, color: Colors.green, size: 22),
                const SizedBox(width: 6),
                Text(
                  'Filters',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _dropdown(
                    'Plan',
                    _selectedPlanFilter,
                    _planOptions,
                    (v) => setState(() {
                      _selectedPlanFilter = v!;
                      _scannedTokenFilter = null;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _dropdown(
                    'Meal',
                    _selectedMealFilter,
                    _mealOptions,
                    (v) => setState(() {
                      _selectedMealFilter = v!;
                      _scannedTokenFilter = null;
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _dropdown(
                    'Address',
                    _selectedAddressFilter,
                    _addressOptions,
                    (v) => setState(() {
                      _selectedAddressFilter = v!;
                      _scannedTokenFilter = null;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context),
                    borderRadius: BorderRadius.circular(8),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Date'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat(
                              'dd MMM yyyy',
                            ).format(_selectedDateFilter),
                            style: textStyle,
                          ),
                          const Icon(
                            Icons.calendar_today,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Export All Orders to CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
                onPressed: _exportAllOrders,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      items: options
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(e, style: GoogleFonts.poppins()),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(labelText: label),
    );
  }
}
