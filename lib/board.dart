import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:tetrisapp/piece.dart';
import 'package:tetrisapp/pixel.dart';
import 'package:tetrisapp/values.dart';
import 'auth_page.dart'; // Import the AuthPage class

/// Create the game board
List<List<Tetromino?>> gameBoard = List.generate(
  colLength,
  (i) => List.generate(
    rowLength,
    (j) => null,
  ),
);

class GameBoard extends StatefulWidget {
  const GameBoard({super.key});

  @override
  State<GameBoard> createState() => _GameBoardState();
}

class _GameBoardState extends State<GameBoard> {
  /// Current Tetris piece
  Piece currentPiece = Piece(type: Tetromino.L);

  /// Current score
  int currentScore = 0;

  /// Top score
  int topScore = 0;

  /// Game over status
  bool gameOver = false;

  /// Timer reference
  Timer? gameTimer;

  @override
  void initState() {
    super.initState();
    fetchTopScore(); // Fetch the top score when the game starts
    startGame();
  }

  @override
  void dispose() {
    /// Cancel the timer to prevent calling setState after dispose
    gameTimer?.cancel();
    super.dispose();
  }

  /// Fetch the user's top score from Firestore
  Future<void> fetchTopScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        setState(() {
          topScore = doc.data()?['topScore'] ?? 0;
        });
      }
    }
  }

  /// Save the user's top score to Firestore
  Future<void> saveTopScore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userDoc.set(
        {'topScore': currentScore},
        SetOptions(merge: true),
      );
    }
  }

  void startGame() {
    currentPiece.initializePiece();

    /// Frame refresh rate
    Duration frameRate = const Duration(milliseconds: 800);
    gameLoop(frameRate);
  }

  void gameLoop(Duration frameRate) {
    gameTimer = Timer.periodic(frameRate, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        clearLines();
        checkLanding();

        if (gameOver) {
          timer.cancel();
          if (currentScore > topScore) {
            saveTopScore(); // Save the new top score
          }
          showGameOverDialog();
        }

        currentPiece.movePiece(Direction.down);
      });
    });
  }

  void showGameOverDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Game Over'),
        content: Text(
          "Your Score: $currentScore\nTop Score: $topScore",
        ),
        actions: [
          TextButton(
            onPressed: () {
              resetGame();
              Navigator.pop(context);
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void resetGame() {
    gameBoard = List.generate(
      colLength,
      (i) => List.generate(
        rowLength,
        (j) => null,
      ),
    );

    gameOver = false;
    currentScore = 0;
    createNewPiece();
    startGame();
  }

  bool checkCollision(Direction direction) {
    for (int i = 0; i < currentPiece.position.length; i++) {
      int row = (currentPiece.position[i] / rowLength).floor();
      int col = currentPiece.position[i] % rowLength;

      if (direction == Direction.left) col -= 1;
      if (direction == Direction.right) col += 1;
      if (direction == Direction.down) row += 1;

      if (row >= colLength || col < 0 || col >= rowLength) return true;

      if (row >= 0 && col >= 0 && gameBoard[row][col] != null) return true;
    }
    return false;
  }

  void checkLanding() {
    if (checkCollision(Direction.down)) {
      for (int i = 0; i < currentPiece.position.length; i++) {
        int row = (currentPiece.position[i] / rowLength).floor();
        int col = currentPiece.position[i] % rowLength;

        if (row >= 0 && col >= 0) gameBoard[row][col] = currentPiece.type;
      }
      createNewPiece();
    }
  }

  void createNewPiece() {
    Random rand = Random();
    Tetromino randomType =
        Tetromino.values[rand.nextInt(Tetromino.values.length)];
    currentPiece = Piece(type: randomType);
    currentPiece.initializePiece();

    if (isGameOver()) gameOver = true;
  }

  void moveLeft() {
    if (!checkCollision(Direction.left)) {
      setState(() {
        currentPiece.movePiece(Direction.left);
      });
    }
  }

  void moveRight() {
    if (!checkCollision(Direction.right)) {
      setState(() {
        currentPiece.movePiece(Direction.right);
      });
    }
  }

  void rotatePiece() {
    setState(() {
      currentPiece.rotatePiece();
    });
  }

  void clearLines() {
    for (int row = colLength - 1; row >= 0; row--) {
      bool rowIsFull = true;
      for (int col = 0; col < rowLength; col++) {
        if (gameBoard[row][col] == null) {
          rowIsFull = false;
          break;
        }
      }
      if (rowIsFull) {
        for (int r = row; r > 0; r--) {
          gameBoard[r] = List.from(gameBoard[r - 1]);
        }
        gameBoard[0] = List.generate(rowLength, (index) => null);
        currentScore++;
      }
    }
  }

  bool isGameOver() {
    for (int col = 0; col < rowLength; col++) {
      if (gameBoard[0][col] != null) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tetris'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AuthPage()),
              );
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              itemCount: rowLength * colLength,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: rowLength,
              ),
              itemBuilder: (context, index) {
                int row = (index / rowLength).floor();
                int col = index % rowLength;

                if (currentPiece.position.contains(index)) {
                  return Pixel(
                    color: currentPiece.color,
                  );
                } else if (gameBoard[row][col] != null) {
                  final Tetromino? tetrominoType = gameBoard[row][col];
                  return Pixel(
                    color: tetrominoColors[tetrominoType] ?? Colors.black,
                  );
                } else {
                  return Pixel(
                    color: Colors.grey[900]!,
                  );
                }
              },
            ),
          ),
          Text(
            'Score: $currentScore\nTop Score: $topScore',
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 50.0, top: 50.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: moveLeft,
                  color: Colors.white,
                  icon: const Icon(Icons.arrow_back_ios),
                ),
                IconButton(
                  onPressed: rotatePiece,
                  color: Colors.white,
                  icon: const Icon(Icons.rotate_right),
                ),
                IconButton(
                  onPressed: moveRight,
                  color: Colors.white,
                  icon: const Icon(Icons.arrow_forward_ios),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
