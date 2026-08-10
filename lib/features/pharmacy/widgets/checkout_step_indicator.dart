import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CheckoutStepIndicator extends StatelessWidget {
  final int currentStep;

  const CheckoutStepIndicator({super.key, required this.currentStep});

  Widget _buildStep(int stepNumber, String title, bool isActive, bool isCompleted) {
    Color color = isActive || isCompleted ? const Color(0xFF3B82F6) : Colors.grey.withValues(alpha: 0.4);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? color : (isCompleted ? color : Colors.white),
            border: Border.all(color: color, width: 2),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    stepNumber.toString(),
                    style: GoogleFonts.inter(
                      color: isActive ? Colors.white : color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            color: isActive || isCompleted ? const Color(0xFF111827) : Colors.grey,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildLine(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        color: isCompleted ? const Color(0xFF3B82F6) : Colors.grey.withValues(alpha: 0.3),
        margin: const EdgeInsets.only(bottom: 24, left: 8, right: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          _buildStep(1, 'Details', currentStep == 1, currentStep > 1),
          _buildLine(currentStep > 1),
          _buildStep(2, 'Payment', currentStep == 2, currentStep > 2),
          _buildLine(currentStep > 2),
          _buildStep(3, 'Review', currentStep == 3, currentStep > 3),
        ],
      ),
    );
  }
}
