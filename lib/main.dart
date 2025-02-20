import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/services.dart';

void main() {
  runApp(MaterialApp(
    home: DigitalPetApp(),
    theme: ThemeData(
      primarySwatch: Colors.brown,
    ),
  ));
}

class DigitalPetApp extends StatefulWidget {
  @override
  _DigitalPetAppState createState() => _DigitalPetAppState();
}

class _DigitalPetAppState extends State<DigitalPetApp> {
  // Pet state variables
  String petName = "Buddy";
  int happinessLevel = 50;
  int hungerLevel = 50;
  int _energyLevel = 50;

  ui.Image? pawImage;
  Timer? hungerTimer;
  Timer? winTimer;
  int winCounter = 0;
  bool gameOver = false;
  bool gameWon = false;

  // Activity selection variables
  String? _selectedActivity;
  final List<String> _activities = ["Walk", "Play", "Rest", "Fetch"];

  TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPawImage();
    // Increase hunger every 30 seconds
    hungerTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (!gameOver && !gameWon) {
        setState(() {
          hungerLevel = (hungerLevel + 5).clamp(0, 100);
          _checkGameOver();
        });
      }
    });
    // Check win condition every second (win if happiness stays >=80 for 3 minutes)
    winTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!gameOver && !gameWon) {
        if (happinessLevel >= 80) {
          winCounter++;
          if (winCounter >= 180) {
            gameWon = true;
            _showWinDialog();
            _cancelTimers();
          }
        } else {
          winCounter = 0;
        }
      }
    });
  }

  @override
  void dispose() {
    hungerTimer?.cancel();
    winTimer?.cancel();
    _nameController.dispose();
    super.dispose();
  }

  // Load paw image from assets
  void _loadPawImage() async {
    final data = await rootBundle.load('assets/dog_paw.png');
    final bytes = data.buffer.asUint8List();
    final image = await decodeImageFromList(bytes);
    setState(() {
      pawImage = image;
    });
  }

  // Pet actions
  void _playWithPet() {
    if (gameOver || gameWon) return;
    setState(() {
      happinessLevel = (happinessLevel + 10).clamp(0, 100);
      _updateHunger();
      _checkGameOver();
    });
  }

  void _feedPet() {
    if (gameOver || gameWon) return;
    setState(() {
      hungerLevel = (hungerLevel - 10).clamp(0, 100);
      _updateHappiness();
      _checkGameOver();
    });
  }

  void _updateHappiness() {
    if (hungerLevel < 30)
      happinessLevel = (happinessLevel - 20).clamp(0, 100);
    else
      happinessLevel = (happinessLevel + 10).clamp(0, 100);
  }

  void _updateHunger() {
    hungerLevel = (hungerLevel + 5).clamp(0, 100);
  }

  void _checkGameOver() {
    if (hungerLevel >= 100 && happinessLevel <= 10 && !gameOver) {
      gameOver = true;
      _cancelTimers();
      _showGameOverDialog();
    }
  }

  void _cancelTimers() {
    hungerTimer?.cancel();
    winTimer?.cancel();
  }

  // Dynamic styling
  Color getPetBorderColor() {
    if (happinessLevel > 70) return Colors.green;
    else if (happinessLevel >= 30) return Colors.yellow;
    else return Colors.red;
  }

  String getMoodIndicator() {
    if (happinessLevel > 70) return "Happy 😊";
    else if (happinessLevel >= 30) return "Neutral 😐";
    else return "Unhappy 😢";
  }

  // Set pet name from text field
  void _setPetName() {
    if (_nameController.text.trim().isNotEmpty) {
      setState(() {
        petName = _nameController.text.trim();
      });
      _nameController.clear();
    }
  }

  // Activity selection: update pet state based on chosen activity
  void _performActivity() {
    if (_selectedActivity == null || gameOver || gameWon) return;
    setState(() {
      switch (_selectedActivity) {
        case "Walk":
          happinessLevel = (happinessLevel + 5).clamp(0, 100);
          _energyLevel = (_energyLevel - 10).clamp(0, 100);
          break;
        case "Play":
          happinessLevel = (happinessLevel + 10).clamp(0, 100);
          _energyLevel = (_energyLevel - 15).clamp(0, 100);
          break;
        case "Rest":
          _energyLevel = (_energyLevel + 20).clamp(0, 100);
          happinessLevel = (happinessLevel + 2).clamp(0, 100);
          break;
        case "Fetch":
          happinessLevel = (happinessLevel + 7).clamp(0, 100);
          _energyLevel = (_energyLevel - 12).clamp(0, 100);
          break;
        default:
          break;
      }
      _selectedActivity = null;
      _checkGameOver();
    });
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("You Win!"),
        content: Text("Your pet has remained happy for 3 minutes!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Optionally restart the game.
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text("Game Over"),
        content: Text("Your pet is too hungry and unhappy. Game Over!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Optionally restart the game.
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  // Helper text style for clean typography
  TextStyle _textStyle(double fontSize, {Color color = Colors.brown}) {
    return TextStyle(
      fontSize: fontSize,
      color: color,
      fontWeight: FontWeight.w500,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Digital Dog'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background layer: gradient with subtle paw icons overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.brown.shade50, Colors.brown.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          if (pawImage != null)
            CustomPaint(
              size: MediaQuery.of(context).size,
              painter: EvenlySpacedPawPainter(
                pawImage: pawImage!,
                tileSize: 20,
              ),
            ),
          // Foreground: scrollable, centered card containing the UI
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Card(
                color: Colors.white.withOpacity(0.9),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pet Name Customization
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: "Enter pet name",
                                labelStyle: _textStyle(16, color: Colors.brown[800]!),
                                filled: true,
                                fillColor: Colors.brown.shade50,
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.brown),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.brown),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.brown, width: 2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _setPetName,
                            child: Text("Set Name"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      // Pet Image with Dynamic Border
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.brown.shade50,
                          border: Border.all(color: getPetBorderColor(), width: 3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.all(8.0),
                        child: Image.asset(
                          'assets/dog.png',
                          width: 150,
                          height: 150,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Name: $petName',
                        style: _textStyle(24, color: Colors.brown[800]!),
                      ),
                      SizedBox(height: 8),
                      // Mood Indicator
                      Text(
                        'Mood: ${getMoodIndicator()}',
                        style: _textStyle(20, color: Colors.brown[700]!),
                      ),
                      SizedBox(height: 12),
                      // Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(
                            'Happiness: $happinessLevel',
                            style: _textStyle(18, color: Colors.brown[700]!),
                          ),
                          Text(
                            'Hunger: $hungerLevel',
                            style: _textStyle(18, color: Colors.brown[700]!),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      // Energy Bar Section
                      Column(
                        children: [
                          Text(
                            'Energy: $_energyLevel',
                            style: _textStyle(18, color: Colors.brown[700]!),
                          ),
                          SizedBox(height: 4),
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: 32),
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(2, 2),
                                )
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                minHeight: 20,
                                value: _energyLevel / 100,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      // Activity Selection
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.brown.shade100.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            DropdownButton<String>(
                              hint: Text("Select Activity", style: _textStyle(16)),
                              value: _selectedActivity,
                              items: _activities.map((activity) {
                                return DropdownMenuItem<String>(
                                  value: activity,
                                  child: Text(activity, style: _textStyle(16, color: Colors.brown[800]!)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedActivity = value;
                                });
                              },
                              dropdownColor: Colors.brown.shade50,
                            ),
                            SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: _performActivity,
                              child: Text("Do Activity"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.brown,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 24),
                      // Action Buttons
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          textStyle: TextStyle(fontSize: 18),
                        ),
                        onPressed: _playWithPet,
                        child: Text('Play with Your Dog'),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          textStyle: TextStyle(fontSize: 18),
                        ),
                        onPressed: _feedPet,
                        child: Text('Feed Your Dog'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter to evenly distribute 10 small paw icons (2 rows x 5 columns) across the screen
class EvenlySpacedPawPainter extends CustomPainter {
  final ui.Image pawImage;
  final double tileSize;

  EvenlySpacedPawPainter({required this.pawImage, this.tileSize = 20});

  @override
  void paint(Canvas canvas, Size size) {
    int cols = 5;
    int rows = 2;
    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < cols; j++) {
        double x = (j + 1) * size.width / (cols + 1) - tileSize / 2;
        double y = (i + 1) * size.height / (rows + 1) - tileSize / 2;
        Rect srcRect = Rect.fromLTWH(
          0,
          0,
          pawImage.width.toDouble(),
          pawImage.height.toDouble(),
        );
        Rect dstRect = Rect.fromLTWH(x, y, tileSize, tileSize);
        canvas.drawImageRect(pawImage, srcRect, dstRect, Paint());
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}