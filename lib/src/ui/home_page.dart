import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game/character_archetypes.dart';
import '../game/game_controller.dart';
import '../game/game_models.dart';
import '../game/game_painter.dart';
import '../theme/app_theme.dart';
import '../widgets/fantasy_character_viewer.dart';
import '../widgets/virtual_joystick.dart';

class ShooterHomePage extends StatefulWidget {
  const ShooterHomePage({super.key});

  @override
  State<ShooterHomePage> createState() => _ShooterHomePageState();
}

class _ShooterHomePageState extends State<ShooterHomePage> {
  late final ShooterGameController _controller;
  late final TextEditingController _nameController;
  late final TextEditingController _roomController;
  late final TextEditingController _serverController;

  @override
  void initState() {
    super.initState();
    _controller = ShooterGameController();
    _nameController = TextEditingController(text: _defaultPilotName());
    _roomController = TextEditingController(text: 'ALPHA');
    _serverController = TextEditingController(
      text: ShooterGameController.defaultServerUrl,
    );
    _controller.addListener(_handleControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerUpdate);
    _controller.dispose();
    _nameController.dispose();
    _roomController.dispose();
    _serverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  Color(0xFF09060F),
                  Color(0xFF120D1E),
                  Color(0xFF1A1220),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: _controller.hasActiveRoom
                  ? _buildGameScreen(context)
                  : _buildLobby(context),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLobby(BuildContext context) {
    final bodyStyle = Theme.of(context).textTheme.bodyMedium;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 980;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: compact
          ? ListView(
              children: <Widget>[
                _buildHero(context, compact: true),
                const SizedBox(height: 20),
                _buildControlPanel(context),
                const SizedBox(height: 18),
                _buildTipsCard(bodyStyle),
              ],
            )
          : Row(
              children: <Widget>[
                Expanded(flex: 7, child: _buildHero(context)),
                const SizedBox(width: 22),
                Expanded(
                  flex: 5,
                  child: Column(
                    children: <Widget>[
                      Expanded(child: _buildControlPanel(context)),
                      const SizedBox(height: 18),
                      _buildTipsCard(bodyStyle),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHero(BuildContext context, {bool compact = false}) {
    final cards = kCharacterArchetypes
        .map(
          (CharacterArchetype archetype) =>
              FantasyCharacterCard(archetype: archetype, compact: compact),
        )
        .toList(growable: false);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF120C16),
            Color(0xFF1A1125),
            Color(0xFF24161D),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x66000000),
            blurRadius: 34,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -20,
            top: -30,
            child: _GlowOrb(color: AppTheme.violet, size: compact ? 160 : 220),
          ),
          Positioned(
            left: -10,
            bottom: -24,
            child: _GlowOrb(color: AppTheme.emerald, size: compact ? 120 : 160),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'FANTASY CO-OP SIEGE',
                    style: GoogleFonts.cinzel(
                      color: AppTheme.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                    ),
                  ),
                ),
                if (!compact) const Spacer(),
                if (compact) const SizedBox(height: 24),
                Text(
                  'MYTHIC\nSIEGE',
                  style: GoogleFonts.cinzelDecorative(
                    fontSize: compact ? 42 : 58,
                    height: 0.95,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Text(
                    'Summon a squad, step into a cursed citadel, and defend the realm against enchanted monstrosities with live online co-op combat and full 3D hero showcases.',
                    style: GoogleFonts.spectral(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 18,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: const <Widget>[
                    _FeatureChip(label: '3D hero roster'),
                    _FeatureChip(label: 'Fantasy citadel battlefield'),
                    _FeatureChip(label: 'Online room co-op'),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: compact ? 360 : 310,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (BuildContext context, int index) =>
                        cards[index],
                    separatorBuilder: (BuildContext _, int index) =>
                        const SizedBox(width: 14),
                    itemCount: cards.length,
                  ),
                ),
                if (!compact) const Spacer(),
                if (compact) const SizedBox(height: 22),
                Text(
                  'Drag the left sigil to move, drag the right sigil to cast fire. Each room defends a shared fortress through escalating waves.',
                  style: GoogleFonts.spectral(
                    color: AppTheme.amber,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: AppTheme.panel,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppTheme.rose.withValues(alpha: 0.06),
            blurRadius: 24,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Realm Gate',
              style: GoogleFonts.cinzelDecorative(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Open a portal to your match server, then create or join a warband code to enter the citadel.',
              style: GoogleFonts.spectral(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Hero Name'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _roomController,
              decoration: const InputDecoration(labelText: 'Warband Code'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _serverController,
              decoration: const InputDecoration(labelText: 'Portal URL'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                if (ShooterGameController.lanServerUrl.isNotEmpty)
                  _PortalPresetChip(
                    label: 'This PC Wi-Fi',
                    value: ShooterGameController.lanServerUrl,
                    onSelected: _applyServerPreset,
                  ),
                _PortalPresetChip(
                  label: 'Android Emulator',
                  value: ShooterGameController.emulatorServerUrl,
                  onSelected: _applyServerPreset,
                ),
                _PortalPresetChip(
                  label: 'This Device',
                  value: ShooterGameController.desktopServerUrl,
                  onSelected: _applyServerPreset,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ShooterGameController.lanServerUrl.isNotEmpty
                  ? 'For your Redmi on the same Wi-Fi, use ${ShooterGameController.lanServerUrl}.'
                  : 'For a real phone, use your computer Wi-Fi IP instead of 10.0.2.2.',
              style: GoogleFonts.spectral(
                color: Colors.white.withValues(alpha: 0.68),
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(
                  child: FilledButton(
                    onPressed: _controller.phase == ConnectionPhase.connecting
                        ? null
                        : () => _controller.createRoom(
                            name: _nameController.text,
                            url: _serverController.text,
                          ),
                    child: const Text('Forge Room'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _controller.phase == ConnectionPhase.connecting
                        ? null
                        : () => _controller.joinRoom(
                            name: _nameController.text,
                            room: _roomController.text,
                            url: _serverController.text,
                          ),
                    child: const Text('Join Warband'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _StatusStrip(
              label: 'STATUS',
              value: _controller.phase == ConnectionPhase.connecting
                  ? 'Connecting'
                  : _controller.statusMessage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCard(TextStyle? bodyStyle) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Portal Guidance',
              style: GoogleFonts.cinzel(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Android emulator: use ws://10.0.2.2:8080\nPhysical device: use your computer LAN IP, for example ws://192.168.1.20:8080\nDesktop simulator or same machine: ws://127.0.0.1:8080',
              style: bodyStyle?.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameScreen(BuildContext context) {
    final snapshot = _controller.snapshot;
    final localPlayer = _controller.localPlayer;
    final localArchetype = resolveArchetype(
      localPlayer?.id.isNotEmpty == true
          ? localPlayer!.id
          : _nameController.text,
    );
    final playerCount = snapshot.players.length;
    final compact = MediaQuery.sizeOf(context).width < 900;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFF110C16), Color(0xFF1C1522)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: CustomPaint(
                  painter: GamePainter(
                    snapshot: snapshot,
                    localPlayerId: _controller.playerId,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 14,
            left: 14,
            right: compact ? 14 : null,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                _HudPill(label: 'ROOM', value: _controller.roomId),
                _HudPill(label: 'PLAYERS', value: '$playerCount'),
                _HudPill(label: 'WAVE', value: '${snapshot.wave}'),
                _HudPill(label: 'SCORE', value: '${snapshot.teamScore}'),
                _HudPill(
                  label: 'UPLINK',
                  value: _controller.phase.name.toUpperCase(),
                  accent: _controller.isConnected
                      ? AppTheme.cyan
                      : AppTheme.rose,
                ),
              ],
            ),
          ),
          Positioned(
            top: 14,
            right: 14,
            child: OutlinedButton.icon(
              onPressed: () => _controller.disconnect(),
              icon: const Icon(Icons.close_rounded),
              label: const Text('Leave'),
            ),
          ),
          Positioned(
            left: 16,
            top: compact ? 78 : 70,
            child: SizedBox(
              width: compact ? 210 : 250,
              child: _SquadPanel(
                players: snapshot.players,
                localPlayerId: _controller.playerId,
              ),
            ),
          ),
          if (localPlayer != null)
            Positioned(
              left: compact ? 16 : 280,
              top: compact ? 86 : 78,
              child: _PlayerCard(
                player: localPlayer,
                archetype: localArchetype,
              ),
            ),
          Positioned(
            left: 18,
            bottom: 18,
            child: VirtualJoystick(
              label: 'MOVE',
              accent: AppTheme.cyan,
              onChanged: _controller.updateMovement,
            ),
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: VirtualJoystick(
              label: 'AIM / FIRE',
              accent: AppTheme.amber,
              onChanged: (vector) =>
                  _controller.updateAim(vector, firing: vector != Offset.zero),
              onActiveChanged: (active) {
                if (!active) {
                  _controller.stopAim();
                }
              },
            ),
          ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Drag the right sigil to unleash spells and steel. Every ally in the warband sees the same siege in real time.',
                style: GoogleFonts.spectral(
                  color: Colors.white.withValues(alpha: 0.74),
                  fontSize: compact ? 11 : 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (_controller.phase == ConnectionPhase.connecting ||
              _controller.phase == ConnectionPhase.disconnected ||
              _controller.phase == ConnectionPhase.error ||
              (localPlayer != null && !localPlayer.isAlive))
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Center(child: _buildOverlayCard(localPlayer)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverlayCard(PlayerSnapshot? localPlayer) {
    String title;
    String body;

    if (_controller.phase == ConnectionPhase.connecting) {
      title = 'Opening portal';
      body =
          'Summoning your hero into the citadel and waiting for the realm server to confirm your arrival.';
    } else if (_controller.phase == ConnectionPhase.error ||
        _controller.phase == ConnectionPhase.disconnected) {
      title = 'Portal interrupted';
      body = _controller.errorMessage ?? _controller.statusMessage;
    } else {
      title = 'Reforging';
      body =
          'Your champion is being restored. Back in ${localPlayer?.respawnIn.ceil() ?? 1}s.';
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: const Color(0xE1121B30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            style: GoogleFonts.cinzelDecorative(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            body,
            textAlign: TextAlign.center,
            style: GoogleFonts.spectral(
              color: Colors.white.withValues(alpha: 0.76),
              height: 1.55,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  void _handleControllerUpdate() {
    final message = _controller.errorMessage;
    if (!mounted || message == null || message.isEmpty) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    _controller.clearError();
  }

  void _applyServerPreset(String value) {
    setState(() {
      _serverController.text = value;
      _serverController.selection = TextSelection.collapsed(
        offset: _serverController.text.length,
      );
    });
  }

  String _defaultPilotName() {
    const names = <String>['Aurel', 'Nyra', 'Syl', 'Kael', 'Seren', 'Thorne'];
    final random = math.Random();
    return '${names[random.nextInt(names.length)]}-${random.nextInt(89) + 10}';
  }
}

class _PortalPresetChip extends StatelessWidget {
  const _PortalPresetChip({
    required this.label,
    required this.value,
    required this.onSelected,
  });

  final String label;
  final String value;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: () => onSelected(value),
      backgroundColor: Colors.white.withValues(alpha: 0.06),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      label: Text(
        label,
        style: GoogleFonts.cinzel(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: GoogleFonts.spectral(
          color: Colors.white.withValues(alpha: 0.86),
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: <Widget>[
          Text(
            label,
            style: GoogleFonts.cinzel(
              color: AppTheme.amber,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.spectral(
                color: Colors.white.withValues(alpha: 0.82),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HudPill extends StatelessWidget {
  const _HudPill({
    required this.label,
    required this.value,
    this.accent = AppTheme.amber,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xCC121B30),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: GoogleFonts.cinzel(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: accent,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.spectral(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _SquadPanel extends StatelessWidget {
  const _SquadPanel({required this.players, required this.localPlayerId});

  final List<PlayerSnapshot> players;
  final String localPlayerId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xCC121B30),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            'Warband',
            style: GoogleFonts.cinzel(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          if (players.isEmpty)
            Text(
              'Waiting for server state...',
              style: GoogleFonts.spectral(
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          for (final player in players.take(5))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: player.isAlive ? AppTheme.cyan : AppTheme.rose,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      player.id == localPlayerId
                          ? '${player.name} (You)'
                          : player.name,
                      style: GoogleFonts.spectral(
                        color: Colors.white.withValues(alpha: 0.84),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${player.score}',
                    style: GoogleFonts.cinzel(
                      color: AppTheme.amber,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.player, required this.archetype});

  final PlayerSnapshot player;
  final CharacterArchetype archetype;

  @override
  Widget build(BuildContext context) {
    final healthRatio = (player.health / player.maxHealth).clamp(0.0, 1.0);

    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xCC15111D),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: 118,
            child: FantasyCharacterViewer(
              archetype: archetype,
              showFrame: false,
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            player.name,
            style: GoogleFonts.cinzelDecorative(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          Text(
            archetype.title,
            style: GoogleFonts.cinzel(
              color: archetype.accent,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0.9,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: healthRatio,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.cyan),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            player.isAlive
                ? '${player.health.toStringAsFixed(0)} HP'
                : 'Respawn in ${player.respawnIn.ceil()}s',
            style: GoogleFonts.spectral(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[
              color.withValues(alpha: 0.34),
              color.withValues(alpha: 0.12),
              color.withValues(alpha: 0.01),
            ],
          ),
        ),
      ),
    );
  }
}
