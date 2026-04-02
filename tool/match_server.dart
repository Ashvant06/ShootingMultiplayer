import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

Future<void> main(List<String> args) async {
  final options = _ServerOptions.parse(args);
  final address = options.host == '0.0.0.0'
      ? InternetAddress.anyIPv4
      : InternetAddress(options.host);
  final server = MatchServer();
  final httpServer = await HttpServer.bind(address, options.port);

  server.start();

  stdout.writeln(
    'Mythic Siege server listening on ws://${httpServer.address.address}:${httpServer.port}',
  );

  await for (final request in httpServer) {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final socket = await WebSocketTransformer.upgrade(request);
      server.handleSocket(socket);
      continue;
    }

    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.text
      ..write(
        'Mythic Siege multiplayer server is running.\nUse WebSocket clients to connect.',
      )
      ..close();
  }
}

class MatchServer {
  MatchServer({this.worldWidth = 1800, this.worldHeight = 1200});

  final double worldWidth;
  final double worldHeight;
  final math.Random _random = math.Random();
  final Map<String, Room> _rooms = <String, Room>{};

  Timer? _ticker;

  void start() {
    _ticker ??= Timer.periodic(
      const Duration(milliseconds: 50),
      (_) => _tick(0.05),
    );
  }

  void handleSocket(WebSocket socket) {
    final connection = ClientConnection(socket);

    socket.listen(
      (dynamic rawMessage) => _handleMessage(connection, rawMessage),
      onDone: () => _disconnect(connection),
      onError: (_) => _disconnect(connection),
      cancelOnError: true,
    );
  }

  void _handleMessage(ClientConnection connection, dynamic rawMessage) {
    if (rawMessage is! String) {
      return;
    }

    final decoded = jsonDecode(rawMessage);
    if (decoded is! Map<String, dynamic>) {
      return;
    }

    switch (decoded['type']) {
      case 'join':
        _joinRoom(
          connection,
          playerName: decoded['playerName'] as String? ?? '',
          roomId: decoded['roomId'] as String? ?? '',
        );
        break;
      case 'input':
        final room = connection.room;
        final player = connection.player;
        if (room == null || player == null) {
          return;
        }
        room.applyInput(
          player.id,
          moveX: (decoded['moveX'] as num?)?.toDouble() ?? 0,
          moveY: (decoded['moveY'] as num?)?.toDouble() ?? 0,
          aimX: (decoded['aimX'] as num?)?.toDouble() ?? 0,
          aimY: (decoded['aimY'] as num?)?.toDouble() ?? 0,
          firing: decoded['firing'] as bool? ?? false,
        );
        break;
      default:
        break;
    }
  }

  void _joinRoom(
    ClientConnection connection, {
    required String playerName,
    required String roomId,
  }) {
    final cleanName = playerName.trim();
    final cleanRoom = roomId.trim().toUpperCase();

    if (cleanName.isEmpty || cleanRoom.isEmpty) {
      connection.sendError('Both player name and room code are required.');
      return;
    }

    _disconnect(connection, closeSocket: false);

    final room = _rooms.putIfAbsent(
      cleanRoom,
      () => Room(
        id: cleanRoom,
        worldWidth: worldWidth,
        worldHeight: worldHeight,
        random: _random,
      ),
    );
    final player = room.addPlayer(cleanName, connection.socket);
    connection.room = room;
    connection.player = player;

    connection.socket.add(
      jsonEncode(<String, Object?>{
        'type': 'joined',
        'playerId': player.id,
        'roomId': cleanRoom,
      }),
    );
  }

  void _disconnect(ClientConnection connection, {bool closeSocket = false}) {
    final room = connection.room;
    final player = connection.player;
    if (room != null && player != null) {
      room.removePlayer(player.id);
      if (room.isEmpty) {
        _rooms.remove(room.id);
      }
    }

    connection.room = null;
    connection.player = null;

    if (closeSocket) {
      connection.socket.close();
    }
  }

