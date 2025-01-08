import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart'; // For charts

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboardPage> {
  int attendanceCount = 0;
  int newUsersCount = 0;
  int activeSessionsCount = 0;

  List<Map<String, dynamic>> globalSessionsData = []; // Data for the chart

  @override
  void initState() {
    super.initState();
    fetchStatistics();
    fetchGlobalSessionsDataForChart();
  }

  Future<void> fetchStatistics() async {
    try {
      // Fetch total sessions created in the last month
      final sessionsResponse = await Supabase.instance.client
          .from('Sessions')
          .select('id')
          .gte('created_at', DateTime.now().subtract(const Duration(days: 30)).toIso8601String());

      print('<DEBUG> Fetched sessions data: ${sessionsResponse}');
      final totalSessionsCreated = sessionsResponse.length;

      // Fetch current active sessions
      final activeSessionsResponse = await Supabase.instance.client
          .from('Sessions')
          .select('id')
          .eq('status', 'active'); // Assuming 'status' column tracks session activity
      final currentActiveSessions = activeSessionsResponse.length;

      // Fetch current number of students marked present in ongoing sessions
      final attendanceResponse = await Supabase.instance.client
          .from('Attendance')
          .select('id')
          .inFilter('session_id', activeSessionsResponse.map((s) => s['id']).toList());
      final currentStudentsPresent = attendanceResponse.length;

      setState(() {
        attendanceCount = currentStudentsPresent;
        newUsersCount = totalSessionsCreated;
        activeSessionsCount = currentActiveSessions;
      });
    } catch (e) {
      print("<DEBUG> Error fetching statistics: $e");
    }
  }

  Future<void> fetchGlobalSessionsDataForChart() async {
    try {
      // Fetch global sessions data for the last 7 days
      final today = DateTime.now();
      final startOfWeek = today.subtract(const Duration(days: 7));

      final response = await Supabase.instance.client
          .from('Sessions')
          .select('start_time, id')
          .gte('start_time', startOfWeek.toIso8601String())
          .order('start_time', ascending: true);

      print('<DEBUG> Global Sessions for Chart Response: $response');

      // Fetch attendance data for each session
      final sessionIds = response.map((s) => s['id'] as String).toList();
      final attendanceResponse = await Supabase.instance.client
          .from('Attendance')
          .select('session_id, status')
          .inFilter('session_id', sessionIds);

      print('<DEBUG> Global Attendance for Chart Response: $attendanceResponse');

      // Group attendance data by date
      final Map<String, int> attendanceByDate = {};
      for (var session in response) {
        final sessionDate = DateTime.parse(session['start_time'] as String)
            .toLocal()
            .toString()
            .split(' ')[0];
        final sessionId = session['id'] as String;
        final sessionAttendance = attendanceResponse
            .where((attendance) =>
        attendance['session_id'] == sessionId &&
            attendance['status'] == 'present')
            .length;
        attendanceByDate.update(
          sessionDate,
              (value) => value + sessionAttendance,
          ifAbsent: () => sessionAttendance,
        );
      }

      print('<DEBUG> Global Attendance Data for Chart: $attendanceByDate');

      // Convert to list of maps for the chart
      setState(() {
        globalSessionsData = attendanceByDate.entries.map((entry) {
          return {
            'date': entry.key,
            'attendance_count': entry.value,
          };
        }).toList();
      });
    } catch (e) {
      print('<DEBUG> Error fetching global sessions data for chart: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Grid for Statistics
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatisticCard(
                  title: 'Total Sessions (Last 30d)',
                  value: newUsersCount.toString(),
                  icon: Icons.calendar_today,
                ),
                _buildStatisticCard(
                  title: 'Active Sessions',
                  value: activeSessionsCount.toString(),
                  icon: Icons.event,
                ),
                _buildStatisticCard(
                  title: 'Students Present (Ongoing)',
                  value: attendanceCount.toString(),
                  icon: Icons.people,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Chart Section
            _buildSectionTitle('Global Sessions Attendance Trends'),
            SizedBox(
              height: 300,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: 1,
                      verticalInterval: 1,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.3),
                          strokeWidth: 1,
                        );
                      },
                      getDrawingVerticalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withOpacity(0.3),
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (globalSessionsData.isNotEmpty &&
                                value.toInt() < globalSessionsData.length) {
                              final date =
                              globalSessionsData[value.toInt()]['date'] as String;
                              return Text(
                                date.split('-').last,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              '${value.toInt()}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    minX: 0,
                    maxX: globalSessionsData.length > 0
                        ? globalSessionsData.length.toDouble() - 1
                        : 0,
                    minY: 0,
                    maxY: globalSessionsData.isNotEmpty
                        ? globalSessionsData
                        .map((data) => (data['attendance_count'] as int).toDouble())
                        .reduce((a, b) => a > b ? a : b)
                        : 10.0,
                    lineBarsData: [
                      LineChartBarData(
                        spots: _generateChartData(),
                        isCurved: true,
                        color: const Color(0xFF1976D2),
                        barWidth: 4,
                        belowBarData: BarAreaData(
                          show: true,
                          color: const Color(0xFF1976D2).withOpacity(0.3),
                        ),
                        dotData: const FlDotData(show: false),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((spot) {
                            final date = globalSessionsData[spot.x.toInt()]['date'] as String;
                            final attendanceCount = spot.y.toInt();
                            return LineTooltipItem(
                              '$date\n$attendanceCount students',
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                              children: [
                                const TextSpan(
                                  text: '\nTap for details',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _generateChartData() {
    return globalSessionsData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      return FlSpot(
        index.toDouble(),
        (data['attendance_count'] as int).toDouble(),
      );
    }).toList();
  }

  Widget _buildStatisticCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon and Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: Colors.blueAccent,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Value
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}