import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/bp_record.dart';

import 'package:intl/intl.dart';

class BPChart extends StatelessWidget {
  final List<BPRecord> records;
  
  BPChart({super.key, required this.records});

  @override
  Widget build(BuildContext context) {
    // Ensure we have at least 2 records to show a line
    if (records.length < 2) {
      return Center(
        child: Text(
          "Need at least 2 measurements to show trend",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: records.map((record) => 
              FlSpot(
                record.timestamp.millisecondsSinceEpoch.toDouble(), 
                record.systolic.toDouble()
              )
            ).toList(),
            color: Colors.red,
            barWidth: 4,
            isCurved: true,
          ),
          LineChartBarData(
            spots: records.map((record) => 
              FlSpot(
                record.timestamp.millisecondsSinceEpoch.toDouble(), 
                record.diastolic.toDouble()
              )
            ).toList(),
            color: Colors.blue,
            barWidth: 4,
            isCurved: true,
          ),
        ],
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                return Text(DateFormat('MMM d').format(date));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                return Text(value.toInt().toString());
              },
            ),
          ),
        ),
      ),
    );
  }
  
}