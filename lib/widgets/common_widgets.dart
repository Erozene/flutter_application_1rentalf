import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppLabel extends StatelessWidget {
  final String text;
  final Color? color;
  const AppLabel(this.text, {this.color, super.key});

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: AppFonts.dmMono(fontSize: 10, letterSpacing: 2, color: color ?? AppColors.textMuted),
      );
}

class AppHeading extends StatelessWidget {
  final String text;
  final double size;
  final Color? color;
  const AppHeading(this.text, {this.size = 32, this.color, super.key});

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: AppFonts.bebasNeue(fontSize: size, color: color ?? AppColors.text, letterSpacing: 3),
      );
}

class AppDivider extends StatelessWidget {
  const AppDivider({super.key});
  @override
  Widget build(BuildContext context) =>
      const Divider(color: AppColors.border, height: 1, thickness: 1);
}

class AppBox extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  const AppBox({required this.child, this.padding, this.color, super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? AppColors.surface,
          border: Border.all(color: AppColors.border),
        ),
        child: child,
      );
}

class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const AppChip({required this.label, this.selected = false, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.orange : Colors.transparent,
            border: Border.all(color: selected ? AppColors.orange : AppColors.borderLight),
          ),
          child: Text(
            label.toUpperCase(),
            style: AppFonts.dmMono(
              fontSize: 10,
              letterSpacing: 1.5,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
          ),
        ),
      );
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const StatusBadge({required this.label, required this.color, super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.5)),
          color: color.withOpacity(0.08),
        ),
        child: Text(label, style: AppFonts.dmMono(fontSize: 9, letterSpacing: 1.5, color: color)),
      );
}

class LoadingOverlay extends StatelessWidget {
  final String? message;
  const LoadingOverlay({this.message, super.key});

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.black87,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 32, height: 32,
                child: CircularProgressIndicator(color: AppColors.orange, strokeWidth: 2),
              ),
              if (message != null) ...[
                const SizedBox(height: 20),
                Text(message!.toUpperCase(),
                    style: AppFonts.dmMono(fontSize: 11, letterSpacing: 2, color: AppColors.textDim)),
              ],
            ],
          ),
        ),
      );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: AppColors.border),
              const SizedBox(height: 20),
              AppHeading(title, size: 24),
              const SizedBox(height: 8),
              Text(subtitle,
                  textAlign: TextAlign.center,
                  style: AppFonts.dmMono(fontSize: 12, color: AppColors.textMuted, letterSpacing: 0.5)),
              if (action != null) ...[const SizedBox(height: 24), action!],
            ],
          ),
        ),
      );
}

class StarRating extends StatelessWidget {
  final double rating;
  final int count;
  const StarRating({required this.rating, this.count = 0, super.key});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...List.generate(5, (i) {
            final filled = i < rating.floor();
            final half = !filled && i < rating;
            return Icon(
              half ? Icons.star_half : (filled ? Icons.star : Icons.star_border),
              size: 14,
              color: filled || half ? AppColors.orange : AppColors.border,
            );
          }),
          const SizedBox(width: 6),
          Text(
            count > 0 ? '${rating.toStringAsFixed(1)} ($count)' : 'No reviews',
            style: AppFonts.dmMono(fontSize: 11, color: AppColors.textMuted, letterSpacing: 0.5),
          ),
        ],
      );
}

void showAppSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 16,
            color: isError ? AppColors.error : AppColors.success,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: AppFonts.dmMono(fontSize: 12))),
        ],
      ),
      backgroundColor: AppColors.surface,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: AppColors.border),
      ),
    ),
  );
}

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool outline;

  const AppButton({
    required this.label,
    this.onPressed,
    this.outline = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (outline) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.orange),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(label,
              style: AppFonts.dmMono(
                  fontSize: 12,
                  letterSpacing: 2,
                  color: AppColors.orange)),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.orange,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(label,
            style: AppFonts.dmMono(
                fontSize: 12,
                letterSpacing: 2,
                color: Colors.white)),
      ),
    );
  }
}
