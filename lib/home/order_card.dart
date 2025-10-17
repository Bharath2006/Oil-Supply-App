import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../order/order_model.dart';

class OrderCard extends StatefulWidget {
  final FoodOrder order;
  final DateTime date;

  const OrderCard({Key? key, required this.order, required this.date})
    : super(key: key);

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  Future<void> _shareQR(BuildContext context) async {
    try {
      final painter = QrPainter(
        data: widget.order.token,
        version: QrVersions.auto,
        color: const Color(0xFF000000),
        emptyColor: Colors.white,
        gapless: true,
      );
      final picData = await painter.toImageData(400);

      if (picData != null) {
        final buffer = picData.buffer;
        await Share.shareXFiles([
          XFile.fromData(
            Uint8List.view(buffer),
            name: 'order_qr.png',
            mimeType: 'image/png',
          ),
        ], text: 'Order QR (TFN: ${widget.order.token})');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to generate QR code.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sharing QR: $e')));
    }
  }

  void _showQRModal(BuildContext context, double qrSize, double fontSize) {
    try {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: '',
        pageBuilder: (context, _, __) {
          return Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Your QR Code',
                    style: GoogleFonts.poppins(
                      fontSize: fontSize + 2,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.deepOrange.shade100),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: QrImageView(
                      data: widget.order.token,
                      version: QrVersions.auto,
                      size: qrSize,
                      foregroundColor: Colors.green.shade800,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'TFN: ${widget.order.token}',
                    style: GoogleFonts.poppins(
                      fontSize: fontSize,
                      color: Colors.grey[700],
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: Text(
                      'Share QR',
                      style: GoogleFonts.poppins(fontSize: fontSize),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _shareQR(context),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Close',
                      style: GoogleFonts.poppins(fontSize: fontSize),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error displaying QR modal: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isSmall = screenWidth < 360;

        final titleFont = isSmall ? 14.0 : 16.0;
        final subtitleFont = isSmall ? 10.0 : 12.0;
        final contentFont = isSmall ? 12.0 : 14.0;
        final iconSize = isSmall ? 16.0 : 18.0;
        final padding = isSmall ? 12.0 : 16.0;
        final qrSize = isSmall ? 160.0 : 200.0;

        String formattedDate;
        try {
          formattedDate = DateFormat('dd MMM yyyy').format(widget.date);
        } catch (e) {
          formattedDate = 'Invalid date';
        }

        final dateKey = DateFormat('yyyy-MM-dd').format(widget.date);
        final mealsForDate = widget.order.deliveryStatus[dateKey];
        final isDelivered =
            mealsForDate != null && mealsForDate.values.any((v) => v == true);

        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 6,
          shadowColor: Colors.black.withOpacity(0.1),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: isDelivered
                    ? [Colors.green.shade50, Colors.white]
                    : [Colors.orange.shade50, Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: EdgeInsets.all(padding),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.fastfood_rounded,
                        color: isDelivered ? Colors.green : Colors.deepOrange,
                        size: iconSize + 2,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.order.plan,
                              style: GoogleFonts.poppins(
                                fontSize: titleFont,
                                fontWeight: FontWeight.bold,
                                color: isDelivered
                                    ? Colors.green.shade800
                                    : Colors.deepOrange.shade800,
                              ),
                            ),
                            Text(
                              formattedDate,
                              style: GoogleFonts.poppins(
                                fontSize: subtitleFont,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isDelivered)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Delivered',
                            style: GoogleFonts.poppins(
                              fontSize: subtitleFont,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      IconButton(
                        tooltip: 'Show QR',
                        icon: Icon(
                          Icons.qr_code_rounded,
                          color: isDelivered
                              ? Colors.green.shade800
                              : Colors.deepOrange.shade800,
                          size: iconSize + 4,
                        ),
                        onPressed: () =>
                            _showQRModal(context, qrSize, contentFont),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.restaurant_menu,
                    'Meals:',
                    widget.order.meals.isNotEmpty
                        ? widget.order.meals.join(', ')
                        : 'No meals selected',
                    contentFont,
                    iconSize,
                  ),
                  _buildInfoRow(
                    Icons.confirmation_number_rounded,
                    'T.NO:',
                    widget.order.token,
                    contentFont,
                    iconSize,
                  ),
                  _buildInfoRow(
                    Icons.location_on_rounded,
                    'Address:',
                    widget.order.address,
                    contentFont,
                    iconSize,
                  ),
                  _buildInfoRow(
                    Icons.attach_money_rounded,
                    'Price:',
                    '₹${widget.order.mealPrice}',
                    contentFont,
                    iconSize,
                  ),
                  _buildInfoRow(
                    Icons.payments_rounded,
                    'Total Price:',
                    '₹${widget.order.totalPrice}',
                    contentFont,
                    iconSize,
                  ),
                  _buildInfoRow(
                    Icons.receipt_long_rounded,
                    'TXN.ID:',
                    widget.order.txnId,
                    contentFont,
                    iconSize,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    double fontSize,
    double iconSize,
  ) {
    try {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: iconSize, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: GoogleFonts.poppins(
                    fontSize: fontSize,
                    color: Colors.black87,
                  ),
                  children: [
                    TextSpan(
                      text: '$label ',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: value),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return Text(
        'Error displaying $label',
        style: GoogleFonts.poppins(color: Colors.red, fontSize: fontSize),
      );
    }
  }
}
