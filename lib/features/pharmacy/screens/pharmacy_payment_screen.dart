import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../providers/cart_provider.dart';
import '../../../core/utils/api_client.dart';
import '../widgets/checkout_step_indicator.dart';

class PharmacyPaymentScreen extends ConsumerStatefulWidget {
  final String name;
  final String phone;
  final double latitude;
  final double longitude;
  final String addressText;
  final String instructions;

  const PharmacyPaymentScreen({
    super.key,
    required this.name,
    required this.phone,
    required this.latitude,
    required this.longitude,
    required this.addressText,
    this.instructions = '',
  });

  @override
  ConsumerState<PharmacyPaymentScreen> createState() => _PharmacyPaymentScreenState();
}

class _PharmacyPaymentScreenState extends ConsumerState<PharmacyPaymentScreen> {
  String _selectedPaymentMethod = 'cash';
  bool _isLoading = false;

  Future<void> _submitOrder() async {
    final cartState = ref.read(cartProvider);
    if (cartState.items.isEmpty || cartState.pharmacy == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final orderData = {
        'service_type': 'pharmacy',
        'subtotal': cartState.subtotal,
        'extra_fee': cartState.pharmacy!.deliveryFee,
        'total_price': cartState.total,
        'payment_method': _selectedPaymentMethod,
        'patient_details': {
          'name': widget.name,
          'phone': widget.phone,
        },
        'location_details': {
          'latitude': widget.latitude,
          'longitude': widget.longitude,
          'address_text': widget.addressText,
          'instructions': widget.instructions,
        },
        'items': cartState.items.map((item) => {
          'id': item.medication.id,
          'name': item.medication.name,
          'price': item.medication.price,
          'quantity': item.quantity,
          'extra_data': {'pharmacy_id': cartState.pharmacy!.id}
        }).toList(),
      };

      final response = await ApiClient.post('/orders', body: orderData);

      if (response.statusCode == 201) {
        if (!mounted) return;
        ref.read(cartProvider.notifier).clearCart();
        _showSuccessDialog();
      } else {
        throw Exception('Failed to create order: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text('Order Placed Successfully', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('Your order has been sent to the pharmacy.', style: GoogleFonts.inter(color: Colors.grey), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); 
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); 
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Done', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption(String id, String title, IconData icon, String subtitle) {
    bool isSelected = _selectedPaymentMethod == id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF3B82F6), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF111827))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? const Color(0xFF3B82F6) : Colors.grey.withValues(alpha: 0.3), width: 2),
                color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
              ),
              child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text('Payment', style: GoogleFonts.inter(color: const Color(0xFF111827), fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Step 2 of 3', style: GoogleFonts.inter(color: Colors.grey, fontSize: 12)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF111827), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CheckoutStepIndicator(currentStep: 2),
            
            // Total Amount Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEFF6FF), Color(0xFFE0E7FF)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Total Amount', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF111827), fontSize: 14)),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('${cartState.total.toInt()}', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                          const SizedBox(width: 4),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text('IQD', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF2563EB))),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Icon(Icons.shopping_bag, color: Color(0xFF3B82F6), size: 48),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Payment Method', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
                  const SizedBox(height: 12),
                  
                  _buildPaymentOption('cash', 'Cash on Delivery', Iconsax.wallet_3_copy, 'Pay when you receive your order'),
                  _buildPaymentOption('card', 'Credit / Debit Card', Iconsax.card_copy, 'Visa, Mastercard & more'),
                  _buildPaymentOption('wallet', 'Digital Wallet', Iconsax.wallet_2_copy, 'Fast and secure payment'),
                  _buildPaymentOption('bank', 'Bank Transfer', Iconsax.bank_copy, 'Transfer directly from your bank'),
                  
                  const SizedBox(height: 24),
                  Text('Payment Summary', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF111827))),
                  const SizedBox(height: 12),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Items Total', style: GoogleFonts.inter(color: Colors.grey)),
                            Text('${cartState.subtotal.toInt()} IQD', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Delivery Fee', style: GoogleFonts.inter(color: Colors.grey)),
                            Text('${cartState.pharmacy?.deliveryFee.toInt() ?? 0} IQD', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF111827))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Discount', style: GoogleFonts.inter(color: Colors.grey)),
                            Text('-0 IQD', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFF10B981))),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Amount', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF111827))),
                            Text('${cartState.total.toInt()} IQD', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF2563EB))),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_outline, color: Color(0xFF10B981), size: 16),
                        const SizedBox(width: 8),
                        Text('All transactions are secure and encrypted', style: GoogleFonts.inter(color: const Color(0xFF10B981), fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitOrder,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Place Order', style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Back to Details', style: GoogleFonts.inter(color: const Color(0xFF2563EB), fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
