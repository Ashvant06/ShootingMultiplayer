import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'game_models.dart';

enum ConnectionPhase { idle, connecting, connected, disconnected, error }

class ShooterGameController extends ChangeNotifier {
  ShooterGameController() {
    _inputTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => _sendInput(),
    );
  }

  static const String emulatorServerUrl = 'ws://10.0.2.2:8080';
  static const String desktopServerUrl = 'ws://127.0.0.1:8080';
  static const String lanServerUrl = String.fromEnvironment(
    'MYTHIC_SERVER_URL',
    defaultValue: '',
  );

  static String get defaultServerUrl =>
      lanServerUrl.isNotEmpty ? lanServerUrl : emulatorServerUrl;

  final math.Random _random = math.Random();

  WebSocket? _socket;
  StreamSubscription<dynamic>? _socketSubscription;
  Timer? _inputTimer;
  bool _intentionalClose = false;

  Offset _moveInput = Offset.zero;
  Offset _aimInput = const Offset(1, 0);
  bool _firing = false;

  ConnectionPhase phase = ConnectionPhase.idle;
  String playerId = '';
  String playerName = '';
  String roomId = '';
  String serverUrl = defaultServerUrl;
  String statusMessage = 'Ready to enter the citadel';
  String? errorMessage;
  WorldSnapshot snapshot = WorldSnapshot.empty;

  bool get hasActiveRoom => roomId.isNotEmpty;
  bool get isConnected => phase == ConnectionPhase.connected;
  PlayerSnapshot? get localPlayer => snapshot.playerById(playerId);

  Future<void> createRoom({required String name, required String url}) async {
    final generatedRoom = _generateRoomCode();
    await joinRoom(name: name, room: generatedRoom, url: url);
  }

  Future<void> joinRoom({
    required String name,
    required String room,
    required String url,
  }) async {
    final trimmedName = name.trim();
    final trimmedRoom = room.trim().toUpperCase();
    final trimmedUrl = url.trim();

    if (trimmedName.isEmpty || trimmedRoom.isEmpty || trimmedUrl.isEmpty) {
      errorMessage = 'Enter a hero name, warband code, and portal URL.';
      notifyListeners();
      return;
    }

    await disconnect(resetRoom: false);

    playerName = trimmedName;
    roomId = trimmedRoom;
    serverUrl = trimmedUrl;
    statusMessage = 'Opening realm portal...';
    errorMessage = null;
    phase = ConnectionPhase.connecting;
    snapshot = WorldSnapshot.empty;
    playerId = '';
    notifyListeners();

    try {
      final socket = await WebSocket.connect(trimmedUrl);
      socket.pingInterval = const Duration(seconds: 5);
      _socket = socket;
      _intentionalClose = false;
      _socketSubscription = socket.listen(
        _handleMessage,
        onDone: _handleSocketDone,
        onError: _handleSocketError,
      );

      socket.add(
        jsonEncode(<String, Object?>{
          'type': 'join',
          'playerName': trimmedName,
          'roomId': trimmedRoom,
        }),
      );
    } catch (error) {
      phase = ConnectionPhase.error;
      statusMessage = 'Unable to reach the realm server.';
      errorMessage = _buildConnectionError(error, trimmedUrl);
      notifyListeners();
    }
  }

  Future<void> disconnect({bool resetRoom = true}) async {
    _intentionalClose = true;
    _firing = false;
    _moveInput = Offset.zero;
    _aimInput = const Offset(1, 0);
    await _socketSubscription?.cancel();
    _socketSubscription = null;
    await _socket?.close();
    _socket = null;

    if (resetRoom) {
      roomId = '';
      playerId = '';
      snapshot = WorldSnapshot.empty;
      phase = ConnectionPhase.idle;
      statusMessage = 'Ready to enter the citadel';
      errorMessage = null;
      notifyListeners();
    }
  }

  void updateMovement(Offset vector) {
    _moveInput = _clampVector(vector);
  }

  void updateAim(Offset vector, {required bool firing}) {
    final normalized = _clampVector(vector);
    _aimInput = normalized == Offset.zero ? _aimInput : normalized;
    _firing = firing && normalized != Offset.zero;
  }

  void stopAim() {
    _firing = false;
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _inputTimer?.cancel();
    _socketSubscription?.cancel();
    _socket?.close();
    super.dispose();
  }

  void _sendInput() {
    final socket = _socket;
    if (socket == null || phase == ConnectionPhase.error || roomId.isEmpty) {
      return;
    }

    try {
      socket.add(
        jsonEncode(<String, Object?>{
          'type': 'input',
          'moveX': _moveInput.dx,
          'moveY': _moveInput.dy,
          'aimX': _aimInput.dx,
          'aimY': _aimInput.dy,
          'firing': _firing,
        }),
      );
    } catch (_) {
      // Socket lifecycle callbacks surface failures to the UI.
    }
  }

  void _handleMessage(dynamic rawMessage) {
    if (rawMessage is! String) {
      return;
    }

    final decoded = jsonDecode(rawMessage);
    if (decoded is! Map<String, dynamic>) {
      return;
    }

    switch (decoded['type']) {
      case 'joined':
        playerId = decoded['playerId'] as String? ?? '';
        phase = ConnectionPhase.connected;
        statusMessage = 'The gate is open. Defend room $roomId.';
        errorMessage = null;
        notifyListeners();
        break;
      case 'state':
        snapshot = WorldSnapshot.fromJson(decoded);
        if (phase != ConnectionPhase.connected) {
          phase = ConnectionPhase.connected;
        }
        notifyListeners();
        break;
      case 'error':
        phase = ConnectionPhase.error;
        statusMessage = 'The realm server rejected the summon.';
        errorMessage = decoded['message'] as String? ?? 'Unknown server error';
        notifyListeners();
        break;
      default:
        break;
    }
  }

  void _handleSocketDone() {
    _socket = null;
    if (_intentionalClose) {
      return;
    }

    phase = ConnectionPhase.disconnected;
    statusMessage = 'Portal lost. Return to the hall and reconnect.';
    errorMessage = 'Socket closed unexpectedly.';
    notifyListeners();
  }

  void _handleSocketError(Object error) {
    if (_intentionalClose) {
      return;
    }

    phase = ConnectionPhase.error;
    statusMessage = 'The realm connection failed.';
    errorMessage = '$error';
    notifyListeners();
  }

  Offset _clampVector(Offset vector) {
    final distance = vector.distance;
    if (distance == 0) {
      return Offset.zero;
    }
    final clamped = math.min(distance, 1.0);
    return Offset(
      vector.dx / distance * clamped,
      vector.dy / distance * clamped,
    );
  }

  String _generateRoomCode() {
    const letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final values = List<String>.generate(
      5,
      (_) => letters[_random.nextInt(letters.length)],
    );
    return values.join();
  }

  String _buildConnectionError(Object error, String attemptedUrl) {
    final buffer = StringBuffer('$error');
    final lanHint = lanServerUrl.isNotEmpty
        ? lanServerUrl
        : 'ws://YOUR_COMPUTER_LAN_IP:8080';

    if (attemptedUrl.contains('10.0.2.2')) {
      buffer.write(
        ' 10.0.2.2 only works from the Android emulator. On a physical phone use $lanHint.',
      );
    } else if (attemptedUrl.contains('127.0.0.1') ||
        attemptedUrl.contains('localhost')) {
      buffer.write(
        ' localhost points to this device. On a physical phone use $lanHint.',
      );
    } else if (Platform.isAndroid) {
      buffer.write(
        ' Make sure the phone and computer are on the same Wi-Fi and that Windows Firewall allows TCP 8080.',
      );
    }

    return buffer.toString();
  }
}
