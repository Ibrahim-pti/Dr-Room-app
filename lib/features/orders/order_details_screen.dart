import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/order_provider.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../doctors/chat_screen.dart';
import '../doctors/video_call_screen.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late OrderModel _currentOrder;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _startPolling();
  }

  void _startPolling() {
    // Only poll if the order is pending or accepted
    if (_currentOrder.status.toLowerCase() != 'completed' && _currentOrder.status.toLowerCase() != 'cancelled') {
      _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
        if (!mounted) return;
        await context.read<OrderProvider>().fetchOrders();
        
        if (mounted) {
          final updatedOrder = context.read<OrderProvider>().orders.firstWhere(
            (o) => o.id == _currentOrder.id,
            orElse: () => _currentOrder,
          );
          
          if (updatedOrder.status != _currentOrder.status || updatedOrder.assignedNurseId != _currentOrder.assignedNurseId) {
            setState(() {
              _currentOrder = updatedOrder;
            });
          }

          if (_currentOrder.status.toLowerCase() == 'completed' || _currentOrder.status.toLowerCase() == 'cancelled') {
            _pollingTimer?.cancel();
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, size: 20, color: AppColors.getTextTitle(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Order Details',
          style: GoogleFonts.poppins(
            color: AppColors.getTextTitle(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Card (Summary) ──
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: _currentOrder.iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      _currentOrder.icon,
                      color: _currentOrder.iconColor,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentOrder.title,
                          style: GoogleFonts.poppins(
                            color: AppColors.getTextTitle(context),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Order ID: #${_currentOrder.id.substring(_currentOrder.id.length >= 6 ? _currentOrder.id.length - 6 : 0)}',
                          style: GoogleFonts.poppins(
                            color: AppColors.textLight,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

            const SizedBox(height: 24),

            // ── Status Banner ──
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _currentOrder.statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _currentOrder.statusColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.info_circle, color: _currentOrder.statusColor),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Status',
                          style: GoogleFonts.poppins(
                            color: _currentOrder.statusColor.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currentOrder.status.toUpperCase(),
                          style: GoogleFonts.poppins(
                            color: _currentOrder.statusColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_currentOrder.status.toLowerCase() == 'pending' || _currentOrder.status.toLowerCase() == 'accepted')
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _currentOrder.statusColor,
                      ),
                    ),
                ],
              ),
            ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

            // ── Assigned Professional Card ──
            if (_currentOrder.assignedNurseId != null && _currentOrder.assignedNurseName != null) ...[
              const SizedBox(height: 32),
              Text(
                'Assigned Professional',
                style: GoogleFonts.poppins(
                  color: AppColors.getTextTitle(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ).animate().fadeIn(),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFFEFF6FF),
                          backgroundImage: _currentOrder.assignedNurseAvatar != null
                              ? NetworkImage(_currentOrder.assignedNurseAvatar!)
                              : const AssetImage('assets/images/doc1.png') as ImageProvider,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentOrder.assignedNurseName!,
                                style: GoogleFonts.poppins(
                                  color: AppColors.getTextTitle(context),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Medical Professional',
                                style: GoogleFonts.poppins(
                                  color: AppColors.textLight,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatScreen(
                                    doctorName: _currentOrder.assignedNurseName!,
                                    doctorImage: 'assets/images/doc1.png',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Iconsax.message, size: 18),
                            label: Text('Chat', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xFF3B82F6),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VideoCallScreen(
                                    doctorName: _currentOrder.assignedNurseName!,
                                    doctorImage: 'assets/images/doc1.png',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Iconsax.call, size: 18),
                            label: Text('Call', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: const Color(0xFF3B82F6),
                              backgroundColor: const Color(0xFFEFF6FF),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().scale(curve: Curves.easeOutBack, duration: 500.ms),
            ],

            const SizedBox(height: 32),

            // ── Details Section ──
            Text(
              'Order Information',
              style: GoogleFonts.poppins(
                color: AppColors.getTextTitle(context),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ).animate(delay: 200.ms).fadeIn(),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.getBorder(context)),
              ),
              child: Column(
                children: [
                  _buildDetailRow(context, 'Date', '${_currentOrder.date.day}/${_currentOrder.date.month}/${_currentOrder.date.year}'),
                  const Divider(height: 32, thickness: 1, color: Color(0xFFE2E8F0)),
                  _buildDetailRow(context, 'Time', '${_currentOrder.date.hour}:${_currentOrder.date.minute.toString().padLeft(2, '0')}'),
                  const Divider(height: 32, thickness: 1, color: Color(0xFFE2E8F0)),
                  _buildDetailRow(context, 'Total Amount', '\$${_currentOrder.price.toStringAsFixed(2)}', isTotal: true),
                ],
              ),
            ).animate(delay: 300.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            color: AppColors.getTextSubtitle(context),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            color: isTotal ? const Color(0xFF3B82F6) : AppColors.getTextTitle(context),
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
