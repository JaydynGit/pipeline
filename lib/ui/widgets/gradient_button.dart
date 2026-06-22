import 'package:flutter/material.dart';
import '../../core/theme.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double width;

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: onPressed == null
            ? const LinearGradient(
                colors: [Colors.grey, Colors.blueGrey],
              )
            : const LinearGradient(
                colors: [AppTheme.primaryBlue, AppTheme.primaryPurple],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
        boxShadow: onPressed == null
            ? []
            : [
                BoxShadow(
                  color: AppTheme.primaryPurple.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: isLoading ? null : onPressed,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
