import 'package:flutter/material.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../core/theme/app_colors.dart';
import '../appointments/all_schedules_screen.dart';
import '../orders/orders_screen.dart';

/// One home for everything the patient has asked for. A patient does not
/// separate "an order" from "an appointment" — both are just *something I
/// requested, what happened to it?* — so the two lists live behind one tab
/// rather than two entries in a menu.
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

  /// Refreshes whichever section is on screen. Called by the shell when the
  /// tab is reopened; the other section refreshes when it is switched to.
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
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // Lives in the shell, has no back
        title: Text(
          'my_requests'.tr(),
          style: GoogleFonts.poppins(
            color: AppColors.getTextTitle(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSectionSwitch(),
          Expanded(
            // IndexedStack so switching back does not rebuild the list or
            // lose the filter the patient had selected.
            child: IndexedStack(index: _sectionIndex, children: _sections),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionSwitch() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.getSurfaceSecondary(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          _buildSectionButton(0, 'services_section'.tr()),
          _buildSectionButton(1, 'appointments_section'.tr()),
        ],
      ),
    );
  }

  Widget _buildSectionButton(int index, String label) {
    final isSelected = _sectionIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _selectSection(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: isSelected
                  ? Colors.white
                  : AppColors.getTextSubtitle(context),
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
