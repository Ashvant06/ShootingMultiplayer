import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import 'character_archetypes.dart';
import 'game_models.dart';

class GamePainter extends CustomPainter {
  const GamePainter({required this.snapshot, required this.localPlayerId});

  final WorldSnapshot snapshot;
  final String localPlayerId;

  @override
  void paint(Canvas canvas, Size size) {
    final localPlayer = snapshot.playerById(localPlayerId);
    final focus =
        localPlayer?.position ??
        Offset(snapshot.worldWidth / 2, snapshot.worldHeight / 2);

    canvas.save();
    canvas.translate(size.width / 2 - focus.dx, size.height / 2 - focus.dy);

    _drawArena(canvas);
    _drawArcaneFloor(canvas);
    _drawEmbers(canvas);
    _drawBullets(canvas);
    _drawEnemies(canvas);
    _drawPlayers(canvas);

    canvas.restore();

    if (localPlayer == null) {
      _drawCenterLabel(canvas, size, 'Summoning hero...');
    }
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) {
    return oldDelegate.snapshot.serverTime != snapshot.serverTime ||
        oldDelegate.localPlayerId != localPlayerId;
  }

  void _drawArena(Canvas canvas) {
    final arena = Rect.fromLTWH(
      0,
      0,
      snapshot.worldWidth,
      snapshot.worldHeight,
    );
    final background = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[
          Color(0xFF171019),
          Color(0xFF261724),
          Color(0xFF1A1626),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(arena);
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = AppTheme.amber.withValues(alpha: 0.28);

    canvas.drawRRect(
      RRect.fromRectAndRadius(arena, const Radius.circular(42)),
      background,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(arena, const Radius.circular(42)),
      border,
    );
  }

  void _drawArcaneFloor(Canvas canvas) {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    for (double x = 90; x < snapshot.worldWidth; x += 140) {
      canvas.drawLine(Offset(x, 0), Offset(x, snapshot.worldHeight), linePaint);
    }
    for (double y = 90; y < snapshot.worldHeight; y += 140) {
      canvas.drawLine(Offset(0, y), Offset(snapshot.worldWidth, y), linePaint);
    }

    final center = Offset(snapshot.worldWidth / 2, snapshot.worldHeight / 2);
    final runePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = AppTheme.violet.withValues(alpha: 0.18);
    canvas.drawCircle(center, 180, runePaint);
    canvas.drawCircle(
      center,
      260,
      runePaint..color = AppTheme.amber.withValues(alpha: 0.12),
    );

    for (int i = 0; i < 12; i++) {
      final angle = math.pi * 2 / 12 * i;
      final inner = center + Offset(math.cos(angle), math.sin(angle)) * 194;
      final outer = center + Offset(math.cos(angle), math.sin(angle)) * 246;
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..color = AppTheme.cyan.withValues(alpha: 0.16)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }

    _drawTorch(canvas, const Offset(120, 120));
    _drawTorch(canvas, Offset(snapshot.worldWidth - 120, 120));
    _drawTorch(canvas, Offset(120, snapshot.worldHeight - 120));
    _drawTorch(
      canvas,
      Offset(snapshot.worldWidth - 120, snapshot.worldHeight - 120),
    );
  }

  void _drawTorch(Canvas canvas, Offset center) {
    final flame = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          Colors.white.withValues(alpha: 0.75),
          AppTheme.amber.withValues(alpha: 0.65),
          AppTheme.rose.withValues(alpha: 0.12),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: 42));
    canvas.drawCircle(center, 28, flame);
    canvas.drawRect(
      Rect.fromCenter(center: center.translate(0, 24), width: 10, height: 30),
      Paint()..color = const Color(0xFF5A3A20),
    );
  }

  void _drawEmbers(Canvas canvas) {
    final tick = snapshot.serverTime / 1000;
    for (int i = 0; i < 24; i++) {
      final x = (i * 73.0 + tick * 18) % snapshot.worldWidth;
      final y =
          (i * 109.0 + math.sin(tick + i) * 60 + tick * 10) %
          snapshot.worldHeight;
      final emberCenter = Offset(x, y);
      canvas.drawCircle(
        emberCenter,
        2 + (i % 3),
        Paint()..color = AppTheme.amber.withValues(alpha: 0.22),
      );
    }
  }

  void _drawBullets(Canvas canvas) {
    for (final bullet in snapshot.bullets) {
      final isLocal = bullet.ownerId == localPlayerId;
      final boltPaint = Paint()
        ..color = (isLocal ? AppTheme.amber : AppTheme.cyan).withValues(
          alpha: 0.95,
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      final highlight = Paint()..color = Colors.white.withValues(alpha: 0.90);

      canvas.drawOval(
        Rect.fromCenter(center: bullet.position, width: 14, height: 8),
        boltPaint,
      );
      canvas.drawCircle(bullet.position, 2.5, highlight);
    }
  }

  void _drawEnemies(Canvas canvas) {
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.24);

    for (final enemy in snapshot.enemies) {
      final center = enemy.position;
      canvas.drawOval(
        Rect.fromCenter(center: center.translate(0, 28), width: 46, height: 16),
        shadowPaint,
      );

      final bodyPath = Path()
        ..moveTo(center.dx, center.dy - 34)
        ..lineTo(center.dx + 24, center.dy - 10)
        ..lineTo(center.dx + 22, center.dy + 18)
        ..lineTo(center.dx, center.dy + 30)
        ..lineTo(center.dx - 22, center.dy + 18)
        ..lineTo(center.dx - 24, center.dy - 10)
        ..close();

      canvas.drawShadow(bodyPath, AppTheme.rose, 18, false);
      canvas.drawPath(
        bodyPath,
        Paint()
          ..shader =
              LinearGradient(
                colors: <Color>[
                  AppTheme.rose.withValues(alpha: 0.95),
                  const Color(0xFF6F1624),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ).createShader(
                Rect.fromCenter(center: center, width: 60, height: 70),
              ),
      );

      final hornPaint = Paint()..color = const Color(0xFFFDE7BE);
      canvas.drawPath(
        Path()
          ..moveTo(center.dx - 10, center.dy - 24)
          ..lineTo(center.dx - 28, center.dy - 44)
          ..lineTo(center.dx - 2, center.dy - 30)
          ..close(),
        hornPaint,
      );
      canvas.drawPath(
        Path()
          ..moveTo(center.dx + 10, center.dy - 24)
          ..lineTo(center.dx + 28, center.dy - 44)
          ..lineTo(center.dx + 2, center.dy - 30)
          ..close(),
        hornPaint,
      );

      canvas.drawCircle(
        center.translate(0, -6),
        12,
        Paint()..color = const Color(0xFFFDEDE6),
      );
      canvas.drawCircle(
        center.translate(-5, -8),
        2,
        Paint()..color = const Color(0xFF1B1012),
      );
      canvas.drawCircle(
        center.translate(5, -8),
        2,
        Paint()..color = const Color(0xFF1B1012),
      );

      final healthRatio = (enemy.health / enemy.maxHealth).clamp(0.0, 1.0);
      _drawEnemyHealth(canvas, center.translate(0, -50), healthRatio);
    }
  }

  void _drawPlayers(Canvas canvas) {
    for (final player in snapshot.players) {
      final isLocal = player.id == localPlayerId;
      final archetype = resolveArchetype(player.id);
      final center = player.position;
      final facing = Offset(
        math.cos(player.rotation),
        math.sin(player.rotation),
      );
      final side = Offset(-facing.dy, facing.dx);

      canvas.drawOval(
        Rect.fromCenter(center: center.translate(0, 22), width: 44, height: 16),
        Paint()..color = Colors.black.withValues(alpha: 0.26),
      );

      final bodyColor = player.isAlive
          ? archetype.accent
          : archetype.accent.withValues(alpha: 0.28);
      final cloakColor = isLocal
          ? AppTheme.amber
          : AppTheme.violet.withValues(alpha: 0.80);

      final cloakPath = Path()
        ..moveTo(center.dx - side.dx * 13, center.dy + 2)
        ..lineTo(center.dx + side.dx * 13, center.dy + 2)
        ..lineTo(center.dx + facing.dx * 6, center.dy + 28)
        ..lineTo(center.dx - facing.dx * 6, center.dy + 28)
        ..close();
      canvas.drawPath(
        cloakPath,
        Paint()
          ..color = cloakColor.withValues(alpha: player.isAlive ? 0.72 : 0.24),
      );

      final torsoRect = Rect.fromCenter(center: center, width: 28, height: 34);
      canvas.drawRRect(
        RRect.fromRectAndRadius(torsoRect, const Radius.circular(14)),
        Paint()
          ..shader = LinearGradient(
            colors: <Color>[
              bodyColor.withValues(alpha: 0.96),
              const Color(0xFF201722),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(torsoRect),
      );

      canvas.drawCircle(
        center.translate(0, -24),
        12,
        Paint()
          ..color = const Color(
            0xFFF7ECDE,
          ).withValues(alpha: player.isAlive ? 0.95 : 0.42),
      );

      canvas.drawCircle(
        center.translate(0, -24),
        14,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = bodyColor.withValues(alpha: player.isAlive ? 0.92 : 0.30),
      );

      canvas.drawLine(
        center + facing * 10,
        center + facing * 34,
        Paint()
          ..color = AppTheme.mist.withValues(alpha: player.isAlive ? 0.92 : 0.4)
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );

      canvas.drawLine(
        center - side * 10,
        center - side * 16 + facing * 8,
        Paint()
          ..color = bodyColor.withValues(alpha: player.isAlive ? 0.9 : 0.3)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        center + side * 10,
        center + side * 16 + facing * 8,
        Paint()
          ..color = bodyColor.withValues(alpha: player.isAlive ? 0.9 : 0.3)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );

      canvas.drawLine(
        center.translate(-6, 18),
        center.translate(-6, 34),
        Paint()
          ..color = const Color(
            0xFF2A2029,
          ).withValues(alpha: player.isAlive ? 0.9 : 0.3)
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        center.translate(6, 18),
        center.translate(6, 34),
        Paint()
          ..color = const Color(
            0xFF2A2029,
          ).withValues(alpha: player.isAlive ? 0.9 : 0.3)
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round,
      );

      _drawHealthBar(
        canvas,
        center,
        player.health / player.maxHealth,
        bodyColor,
      );
      _drawLabel(
        canvas,
        player.name,
        center.translate(0, -48),
        isLocal ? archetype.title : '${player.score} K',
      );

      if (!player.isAlive) {
        _drawSmallLabel(
          canvas,
          'REFORGE ${player.respawnIn.ceil()}',
          center.translate(0, 44),
        );
      }
    }
  }

  void _drawEnemyHealth(Canvas canvas, Offset center, double ratio) {
    final barRect = Rect.fromCenter(center: center, width: 44, height: 6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(barRect, const Radius.circular(8)),
      Paint()..color = Colors.black.withValues(alpha: 0.30),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          barRect.left,
          barRect.top,
          barRect.width * ratio,
          barRect.height,
        ),
        const Radius.circular(8),
      ),
      Paint()..color = AppTheme.amber,
    );
  }

  void _drawHealthBar(Canvas canvas, Offset center, double ratio, Color color) {
    final background = Paint()..color = Colors.black.withValues(alpha: 0.36);
    final fill = Paint()..color = color;
    final rect = Rect.fromCenter(
      center: center.translate(0, -34),
      width: 52,
      height: 7,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      background,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          rect.left,
          rect.top,
          rect.width * ratio.clamp(0.0, 1.0),
          rect.height,
        ),
        const Radius.circular(12),
      ),
      fill,
    );
  }

  void _drawLabel(Canvas canvas, String name, Offset anchor, String tag) {
    final paragraph = TextPainter(
      text: TextSpan(
        style: GoogleFonts.spectral(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        children: <InlineSpan>[
          TextSpan(text: name),
          TextSpan(
            text: '  $tag',
            style: GoogleFonts.cinzel(
              color: AppTheme.amber,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 220);

    paragraph.paint(
      canvas,
      anchor.translate(-paragraph.width / 2, -paragraph.height / 2),
    );
  }

  void _drawSmallLabel(Canvas canvas, String text, Offset anchor) {
    final paragraph = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.cinzel(
          color: Colors.white.withValues(alpha: 0.74),
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    paragraph.paint(
      canvas,
      anchor.translate(-paragraph.width / 2, -paragraph.height / 2),
    );
  }

  void _drawCenterLabel(Canvas canvas, Size size, String text) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: GoogleFonts.cinzelDecorative(
          color: Colors.white.withValues(alpha: 0.76),
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    painter.paint(
      canvas,
      Offset(
        size.width / 2 - painter.width / 2,
        size.height / 2 - painter.height / 2,
      ),
    );
  }
}
