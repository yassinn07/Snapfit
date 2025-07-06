import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class BrandDashboardScreen extends StatelessWidget {
  final int totalClicks;
  final int totalVisits;
  final int totalRecommended;
  final int totalLikedRecommendation;

  const BrandDashboardScreen({Key? key, required this.totalClicks, required this.totalVisits, required this.totalRecommended, required this.totalLikedRecommendation}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Dashboard', style: TextStyle(fontFamily: 'Archivo', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Brand Performance Overview',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Archivo'),
            ),
            const SizedBox(height: 24),
            _buildChartCard(
              title: 'Total Clicks',
              value: totalClicks,
              chart: _buildSingleValueLineChart(totalClicks, color: Colors.blue),
            ),
            const SizedBox(height: 24),
            _buildChartCard(
              title: 'Store Visits',
              value: totalVisits,
              chart: _buildSingleValueBarChart(totalVisits, color: Colors.deepPurple),
            ),
            const SizedBox(height: 24),
            _buildChartCard(
              title: 'Recommended',
              value: totalRecommended,
              chart: _buildSingleValueLineChart(totalRecommended, color: Colors.green),
            ),
            const SizedBox(height: 24),
            _buildChartCard(
              title: 'Liked the Recommendation',
              value: totalLikedRecommendation,
              chart: _buildSingleValueBarChart(totalLikedRecommendation, color: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard({required String title, required int value, required Widget chart}) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'Archivo')),
                Text(value.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Archivo')),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(height: 140, child: chart),
          ],
        ),
      ),
    );
  }

  static Widget _buildSingleValueLineChart(int value, {Color color = Colors.blue}) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: value == 0 ? 1 : value.toDouble(),
        lineBarsData: [
          LineChartBarData(
            spots: [FlSpot(0, 0), FlSpot(1, value.toDouble())],
            isCurved: true,
            color: color,
            barWidth: 4,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: color.withOpacity(0.15)),
          ),
        ],
      ),
    );
  }

  static Widget _buildSingleValueBarChart(int value, {Color color = Colors.deepPurple}) {
    return BarChart(
      BarChartData(
        gridData: FlGridData(show: false),
        titlesData: FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: value == 0 ? 1 : value.toDouble(),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: value.toDouble(), color: color, width: 32)])
        ],
      ),
    );
  }
} 