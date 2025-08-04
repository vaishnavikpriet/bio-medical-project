import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../models/bp_record.dart' as bp_model;
import 'measure_screen.dart';
import 'history_screen.dart';
import '../services/storage_service.dart' as storage_service;
import '../models/signal_quality.dart' as model;
import 'profile_screen.dart';
import 'package:biomedical/login_screen.dart';
import '../authentication.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

// Removed SingleTickerProviderStateMixin as we are using a dedicated animation package
class _HomeScreenState extends State<HomeScreen> {
  bp_model.BPRecord? latestRecord;
  List<bp_model.BPRecord> allRecords = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Added a small delay to allow the screen to build before loading data
    // This makes the initial shimmer animation feel smoother
    Future.delayed(const Duration(milliseconds: 300), _loadData);
  }

  Future<void> _loadData() async {
    try {
      setState(() => isLoading = true);
      final records = await storage_service.StorageService().getAllBPRecords();
      if (mounted) {
        setState(() {
          allRecords = records;
          latestRecord = records.isNotEmpty ? records.first : null;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load data: $e')));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadData(); // Refresh when screen becomes visible again
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use a subtle background color to make cards pop
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'BP Monitor',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        // Make AppBar transparent for a more modern look
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.blueAccent),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HistoryScreen()),
              );
              _loadData(); // Reload data when returning from history
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.deepPurple),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen()),
              );
            },
          ),
          // Update the logout button in home_screen.dart
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              try {
                // Clear authentication state
                await AuthService().signOut();

                // Navigate to login screen and remove all previous routes
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        LoginScreen(authService: AuthService()),
                  ),
                  (route) => false,
                );
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
              }
            },
          ),
        ],
      ),
      body: isLoading
          ? _buildShimmerLoading()
          : RefreshIndicator(
              onRefresh: _loadData,
              // Use AnimationLimiter to initialize the staggered animations
              child: AnimationLimiter(
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 500),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      verticalOffset: 50.0,
                      child: FadeInAnimation(child: widget),
                    ),
                    children: [
                      // Animate the top card switching between no-data and data states
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        child: latestRecord == null
                            ? _buildNoDataCard()
                            : _buildStatusCard(),
                      ),
                      const SizedBox(height: 24),
                      _buildChartCard(), // New, enhanced chart card
                      const SizedBox(height: 24),
                      _buildMeasureButton(),
                      const SizedBox(height: 24),
                      _buildTipsSection(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ✨ --- UI IMPROVEMENT: Shimmer Loading --- ✨
  // No major changes here, it's already a good implementation.
  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 250,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 65,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }

  // ✨ --- UI IMPROVEMENT: "No Data" Card --- ✨
  Widget _buildNoDataCard() {
    return Card(
      key: const ValueKey<int>(0), // Key for AnimatedSwitcher
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            const Icon(
              Icons.favorite_border,
              size: 50,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 16),
            const Text(
              'Welcome!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Measure BP Now" to get your first reading.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      key: const ValueKey<int>(1),
      elevation: 4,
      shadowColor: Colors.blueAccent.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [Colors.blueAccent.withOpacity(0.05), Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Latest Reading',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Responsive BP value row
              LayoutBuilder(
                builder: (context, constraints) {
                  final isSmallScreen = constraints.maxWidth < 350;
                  return isSmallScreen
                      ? Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildBPCard(
                                  'SYS',
                                  latestRecord!.systolic,
                                  'mmHg',
                                  const Color(0xFFFF6B6B),
                                ),
                                _buildBPCard(
                                  'DIA',
                                  latestRecord!.diastolic,
                                  'mmHg',
                                  const Color(0xFF4D96FF),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildBPCard(
                              'Pulse',
                              latestRecord!.pulse,
                              'bpm',
                              const Color(0xFF9C27B0),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildBPCard(
                              'SYS',
                              latestRecord!.systolic,
                              'mmHg',
                              const Color(0xFFFF6B6B),
                            ),
                            _buildBPCard(
                              'DIA',
                              latestRecord!.diastolic,
                              'mmHg',
                              const Color(0xFF4D96FF),
                            ),
                            _buildBPCard(
                              'Pulse',
                              latestRecord!.pulse,
                              'bpm',
                              const Color(0xFF9C27B0),
                            ),
                          ],
                        );
                },
              ),

              const SizedBox(height: 20),
              const Divider(color: Colors.black12),
              const SizedBox(height: 12),

              // Bottom row with timestamp and quality
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_filled_rounded,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            DateFormat(
                              'MMM dd, hh:mm a',
                            ).format(latestRecord!.timestamp),
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildQualityIndicator(latestRecord!.signalQuality),
                ],
              ),

              const SizedBox(height: 12),

              // Condition banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _getConditionColor(
                    latestRecord!.condition,
                  ).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getConditionColor(
                      latestRecord!.condition,
                    ).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  latestRecord!.condition.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _getConditionColor(latestRecord!.condition),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFlChart(List<bp_model.BPRecord> records) {
    final systolicSpots = <FlSpot>[];
    final diastolicSpots = <FlSpot>[];

    for (int i = 0; i < records.length; i++) {
      systolicSpots.add(FlSpot(i.toDouble(), records[i].systolic.toDouble()));
      diastolicSpots.add(FlSpot(i.toDouble(), records[i].diastolic.toDouble()));
    }

    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, _) {
                if (value.toInt() >= records.length) return Container();
                final date = records[value.toInt()].timestamp;
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    DateFormat('MMM dd').format(date),
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF6C7B8A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 20,
              getTitlesWidget: (value, _) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Text(
                  value.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6C7B8A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            if (value == 120) {
              return FlLine(
                color: const Color(0xFFFF6B6B),
                strokeWidth: 1.5,
                dashArray: [4, 4],
              );
            } else if (value == 80) {
              return FlLine(
                color: const Color(0xFF4D96FF),
                strokeWidth: 1.5,
                dashArray: [4, 4],
              );
            }
            return FlLine(color: const Color(0xFFE0E6ED), strokeWidth: 1);
          },
        ),
        borderData: FlBorderData(show: false),
        minY: 40,
        maxY: 200,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipBgColor: Colors.white,
            tooltipRoundedRadius: 8,
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final record = records[spot.spotIndex];
                return LineTooltipItem(
                  '${record.timestamp.day}/${record.timestamp.month}\n'
                  'SYS: ${record.systolic} mmHg\n'
                  'DIA: ${record.diastolic} mmHg\n'
                  'Pulse: ${record.pulse} bpm',
                  const TextStyle(
                    color: Colors.black87,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: systolicSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            barWidth: 3,
            color: const Color(0xFFFF6B6B),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFFF6B6B).withOpacity(0.2),
                  const Color(0xFFFF6B6B).withOpacity(0.01),
                ],
              ),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFFFF6B6B),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
          LineChartBarData(
            spots: diastolicSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            barWidth: 3,
            color: const Color(0xFF4D96FF),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF4D96FF).withOpacity(0.2),
                  const Color(0xFF4D96FF).withOpacity(0.01),
                ],
              ),
            ),
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFF4D96FF),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBPCard(String label, int value, String unit, Color color) {
    return Container(
      constraints: const BoxConstraints(minWidth: 80),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                  height: 0.9,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0, left: 4),
                child: Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.monitor_heart_outlined,
                color: Color(0xFF6C7B8A),
              ),
              const SizedBox(width: 8),
              Text(
                'BLOOD PRESSURE TREND',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: allRecords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.heart_broken_outlined,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "No measurements yet",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Your blood pressure readings will appear here",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildFlChart(allRecords.reversed.take(7).toList()),
          ),
          const SizedBox(height: 16),
          if (allRecords.isNotEmpty)
            Row(
              children: [
                _buildLegendItem('Systolic', const Color(0xFFFF6B6B)),
                const SizedBox(width: 16),
                _buildLegendItem('Diastolic', const Color(0xFF4D96FF)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ✨ --- UI IMPROVEMENT: Action Button --- ✨
  Widget _buildMeasureButton() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.favorite_rounded, size: 28),
      label: const Text(
        'Measure BP Now',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      style:
          ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            // Apply a gradient to the button
            backgroundColor:
                Colors.transparent, // Important for gradient to show
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 0, // Elevation is handled by the container
          ).copyWith(
            // Use a Container to apply the gradient and shadow
            // This is a common pattern for custom button styles
            elevation: MaterialStateProperty.all(0),
            overlayColor: MaterialStateProperty.all(
              Colors.white.withOpacity(0.2),
            ),
          ),
      onPressed: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MeasureScreen()),
        );
        if (result != null) {
          _loadData();
        }
      },
    ).
    // Wrap the button in a decorated container for gradient and shadow
    // This provides more styling flexibility than the button's style property alone
    let(
      (button) => Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Colors.blueAccent, Color(0xFF007BFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: button,
      ),
    );
  }

  // Extension to use .let for cleaner widget wrapping
}

