import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StatsScreen extends StatefulWidget {
  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<int> weeklyPagesRead = [70, 100, 0, 50, 200, 40, 100]; // Pages read per day
  int totalPagesRead = 0; // Total pages read
  int totalBookPages = 0; // Total book pages

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  /// Load statistics from SharedPreferences and calculate totals
  Future<void> _loadStatistics() async {
    final prefs = await SharedPreferences.getInstance();

    // Récupérez le nombre total de pages lues
    final savedTotalPagesRead = prefs.getInt('totalPagesRead') ?? 0;
    print("Total pages read from SharedPreferences: $savedTotalPagesRead");  // Log du nombre de pages lues récupérées

    // Récupérez le nombre total de pages des livres
    final savedTotalBookPages = prefs.getInt('totalBookPages') ?? 0;
    print("Total book pages from SharedPreferences: $savedTotalBookPages");  // Log du nombre total de pages des livres récupérées

    setState(() {
      totalPagesRead = savedTotalPagesRead;
      totalBookPages = savedTotalBookPages;
    });

    _calculateWeeklyPagesRead();
  }

  /// Distribute total pages read across the week
  void _calculateWeeklyPagesRead() {
    if (totalPagesRead == 0) {
      setState(() {
        weeklyPagesRead = [70, 100, 0, 50, 200, 40, 100]; // Default weekly pages if no data
      });
      print("No total pages read available, using default weekly data.");  // Log si aucune donnée de pages lues
      return;
    }

    setState(() {
      final pagesPerDay = totalPagesRead ~/ 7;
      weeklyPagesRead = List<int>.generate(7, (index) => pagesPerDay);
      print("Total pages read distributed across the week: $weeklyPagesRead");  // Log de la distribution des pages
    });
  }

  @override
  Widget build(BuildContext context) {
    print("Total Pages Read: $totalPagesRead");  // Log du nombre total de pages lues
    print("Total Book Pages: $totalBookPages");  // Log du nombre total de pages des livres

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
        title: Text(
          'Statistiques Lecture',
          style: TextStyle(
            fontFamily: 'Georgia',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              _buildWeeklyChart(),
              SizedBox(height: 40), // Augmenter l'espace entre le graphique et les statistiques
              _buildStatsRow(),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the weekly chart for pages read
  Widget _buildWeeklyChart() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pages Lues Cette Semaine',
          style: TextStyle(
            fontSize: 22, // Augmenter la taille du texte
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 10),
        Container(
          height: 300, // Augmenter la hauteur du graphique
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, _) => Text(
                        value.toInt().toString(),
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (value.toInt() < 0 || value.toInt() >= days.length) {
                          return SizedBox();
                        }
                        return Text(
                          days[value.toInt()],
                          style: TextStyle(fontSize: 14, color: Colors.grey), // Augmenter la taille du texte
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      FlSpot(0, 70),
                      FlSpot(1, 100),
                      FlSpot(2, 50),
                      FlSpot(3, 90),
                      FlSpot(4, 200),
                      FlSpot(5, 40),
                      FlSpot(6, 120),
                    ],
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.2)),
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build a row of statistical data (pages read and total book pages)
  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _StatItemWidget(
          title: 'Total Pages Lues',
          value: totalPagesRead.toString(),
        ),
        _StatItemWidget(
          title: 'Total Pages Livres',
          value: totalBookPages.toString(),
        ),
      ],
    );
  }
}

class _StatItemWidget extends StatelessWidget {
  final String title;
  final String value;

  _StatItemWidget({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 16, color: Colors.grey), // Augmenter la taille du texte
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 24, // Augmenter la taille du texte
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
