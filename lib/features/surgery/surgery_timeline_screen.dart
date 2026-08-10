import 'package:flutter/material.dart';
import 'package:dr_room/core/theme/dr_room_fonts.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';

class SurgeryTimelineScreen extends StatefulWidget {
  const SurgeryTimelineScreen({super.key});

  @override
  State<SurgeryTimelineScreen> createState() => _SurgeryTimelineScreenState();
}

class _SurgeryTimelineScreenState extends State<SurgeryTimelineScreen> {
  // 0 = first phase done, 1 = second phase active, etc.
  int _currentPhase = 2;

  final List<Map<String, dynamic>> _phases = [
    {
      'title': '2 Weeks Before',
      'subtitle': 'Pre-Surgery Preparation',
      'color': Color(0xFF3B82F6),
      'icon': Iconsax.calendar_tick,
      'tasks': [
        {'task': 'Complete blood tests (CBC, Coagulation)', 'done': true},
        {'task': 'Stop blood-thinning medications', 'done': true},
        {'task': 'Get ECG & chest X-ray done', 'done': true},
        {'task': 'Inform your surgeon about all medications', 'done': true},
      ],
    },
    {
      'title': '1 Week Before',
      'subtitle': 'Diet & Lifestyle Changes',
      'color': Color(0xFF8B5CF6),
      'icon': Iconsax.heart,
      'tasks': [
        {'task': 'Stop smoking & alcohol completely', 'done': true},
        {'task': 'Start eating light, protein-rich meals', 'done': true},
        {'task': 'Pre-operative consultation with surgeon', 'done': true},
        {'task': 'Arrange transportation for surgery day', 'done': false},
      ],
    },
    {
      'title': '1 Day Before',
      'subtitle': 'Final Preparations',
      'color': Color(0xFFF59E0B),
      'icon': Iconsax.warning_2,
      'tasks': [
        {'task': 'No food or drink after midnight (NPO)', 'done': false},
        {'task': 'Shower with antibacterial soap', 'done': false},
        {'task': 'Remove all jewelry & nail polish', 'done': false},
        {'task': 'Pack hospital bag (ID, insurance, loose clothes)', 'done': false},
      ],
    },
    {
      'title': 'Surgery Day',
      'subtitle': 'The Big Day',
      'color': Color(0xFFEF4444),
      'icon': Iconsax.hospital,
      'tasks': [
        {'task': 'Arrive at hospital 2 hours early', 'done': false},
        {'task': 'Sign consent forms', 'done': false},
        {'task': 'Change into hospital gown', 'done': false},
        {'task': 'Surgery: Estimated 2-3 hours', 'done': false},
      ],
    },
    {
      'title': 'Day 1 - 3 After',
      'subtitle': 'Immediate Recovery',
      'color': Color(0xFF10B981),
      'icon': Iconsax.activity,
      'tasks': [
        {'task': 'Monitored in recovery room', 'done': false},
        {'task': 'Pain management with prescribed medication', 'done': false},
        {'task': 'Start walking short distances', 'done': false},
        {'task': 'Follow liquid/soft diet plan', 'done': false},
      ],
    },
    {
      'title': '1 Week After',
      'subtitle': 'First Follow-Up',
      'color': Color(0xFF06B6D4),
      'icon': Iconsax.clipboard_tick,
      'tasks': [
        {'task': 'Follow-up appointment with surgeon', 'done': false},
        {'task': 'Wound dressing change & inspection', 'done': false},
        {'task': 'Begin prescribed physical therapy', 'done': false},
        {'task': 'Report any unusual symptoms immediately', 'done': false},
      ],
    },
    {
      'title': '1 Month After',
      'subtitle': 'Full Recovery Check',
      'color': Color(0xFF10B981),
      'icon': Iconsax.medal_star,
      'tasks': [
        {'task': 'Final follow-up & clearance from surgeon', 'done': false},
        {'task': 'Return to normal activities gradually', 'done': false},
        {'task': 'Continue physical therapy if needed', 'done': false},
        {'task': 'Celebrate your recovery! 🎉', 'done': false},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBackground(context),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(context),
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Surgery Timeline',
          style: GoogleFonts.poppins(
            color: AppColors.getTextTitle(context),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.getTextTitle(context)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // ── Surgery Info Header ──
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  begin: AlignmentDirectional.topStart,
                  end: AlignmentDirectional.bottomEnd,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Iconsax.hospital, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Knee Replacement',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dr. Ayesha Rahman • Nov 20, 2026',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: (_currentPhase + 1) / _phases.length,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Phase ${_currentPhase + 1} of ${_phases.length}',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1, end: 0),

            const SizedBox(height: 32),

            // ── Timeline ──
            ...List.generate(_phases.length, (index) {
              final phase = _phases[index];
              final isCompleted = index < _currentPhase;
              final isCurrent = index == _currentPhase;
              final isUpcoming = index > _currentPhase;
              final Color phaseColor = phase['color'];

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline Line & Dot
                  SizedBox(
                    width: 40,
                    child: Column(
                      children: [
                        // Dot
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? const Color(0xFF10B981)
                                : isCurrent
                                    ? phaseColor
                                    : AppColors.getBorder(context),
                            shape: BoxShape.circle,
                            border: isCurrent
                                ? Border.all(
                                    color: phaseColor.withValues(alpha: 0.3),
                                    width: 4,
                                  )
                                : null,
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: phaseColor.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                    )
                                  ]
                                : null,
                          ),
                          child: isCompleted
                              ? const Icon(Icons.check, color: Colors.white, size: 14)
                              : isCurrent
                                  ? Container(
                                      margin: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    )
                                  : null,
                        ),
                        // Line
                        if (index < _phases.length - 1)
                          Container(
                            width: 2,
                            height: 120,
                            color: isCompleted
                                ? const Color(0xFF10B981).withValues(alpha: 0.5)
                                : AppColors.getBorder(context),
                          ),
                      ],
                    ),
                  ),

                  // Phase Card
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(bottom: 24),
                      child: GestureDetector(
                        onTap: () => _showPhaseDetails(context, phase, isCompleted, isCurrent),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? phaseColor.withValues(alpha: 0.08)
                                : AppColors.getSurface(context),
                            borderRadius: BorderRadius.circular(20),
                            border: isCurrent
                                ? Border.all(color: phaseColor.withValues(alpha: 0.3))
                                : Border.all(color: AppColors.getBorder(context).withValues(alpha: 0.5)),
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: phaseColor.withValues(alpha: 0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    phase['icon'],
                                    color: isUpcoming
                                        ? AppColors.getTextSubtitle(context)
                                        : phaseColor,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      phase['title'],
                                      style: GoogleFonts.poppins(
                                        color: isUpcoming
                                            ? AppColors.getTextSubtitle(context)
                                            : AppColors.getTextTitle(context),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (isCompleted)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Done ✓',
                                        style: GoogleFonts.poppins(
                                          color: const Color(0xFF10B981),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  if (isCurrent)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: phaseColor.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Current',
                                        style: GoogleFonts.poppins(
                                          color: phaseColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsetsDirectional.only(start: 32),
                                child: Text(
                                  phase['subtitle'],
                                  style: GoogleFonts.poppins(
                                    color: AppColors.getTextSubtitle(context),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              if (isCurrent) ...[
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsetsDirectional.only(start: 32),
                                  child: Text(
                                    'Tap to see tasks →',
                                    style: GoogleFonts.poppins(
                                      color: phaseColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: (80 * index).ms).slideX(begin: 0.05, end: 0);
            }),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  void _showPhaseDetails(
    BuildContext context,
    Map<String, dynamic> phase,
    bool isCompleted,
    bool isCurrent,
  ) {
    final Color phaseColor = phase['color'];
    final List<Map<String, dynamic>> tasks = phase['tasks'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.getSurface(context),
                borderRadius: const BorderRadiusDirectional.only(
                  topStart: Radius.circular(32),
                  topEnd: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.getBorder(context),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Phase Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: phaseColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(phase['icon'], color: phaseColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              phase['title'],
                              style: GoogleFonts.poppins(
                                color: AppColors.getTextTitle(context),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              phase['subtitle'],
                              style: GoogleFonts.poppins(
                                color: AppColors.getTextSubtitle(context),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  Text(
                    'Checklist',
                    style: GoogleFonts.poppins(
                      color: AppColors.getTextTitle(context),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tasks
                  Expanded(
                    child: ListView.separated(
                      itemCount: tasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return GestureDetector(
                          onTap: () {
                            setSheetState(() {
                              task['done'] = !(task['done'] as bool);
                            });
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: (task['done'] as bool)
                                  ? const Color(0xFF10B981).withValues(alpha: 0.08)
                                  : AppColors.getBackground(context),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: (task['done'] as bool)
                                    ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                    : AppColors.getBorder(context),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: (task['done'] as bool)
                                        ? const Color(0xFF10B981)
                                        : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: (task['done'] as bool)
                                          ? const Color(0xFF10B981)
                                          : AppColors.getTextSubtitle(context),
                                      width: 2,
                                    ),
                                  ),
                                  child: (task['done'] as bool)
                                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    task['task'],
                                    style: GoogleFonts.poppins(
                                      color: (task['done'] as bool)
                                          ? AppColors.getTextSubtitle(context)
                                          : AppColors.getTextTitle(context),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      decoration: (task['done'] as bool)
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).animate().fadeIn(delay: (80 * index).ms);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
