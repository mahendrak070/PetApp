import 'package:flutter/material.dart';
import 'dart:ui' as ui;
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
  String petName = "Buddy"; // Default dog name
  int happinessLevel = 50;
  int hungerLevel = 50;
  ui.Image? pawImage;

  @override
  void initState() {
    super.initState();
    _loadPawImage();
  }

  // Load the paw image from assets
  void _loadPawImage() async {
    final data = await rootBundle.load('assets/dog_paw.png');
    final bytes = data.buffer.asUint8List();
    final image = await decodeImageFromList(bytes);
    setState(() {
      pawImage = image;
    });
  }

  // Increase happiness and update hunger when playing with the dog
  void _playWithPet() {
    setState(() {
      happinessLevel = (happinessLevel + 10).clamp(0, 100);
      _updateHunger();
    });
  }

  // Decrease hunger and update happiness when feeding the dog
  void _feedPet() {
    setState(() {
      hungerLevel = (hungerLevel - 10).clamp(0, 100);
      _updateHappiness();
    });
  }

  // Update happiness based on hunger level
  void _updateHappiness() {
    if (hungerLevel < 30) {
      happinessLevel = (happinessLevel - 20).clamp(0, 100);
    } else {
      happinessLevel = (happinessLevel + 10).clamp(0, 100);
    }
  }

  // Increase hunger level slightly when playing with the dog
  void _updateHunger() {
    hungerLevel = (hungerLevel + 5).clamp(0, 100);
    if (hungerLevel > 100) {
      hungerLevel = 100;
      happinessLevel = (happinessLevel - 20).clamp(0, 100);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Digital Pet'),
      ),
      body: Stack(
        children: [
          // Bottom layer: Gradient background that matches the UI theme
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.brown.shade50, Colors.brown.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Middle layer: Evenly spaced paw icons
          if (pawImage != null)
            CustomPaint(
              size: MediaQuery.of(context).size,
              painter: EvenlySpacedPawPainter(
                pawImage: pawImage!,
                tileSize: 20, // Adjust the icon size as needed
              ),
            ),
          // Top layer: Foreground content
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Dog image container with themed border and padding
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.brown[50],
                      border: Border.all(color: Colors.brown, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.all(8.0),
                    child: Image.asset(
                      'assets/dog.png', // Your dog image asset
                      width: 150,
                      height: 150,
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'Name: $petName',
                    style: TextStyle(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown[800],
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'Happiness Level: $happinessLevel',
                    style: TextStyle(
                      fontSize: 20.0,
                      color: Colors.brown[700],
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'Hunger Level: $hungerLevel',
                    style: TextStyle(
                      fontSize: 20.0,
                      color: Colors.brown[700],
                    ),
                  ),
                  SizedBox(height: 32.0),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown, // New style property
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
                      backgroundColor: Colors.brown, // New style property
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

// Custom painter that evenly distributes 10 small paw icons (2 rows x 5 columns) over the screen
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
        // Compute x and y positions to evenly space the icons across the screen
        double x = (j + 1) * size.width / (cols + 1) - tileSize / 2;
        double y = (i + 1) * size.height / (rows + 1) - tileSize / 2;

        Rect srcRect = Rect.fromLTWH(0, 0, pawImage.width.toDouble(), pawImage.height.toDouble());
        Rect dstRect = Rect.fromLTWH(x, y, tileSize, tileSize);
        canvas.drawImageRect(pawImage, srcRect, dstRect, Paint());
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
