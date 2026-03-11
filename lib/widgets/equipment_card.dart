import 'package:flutter/material.dart';
import '../models/equipment.dart';
import '../theme/app_theme.dart';
import 'common_widgets.dart';

class EquipmentCard extends StatefulWidget {
  final Equipment item;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showActions;

  const EquipmentCard({
    required this.item,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    this.showActions = false,
    Key? key,
  }) : super(key: key);

  @override
  State<EquipmentCard> createState() => _EquipmentCardState();
}

class _EquipmentCardState extends State<EquipmentCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: _hovered ? AppColors.orange : AppColors.border),
            boxShadow: _hovered
                ? [BoxShadow(color: AppColors.orange.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 8))]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    widget.item.imageUrl.isNotEmpty
                        ? Image.network(
                            widget.item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.surfaceAlt,
                              child: const Icon(Icons.image_not_supported, color: AppColors.border, size: 32),
                            ),
                          )
                        : Container(
                            color: AppColors.surfaceAlt,
                            child: const Icon(Icons.camera_alt, color: AppColors.border, size: 32),
                          ),
                    AnimatedOpacity(
                      opacity: _hovered ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Color(0xDDFF4E00), Colors.transparent],
                            stops: [0.0, 0.6],
                          ),
                        ),
                        alignment: Alignment.bottomLeft,
                        padding: const EdgeInsets.all(12),
                        child: Text('BOOK NOW →',
                            style: AppFonts.dmMono(fontSize: 10, letterSpacing: 2, color: Colors.white)),
                      ),
                    ),
                    if (!widget.item.available)
                      Positioned(
                        top: 10, right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          color: Colors.black87,
                          child: Text('UNAVAILABLE',
                              style: AppFonts.dmMono(fontSize: 8, letterSpacing: 1.5, color: AppColors.textMuted)),
                        ),
                      ),
                    if (widget.showActions)
                      Positioned(
                        top: 8, right: 8,
                        child: Column(
                          children: [
                            _ActionBtn(icon: Icons.edit, onTap: widget.onEdit ?? () {}),
                            const SizedBox(height: 4),
                            _ActionBtn(icon: Icons.delete_outline, onTap: widget.onDelete ?? () {}, danger: true),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppLabel(widget.item.category, color: AppColors.orange),
                    const SizedBox(height: 4),
                    Text(widget.item.title,
                        style: AppFonts.dmMono(fontSize: 13, weight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        RichText(
                          text: TextSpan(children: [
                            TextSpan(
                                text: '\$${widget.item.price.toInt()}',
                                style: AppFonts.bebasNeue(fontSize: 22, color: AppColors.orange, letterSpacing: 1)),
                            TextSpan(
                                text: '/day',
                                style: AppFonts.dmMono(fontSize: 10, color: AppColors.textMuted)),
                          ]),
                        ),
                        if (widget.item.reviewCount > 0)
                          Row(children: [
                            const Icon(Icons.star, size: 12, color: AppColors.orange),
                            const SizedBox(width: 3),
                            Text(widget.item.rating.toStringAsFixed(1),
                                style: AppFonts.dmMono(fontSize: 11, color: AppColors.textDim)),
                          ]),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;
  const _ActionBtn({required this.icon, required this.onTap, this.danger = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            color: Colors.black87,
            border: Border.all(color: danger ? AppColors.error.withOpacity(0.5) : AppColors.borderLight),
          ),
          child: Icon(icon, size: 14, color: danger ? AppColors.error : AppColors.textDim),
        ),
      );
}
