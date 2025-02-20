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
  // Existing pet state variables
  String petName = "Buddy"; // Default pet name
  int happinessLevel = 50;
  int hungerLevel = 50;
  
  // New energy level variable (0 to 100)
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
    // Check win condition every second (win if happiness stays >= 80 for 3 minutes)
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

  // Load the paw icon image from assets
  void _loadPawImage() async {
    final data = await rootBundle.load('assets/dog_paw.png');
    final bytes = data.buffer.asUint8List();
    final image = await decodeImageFromList(bytes);
    setState(() {
      pawImage = image;
    });
  }

  // Increase happiness and update hunger when playing with the pet
  void _playWithPet() {
    if (gameOver || gameWon) return;
    setState(() {
      happinessLevel = (happinessLevel + 10).clamp(0, 100);
      _updateHunger();
      _checkGameOver();
    });
  }

  // Decrease hunger and update happiness when feeding the pet
  void _feedPet() {
    if (gameOver || gameWon) return;
    setState(() {
      hungerLevel = (hungerLevel - 10).clamp(0, 100);
      _updateHappiness();
      _checkGameOver();
    });
  }

  // Update happiness based on current hunger level
  void _updateHappiness() {
    if (hungerLevel < 30) {
      happinessLevel = (happinessLevel - 20).clamp(0, 100);
    } else {
      happinessLevel = (happinessLevel + 10).clamp(0, 100);
    }
  }

  // Increase hunger slightly when playing with the pet
  void _updateHunger() {
    hungerLevel = (hungerLevel + 5).clamp(0, 100);
  }

  // Check loss condition: if hunger is 100 and happiness is 10 or less
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

  // Dynamic border color for pet image based on happiness level
  Color getPetBorderColor() {
    if (happinessLevel > 70) return Colors.green;
    else if (happinessLevel >= 30) return Colors.yellow;
    else return Colors.red;
  }

  // Mood indicator text with emoji
  String getMoodIndicator() {
    if (happinessLevel > 70) return "Happy 😊";
    else if (happinessLevel >= 30) return "Neutral 😐";
    else return "Unhappy 😢";
  }

  // Set pet name from text input field
  void _setPetName() {
    if (_nameController.text.trim().isNotEmpty) {
      setState(() {
        petName = _nameController.text.trim();
      });
      _nameController.clear();
    }
  }

  // Activity selection: perform selected activity and update pet state
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
      // Reset selection after performing the activity
      _selectedActivity = null;
      _checkGameOver();
    });
  }

  // Show win dialog when win condition is met
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
              // Optionally, restart the game here.
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  // Show game over dialog when loss condition is met
  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Force user to acknowledge game over.
      builder: (_) => AlertDialog(
        title: Text("Game Over"),
        content: Text("Your pet is too hungry and unhappy. Game Over!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Optionally, restart the game here.
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  // Helper text style with subtle white shadow for readability
  TextStyle _textStyle(double fontSize, {Color color = Colors.brown}) {
    return TextStyle(
      fontSize: fontSize,
      color: color,
      shadows: [
        Shadow(
          offset: Offset(1, 1),
          blurRadius: 2,
          color: Colors.white,
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Digital Dog'),
      ),
      body: Stack(
        children: [
          // Layer 1: Gradient background that fits the dog-themed UI
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.brown.shade50, Colors.brown.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Layer 2: Evenly spaced paw icons in the background
          if (pawImage != null)
            CustomPaint(
              size: MediaQuery.of(context).size,
              painter: EvenlySpacedPawPainter(
                pawImage: pawImage!,
                tileSize: 20,
              ),
            ),
          // Layer 3: Foreground content in a scrollable area with padding to avoid overlap
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Pet Name Customization with matching UI style
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: "Enter pet name",
                              labelStyle: _textStyle(16, color: Colors.brown[800]!),
                              filled: true,
                              fillColor: Colors.brown[50],
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
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Dog image with dynamic border color based on happiness
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.brown[50],
                      border: Border.all(color: getPetBorderColor(), width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.all(8.0),
                    child: Image.asset(
                      'assets/dog.png', // Dog image asset
                      width: 150,
                      height: 150,
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'Name: $petName',
                    style: _textStyle(24, color: Colors.brown[800]!),
                  ),
                  SizedBox(height: 8.0),
                  // Mood indicator text with emoji
                  Text(
                    'Mood: ${getMoodIndicator()}',
                    style: _textStyle(20, color: Colors.brown[700]!),
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'Happiness Level: $happinessLevel',
                    style: _textStyle(20, color: Colors.brown[700]!),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    'Hunger Level: $hungerLevel',
                    style: _textStyle(20, color: Colors.brown[700]!),
                  ),
                  SizedBox(height: 16.0),
                  // Energy bar widget with enhanced styling
                  Text(
                    'Energy Level: $_energyLevel',
                    style: _textStyle(20, color: Colors.brown[700]!),
                  ),
                  SizedBox(height: 4.0),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 32.0),
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
                  SizedBox(height: 16.0),
                  // Activity selection row with decorative container
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.brown,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            textStyle: TextStyle(fontSize: 16),
                          ),
                          onPressed: _performActivity,
                          child: Text("Do Activity"),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.0),
                  // Action Buttons for playing and feeding the pet
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
                  SizedBox(height: 16.0),
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
        ],
      ),
    );
  }
}

// Custom painter that evenly distributes 10 small paw icons (2 rows x 5 columns) across the screen
class EvenlySpacedPawPainter extends CustomPainter {
  final ui.Image pawImage;
  final double tileSize;

  EvenlySpacedPawPainter({required this.pawImage, this.tileSize = 20});

  @override
  void paint(Canvas canvas, Size size) {
    // Arrange 10 icons in 2 rows and 5 columns
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