  void _tick(double dt) {
    final emptyRooms = <String>[];
    for (final room in _rooms.values) {
      room.tick(dt);
      room.broadcastState();
      if (room.isEmpty) {
        emptyRooms.add(room.id);
      }
    }

    for (final roomId in emptyRooms) {
      _rooms.remove(roomId);
    }
  }
}

class Room {
  Room({
    required this.id,
    required this.worldWidth,
    required this.worldHeight,
    required this.random,
  });

  final String id;
  final double worldWidth;
  final double worldHeight;
  final math.Random random;

  final Map<String, PlayerEntity> players = <String, PlayerEntity>{};
  final List<EnemyEntity> enemies = <EnemyEntity>[];
  final List<BulletEntity> bullets = <BulletEntity>[];

  int teamScore = 0;
  int wave = 1;
  int _idCounter = 0;
  double _spawnClock = 0;

  bool get isEmpty => players.isEmpty;

  PlayerEntity addPlayer(String name, WebSocket socket) {
    final spawn = _randomSpawn();
    final player = PlayerEntity(
      id: _nextId('p'),
      name: name,
      socket: socket,
      x: spawn.dx,
      y: spawn.dy,
    );
    players[player.id] = player;
    return player;
  }

  void removePlayer(String playerId) {
    players.remove(playerId);
  }

  void applyInput(
    String playerId, {
    required double moveX,
    required double moveY,
    required double aimX,
    required double aimY,
    required bool firing,
  }) {
    final player = players[playerId];
    if (player == null) {
      return;
    }

    final move = _normalized(moveX, moveY);
    final aim = _normalized(aimX, aimY);
    player
      ..moveX = move.dx
      ..moveY = move.dy
      ..aimX = aim.dx
      ..aimY = aim.dy
      ..firing = firing && aim != Offset2.zero;

    if (aim != Offset2.zero) {
      player.rotation = math.atan2(aim.dy, aim.dx);
    }
  }

  void tick(double dt) {
    wave = math.max(1, 1 + teamScore ~/ 120);

    _updatePlayers(dt);
    _spawnEnemies(dt);
    _updateBullets(dt);
    _updateEnemies(dt);
    _handleCollisions(dt);
  }

  void broadcastState() {
    if (players.isEmpty) {
      return;
    }

    final payload = jsonEncode(<String, Object?>{
      'type': 'state',
      'roomId': id,
      'worldWidth': worldWidth,
      'worldHeight': worldHeight,
      'teamScore': teamScore,
      'wave': wave,
      'serverTime': DateTime.now().millisecondsSinceEpoch,
      'players': players.values
          .map((player) => player.toJson())
          .toList(growable: false),
      'bullets': bullets
          .map((bullet) => bullet.toJson())
          .toList(growable: false),
      'enemies': enemies.map((enemy) => enemy.toJson()).toList(growable: false),
    });

    final disconnected = <String>[];
    for (final player in players.values) {
      try {
        player.socket.add(payload);
      } catch (_) {
        disconnected.add(player.id);
      }
    }

    for (final playerId in disconnected) {
      removePlayer(playerId);
    }
  }

  void _updatePlayers(double dt) {
    for (final player in players.values) {
      player.shootCooldown = math.max(0, player.shootCooldown - dt);

      if (!player.isAlive) {
        player.respawnTimer = math.max(0, player.respawnTimer - dt);
        if (player.respawnTimer == 0) {
          final spawn = _randomSpawn();
          player
            ..x = spawn.dx
            ..y = spawn.dy
            ..health = player.maxHealth
            ..moveX = 0
            ..moveY = 0;
        }
        continue;
      }

      player.x = _clamp(
        player.x + player.moveX * player.speed * dt,
        player.radius,
        worldWidth - player.radius,
      );
      player.y = _clamp(
        player.y + player.moveY * player.speed * dt,
        player.radius,
        worldHeight - player.radius,
      );

      if (player.firing && player.shootCooldown == 0) {
        player.shootCooldown = 0.18;
        bullets.add(
          BulletEntity(
            id: _nextId('b'),
            ownerId: player.id,
            x: player.x + player.aimX * 28,
            y: player.y + player.aimY * 28,
            vx: player.aimX * 520,
            vy: player.aimY * 520,
          ),
        );
      }
    }
  }