extension ObjectLet<T> on T {
  R let<R>(R Function(T it) closure) => closure(this);
}

// ✨ --- UI IMPROVEMENT: Tips Section --- ✨
Widget _buildTipsSection() {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    color: Colors.teal.withOpacity(0.05),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: Colors.teal),
              SizedBox(width: 8),
              Text(
                'Measurement Tips',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipItem('Sit comfortably with your face well-lit.'),
          _buildTipItem('Avoid direct sunlight or strong backlighting.'),
          _buildTipItem('Stay completely still and quiet during measurement.'),
          _buildTipItem('Ensure your device camera is clean.'),
        ],
      ),
    ),
  );
}

Widget _buildTipItem(String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.check_circle, color: Colors.teal, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 15, height: 1.4)),
        ),
      ],
    ),
  );
}

// Helper for condition color - no changes needed, it's good
Color _getConditionColor(String condition) {
  switch (condition.toLowerCase()) {
    case 'normal':
      return Colors.green;
    case 'elevated':
      return Colors.orange;
    case 'high blood pressure (hypertension stage 1)':
    case 'high blood pressure (hypertension stage 2)':
      return Colors.red;
    case 'hypertensive crisis (seek immediate medical attention)':
      return Colors.purple.shade700;
    default:
      return Colors.blueGrey;
  }
}

// Helper for signal quality indicator - no changes needed
Widget _buildQualityIndicator(model.SignalQuality quality) {
  final Map<model.SignalQuality, dynamic> props = {
    model.SignalQuality.poor: {'color': Colors.red, 'label': 'POOR'},
    model.SignalQuality.fair: {'color': Colors.orange, 'label': 'FAIR'},
    model.SignalQuality.good: {'color': Colors.lightGreen, 'label': 'GOOD'},
    model.SignalQuality.excellent: {
      'color': Colors.green,
      'label': 'EXCELLENT',
    },
  };

  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: props[quality]!['color'],
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      'Quality: ${props[quality]!['label']}',
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 10,
      ),
    ),
  );
}
