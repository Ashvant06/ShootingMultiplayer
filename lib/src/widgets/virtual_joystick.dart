import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VirtualJoystick extends StatefulWidget {
  const VirtualJoystick({
    super.key,
    required this.label,
    required this.accent,
    required this.onChanged,
    this.onActiveChanged,
  });

  final String label;
  final Color accent;
  final ValueChanged<Offset> onChanged;
  final ValueChanged<bool>? onActiveChanged;

  @override
  State<VirtualJoystick> createState() => _VirtualJoystickState();
}

class _VirtualJoystickState extends State<VirtualJoystick> {
  Offset _knobOffset = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 148,
      height: 148,
      child: GestureDetector(
        onPanStart: (details) =>
            _update(details.localPosition, const Size(148, 148)),
        onPanUpdate: (details) =>
            _update(details.localPosition, const Size(148, 148)),
        onPanEnd: (_) => _reset(),
        onPanCancel: _reset,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: <Color>[
                widget.accent.withValues(alpha: 0.28),
                widget.accent.withValues(alpha: 0.08),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
            border: Border.all(
              color: widget.accent.withValues(alpha: 0.42),
              width: 1.6,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: widget.accent.withValues(alpha: 0.16),
                blurRadius: 24,
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Text(
                widget.label,
                style: GoogleFonts.orbitron(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              Positioned(
                left: 74 + _knobOffset.dx - 24,
                top: 74 + _knobOffset.dy - 24,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: <Color>[
                        Colors.white.withValues(alpha: 0.95),
                        widget.accent.withValues(alpha: 0.9),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: widget.accent.withValues(alpha: 0.25),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _update(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final delta = localPosition - center;
    const maxRadius = 38.0;

    Offset knob = delta;
    if (delta.distance > maxRadius) {
      knob = delta / delta.distance * maxRadius;
    }

    setState(() {
      _knobOffset = knob;
    });

    widget.onActiveChanged?.call(true);
    widget.onChanged(Offset(knob.dx / maxRadius, knob.dy / maxRadius));
  }

  void _reset() {
    if (_knobOffset == Offset.zero) {
      widget.onActiveChanged?.call(false);
      widget.onChanged(Offset.zero);
      return;
    }

    setState(() {
      _knobOffset = Offset.zero;
    });
    widget.onActiveChanged?.call(false);
    widget.onChanged(Offset.zero);
  }
}
