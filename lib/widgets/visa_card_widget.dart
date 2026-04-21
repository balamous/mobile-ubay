import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../data/models/card_model.dart';

// ── Card gradient presets ────────────────────────────────────────────────────
LinearGradient _gradientForCard(CardModel card, int index) {
  switch (index % 3) {
    case 0:
      return AppColors.cardSignatureGradient;
    case 1:
      return AppColors.cardPlatinumGradient;
    default:
      return AppColors.cardDebitGradient;
  }
}

// ── PageView card carousel ───────────────────────────────────────────────────
class CardCarousel extends StatefulWidget {
  final List<CardModel> cards;
  final bool showDetails;
  final void Function(int index)? onCardTap;
  final double height;

  const CardCarousel({
    super.key,
    required this.cards,
    this.showDetails = false,
    this.onCardTap,
    this.height = 210,
  });

  @override
  State<CardCarousel> createState() => _CardCarouselState();
}

class _CardCarouselState extends State<CardCarousel> {
  final PageController _pageCtrl = PageController(viewportFraction: 0.88);
  int _current = 0;

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: widget.cards.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (_, i) {
              return AnimatedScale(
                scale: _current == i ? 1.0 : 0.93,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: VisaCardWidget(
                    card: widget.cards[i],
                    cardIndex: i,
                    showDetails: widget.showDetails,
                    onTap: () => widget.onCardTap?.call(i),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.cards.length > 1) ...[
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.cards.length, (i) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _current == i ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _current == i
                      ? AppColors.primary
                      : AppColors.grey300,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

// ── Single card widget ───────────────────────────────────────────────────────
class VisaCardWidget extends StatefulWidget {
  final CardModel card;
  final int cardIndex;
  final bool showDetails;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const VisaCardWidget({
    super.key,
    required this.card,
    this.cardIndex = 0,
    this.showDetails = false,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  State<VisaCardWidget> createState() => _VisaCardWidgetState();
}

class _VisaCardWidgetState extends State<VisaCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _flip() {
    if (_isFront) {
      _flipCtrl.forward();
    } else {
      _flipCtrl.reverse();
    }
    setState(() => _isFront = !_isFront);
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.height ?? 200.0;
    final gradient = _gradientForCard(widget.card, widget.cardIndex);

    return GestureDetector(
      onTap: widget.onTap ?? _flip,
      child: SizedBox(
        width: widget.width ?? double.infinity,
        height: h,
        child: AnimatedBuilder(
          animation: _flipAnim,
          builder: (_, __) {
            final isShowFront = _flipAnim.value < 0.5;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(3.14159265 * _flipAnim.value),
              child: isShowFront
                  ? _Front(
                      card: widget.card,
                      gradient: gradient,
                      showDetails: widget.showDetails,
                      height: h,
                    )
                  : _Back(
                      card: widget.card,
                      gradient: gradient,
                      showDetails: widget.showDetails,
                      height: h,
                    ),
            );
          },
        ),
      ),
    );
  }
}

// ── Front face ───────────────────────────────────────────────────────────────
class _Front extends StatelessWidget {
  final CardModel card;
  final LinearGradient gradient;
  final bool showDetails;
  final double height;

  const _Front({
    required this.card,
    required this.gradient,
    required this.showDetails,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppConstants.radius2XL),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.45),
            blurRadius: 28,
            offset: const Offset(0, 14),
            spreadRadius: -4,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Topographic lines decoration
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.radius2XL),
              child: CustomPaint(painter: _TopoLinePainter()),
            ),
          ),
          // Subtle circle
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -30,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'uBAY',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _cardLabel,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    _statusBadge(),
                  ],
                ),
                const Spacer(),
                // Chip
                _buildChip(),
                const SizedBox(height: 14),
                // Card number
                Text(
                  showDetails
                      ? _formatNumber(card.cardNumber)
                      : '••••  ••••  ••••  ${card.cardNumber.substring(card.cardNumber.length - 4)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 3.5,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 18),
                // Bottom row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TITULAIRE',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            card.cardHolder,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EXPIRE',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          card.expiryDate,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    _cardLogo(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _cardLabel {
    if (card.type == CardType.visa) return 'VISA SIGNATURE';
    return 'MASTERCARD';
  }

  Widget _statusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (card.isActive ? Colors.greenAccent : Colors.redAccent)
            .withOpacity(0.18),
        borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        border: Border.all(
          color: (card.isActive ? Colors.greenAccent : Colors.redAccent)
              .withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Text(
        card.isActive ? 'Active' : 'Bloquée',
        style: TextStyle(
          color: card.isActive ? Colors.greenAccent : Colors.redAccent,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildChip() {
    return Container(
      width: 40,
      height: 30,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDEB887), Color(0xFFC8A96E)],
        ),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Chip lines
          Positioned(
            top: 9,
            left: 4,
            right: 4,
            child: Container(height: 1, color: Colors.brown.withOpacity(0.35)),
          ),
          Positioned(
            top: 18,
            left: 4,
            right: 4,
            child: Container(height: 1, color: Colors.brown.withOpacity(0.35)),
          ),
          Positioned(
            left: 14,
            top: 3,
            bottom: 3,
            child: Container(width: 1, color: Colors.brown.withOpacity(0.35)),
          ),
          Positioned(
            right: 14,
            top: 3,
            bottom: 3,
            child: Container(width: 1, color: Colors.brown.withOpacity(0.35)),
          ),
        ],
      ),
    );
  }

  Widget _cardLogo() {
    if (card.type == CardType.visa) {
      return const Text(
        'VISA',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w900,
          fontStyle: FontStyle.italic,
          letterSpacing: 1,
        ),
      );
    }
    return SizedBox(
      width: 44,
      height: 28,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFEB001B),
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF79E1B).withOpacity(0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(String n) {
    final clean = n.replaceAll(' ', '');
    final groups = <String>[];
    for (var i = 0; i < clean.length; i += 4) {
      groups.add(clean.substring(i, (i + 4).clamp(0, clean.length)));
    }
    return groups.join('  ');
  }
}

// ── Back face ────────────────────────────────────────────────────────────────
class _Back extends StatelessWidget {
  final CardModel card;
  final LinearGradient gradient;
  final bool showDetails;
  final double height;

  const _Back({
    required this.card,
    required this.gradient,
    required this.showDetails,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()..rotateY(3.14159265),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppConstants.radius2XL),
        ),
        child: Column(
          children: [
            const SizedBox(height: 30),
            // Magnetic stripe
            Container(
              height: 42,
              color: Colors.black.withOpacity(0.65),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          '   Authorized signature',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withOpacity(0.5),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 56,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      showDetails ? card.cvv : '•••',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(right: 24),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'CVV',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.45),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Topo line painter ────────────────────────────────────────────────────────
class _TopoLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path();
    final step = size.height / 6;
    for (var i = 0; i < 6; i++) {
      final y = step * i + step / 2;
      path.moveTo(0, y + 10 * (i % 2 == 0 ? 1 : -1));
      path.cubicTo(
        size.width * 0.25,
        y - 20 * (i % 2 == 0 ? 1 : -1),
        size.width * 0.75,
        y + 20 * (i % 2 == 0 ? 1 : -1),
        size.width,
        y - 10 * (i % 2 == 0 ? 1 : -1),
      );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
