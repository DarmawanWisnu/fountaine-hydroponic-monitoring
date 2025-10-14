import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTime? selectedDate;

  // Dummy data
  final List<Map<String, dynamic>> _historyData = [
    {
      "date": DateTime(2025, 10, 8, 16, 30, 34),
      "kit": "Kit 1",
      "id": "SUF-UINJKT-HM-F2000",
      "ph": 6.7,
      "ppm": 300,
      "humidity": 75,
      "temperature": 28,
    },
    {
      "date": DateTime(2025, 10, 8, 12, 30, 34),
      "kit": "Kit 1",
      "id": "SUF-UINJKT-HM-F2000",
      "ph": 6.7,
      "ppm": 300,
      "humidity": 75,
      "temperature": 28,
    },
    {
      "date": DateTime(2025, 10, 7, 14, 15, 12),
      "kit": "Kit 1",
      "id": "SUF-UINJKT-HM-F2000",
      "ph": 6.6,
      "ppm": 310,
      "humidity": 72,
      "temperature": 27,
    },
  ];

  static const Color _bg = Color(0xFFF6FBF6);
  static const Color _primary = Color(0xFF154B2E);
  static const Color _muted = Color(0xFF7A7A7A);

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.of(context).size.width / 375.0;
    final filteredData = selectedDate == null
        ? _historyData
        : _historyData
              .where(
                (item) =>
                    DateFormat('yyyy-MM-dd').format(item['date']) ==
                    DateFormat('yyyy-MM-dd').format(selectedDate!),
              )
              .toList();

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20 * s, vertical: 14 * s),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 20 * s,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.arrow_back,
                        color: _primary,
                        size: 20 * s,
                      ),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'History',
                        style: TextStyle(
                          fontSize: 20 * s,
                          fontWeight: FontWeight.w800,
                          color: _primary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 40 * s),
                ],
              ),

              SizedBox(height: 16 * s),

              // Date Picker Dropdown
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2024, 1, 1),
                    lastDate: DateTime(2026, 12, 31),
                  );
                  if (picked != null) {
                    setState(() => selectedDate = picked);
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 18 * s,
                    vertical: 14 * s,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18 * s),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        selectedDate == null
                            ? 'Select Date'
                            : DateFormat('d MMMM yyyy').format(selectedDate!),
                        style: TextStyle(
                          color: selectedDate == null ? _muted : _primary,
                          fontSize: 15 * s,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _primary,
                        size: 22 * s,
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 18 * s),

              if (filteredData.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No data available for this date.',
                      style: TextStyle(color: _muted, fontSize: 15 * s),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredData.length,
                    itemBuilder: (context, index) {
                      final item = filteredData[index];
                      final formattedDate = DateFormat(
                        'd MMMM yyyy, HH:mm:ss',
                      ).format(item['date']);
                      return Padding(
                        padding: EdgeInsets.only(bottom: 14 * s),
                        child: Container(
                          padding: EdgeInsets.all(16 * s),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16 * s),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['kit'],
                                style: TextStyle(
                                  color: _primary,
                                  fontSize: 16 * s,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 6 * s),
                              Text(
                                item['id'],
                                style: TextStyle(
                                  fontSize: 14 * s,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 6 * s),
                              Text(
                                'Water Acidity : ${item['ph']} pH',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 14 * s,
                                ),
                              ),
                              Text(
                                'Total Dissolved Solids (TDS) : ${item['ppm']} PPM',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 14 * s,
                                ),
                              ),
                              Text(
                                'Humidity : ${item['humidity']}%',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 14 * s,
                                ),
                              ),
                              Text(
                                'Temperature : ${item['temperature']}° C',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 14 * s,
                                ),
                              ),
                              SizedBox(height: 8 * s),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  formattedDate,
                                  style: TextStyle(
                                    color: _muted,
                                    fontSize: 12 * s,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),

      // Floating button (bottom right)
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primary,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Add new history feature coming soon'),
            ),
          );
        },
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
