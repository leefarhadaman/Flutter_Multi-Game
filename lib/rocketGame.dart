import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() => runApp(MyGame());

class MyGame extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // Player position
  double playerX = 0.5;

  // Game objects
  List<Map<String, dynamic>> asteroids = [];
  List<Map<String, dynamic>> bullets = [];
  Random random = Random();

  // Game variables
  int score = 0;
  bool isPlaying = false;
  double asteroidSpeed = 1.0;

  // Game loop
  void startGame() {
    isPlaying = true;
    score = 0;
    asteroidSpeed = 1.0;
    asteroids.clear();
    bullets.clear();

    // Game loop for asteroids and bullets
    Timer.periodic(Duration(milliseconds: 16), (timer) {
      if (!isPlaying) {
        timer.cancel();
        return;
      }

      setState(() {
        // Increase difficulty over time
        asteroidSpeed += 0.0005;

        // Track asteroids to remove
        List<Map<String, dynamic>> asteroidsToRemove = [];
        List<Map<String, dynamic>> bulletsToRemove = [];

        // Move asteroids down
        for (var asteroid in asteroids) {
          asteroid['y'] += 0.01 * asteroidSpeed;

          // Check if asteroid hits the player
          if (asteroid['y'] > 0.9 && asteroid['x'] > playerX - 0.1 && asteroid['x'] < playerX + 0.1) {
            isPlaying = false; // Game over
          }

          // Mark asteroid for removal if it goes below the screen
          if (asteroid['y'] > 1.0) {
            asteroidsToRemove.add(asteroid);
          }
        }

        // Move bullets up
        for (var bullet in bullets) {
          bullet['y'] -= 0.02;

          // Check if bullet hits an asteroid
          for (var asteroid in asteroids) {
            if ((bullet['x'] - asteroid['x']).abs() < 0.05 && (bullet['y'] - asteroid['y']).abs() < 0.05) {
              asteroidsToRemove.add(asteroid);
              bulletsToRemove.add(bullet);
              score++;
              break;
            }
          }

          // Mark bullet for removal if it goes above the screen
          if (bullet['y'] < 0) {
            bulletsToRemove.add(bullet);
          }
        }

        // Remove marked asteroids and bullets
        asteroids.removeWhere((asteroid) => asteroidsToRemove.contains(asteroid));
        bullets.removeWhere((bullet) => bulletsToRemove.contains(bullet));

        // Add new asteroids randomly
        if (random.nextDouble() < 0.02) {
          asteroids.add({
            'x': random.nextDouble(),
            'y': 0.0,
          });
        }
      });
    });
  }

  void movePlayer(double direction) {
    setState(() {
      playerX += direction * 0.05; // Smoother movement
      if (playerX < 0) playerX = 0;
      if (playerX > 1) playerX = 1;
    });
  }

  void shootBullet() {
    setState(() {
      bullets.add({
        'x': playerX,
        'y': 0.9,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          setState(() {
            playerX += details.delta.dx / MediaQuery.of(context).size.width;
            if (playerX < 0) playerX = 0;
            if (playerX > 1) playerX = 1;
          });
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Colors.blue.shade900], // Space-themed gradient
            ),
          ),
          child: Column(
            children: [
              // Game Area
              Expanded(
                flex: 3,
                child: Stack(
                  children: [
                    // Asteroids
                    for (var asteroid in asteroids)
                      AnimatedPositioned(
                        duration: Duration(milliseconds: 16),
                        left: asteroid['x'] * MediaQuery.of(context).size.width,
                        top: asteroid['y'] * MediaQuery.of(context).size.height,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),

                    // Bullets
                    for (var bullet in bullets)
                      AnimatedPositioned(
                        duration: Duration(milliseconds: 16),
                        left: bullet['x'] * MediaQuery.of(context).size.width,
                        top: bullet['y'] * MediaQuery.of(context).size.height,
                        child: Container(
                          width: 10,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.yellow,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),

                    // Player spaceship
                    Positioned(
                      left: playerX * MediaQuery.of(context).size.width - 25,
                      bottom: 0,
                      child: CustomPaint(
                        size: Size(50, 50),
                        painter: SpaceshipPainter(),
                      ),
                    ),
                  ],
                ),
              ),

              // Score and Controls
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Score: $score',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 20),
                    if (!isPlaying)
                      ElevatedButton(
                        onPressed: startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        ),
                        child: Text(
                          isPlaying ? 'Pause' : 'Start Game',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    if (isPlaying)
                      IconButton(
                        icon: Icon(Icons.arrow_upward, size: 40, color: Colors.white),
                        onPressed: shootBullet,
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

// Custom painter for the spaceship
class SpaceshipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(size.width / 2, 0); // Top point
    path.lineTo(0, size.height); // Bottom-left point
    path.lineTo(size.width, size.height); // Bottom-right point
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}