import 'package:camera/camera.dart';
import 'dart:math' as math;
import 'dart:typed_data';

class PPGProcessor {
  static const int _windowSize = 30;
  static const double _minValidAmplitude = 0.1;

static List<double> extractPPG(List<CameraImage> frames, {bool simplified = false}) {
  if (frames.isEmpty) return [];

  List<double> ppgSignal = [];
  Uint8List? previousYPlane;
  List<double> motionHistory = [];

  for (final frame in frames) {
    final yPlane = frame.planes[0].bytes;
    double brightness = _calculateFaceROIBrightness(yPlane);

    if (previousYPlane != null) {
      double motion = _calculateFrameDifference(yPlane, previousYPlane);
      motionHistory.add(motion);
      
      // Improved motion compensation with moving average
      if (motionHistory.length > 5) {
        List<double> lastFive = motionHistory.sublist(motionHistory.length - 5);
        double avgMotion = lastFive.reduce((a, b) => a + b) / lastFive.length;
        brightness = brightness / (1 + (avgMotion * 5).clamp(0.0, 0.8));
      }
    }
    
    previousYPlane = yPlane;
    ppgSignal.add(brightness);
  }

  ppgSignal = _normalizeSignal(ppgSignal);
  ppgSignal = _bandpassFilter(ppgSignal, 30, 0.7, 4.0);

  // Add signal validation
  if (_isSignalFlat(ppgSignal)) {
    throw Exception("Signal too weak - please ensure proper lighting and camera contact");
  }

  return ppgSignal;
}

static bool _isSignalFlat(List<double> signal) {
  if (signal.length < 10) return true;
  final maxVal = signal.reduce(math.max);
  final minVal = signal.reduce(math.min);
  return (maxVal - minVal) < 0.05; // Threshold for flat signal
}

  static int calculatePulseRate(List<double> ppgSignal, int fps) {
    if (ppgSignal.length < _windowSize * 2) return 72;

    try {
      final bestSegment = _findBestSignalSegment(ppgSignal);
      final autocorr = autocorrelate(bestSegment);
      final peakIndices = findPeaks(autocorr);

      if (peakIndices.length < 2) return 72;

      double avgInterval = 0;
      for (int i = 1; i < peakIndices.length; i++) {
        avgInterval += (peakIndices[i] - peakIndices[i - 1]);
      }
      avgInterval /= (peakIndices.length - 1);

      final bpm = (60 * fps / avgInterval).round();
      return bpm.clamp(40, 180);
    } catch (e) {
      return 72;
    }
  }

  static double _calculateFaceROIBrightness(Uint8List yPlane) {
    // Using a fixed size for ROI calculation assuming image format doesn't change drastically.
    // A more robust method would pass width/height from the CameraImage object.
    final width = math.sqrt(yPlane.length).round();
    final height = (yPlane.length / width).round();

    if (width == 0 || height == 0) return 0.0;
    
    final centerX = width ~/ 2;
    final centerY = height ~/ 2;
    final roiWidth = width ~/ 4;
    final roiHeight = height ~/ 4;

    double sum = 0;
    int count = 0;

    for (int y = centerY - roiHeight; y <= centerY + roiHeight; y++) {
      for (int x = centerX - roiWidth; x <= centerX + roiWidth; x++) {
        if (x >= 0 && x < width && y >= 0 && y < height) {
          sum += yPlane[y * width + x];
          count++;
        }
      }
    }
    return count > 0 ? sum / count : 0.0;
  }

  static double _calculateFrameDifference(Uint8List current, Uint8List previous) {
    if (current.length != previous.length) return 0.0;

    double diffSum = 0;
    for (int i = 0; i < current.length; i++) {
      diffSum += (current[i] - previous[i]).abs();
    }
    return diffSum / current.length / 255.0;
  }


  static List<double> _normalizeSignal(List<double> signal) {
    if (signal.isEmpty) return [];
    final maxVal = signal.reduce(math.max);
    final minVal = signal.reduce(math.min);
    final range = maxVal - minVal;

    if (range < _minValidAmplitude) return List.filled(signal.length, 0.5);

    return signal.map((v) => (v - minVal) / range).toList();
  }

  static List<double> _bandpassFilter(List<double> signal, double fps, double lowCutoff, double highCutoff) {
    // 2nd order Butterworth filter coefficients (pre-calculated)
    const b0 = 0.0675, b2 = -0.135, b4 = 0.0675;
    const a1 = -3.142, a2 = 3.968, a3 = -2.238, a4 = 0.492;

    List<double> filtered = List.filled(signal.length, 0.0);
    for (int i = 4; i < signal.length; i++) {
      filtered[i] =
          b0 * signal[i] +
          b2 * signal[i - 2] +
          b4 * signal[i - 4] -
          a1 * filtered[i - 1] -
          a2 * filtered[i - 2] -
          a3 * filtered[i - 3] -
          a4 * filtered[i - 4];
    }
    return filtered;
  }

  static List<double> _findBestSignalSegment(List<double> signal) {
    int bestStart = 0;
    double bestQuality = 0;

    for (int i = 0; i <= signal.length - _windowSize; i++) {
      final segment = signal.sublist(i, i + _windowSize);
      final quality = _calculateSegmentQuality(segment);

      if (quality > bestQuality) {
        bestQuality = quality;
        bestStart = i;
      }
    }
    return signal.sublist(bestStart, bestStart + _windowSize);
  }

  static double _calculateSegmentQuality(List<double> segment) {
    if(segment.isEmpty) return 0;
    
    final maxVal = segment.reduce(math.max);
    final minVal = segment.reduce(math.min);
    final amplitude = maxVal - minVal;

    if (amplitude < _minValidAmplitude) return 0;

    final mean = segment.reduce((a, b) => a + b) / segment.length;
    final variance = segment.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / segment.length;
    
    if (variance == 0) return 0;

    return amplitude / math.sqrt(variance); // Higher amplitude and lower variance is better
  }

  static List<double> autocorrelate(List<double> signal) {
    List<double> autocorr = [];
    final n = signal.length;

    for (int lag = 0; lag < n ~/ 2; lag++) {
      double sum = 0;
      for (int i = 0; i < n - lag; i++) {
        sum += signal[i] * signal[i + lag];
      }
      autocorr.add(sum / (n - lag));
    }
    return autocorr;
  }

  static List<int> findPeaks(List<double> signal) {
    List<int> peaks = [];
    if(signal.isEmpty) return peaks;

    double threshold = signal.reduce(math.max) * 0.5;

    for (int i = 1; i < signal.length - 1; i++) {
      if (signal[i] > threshold && signal[i] > signal[i - 1] && signal[i] > signal[i + 1]) {
        peaks.add(i);
      }
    }
    return peaks;
  }
}