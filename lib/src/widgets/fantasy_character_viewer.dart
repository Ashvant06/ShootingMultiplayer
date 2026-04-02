import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_cube/flutter_cube.dart' as cube;
import 'package:google_fonts/google_fonts.dart';

import '../game/character_archetypes.dart';
import '../theme/app_theme.dart';

class FantasyCharacterViewer extends StatefulWidget {
  const FantasyCharacterViewer({
    super.key,
    required this.archetype,
    this.interactive = false,
    this.padding = const EdgeInsets.all(12),
    this.showFrame = true,
  });

  final CharacterArchetype archetype;
  final bool interactive;
  final EdgeInsets padding;
  final bool showFrame;

  @override
  State<FantasyCharacterViewer> createState() => _FantasyCharacterViewerState();
}

class _FantasyCharacterViewerState extends State<FantasyCharacterViewer>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  cube.Scene? _scene;
  cube.Object? _model;
  double _time = 0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: widget.padding,
      child: cube.Cube(
        // Keep the in-app hero showcase lightweight and local.
        interactive: widget.interactive,
        onSceneCreated: _onSceneCreated,
      ),
    );

    if (!widget.showFrame) {
      return content;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: RadialGradient(
          colors: <Color>[
            widget.archetype.accent.withValues(alpha: 0.28),
            const Color(0x66110F17),
            const Color(0x22110F17),
          ],
          center: const Alignment(0, -0.25),
          radius: 1.1,
        ),
        border: Border.all(
          color: widget.archetype.accent.withValues(alpha: 0.28),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: widget.archetype.accent.withValues(alpha: 0.16),
            blurRadius: 26,
          ),
        ],
      ),
      child: content,
    );
  }

  void _onSceneCreated(cube.Scene scene) {
    _scene = scene;
    scene.camera.position.setValues(0, 1.2, -16);
    scene.camera.target.setValues(0, 0.8, 0);
    scene.camera.zoom = 1.15;
    scene.light.position.setValues(0, 8, 6);
    scene.light.setColor(widget.archetype.accent, 0.45, 0.9, 0.25);

    final model = cube.Object(
      fileName: widget.archetype.modelAsset,
      lighting: true,
      backfaceCulling: false,
      normalized: true,
    );
    model.rotation.setValues(-10, 24, 0);
    model.scale.setValues(3.4, 3.4, 3.4);
    model.updateTransform();
    scene.world.add(model);
    _model = model;
  }

  void _tick(Duration elapsed) {
    final scene = _scene;
    final model = _model;
    if (scene == null || model == null || !mounted) {
      return;
    }

    _time = elapsed.inMilliseconds / 1000;
    model.rotation
      ..x = -10 + math.sin(_time * 0.8) * 2.5
      ..y = 24 + _time * 18
      ..z = math.sin(_time * 0.45) * 1.5;
    model.updateTransform();
    scene.update();
  }
}

class FantasyCharacterCard extends StatelessWidget {
  const FantasyCharacterCard({
    super.key,
    required this.archetype,
    this.compact = false,
  });

  final CharacterArchetype archetype;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 220 : 250,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xAA15111D),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: compact ? 148 : 185,
            child: FantasyCharacterViewer(archetype: archetype),
          ),
          SizedBox(height: compact ? 10 : 14),
          Text(
            archetype.title.toUpperCase(),
            style: GoogleFonts.cinzel(
              color: archetype.accent,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            archetype.name,
            style: GoogleFonts.cinzelDecorative(
              color: Colors.white,
              fontSize: compact ? 18 : 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            archetype.summary,
            maxLines: compact ? 3 : 4,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spectral(
              color: AppTheme.mist.withValues(alpha: 0.78),
              fontSize: compact ? 13 : 14,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
