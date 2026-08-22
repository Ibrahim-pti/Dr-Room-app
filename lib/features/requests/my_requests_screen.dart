import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import '../appointments/all_schedules_screen.dart';
import '../orders/orders_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => MyRequestsScreenState();
}

class MyRequestsScreenState extends State<MyRequestsScreen> {
  final GlobalKey<OrdersScreenState> _ordersKey = GlobalKey<OrdersScreenState>();
  final GlobalKey<AllSchedulesScreenState> _appointmentsKey =
      GlobalKey<AllSchedulesScreenState>();

  int _sectionIndex = 0;

  late final List<Widget> _sections = [
    OrdersScreen(key: _ordersKey, embedded: true),
    AllSchedulesScreen(key: _appointmentsKey, embedded: true),
  ];

  TextStyle _kStyle({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = const Color(0xFF0F172A),
    double? height,
  }) {
    return TextStyle(
      fontFamily: 'Rabar',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  void refresh() {
    if (_sectionIndex == 0) {
      _ordersKey.currentState?.refresh();
    } else {
      _appointmentsKey.currentState?.refresh();
    }
  }

  void _selectSection(int index) {
    if (_sectionIndex == index) return;
    setState(() => _sectionIndex = index);
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Text(
          'داواکارییەکانم',
          style: _kStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _buildSectionSwitch(isDark),
          const SizedBox(height: 14),
          Expanded(
            child: IndexedStack(index: _sectionIndex, children: _sections),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionSwitch(bool isDark) {
    final bg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          _buildSectionButton(0, 'خزمەتگوزارییەکان', Iconsax.hospital, isDark),
          _buildSectionButton(1, 'چاوپێکەوتنەکان', Iconsax.calendar_1, isDark),
        ],
      ),
    );
  }

  Widget _buildSectionButton(int index, String label, IconData icon, bool isDark) {
    final isSelected = _sectionIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _selectSection(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 17,
                color: isSelected
                    ? Colors.white
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: _kStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}