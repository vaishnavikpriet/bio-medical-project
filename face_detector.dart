import 'package:flutter/material.dart';

class FaceDetectorOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.green,
          width: 3,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      width: 250,
      height: 250,
      child: Stack(
        children: [
          Positioned(
            top: 10,
            left: 10,
            child: Icon(Icons.face, color: Colors.green),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: Icon(Icons.face, color: Colors.green),
          ),
          Positioned(
            bottom: 10,
            left: 10,
            child: Icon(Icons.face, color: Colors.green),
          ),
          Positioned(
            bottom: 10,
            right: 10,
            child: Icon(Icons.face, color: Colors.green),
          ),
        ],
      ),
    );
  }
}