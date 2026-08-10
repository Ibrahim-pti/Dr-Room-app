import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/payment_provider.dart';
import '../../core/models/payment_model.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String description;
  final String type;
  final Map<String, dynamic> metadata;
  final VoidCallback onSuccess;
  final Function(String error)? onError;

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.description,
    required this.type,
    required this.metadata,
    required this.onSuccess,
    this.onError,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late PaymentProvider _paymentProvider;
  PaymentMethod? _selectedMethod;
  bool _saveForLater = false;

  @override
  void initState() {
    super.initState();
    _paymentProvider = Provider.of<PaymentProvider>(context, listen: false);
    _paymentProvider.fetchPaymentMethods();
  }

  Future<void> _processPayment() async {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    final intentCreated = await _paymentProvider.createPaymentIntent(
      amount: widget.amount,
      currency: 'USD',
      description: widget.description,
      metadata: {
        ...widget.metadata,
        'type': widget.type,
      },
    );

    if (!intentCreated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_paymentProvider.error ?? 'Payment failed')),
        );
      }
      return;
    }

    final confirmed = await _paymentProvider.confirmPayment(
      paymentIntentId: _paymentProvider.currentPaymentIntent!.paymentIntentId,
      paymentMethodId: _selectedMethod!.id,
    );

    if (confirmed) {
      if (mounted) {
        _showSuccessDialog();
      }
    } else {
      if (mounted) {
        widget.onError?.call(_paymentProvider.error ?? 'Payment failed');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_paymentProvider.error ?? 'Payment failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.tick_circle,
                  color: AppColors.success,
                  size: 48,
                ),
              ).animate().scale(delay: 100.ms, duration: 500.ms),
              const SizedBox(height: 16),
              Text(
                'Payment Successful!',
                style: AppTypography.headingSm.copyWith(color: AppColors.textDark),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Your payment has been processed securely',
                style: AppTypography.bodySm.copyWith(color: AppColors.textMedium),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onSuccess();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Continue',
                    style: AppTypography.button.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Secure Payment', style: AppTypography.headingSm),
        elevation: 0,
      ),
      body: Consumer<PaymentProvider>(
        builder: (context, paymentProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAmountCard(),
                const SizedBox(height: 24),
                Text(
                  'Payment Method',
                  style: AppTypography.headingSm.copyWith(color: AppColors.textDark),
                ),
                const SizedBox(height: 12),
                if (paymentProvider.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (paymentProvider.paymentMethods.isEmpty)
                  _buildAddNewCard()
                else
                  _buildPaymentMethodsList(paymentProvider),
                const SizedBox(height: 24),
                if (paymentProvider.paymentMethods.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Iconsax.add),
                    label: const Text('Add New Card'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                const SizedBox(height: 24),
                CheckboxListTile(
                  value: _saveForLater,
                  onChanged: (value) {
                    setState(() => _saveForLater = value ?? false);
                  },
                  title: Text(
                    'Save this card for future payments',
                    style: AppTypography.bodySm.copyWith(color: AppColors.textDark),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: paymentProvider.isLoading ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: paymentProvider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                        : Text(
                            'Pay \$${widget.amount.toStringAsFixed(2)}',
                            style: AppTypography.button.copyWith(color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Iconsax.shield_tick,
                      size: 16,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Secured with Stripe encryption',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.textMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amount to Pay',
            style: AppTypography.bodySm.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${widget.amount.toStringAsFixed(2)}',
            style: AppTypography.headingMd.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 12),
          Text(
            widget.description,
            style: AppTypography.bodySm.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsList(PaymentProvider paymentProvider) {
    return Column(
      children: List.generate(
        paymentProvider.paymentMethods.length,
        (index) {
          final method = paymentProvider.paymentMethods[index];
          final isSelected = _selectedMethod?.id == method.id;

          return GestureDetector(
            onTap: () => setState(() => _selectedMethod = method),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.cardBorderLight,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(12),
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.05)
                    : Colors.transparent,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLightSecondary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        method.type == 'card'
                            ? Iconsax.card
                            : Iconsax.wallet_2,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${method.brand.toUpperCase()} •••• ${method.last4}',
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Expires ${method.expiryMonth}/${method.expiryYear}',
                          style: AppTypography.bodySm.copyWith(
                            color: AppColors.textMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Iconsax.tick_circle,
                      color: AppColors.primary,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddNewCard() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.cardBorderLight,
            style: BorderStyle.solid,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              Iconsax.add_square,
              size: 32,
              color: AppColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Add Payment Method',
              style: AppTypography.labelMd.copyWith(color: AppColors.textDark),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Add a card to continue',
              style: AppTypography.bodySm.copyWith(color: AppColors.textMedium),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