  void _spawnEnemies(double dt) {
    _spawnClock += dt;
    final livingPlayers = players.values
        .where((player) => player.isAlive)
        .length;
    if (livingPlayers == 0) {
      return;
    }

    final targetEnemies = math.max(4, livingPlayers * 4 + wave);
    final spawnInterval = math.max(0.5, 1.6 - wave * 0.06);
    if (_spawnClock < spawnInterval || enemies.length >= targetEnemies) {
      return;
    }

    _spawnClock = 0;
    final spawn = _edgeSpawn();
    enemies.add(
      EnemyEntity(
        id: _nextId('e'),
        x: spawn.dx,
        y: spawn.dy,
        health: 44 + wave * 4,
        maxHealth: 44 + wave * 4,
      ),
    );
  }

  void _updateBullets(double dt) {
    bullets.removeWhere((bullet) {
      bullet
        ..x += bullet.vx * dt
        ..y += bullet.vy * dt
        ..life -= dt;

      return bullet.life <= 0 ||
          bullet.x < -20 ||
          bullet.y < -20 ||
          bullet.x > worldWidth + 20 ||
          bullet.y > worldHeight + 20;
    });
  }

  void _updateEnemies(double dt) {
    for (final enemy in enemies) {
      final target = _nearestLivingPlayer(enemy.x, enemy.y);
      if (target == null) {
        continue;
      }

      final direction = _normalized(target.x - enemy.x, target.y - enemy.y);
      enemy.x = _clamp(
        enemy.x + direction.dx * enemy.speed(wave) * dt,
        enemy.radius,
        worldWidth - enemy.radius,
      );
      enemy.y = _clamp(
        enemy.y + direction.dy * enemy.speed(wave) * dt,
        enemy.radius,
        worldHeight - enemy.radius,
      );
    }
  }

  void _handleCollisions(double dt) {
    final removedBullets = <String>{};
    final removedEnemies = <String>{};

    for (final bullet in bullets) {
      if (removedBullets.contains(bullet.id)) {
        continue;
      }

      for (final enemy in enemies) {
        if (removedEnemies.contains(enemy.id)) {
          continue;
        }

        final hitDistance = bullet.radius + enemy.radius;
        if (_distanceSquared(bullet.x, bullet.y, enemy.x, enemy.y) >
            hitDistance * hitDistance) {
          continue;
        }

        removedBullets.add(bullet.id);
        enemy.health -= 20;

        if (enemy.health <= 0) {
          removedEnemies.add(enemy.id);
          teamScore += 10;
          final owner = players[bullet.ownerId];
          if (owner != null) {
            owner.score += 1;
          }
        }
        break;
      }
    }

    bullets.removeWhere((bullet) => removedBullets.contains(bullet.id));
    enemies.removeWhere((enemy) => removedEnemies.contains(enemy.id));

    for (final enemy in enemies) {
      for (final player in players.values) {
        if (!player.isAlive) {
          continue;
        }

        final hitDistance = enemy.radius + player.radius;
        if (_distanceSquared(enemy.x, enemy.y, player.x, player.y) >
            hitDistance * hitDistance) {
          continue;
        }

        player.health = math.max(0, player.health - (28 + wave * 1.2) * dt);
        if (!player.isAlive) {
          player
            ..respawnTimer = 3.2
            ..moveX = 0
            ..moveY = 0
            ..firing = false;
        }
      }
    }
  }

  PlayerEntity? _nearestLivingPlayer(double x, double y) {
    PlayerEntity? target;
    double bestDistance = double.infinity;

    for (final player in players.values) {
      if (!player.isAlive) {
        continue;
      }

      final distance = _distanceSquared(x, y, player.x, player.y);
      if (distance < bestDistance) {
        bestDistance = distance;
        target = player;
      }
    }

    return target;
  }

