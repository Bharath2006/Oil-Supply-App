import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PaymentOptionsDialog extends StatefulWidget {
  final VoidCallback onQRSelected;
  final VoidCallback onUPISelected;

  const PaymentOptionsDialog({
    super.key,
    required this.onQRSelected,
    required this.onUPISelected,
  });

  @override
  State<PaymentOptionsDialog> createState() => _PaymentOptionsDialogState();
}

class _PaymentOptionsDialogState extends State<PaymentOptionsDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Choose Payment Method'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.qr_code, color: Colors.blue),
            title: const Text('Scan QR Code'),
            subtitle: const Text('Recommended for faster payment'),
            onTap: () async {
              await HapticFeedback.selectionClick();
              widget.onQRSelected();
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(
              Icons.account_balance_wallet,
              color: Colors.green,
            ),
            title: const Text('UPI Payment'),
            subtitle: const Text('Pay using any UPI app'),
            onTap: () async {
              await HapticFeedback.selectionClick();
              widget.onUPISelected();
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await HapticFeedback.selectionClick();
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class QRPaymentDialog extends StatefulWidget {
  final double totalPrice;
  final VoidCallback onPaymentComplete;

  const QRPaymentDialog({
    super.key,
    required this.totalPrice,
    required this.onPaymentComplete,
  });

  @override
  State<QRPaymentDialog> createState() => _QRPaymentDialogState();
}

class _QRPaymentDialogState extends State<QRPaymentDialog> {
  late String upiId;
  late String upiQrData;

  @override
  void initState() {
    super.initState();
    upiId = "9080121722@ptsbi";
    upiQrData =
        "upi://pay?pa=$upiId&pn=Tiffin Service&am=${widget.totalPrice.toStringAsFixed(2)}&cu=INR";
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Scan to Pay'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: QrImageView(
                data: upiQrData,
                size: 200,
                backgroundColor: Colors.white,
                errorStateBuilder: (context, error) {
                  return const Column(
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 50),
                      SizedBox(height: 8),
                      Text(
                        'Failed to generate QR code',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Amount: ₹${widget.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('UPI ID: $upiId', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            const Text(
              'After successful payment, please enter the transaction details below',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await HapticFeedback.selectionClick();
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            await HapticFeedback.mediumImpact();
            Navigator.pop(context);
            widget.onPaymentComplete();
          },
          child: const Text('I Have Paid'),
        ),
      ],
    );
  }
}

class UPIPaymentDialog extends StatefulWidget {
  final double totalPrice;
  final VoidCallback onPaymentComplete;

  const UPIPaymentDialog({
    super.key,
    required this.totalPrice,
    required this.onPaymentComplete,
  });

  @override
  State<UPIPaymentDialog> createState() => _UPIPaymentDialogState();
}

class _UPIPaymentDialogState extends State<UPIPaymentDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('UPI Payment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Please send the payment to the following UPI ID:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '9080121722@ptsbi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Amount: ₹${widget.totalPrice.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text(
              'After successful payment, please enter the transaction details below',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await HapticFeedback.selectionClick();
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            await HapticFeedback.mediumImpact();
            Navigator.pop(context);
            widget.onPaymentComplete();
          },
          child: const Text('I Have Paid'),
        ),
      ],
    );
  }
}

class TransactionDetailsForm extends StatefulWidget {
  final Function(String upiId, String upiName, String txnId) onSubmit;
  final String? error;

  const TransactionDetailsForm({super.key, required this.onSubmit, this.error});

  @override
  _TransactionDetailsFormState createState() => _TransactionDetailsFormState();
}

class _TransactionDetailsFormState extends State<TransactionDetailsForm> {
  final _upiIdController = TextEditingController();
  final _upiNameController = TextEditingController();
  final _txnIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _upiIdController.dispose();
    _upiNameController.dispose();
    _txnIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Payment Details'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _upiIdController,
                decoration: const InputDecoration(
                  labelText: 'Your UPI ID',
                  hintText: 'e.g. yourname@upi',
                  prefixIcon: Icon(Icons.account_circle),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your UPI ID';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid UPI ID';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _upiNameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name as in UPI',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  if (value.length < 3) {
                    return 'Name too short';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _txnIdController,
                decoration: const InputDecoration(
                  labelText: 'Transaction ID',
                  hintText: 'From payment receipt',
                  prefixIcon: Icon(Icons.receipt),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter transaction ID';
                  }
                  if (value.length < 8) {
                    return 'Transaction ID too short';
                  }
                  return null;
                },
              ),
              if (widget.error != null) ...[
                const SizedBox(height: 16),
                Text(widget.error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await HapticFeedback.selectionClick();
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              await HapticFeedback.mediumImpact();
              widget.onSubmit(
                _upiIdController.text.trim(),
                _upiNameController.text.trim(),
                _txnIdController.text.trim(),
              );
            }
          },
          child: const Text('Confirm Payment'),
        ),
      ],
    );
  }
}

class OrderSuccessScreen extends StatefulWidget {
  final String token;

  const OrderSuccessScreen({super.key, required this.token});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Hero(
          tag: 'success',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Order Confirmed!",
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Order ID: ${widget.token}",
                style: GoogleFonts.poppins(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  await HapticFeedback.selectionClick();
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                icon: const Icon(Icons.home),
                label: const Text("Back to Home"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
