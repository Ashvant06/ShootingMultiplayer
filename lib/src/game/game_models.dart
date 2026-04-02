import 'dart:ui';

class WorldSnapshot {
  const WorldSnapshot({
    required this.worldWidth,
    required this.worldHeight,
    required this.players,
    required this.enemies,
    required this.bullets,
    required this.teamScore,
    required this.wave,
    required this.serverTime,
  });

  final double worldWidth;
  final double worldHeight;
  final List<PlayerSnapshot> players;
  final List<EnemySnapshot> enemies;
  final List<BulletSnapshot> bullets;
  final int teamScore;
  final int wave;
  final int serverTime;

  static const empty = WorldSnapshot(
    worldWidth: 1800,
    worldHeight: 1200,
    players: <PlayerSnapshot>[],
    enemies: <EnemySnapshot>[],
    bullets: <BulletSnapshot>[],
    teamScore: 0,
    wave: 1,
    serverTime: 0,
  );

  factory WorldSnapshot.fromJson(Map<String, dynamic> json) {
    return WorldSnapshot(
      worldWidth: (json['worldWidth'] as num?)?.toDouble() ?? 1800,
      worldHeight: (json['worldHeight'] as num?)?.toDouble() ?? 1200,
      players: ((json['players'] as List<dynamic>?) ?? const <dynamic>[])
          .map(
            (dynamic item) =>
                PlayerSnapshot.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      enemies: ((json['enemies'] as List<dynamic>?) ?? const <dynamic>[])
          .map(
            (dynamic item) =>
                EnemySnapshot.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      bullets: ((json['bullets'] as List<dynamic>?) ?? const <dynamic>[])
          .map(
            (dynamic item) =>
                BulletSnapshot.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      teamScore: (json['teamScore'] as num?)?.toInt() ?? 0,
      wave: (json['wave'] as num?)?.toInt() ?? 1,
      serverTime: (json['serverTime'] as num?)?.toInt() ?? 0,
    );
  }

  PlayerSnapshot? playerById(String? id) {
    if (id == null || id.isEmpty) {
      return null;
    }
    for (final player in players) {
      if (player.id == id) {
        return player;
      }
    }
    return null;
  }
}

class PlayerSnapshot {
  const PlayerSnapshot({
    required this.id,
    required this.name,
    required this.x,
    required this.y,
    required this.rotation,
    required this.health,
    required this.maxHealth,
    required this.score,
    required this.respawnIn,
  });

  final String id;
  final String name;
  final double x;
  final double y;
  final double rotation;
  final double health;
  final double maxHealth;
  final int score;
  final double respawnIn;

  bool get isAlive => health > 0;
  Offset get position => Offset(x, y);

  factory PlayerSnapshot.fromJson(Map<String, dynamic> json) {
    return PlayerSnapshot(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Pilot',
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      health: (json['health'] as num?)?.toDouble() ?? 0,
      maxHealth: (json['maxHealth'] as num?)?.toDouble() ?? 100,
      score: (json['score'] as num?)?.toInt() ?? 0,
      respawnIn: (json['respawnIn'] as num?)?.toDouble() ?? 0,
    );
  }
}

class EnemySnapshot {
  const EnemySnapshot({
    required this.id,
    required this.x,
    required this.y,
    required this.health,
    required this.maxHealth,
  });

  final String id;
  final double x;
  final double y;
  final double health;
  final double maxHealth;

  Offset get position => Offset(x, y);

  factory EnemySnapshot.fromJson(Map<String, dynamic> json) {
    return EnemySnapshot(
      id: json['id'] as String? ?? '',
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
      health: (json['health'] as num?)?.toDouble() ?? 40,
      maxHealth: (json['maxHealth'] as num?)?.toDouble() ?? 40,
    );
  }
}

class BulletSnapshot {
  const BulletSnapshot({
    required this.id,
    required this.ownerId,
    required this.x,
    required this.y,
  });

  final String id;
  final String ownerId;
  final double x;
  final double y;

  Offset get position => Offset(x, y);

  factory BulletSnapshot.fromJson(Map<String, dynamic> json) {
    return BulletSnapshot(
      id: json['id'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      x: (json['x'] as num?)?.toDouble() ?? 0,
      y: (json['y'] as num?)?.toDouble() ?? 0,
    );
  }
}
