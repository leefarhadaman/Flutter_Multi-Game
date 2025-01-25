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
  // Bird position and state
  double birdY = 0.5; // Initial Y position (middle of the screen)
  double birdVelocity = 0.0; // Vertical velocity for flapping
  bool isFlapping = false;

  // Pipes
  List<Map<String, double>> pipes = [];
  Random random = Random();

  // Game variables
  int score = 0;
  bool isPlaying = false;
  bool isGameOver = false;
  double gameSpeed = 1.0;

  // Gradient animation
  Color gradientStart = Colors.blue.shade300;
  Color gradientEnd = Colors.blue.shade900;
  bool gradientToggle = false;

  // Game loop
  void startGame() {
    isPlaying = true;
    isGameOver = false;
    score = 0;
    gameSpeed = 1.0;
    birdY = 0.5;
    birdVelocity = 0.0;
    pipes.clear();

    // Game loop
    Timer.periodic(Duration(milliseconds: 16), (timer) {
      if (!isPlaying) {
        timer.cancel();
        return;
      }

      setState(() {
        // Increase difficulty over time
        gameSpeed += 0.0005;

        // Bird physics
        if (isFlapping) {
          birdVelocity = -0.1; // Flap strength
          isFlapping = false;
        }
        birdY += birdVelocity;
        birdVelocity += 0.005; // Gravity

        // Check for collision with ground or ceiling
        if (birdY < 0 || birdY > 1) {
          isPlaying = false;
          isGameOver = true;
        }

        // Move pipes
        for (int i = 0; i < pipes.length; i++) {
          // Update pipe position explicitly
          pipes[i]['x'] = pipes[i]['x']! - 0.01 * gameSpeed;

          // Check for collision with pipes
          if (pipes[i]['x']! < 0.2 && pipes[i]['x']! > -0.2) {
            double pipeGap = pipes[i]['gap']!;
            if (birdY < pipeGap || birdY > pipeGap + 0.2) {
              isPlaying = false;
              isGameOver = true;
            }
          }

          // Remove pipes that go off-screen
          if (pipes[i]['x']! < -0.2) {
            pipes.removeAt(i);
            break;
          }
        }

        // Add new pipes randomly
        if (random.nextDouble() < 0.02) {
          double gap = random.nextDouble() * 0.6 + 0.2; // Random gap position
          pipes.add({'x': 1.2, 'gap': gap});
        }

        // Increase score if bird passes through pipes
        for (var pipe in pipes) {
          if (pipe['x']! < 0.1 && pipe['x']! > -0.1) {
            score++;
          }
        }

        // Toggle gradient colors
        gradientToggle = !gradientToggle;
      });
    });
  }

  void flap() {
    if (!isPlaying && !isGameOver) {
      startGame(); // Start the game on first tap
    } else if (isPlaying) {
      isFlapping = true; // Flap the bird
    }
  }

  void restartGame() {
    setState(() {
      isGameOver = false;
    });
    startGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: flap,
        child: TweenAnimationBuilder<Color?>(
          duration: Duration(seconds: 2),
          tween: ColorTween(
            begin: gradientToggle ? Colors.blue.shade300 : Colors.purple.shade300,
            end: gradientToggle ? Colors.blue.shade900 : Colors.purple.shade900,
          ),
          builder: (context, color, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color!, color.withOpacity(0.8)],
                ),
              ),
              child: Stack(
                children: [
                  // Game Area
                  Column(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Stack(
                          children: [
                            // Bird
                            Positioned(
                              left: 100,
                              top: MediaQuery.of(context).size.height * birdY,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.yellow,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.orange, width: 2),
                                ),
                              ),
                            ),

                            // Pipes
                            for (var pipe in pipes)
                              Positioned(
                                left: MediaQuery.of(context).size.width * pipe['x']!,
                                top: 0,
                                child: Column(
                                  children: [
                                    // Upper pipe
                                    Container(
                                      width: 50,
                                      height: MediaQuery.of(context).size.height * pipe['gap']!,
                                      color: Colors.green,
                                    ),
                                    // Gap
                                    SizedBox(height: 100),
                                    // Lower pipe
                                    Container(
                                      width: 50,
                                      height: MediaQuery.of(context).size.height * (1 - pipe['gap']! - 0.2),
                                      color: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Score
                      Container(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'Score: $score',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),

                  // Game Over Screen
                  if (isGameOver)
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Game Over!',
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Score: $score',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: restartGame,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            ),
                            child: Text(
                              'Restart Game',
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}