  Offset2 _randomSpawn() {
    return Offset2(
      140 + random.nextDouble() * (worldWidth - 280),
      140 + random.nextDouble() * (worldHeight - 280),
    );
  }

  Offset2 _edgeSpawn() {
    switch (random.nextInt(4)) {
      case 0:
        return Offset2(20, random.nextDouble() * worldHeight);
      case 1:
        return Offset2(worldWidth - 20, random.nextDouble() * worldHeight);
      case 2:
        return Offset2(random.nextDouble() * worldWidth, 20);
      default:
        return Offset2(random.nextDouble() * worldWidth, worldHeight - 20);
    }
  }

  Offset2 _normalized(double x, double y) {
    final distance = math.sqrt(x * x + y * y);
    if (distance == 0) {
      return Offset2.zero;
    }
    return Offset2(x / distance, y / distance);
  }

  String _nextId(String prefix) {
    _idCounter += 1;
    return '$prefix$_idCounter';
  }

  double _distanceSquared(double ax, double ay, double bx, double by) {
    final dx = ax - bx;
    final dy = ay - by;
    return dx * dx + dy * dy;
  }

  double _clamp(double value, double min, double max) {
    return value < min ? min : (value > max ? max : value);
  }
}

class ClientConnection {
  ClientConnection(this.socket);

  final WebSocket socket;
  Room? room;
  PlayerEntity? player;

  void sendError(String message) {
    socket.add(
      jsonEncode(<String, Object?>{'type': 'error', 'message': message}),
    );
  }
}

class PlayerEntity {
  PlayerEntity({
    required this.id,
    required this.name,
    required this.socket,
    required this.x,
    required this.y,
  });

  final String id;
  final String name;
  final WebSocket socket;

  double x;
  double y;
  double rotation = 0;
  double moveX = 0;
  double moveY = 0;
  double aimX = 1;
  double aimY = 0;
  bool firing = false;
  int score = 0;

  final double radius = 20;
  final double maxHealth = 100;
  final double speed = 250;

  double health = 100;
  double shootCooldown = 0;
  double respawnTimer = 0;

  bool get isAlive => health > 0;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'x': x,
      'y': y,
      'rotation': rotation,
      'health': health,
      'maxHealth': maxHealth,
      'score': score,
      'respawnIn': respawnTimer,
    };
  }
}

class BulletEntity {
  BulletEntity({
    required this.id,
    required this.ownerId,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
  });

  final String id;
  final String ownerId;
  final double vx;
  final double vy;
  final double radius = 6;

  double x;
  double y;
  double life = 1.1;

  Map<String, Object?> toJson() {
    return <String, Object?>{'id': id, 'ownerId': ownerId, 'x': x, 'y': y};
  }
}

class EnemyEntity {
  EnemyEntity({
    required this.id,
    required this.x,
    required this.y,
    required this.health,
    required this.maxHealth,
  });

  final String id;
  final double radius = 24;
  final double maxHealth;

  double x;
  double y;
  double health;

  double speed(int wave) => 86 + wave * 5.5;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'x': x,
      'y': y,
      'health': health,
      'maxHealth': maxHealth,
    };
  }
}

class Offset2 {
  const Offset2(this.dx, this.dy);

  final double dx;
  final double dy;

  static const zero = Offset2(0, 0);

  @override
  bool operator ==(Object other) {
    return other is Offset2 && other.dx == dx && other.dy == dy;
  }

  @override
  int get hashCode => Object.hash(dx, dy);
}

class _ServerOptions {
  const _ServerOptions({required this.host, required this.port});

  final String host;
  final int port;

  factory _ServerOptions.parse(List<String> args) {
    var host = '0.0.0.0';
    var port = int.tryParse(Platform.environment['PORT'] ?? '') ?? 8080;

    for (final arg in args) {
      if (arg.startsWith('--host=')) {
        host = arg.substring('--host='.length);
      } else if (arg.startsWith('--port=')) {
        port = int.tryParse(arg.substring('--port='.length)) ?? port;
      }
    }

    return _ServerOptions(host: host, port: port);
  }
}
