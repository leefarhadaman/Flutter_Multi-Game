import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
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
  double basketX = 0.5;

  // Falling objects
  List<Map<String, dynamic>> fruits = [];
  Random random = Random();

  // Game variables
  int score = 0;
  bool isPlaying = false;
  double speed = 1.0;
  int timeLeft = 15; // 15-second timer

  // Audio player for sound effects
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Game loop
  void startGame() {
    isPlaying = true;
    score = 0;
    speed = 1.0;
    timeLeft = 15;
    fruits.clear();

    // Timer for countdown
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (!isPlaying) {
        timer.cancel();
        return;
      }

      setState(() {
        timeLeft--;
        if (timeLeft <= 0) {
          isPlaying = false;
          timer.cancel();
        }
      });
    });

    // Game loop for falling fruits
    Timer.periodic(Duration(milliseconds: 16), (timer) {
      if (!isPlaying) {
        timer.cancel();
        return;
      }

      setState(() {
        // Move fruits down
        for (var fruit in fruits) {
          fruit['y'] += 0.01 * speed;

          // Check if fruit is caught
          if (fruit['y'] > 0.9 && fruit['x'] > basketX - 0.15 && fruit['x'] < basketX + 0.15) {
            score++;
            speed += 0.1;
            fruit['y'] = -0.1;
            fruit['x'] = random.nextDouble();

            // Play sound effect
            _audioPlayer.play(AssetSource('sounds/catch.mp3'));
          }

          // Remove fruit if it goes below the screen
          if (fruit['y'] > 1.0) {
            fruits.remove(fruit);
            break;
          }
        }

        // Add new fruits randomly
        if (random.nextDouble() < 0.02) {
          fruits.add({
            'x': random.nextDouble(),
            'y': 0.0,
            'type': random.nextInt(4), // 0: apple, 1: banana, 2: orange, 3: strawberry
          });
        }
      });
    });
  }

  void moveBasket(double direction) {
    setState(() {
      basketX += direction * 0.05; // Smoother movement
      if (basketX < 0) basketX = 0;
      if (basketX > 1) basketX = 1;
    });
  }

  // Custom basket design
  Widget _buildBasket() {
    return Container(
      width: 150, // Basket width
      height: 75, // Basket height
      child: ClipPath(
        clipper: BasketClipper(),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.brown.shade600, Colors.brown.shade800],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue.shade300, Colors.green.shade200], // Gradient background
          ),
        ),
        child: Column(
          children: [
            // Game Area
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  // Falling fruits
                  for (var fruit in fruits)
                    AnimatedPositioned(
                      duration: Duration(milliseconds: 16),
                      left: fruit['x'] * MediaQuery.of(context).size.width,
                      top: fruit['y'] * MediaQuery.of(context).size.height,
                      child: Image.asset(
                        'assets/fruit${fruit['type']}.png',
                        width: 50,
                        height: 50,
                      ),
                    ),

                  // Basket
                  Positioned(
                    left: basketX * MediaQuery.of(context).size.width - 75, // Center the basket
                    bottom: 0,
                    child: _buildBasket(),
                  ),
                ],
              ),
            ),

            // Score, Timer, and Controls
            Expanded(
              flex: 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Score: $score',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Time Left: $timeLeft',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
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
                        timeLeft <= 0 ? 'Restart Game' : 'Start Game',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  if (isPlaying)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_left, size: 40, color: Colors.white),
                          onPressed: () => moveBasket(-1),
                        ),
                        SizedBox(width: 20),
                        IconButton(
                          icon: Icon(Icons.arrow_right, size: 40, color: Colors.white),
                          onPressed: () => moveBasket(1),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom clipper for the basket shape
class BasketClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    // Top open edge (wider)
    path.moveTo(size.width * 0.1, 0); // Start from the left top
    path.lineTo(size.width * 0.9, 0); // Draw to the right top

    // Right side (tapered)
    path.lineTo(size.width * 0.95, size.height * 0.3); // Curve inward slightly
    path.lineTo(size.width * 0.8, size.height); // Draw to the bottom right

    // Bottom edge (narrower)
    path.lineTo(size.width * 0.2, size.height); // Draw to the bottom left

    // Left side (tapered)
    path.lineTo(size.width * 0.05, size.height * 0.3); // Curve inward slightly
    path.close(); // Close the path to complete the shape

    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}