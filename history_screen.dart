import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Using for animations
import '../models/bp_record.dart';
import '../services/storage_service.dart';
import '../models/signal_quality.dart' as model;

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<BPRecord> _records = [];
  bool _isLoading = true;
  bool _showChart = false;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    final records = await StorageService().getAllBPRecords();
    if (mounted) {
      setState(() {
        // Records are sorted newest first from storage
        _records = records;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Health Journey', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        actions: [
          if (_records.isNotEmpty)
            IconButton(
              tooltip: _showChart ? "Show List View" : "Show Chart View",
              icon: Icon(_showChart ? Icons.list_alt_rounded : Icons.bar_chart_rounded),
              onPressed: () => setState(() => _showChart = !_showChart),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _isLoading
            ? _buildLoadingState()
            : _records.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _loadRecords,
                    child: _showChart ? _buildChartView() : _buildTimelineView(),
                  ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(child: CircularProgressIndicator());
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.monitor_heart_outlined, size: 100, color: Colors.grey[300]),
          const SizedBox(height: 20),
          Text(
            'No History Yet',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          ),
          const SizedBox(height: 10),
          Text(
            'Start a new measurement to begin your health journey.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildTimelineView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final record = _records[index];
        return _buildTimelineItem(record, isFirst: index == 0, isLast: index == _records.length - 1)
            .animate()
            .fadeIn(delay: (100 * (index > 5 ? 5 : index)).ms, duration: 400.ms)
            .slideX(begin: -0.2, curve: Curves.easeOutCubic);
      },
    );
  }

  Widget _buildTimelineItem(BPRecord record, {bool isFirst = false, bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left side: Timeline Spine
          SizedBox(
            width: 60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(DateFormat('h:mm').format(record.timestamp), style: TextStyle(fontWeight: FontWeight.bold)),
                Text(DateFormat('a').format(record.timestamp), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                const SizedBox(height: 8),
                Container(
                  width: 2,
                  height: 20,
                  color: isFirst ? Colors.transparent : Colors.grey[300],
                ),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: _getConditionColor(record.condition), width: 3),
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : Colors.grey[300],
                  ),
                )
              ],
            ),
          ),
          // Right side: Record Card
          Expanded(child: _buildRecordCard(record)),
        ],
      ),
    );
  }
  
  Widget _buildRecordCard(BPRecord record) {
    Color conditionColor = _getConditionColor(record.condition);
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showRecordDetails(record),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border(left: BorderSide(color: conditionColor, width: 5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('EEE, MMM d, y').format(record.timestamp),
                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800]),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                         if (value == 'delete') {
                           bool? confirm = await _showDeleteConfirmation();
                           if(confirm ?? false) {
                            await StorageService().deleteBPRecord(record.key);
                            _loadRecords();
                           }
                         }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'delete', child: Text('Delete Record')),
                      ],
                      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildValueIndicator('SYS', record.systolic, 'mmHg', conditionColor),
                    Container(width: 1, height: 40, color: Colors.grey[200]),
                    _buildValueIndicator('DIA', record.diastolic, 'mmHg', Colors.blueGrey),
                    Container(width: 1, height: 40, color: Colors.grey[200]),
                    _buildValueIndicator('PULSE', record.pulse, 'bpm', Colors.purpleAccent),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
 Widget _buildChartView() {
    final chartData = _records.reversed.toList();

    // Calculate stats
    final avgSys = _records.isNotEmpty ? _records.map((r) => r.systolic).reduce((a, b) => a + b) / _records.length : 0;
    final avgDia = _records.isNotEmpty ? _records.map((r) => r.diastolic).reduce((a, b) => a + b) / _records.length : 0;
    final maxSys = _records.isNotEmpty ? _records.map((r) => r.systolic).reduce((a, b) => a > b ? a : b) : 0;
    final minSys = _records.isNotEmpty ? _records.map((r) => r.systolic).reduce((a, b) => a < b ? a : b) : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Health Trend", style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          // --- Stats Section ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatChip("Avg", "${avgSys.toStringAsFixed(0)} / ${avgDia.toStringAsFixed(0)}", Colors.blue),
              _buildStatChip("Highest", "$maxSys", Colors.red),
              _buildStatChip("Lowest", "$minSys", Colors.green),
            ],
          ),
          const SizedBox(height: 24),
          // --- NEW Bar Chart ---
          AspectRatio(
            aspectRatio: 1.5,
            child: BarChart(
              BarChartData(
                // Interactive Tooltips
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: Colors.blueGrey,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      String label = rodIndex == 0 ? 'SYS' : 'DIA';
                      return BarTooltipItem(
                        '$label: ${rod.toY.toInt()}',
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                // Axis Titles
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= chartData.length) return const Text('');
                        // Show date label for every few items to avoid clutter
                        if (index % 3 == 0) {
                           return SideTitleWidget(
                            axisSide: meta.axisSide,
                            space: 4,
                            child: Text(DateFormat('d MMM').format(chartData[index].timestamp), style: const TextStyle(fontSize: 10)),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 22,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 35),
                  ),
                ),
                // Borders and Grid
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
                  },
                ),
                // Health Zone Lines
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    _buildHealthZoneLine(140, Colors.red.shade300),
                    _buildHealthZoneLine(130, Colors.orange.shade300),
                    _buildHealthZoneLine(120, Colors.green.shade300),
                  ],
                ),
                // Bar Data
                barGroups: chartData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final record = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      // Systolic Bar
                      BarChartRodData(
                        toY: record.systolic.toDouble(),
                        color: Colors.redAccent.withOpacity(0.8),
                        width: 7,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      // Diastolic Bar
                      BarChartRodData(
                        toY: record.diastolic.toDouble(),
                        color: Colors.blueAccent.withOpacity(0.8),
                        width: 7,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
                alignment: BarChartAlignment.spaceAround,
                maxY: 200,
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
  
  // Helper method for creating the health zone lines
  HorizontalLine _buildHealthZoneLine(double y, Color color) {
    return HorizontalLine(
      y: y,
      color: color,
      strokeWidth: 1,
      dashArray: [8, 4],
      label: HorizontalLineLabel(
        show: true,
        alignment: Alignment.topRight,
        padding: const EdgeInsets.only(right: 5, bottom: 2),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
        labelResolver: (line) => '${line.y.toInt()}',
      ),
    );
  }


  Widget _buildStatChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildValueIndicator(String label, int value, String unit, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('$value', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
        Text(unit, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }
  
  Future<bool?> _showDeleteConfirmation() {
     return showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Record'),
          content: const Text('Are you sure you want to permanently delete this measurement?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
  }
  
  void _showRecordDetails(BPRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(DateFormat('MMMM d, yyyy - h:mm a').format(record.timestamp), style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: _getConditionColor(record.condition).withOpacity(0.1),
              ),
              child: Column(
                children: [
                   Text(record.condition, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _getConditionColor(record.condition))),
                   const SizedBox(height: 16),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                     children: [
                       _buildValueIndicator('Systolic', record.systolic, 'mmHg', Colors.redAccent),
                       _buildValueIndicator('Diastolic', record.diastolic, 'mmHg', Colors.blueAccent),
                       _buildValueIndicator('Pulse', record.pulse, 'bpm', Colors.purpleAccent),
                     ],
                   )
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildQualityBadge(record.signalQuality)
          ],
        ),
      ),
    );
  }

  Widget _buildQualityBadge(model.SignalQuality quality) {
    final props = {
      model.SignalQuality.poor: {'color': Colors.red[400]!, 'icon': Icons.signal_cellular_alt_1_bar_rounded, 'label': 'POOR'},
      model.SignalQuality.fair: {'color': Colors.orange[400]!, 'icon': Icons.signal_cellular_alt_2_bar_rounded, 'label': 'FAIR'},
      model.SignalQuality.good: {'color': Colors.lightGreen[400]!, 'icon': Icons.signal_cellular_alt_rounded, 'label': 'GOOD'},
      model.SignalQuality.excellent: {'color': Colors.green[400]!, 'icon': Icons.signal_cellular_alt_rounded, 'label': 'EXCELLENT'},
    };
    final qualityProps = props[quality]!;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: (qualityProps['color'] as Color).withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(qualityProps['icon'] as IconData, color: qualityProps['color'] as Color, size: 18),
          const SizedBox(width: 8),
          Text(
            "Signal Quality: ${qualityProps['label']}",
            style: TextStyle(color: qualityProps['color'] as Color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'normal': return Colors.green;
      case 'elevated': return Colors.orange;
      case 'high blood pressure (hypertension stage 1)': return Colors.red.shade400;
      case 'high blood pressure (hypertension stage 2)': return Colors.red.shade700;
      case 'hypertensive crisis (seek immediate medical attention)': return Colors.deepPurple;
      default: return Colors.blueGrey;
    }
  }
}