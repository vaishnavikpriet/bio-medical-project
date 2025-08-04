import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import '../models/bp_record.dart' as bp;
import '../services/bp_service.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import '../models/signal_quality.dart';

import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../data/demo_data.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import '../services/storage_service.dart';

const _measurementDuration = 30;
const _requiredFaceStabilityFrames = 15;

extension IterableNumExtension on Iterable<num> {
  double average() {
    if (isEmpty) return 0.0;
    return reduce((a, b) => a + b).toDouble() / length;
  }
}

class MeasureScreen extends StatefulWidget {
  @override
  _MeasureScreenState createState() => _MeasureScreenState();
}

class _MeasureScreenState extends State<MeasureScreen>
    with SingleTickerProviderStateMixin {
  late CameraController _controller;
  List<CameraDescription> _cameras = [];
  bool _isMeasuring = false;
  int _progress = 0;
  bp.BPRecord? _result;
  final CountDownController _countDownController = CountDownController();
  String _statusMessage = 'Initializing camera...';
  List<CameraImage> _preMeasurementFrames = [];
  List<CameraImage> _measurementFrames = [];
  double motionLevel = 0.0;
  CameraImage? _previousImageForMotion;
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _initializeCamera();
  }

  static SignalQuality _parseSignalQuality(String quality) {
    switch (quality.toLowerCase()) {
      case 'excellent':
        return SignalQuality.excellent;
      case 'good':
        return SignalQuality.good;
      case 'fair':
        return SignalQuality.fair;
      default:
        return SignalQuality.poor;
    }
  }


  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    final initialCamera = _cameras.length > 1
        ? _cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.front,
            orElse: () => _cameras.first,
          )
        : _cameras.first;

    _controller = CameraController(
      initialCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await _controller.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
        _statusMessage = 'Ready to measure';
      });

      _controller.startImageStream((image) {
        if (!_isMeasuring) {
          _preMeasurementFrames.add(image);
          if (_preMeasurementFrames.length > _requiredFaceStabilityFrames * 2) {
            _preMeasurementFrames.removeAt(0);
          }
        } else {
          _measurementFrames.add(image);
        }
        _previousImageForMotion = image;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Failed to initialize camera. Please try again.';
          _isCameraInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _startMeasurement() {
    // First check face stability
    if (!_checkFaceStability(_preMeasurementFrames)) {
      setState(() {
        _statusMessage = 'Please hold still before starting measurement';
      });
      return;
    }

    setState(() {
      _isMeasuring = true;
      _statusMessage = 'Measuring... Please wait';
      _measurementFrames.clear();
      _progress = 0;
    });

    // Update progress periodically
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_isMeasuring || !mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _progress = ((timer.tick / _measurementDuration) * 100).toInt();

        // Calculate and display real-time motion level
        if (_previousImageForMotion != null && _measurementFrames.isNotEmpty) {
          motionLevel = calculateMotionLevel(_measurementFrames.last);
          if (motionLevel > 0.15) {
            _statusMessage = 'Too much movement! Please hold still';
          }
        }
      });
    });

    _countDownController.start();

    Future.delayed(const Duration(seconds: _measurementDuration + 1), () {
      if (!mounted || !_isMeasuring) return;
      setState(() => _statusMessage = 'Processing data...');
      _completeMeasurement();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Measure Blood Pressure')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CameraPreview(_controller),
                if (_isMeasuring) _buildMeasurementOverlay(),
                Positioned(top: 20, child: _buildStatusMessage()),
              ],
            ),
          ),
          if (_result != null) _buildResultCard(),
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildStatusMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusMessage,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMeasurementOverlay() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: CircularCountDownTimer(
                width: 150,
                height: 150,
                duration: _measurementDuration,
                controller: _countDownController,
                fillColor: Colors.redAccent,
                ringColor: Colors.grey.withOpacity(0.3),
                strokeWidth: 10,
                textStyle: TextStyle(
                  fontSize: 32,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                isReverse: true,
                onComplete: () {},
              ),
            );
          },
        ),
        SizedBox(height: 20),
        TweenAnimationBuilder(
          tween: Tween<double>(begin: 0, end: _progress / 100),
          duration: Duration(milliseconds: 300),
          builder: (context, value, child) {
            return LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.grey.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.redAccent),
              minHeight: 10,
            );
          },
        ),
        SizedBox(height: 20),
        Text(
          'Hold still...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                blurRadius: 5.0,
                color: Colors.black,
                offset: Offset(2.0, 2.0),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    return SlideTransition(
      position: Tween<Offset>(begin: Offset(0, 1), end: Offset.zero).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutBack,
        ),
      ),
      child: Card(
        margin: EdgeInsets.all(16),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Measurement Result',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueAccent,
                ),
              ),
              const Divider(height: 20, thickness: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildResultItem(
                    'SYS',
                    '${_result!.systolic}',
                    'mmHg',
                    Colors.green,
                  ),
                  _buildResultItem(
                    'DIA',
                    '${_result!.diastolic}',
                    'mmHg',
                    Colors.orange,
                  ),
                  _buildResultItem(
                    'Pulse',
                    '${_result!.pulse}',
                    'bpm',
                    Colors.purple,
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat(
                      'MMM dd, yyyy - hh:mm a',
                    ).format(_result!.timestamp),
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getConditionColor(_result!.condition),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _result!.condition,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildQualityIndicator(_result!.signalQuality),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultItem(
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(unit, style: const TextStyle(color: Colors.grey, fontSize: 14)),
      ],
    );
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'normal':
        return Colors.green;
      case 'elevated':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (!_isMeasuring && _result == null)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF42A5F5), Color(0xFF1976D2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_arrow, size: 24),
                  label: const Text('Check BP '),
                  onPressed: !_isMeasuring ? _startMeasurement : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        Colors.transparent, // important for gradient
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 30,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ),

          if (_result != null)
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Save Result'),
                onPressed: () {
                  if (_result != null) {
                    Navigator.pop(context, _result);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          if (_isMeasuring)
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _isMeasuring = false;
                    _result = null;
                    _statusMessage = 'Measurement canceled.';
                    _progress = 0;
                    _preMeasurementFrames.clear();
                    _measurementFrames.clear();
                    _previousImageForMotion = null;
                    _countDownController.reset();
                  });
                },
              ),
            ),
          if (!_isMeasuring)
            SizedBox(width: _result != null || _isMeasuring ? 0 : 16),
          if (!_isMeasuring)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF26A69A), Color(0xFF00796B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.download, size: 24),
                  label: const Text('Export Data'),
                  onPressed: () async {
                    final records = StorageService().getAllBPRecords();
                    if (records.isNotEmpty) {
                      Directory? downloadsDirectory =
                          await getDownloadsDirectory();
                      if (downloadsDirectory != null) {
                        final file = File(
                          '${downloadsDirectory.path}/bp_data_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv',
                        );
                        final csvData = const ListToCsvConverter().convert([
                          [
                            'Timestamp',
                            'Systolic',
                            'Diastolic',
                            'Pulse',
                            'Condition',
                            'Signal Quality',
                          ],
                          ...records.map(
                            (r) => [
                              r.timestamp.toIso8601String(),
                              r.systolic,
                              r.diastolic,
                              r.pulse,
                              r.condition,
                              r.signalQuality.toString().split('.').last,
                            ],
                          ),
                        ]);
                        await file.writeAsString(csvData);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Data exported to ${file.path}'),
                            ),
                          );
                        }
                      } else if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Could not access downloads directory.',
                            ),
                          ),
                        );
                      }
                    } else if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No data to export.')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _validateWithDemoData(bp.BPRecord record) async {
    try {
      final csvTable = const CsvToListConverter().convert(
        BPData.csvData,
        eol: '\n',
      );
      final demoRecords = csvTable
          .skip(1)
          .map((row) {
            try {
              if (row.length < 6) return null;
              return bp.BPRecord(
                timestamp: DateTime.parse(row[0].toString()),
                systolic: int.parse(row[1].toString()),
                diastolic: int.parse(row[2].toString()),
                pulse: int.parse(row[3].toString()),
                condition: row[4].toString(),
                signalQuality: _parseSignalQuality(row[5].toString()),
              );
            } catch (e) {
              return null;
            }
          })
          .where((record) => record != null)
          .cast<bp.BPRecord>()
          .toList();

      final similarRecords = demoRecords
          .where(
            (demo) =>
                (demo.systolic - record.systolic).abs() <= 10 &&
                (demo.diastolic - record.diastolic).abs() <= 10 &&
                (demo.pulse - record.pulse).abs() <= 10,
          )
          .toList();

      if (similarRecords.isNotEmpty) {
        final avgSystolic = similarRecords
            .map((r) => r.systolic.toDouble())
            .average();
        final avgDiastolic = similarRecords
            .map((r) => r.diastolic.toDouble())
            .average();
        final avgPulse = similarRecords
            .map((r) => r.pulse.toDouble())
            .average();
        final deviation = (
          systolic: ((record.systolic - avgSystolic) / avgSystolic * 100).abs(),
          diastolic: ((record.diastolic - avgDiastolic) / avgDiastolic * 100)
              .abs(),
          pulse: ((record.pulse - avgPulse) / avgPulse * 100).abs(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Validation: Within ${deviation.systolic.toStringAsFixed(1)}% of demo data average',
                style: TextStyle(fontSize: 16),
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Handle error
    }
  }

  double _calculateAvgBrightness(CameraImage image) {
    if (image.planes.isEmpty || image.planes[0].bytes.isEmpty) return 0.0;
    final plane = image.planes[0];
    final bytes = plane.bytes;
    int sum = 0;
    for (int i = 0; i < bytes.length; i++) {
      sum += bytes[i];
    }
    return sum / bytes.length;
  }

  void _completeMeasurement() async {
    _animationController.stop();
    setState(() => _statusMessage = 'Processing data...');
    try {
      final result = await compute(_processDataInIsolate, {
        'frames': _measurementFrames,
        'motionLevel': motionLevel,
      });
      final record = bp.BPRecord(
        systolic: result['systolic'],
        diastolic: result['diastolic'],
        pulse: result['pulse'],
        timestamp: DateTime.now(),
        condition: result['condition'],
        signalQuality: SignalQuality.values[result['quality']],
      );
      await _saveResultToStorage(record);
      await _validateWithDemoData(record);
      if (mounted) {
        setState(() {
          _result = record;
          _isMeasuring = false;
          _statusMessage = 'Measurement complete!';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage =
              'Measurement failed: ${e.toString().replaceAll("Exception: ", "")}';
          _isMeasuring = false;
          _result = null;
        });
      }
    } finally {
      _measurementFrames.clear();
      _preMeasurementFrames.clear();
      _previousImageForMotion = null;
    }
  }

  Future<void> _saveResultToStorage(bp.BPRecord record) async {
    try {
      await StorageService().saveBPRecord(record);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Measurement saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save measurement: ${e.toString()}'),
          ),
        );
      }
    }
  }

  bool _checkFaceStability(List<CameraImage> recentFrames) {
    if (recentFrames.length < _requiredFaceStabilityFrames) return false;
    final framesForStability = recentFrames.sublist(
      recentFrames.length - _requiredFaceStabilityFrames,
    );
    if (framesForStability.isEmpty) return false;
    List<double> brightnessValues = [];
    List<double> motionValues = [];
    for (int i = 0; i < framesForStability.length; i++) {
      final currentFrame = framesForStability[i];
      brightnessValues.add(_calculateAvgBrightness(currentFrame));
      if (i > 0) {
        motionValues.add(
          _calculateFrameDifference(
            currentFrame.planes[0].bytes,
            framesForStability[i - 1].planes[0].bytes,
          ),
        );
      }
    }
    final brightnessMean = brightnessValues.average();
    final brightnessVar = brightnessValues
        .map((v) => math.pow(v - brightnessMean, 2))
        .average();
    final avgMotion = motionValues.average();
    return brightnessVar < 50 && avgMotion < 0.1;
  }

  double calculateMotionLevel(CameraImage image) {
    double motion = 0.0;
    if (_previousImageForMotion != null) {
      motion = _calculateFrameDifference(
        image.planes[0].bytes,
        _previousImageForMotion!.planes[0].bytes,
      );
    }
    return motion;
  }

  double _calculateFrameDifference(Uint8List current, Uint8List previous) {
    if (current.length != previous.length) return 1.0;
    double diffSum = 0;
    for (int i = 0; i < current.length; i++) {
      diffSum += (current[i] - previous[i]).abs();
    }
    return diffSum / current.length / 255.0;
  }


  Widget _buildQualityIndicator(SignalQuality quality) {
    final colors = {
      SignalQuality.poor: Colors.red,
      SignalQuality.fair: Colors.orange,
      SignalQuality.good: Colors.lightGreen,
      SignalQuality.excellent: Colors.green,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors[quality],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Quality: ${quality.toString().split('.').last.toUpperCase()}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

Future<Map<String, dynamic>> _processDataInIsolate(
  Map<String, dynamic> params,
) async {
  final frames = params['frames'] as List<CameraImage>;
  final motionLevel = params['motionLevel'] as double;
  if (frames.isEmpty) {
    throw Exception('No frames were captured.');
  }
  final brightnessValues = frames.map((f) {
    if (f.planes.isEmpty || f.planes[0].bytes.isEmpty) return 0.0;
    final bytes = f.planes[0].bytes;
    int sum = 0;
    for (int i = 0; i < bytes.length; i++) {
      sum += bytes[i];
    }
    return sum / bytes.length;
  }).toList();
  final meanBrightness = brightnessValues.average();
  final brightnessVariance = brightnessValues
      .map((b) => math.pow(b - meanBrightness, 2))
      .average();
  SignalQuality quality;
  if (motionLevel > 0.1 || meanBrightness < 50 || meanBrightness > 230) {
    quality = SignalQuality.poor;
  } else if (brightnessVariance > 50) {
    quality = SignalQuality.fair;
  } else if (brightnessVariance > 10) {
    quality = SignalQuality.good;
  } else {
    quality = SignalQuality.excellent;
  }
  if (quality == SignalQuality.poor) {
    throw Exception(
      'Poor signal. Please try again in better light and stay still.',
    );
  }
  try {
    final result = await BPService.estimateBP(frames);
    return {
      'systolic': result.systolic,
      'diastolic': result.diastolic,
      'pulse': result.pulse,
      'condition': result.condition,
      'quality': quality.index,
    };
  } catch (e) {
    throw Exception('Could not process PPG signal.');
  }
}
