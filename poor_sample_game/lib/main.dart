import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const DodgeApp());

class DodgeApp extends StatelessWidget {
  const DodgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dodge Ball',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const DodgeGameScreen(),
    );
  }
}

class Ball {
  double x;
  double y;
  double speed;
  double radius;
  Ball({required this.x, required this.y, required this.speed, required this.radius});
}

class DodgeGameScreen extends StatefulWidget {
  const DodgeGameScreen({super.key});

  @override
  State<DodgeGameScreen> createState() => _DodgeGameScreenState();
}

class _DodgeGameScreenState extends State<DodgeGameScreen> {
  final Random _rnd = Random();
  double _screenW = 400;
  double _screenH = 700;
  final double _playerSize = 60;
  double _playerX = 170;
  double _playerY = 620;

  List<Ball> _balls = [];
  int _score = 0;
  bool _gameOver = false;

  Timer? _spawnTimer;
  Timer? _gameTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      setState(() {
        _screenW = size.width;
        _screenH = size.height;
        _playerX = _screenW / 2 - _playerSize / 2;
        _playerY = _screenH - 120;
      });
      _startGame();
    });
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _gameTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    _balls.clear();
    _score = 0;
    _gameOver = false;
    _spawnTimer?.cancel();
    _gameTimer?.cancel();

    _spawnTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (_gameOver) return;
      final radius = 18.0 + _rnd.nextDouble() * 18;
      final x = _rnd.nextDouble() * (_screenW - radius * 2) + radius;
      final speed = 4.0 + _rnd.nextDouble() * 4 + _score * 0.02;
      setState(() {
        _balls.add(Ball(x: x, y: -radius, speed: speed, radius: radius));
      });
    });

    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (_gameOver) return;
      setState(() {
        for (final b in _balls) {
          b.y += b.speed;
        }
        // remove passed balls
        _balls.removeWhere((b) {
          if (b.y - b.radius > _screenH) {
            _score++;
            return true;
          }
          return false;
        });
        // collision
        final playerCenterX = _playerX + _playerSize / 2;
        final playerCenterY = _playerY + _playerSize / 2;
        for (final b in _balls) {
          final dx = (b.x) - playerCenterX;
          final dy = (b.y) - playerCenterY;
          final dist = sqrt(dx * dx + dy * dy);
          if (dist < b.radius + _playerSize / 2) {
            _gameOver = true;
            break;
          }
        }
      });
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_gameOver) return;
    setState(() {
      _playerX += details.delta.dx;
      _playerX = _playerX.clamp(0, _screenW - _playerSize);
    });
  }

  void _restart() {
    _startGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('공 피하기 - Dodge Ball'),
        centerTitle: true,
      ),
      body: GestureDetector(
        onPanUpdate: _onPanUpdate,
        child: Stack(
          children: [
            Container(color: Colors.black87),
            // score
            Positioned(
              top: 40,
              left: 20,
              child: Text(
                'Score: $_score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // player
            Positioned(
              left: _playerX,
              top: _playerY,
              child: Container(
                width: _playerSize,
                height: _playerSize,
                decoration: BoxDecoration(
                  color: Colors.greenAccent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 8,
                      offset: const Offset(2, 2),
                    )
                  ],
                ),
                child: const Icon(Icons.person, color: Colors.black),
              ),
            ),
            // balls
            ..._balls.map((b) => Positioned(
                  left: b.x - b.radius,
                  top: b.y - b.radius,
                  child: Container(
                    width: b.radius * 2,
                    height: b.radius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.redAccent,
                    ),
                  ),
                )),
            // game over overlay
            if (_gameOver)
              Container(
                color: Colors.black54,
                child: Center(
                  child: AlertDialog(
                    title: const Text('Game Over'),
                    content: Text('Final Score: $_score\n화면 드래그로 플레이어 이동'),
                    actions: [
                      TextButton(
                        onPressed: _restart,
                        child: const Text('Restart'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
