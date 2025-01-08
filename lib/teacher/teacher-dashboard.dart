import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart'; // For charts

class TeacherDashboardPage extends StatefulWidget {
  final String teacherId; // Pass teacherId from login

  const TeacherDashboardPage({super.key, required this.teacherId});

  @override
  _TeacherDashboardPageState createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  late final String teacherId;

  int todaysSessionsCount = 0;
  double todaysPresenceRate = 0.0;
  int allTimeSessionsCount = 0;
  double allTimePresenceRate = 0.0;

  List<Map<String, dynamic>> attendanceData = []; // Data for the chart

  @override
  void initState() {
    super.initState();
    teacherId = widget.teacherId; // Use teacherId from the widget
    print('<DEBUG> Teacher ID in Dashboard: $teacherId'); // Debug
    fetchTeacherStatistics();
    fetchAttendanceDataForChart();
  }

  Future<void> fetchTeacherStatistics() async {
    try {
      if (teacherId.isEmpty) {
        print('<DEBUG> No teacher logged in.');
        return;
      }

      // Fetch today's sessions count
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final todaysSessionsResponse = await Supabase.instance.client
          .from('Sessions') // Correct table name
          .select('id, group') // Correct column names
          .eq('teacher', teacherId) // Correct column name
          .gte('start_time', startOfDay.toIso8601String()); // Correct column name

      print('<DEBUG> Today\'s Sessions Response: $todaysSessionsResponse'); // Debug
      todaysSessionsCount = todaysSessionsResponse.length;

      // Calculate today's presence rate
      final todaysSessionIds =
      todaysSessionsResponse.map((s) => s['id'] as String).toList();
      final todaysAttendanceResponse = await Supabase.instance.client
          .from('Attendance')
          .select('id, status')
          .inFilter('session_id', todaysSessionIds);

      print('<DEBUG> Today\'s Attendance Response: $todaysAttendanceResponse'); // Debug

      // Count present students for today
      final todaysPresenceCount = todaysAttendanceResponse
          .where((attendance) => attendance['status'] == 'present')
          .length;

      // Calculate total students for today (assuming 7 students per group)
      final totalStudentsToday = todaysSessionsCount * 7;

      todaysPresenceRate = totalStudentsToday > 0
          ? (todaysPresenceCount / totalStudentsToday) * 100
          : 0.0;

      // Fetch all-time sessions count
      final allTimeSessionsResponse = await Supabase.instance.client
          .from('Sessions') // Correct table name
          .select('id')
          .eq('teacher', teacherId); // Correct column name

      print('<DEBUG> All-Time Sessions Response: $allTimeSessionsResponse'); // Debug
      allTimeSessionsCount = allTimeSessionsResponse.length;

      // Calculate all-time presence rate
      final allTimeSessionIds =
      allTimeSessionsResponse.map((s) => s['id'] as String).toList();
      final allTimeAttendanceResponse = await Supabase.instance.client
          .from('Attendance')
          .select('id, status')
          .inFilter('session_id', allTimeSessionIds);

      print('<DEBUG> All-Time Attendance Response: $allTimeAttendanceResponse'); // Debug

      // Count present students for all-time
      final allTimePresenceCount = allTimeAttendanceResponse
          .where((attendance) => attendance['status'] == 'present')
          .length;

      // Calculate total students for all-time (assuming 7 students per group)
      final totalStudentsAllTime = allTimeSessionsCount * 7;

      allTimePresenceRate = totalStudentsAllTime > 0
          ? (allTimePresenceCount / totalStudentsAllTime) * 100
          : 0.0;

      // Update state with fetched statistics
      setState(() {});
    } catch (e) {
      print('<DEBUG> Error fetching teacher statistics: $e');
    }
  }

  Future<void> fetchAttendanceDataForChart() async {
    try {
      // Fetch attendance data for the last 7 days
      final today = DateTime.now();
      final startOfWeek = today.subtract(const Duration(days: 7));

      final response = await Supabase.instance.client
          .from('Sessions') // Correct table name
          .select('start_time, id') // Correct column names
          .eq('teacher', teacherId) // Correct column name
          .gte('start_time', startOfWeek.toIso8601String()) // Correct column name
          .order('start_time', ascending: true);

      print('<DEBUG> Sessions for Chart Response: $response'); // Debug

      // Fetch attendance data for each session
      final sessionIds = response.map((s) => s['id'] as String).toList();
      final attendanceResponse = await Supabase.instance.client
          .from('Attendance')
          .select('session_id, status')
          .inFilter('session_id', sessionIds);

      print('<DEBUG> Attendance for Chart Response: $attendanceResponse'); // Debug

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

      print('<DEBUG> Attendance Data for Chart: $attendanceByDate'); // Debug

      // Convert to list of maps for the chart
      setState(() {
        attendanceData = attendanceByDate.entries.map((entry) {
          return {
            'date': entry.key,
            'attendance_count': entry.value,
          };
        }).toList();
      });
    } catch (e) {
      print('<DEBUG> Error fetching attendance data for chart: $e');
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
                  title: "Today's Sessions",
                  value: todaysSessionsCount.toString(),
                  icon: Icons.calendar_today,
                ),
                _buildStatisticCard(
                  title: "Today's Presence Rate",
                  value: '${todaysPresenceRate.toStringAsFixed(1)}%',
                  icon: Icons.people,
                  isPercentage: true,
                ),
                _buildStatisticCard(
                  title: 'All-Time Sessions',
                  value: allTimeSessionsCount.toString(),
                  icon: Icons.history,
                ),
                _buildStatisticCard(
                  title: 'All-Time Presence Rate',
                  value: '${allTimePresenceRate.toStringAsFixed(1)}%',
                  icon: Icons.trending_up,
                  isPercentage: true,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Chart Section
            _buildSectionTitle('Attendance Trends'),
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
                            // Display day or date on the X-axis
                            if (attendanceData.isNotEmpty && value.toInt() < attendanceData.length) {
                              final date = attendanceData[value.toInt()]['date'] as String;
                              return Text(
                                date.split('-').last, // Display day of the month (e.g., "01", "02")
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
                            // Display attendance count on the Y-axis
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
                    maxX: attendanceData.length > 0
                        ? attendanceData.length.toDouble() - 1
                        : 0,
                    minY: 0,
                    maxY: attendanceData.isNotEmpty
                        ? attendanceData
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
                            final date = attendanceData[spot.x.toInt()]['date'] as String;
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
    return attendanceData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      return FlSpot(
        index.toDouble(), // X-axis: Index of the data point
        (data['attendance_count'] as int).toDouble(), // Y-axis: Attendance count (cast to double)
      );
    }).toList();
  }

  Widget _buildStatisticCard({
    required String title,
    required String value,
    required IconData icon,
    bool isPercentage = false,
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
                    overflow: TextOverflow.ellipsis, // Handle overflow
                    maxLines: 2, // Allow up to 2 lines for the title
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
            const SizedBox(height: 8),

            // Progress Bar (for percentages)
            if (isPercentage)
              Flexible(
                child: LinearProgressIndicator(
                  value: double.parse(value.replaceAll('%', '')) / 100,
                  backgroundColor: Colors.blueAccent.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
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