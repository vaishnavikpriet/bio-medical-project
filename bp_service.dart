import 'package:camera/camera.dart';
import 'dart:math' as math;
import '../models/bp_record.dart';
import '../models/signal_quality.dart';
import 'ppg_processor.dart';

class BPService {
  static const int _fps = 30; // Camera frames per second

  static Future<BPRecord> estimateBP(List<CameraImage> frames) async {
    // --- 1. Extract PPG Signal ---
    final ppgSignal = PPGProcessor.extractPPG(frames);

    if (ppgSignal.length < _fps * 5) {
      throw Exception("Measurement too short. Please hold still for the full duration.");
    }

    // --- 2. Assess Signal Quality ---
    final quality = _assessQuality(ppgSignal);
    if (quality == SignalQuality.poor) {
      throw Exception("Poor signal. Try again in better lighting and hold steady.");
    }

    // --- 3. Calculate Robust Features ---
    final pulseRate = PPGProcessor.calculatePulseRate(ppgSignal, _fps);
    final double amplitude = ppgSignal.max() - ppgSignal.min();
    final double standardDeviation = ppgSignal.stdDev(); // Represents Heart Rate Variability

    // --- 4. NEW: Estimate BP using a more Robust Model ---
    // This model uses features that are less prone to failure than PTT.
    // NOTE: These formulas are empirical and for demonstration purposes.
    final systolic = _estimateSystolic(pulseRate, amplitude, standardDeviation);
    final diastolic = _estimateDiastolic(systolic, pulseRate, standardDeviation);

    return BPRecord(
      systolic: systolic.round(),
      diastolic: diastolic.round(),
      pulse: pulseRate,
      timestamp: DateTime.now(),
      condition: _getCondition(systolic, diastolic),
      signalQuality: quality,
    );
  }

static double _estimateSystolic(int pulseRate, double amplitude, double stdDev) {
  // More dynamic baseline based on pulse rate
  double baseline = 100 + (pulseRate - 60) * 0.3;
  
  // Amplitude adjustment with non-linear scaling
  double amplitudeFactor = math.pow((0.5 - amplitude).abs(), 1.5) * 20;
  if (amplitude < 0.5) {
    baseline += amplitudeFactor;
  } else {
    baseline -= amplitudeFactor;
  }

  // HRV adjustment with saturation
  double hrvFactor = (0.03 - stdDev) * 150;
  hrvFactor = hrvFactor.clamp(-15, 15);
  baseline += hrvFactor;

  // Add noise with pulse-rate dependent variance
  double noiseScale = 1 + (pulseRate - 60).abs() / 60;
  double randomFactor = (math.Random().nextDouble() * 6 - 3) * noiseScale;
  
  return baseline.clamp(90 + randomFactor, 160 + randomFactor).roundToDouble();
}

static double _estimateDiastolic(double systolic, int pulseRate, double stdDev) {
  // More physiological relationship
  double diastolic = 0.55 * systolic + 0.3 * pulseRate - 15;
  
  // HRV adjustment
  diastolic += (0.03 - stdDev) * 80;
  
  // Ensure plausible values
  diastolic = diastolic.clamp(
    systolic * 0.5 - 10,
    systolic - 15
  );
  
  // Add smaller random variation
  diastolic += math.Random().nextDouble() * 4 - 2;
  
  return diastolic.clamp(50, 100).roundToDouble();
}
  static SignalQuality _assessQuality(List<double> ppgSignal) {
    if (ppgSignal.isEmpty) return SignalQuality.poor;

    final amplitude = ppgSignal.max() - ppgSignal.min();
    if (amplitude < 0.05) return SignalQuality.poor;

    final stdDev = ppgSignal.stdDev();
    if (stdDev < 0.01) return SignalQuality.poor;

    // Zero-crossing rate helps determine if the signal is periodic like a heartbeat
    int zeroCrossings = 0;
    for (int i = 1; i < ppgSignal.length; i++) {
      // Check for crossing the mean value of the normalized signal (0.5)
      if ((ppgSignal[i - 1] - 0.5) * (ppgSignal[i] - 0.5) < 0) {
        zeroCrossings++;
      }
    }

    final crossingsPerSecond = zeroCrossings / (ppgSignal.length / _fps);
    // A normal heart rate (60-120bpm) corresponds to 1-2 full cycles (2-4 crossings) per second
    if (crossingsPerSecond < 1.5 || crossingsPerSecond > 5.0) {
      return SignalQuality.fair;
    }

    return SignalQuality.good;
  }

  static String _getCondition(double systolic, double diastolic) {
    if (systolic >= 180 || diastolic >= 120) {
      return 'Hypertensive Crisis (Seek immediate medical attention)';
    } else if (systolic >= 140 || diastolic >= 90) {
      return 'High Blood Pressure (Hypertension Stage 2)';
    } else if ((systolic >= 130 && systolic <= 139) ||
        (diastolic >= 80 && diastolic <= 89)) {
      return 'High Blood Pressure (Hypertension Stage 1)';
    } else if (systolic >= 120 && systolic < 130 && diastolic < 80) {
      return 'Elevated';
    }
    return 'Normal';
  }
}

extension ListStats on List<double> {
  double max() {
    if (isEmpty) return 0.0;
    return reduce((a, b) => a > b ? a : b);
  }

  double min() {
    if (isEmpty) return 0.0;
    return reduce((a, b) => a < b ? a : b);
  }

  double average() {
    if (isEmpty) return 0.0;
    return reduce((a, b) => a + b) / length;
  }

  double stdDev() {
    if (length < 2) return 0.0;
    final mean = average();
    final variance =
        map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / (length - 1);
    return math.sqrt(variance);
  }
}