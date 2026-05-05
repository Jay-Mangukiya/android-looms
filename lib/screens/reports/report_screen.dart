import 'dart:io';
import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/gradient_button.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../productions/production_list_screen.dart';
import '../workers/worker_list_screen.dart';
import '../takas/taka_list_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  DateTimeRange? _selectedDateRange;
  String _reportType = 'Production';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      drawer: const AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Select Date Range', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_selectedDateRange == null 
                          ? 'Choose Dates' 
                          : '${_selectedDateRange!.start.toString().split(' ')[0]} - ${_selectedDateRange!.end.toString().split(' ')[0]}'),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedDateRange = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<String>(
              value: _reportType,
              decoration: const InputDecoration(labelText: 'Report Type', border: OutlineInputBorder()),
              items: ['Production', 'Workers', 'Takas', 'Earnings'].map((String value) {
                return DropdownMenuItem<String>( value: value, child: Text(value) );
              }).toList(),
              onChanged: (newValue) => setState(() => _reportType = newValue!),
            ),
            const SizedBox(height: 24),
            
            GradientButton(
              text: 'Generate Report',
              onPressed: () {
                if (_selectedDateRange == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a date range')),
                  );
                  return;
                }
                
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GeneratedReportScreen(
                      dateRange: _selectedDateRange!,
                      reportType: _reportType,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class GeneratedReportScreen extends StatefulWidget {
  final DateTimeRange dateRange;
  final String reportType;

  const GeneratedReportScreen({
    super.key,
    required this.dateRange,
    required this.reportType,
  });

  @override
  State<GeneratedReportScreen> createState() => _GeneratedReportScreenState();
}

class _GeneratedReportScreenState extends State<GeneratedReportScreen> {
  bool _isDownloading = false;

  Future<void> _downloadReport(List<Map<String, String>> data) async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final pdf = pw.Document();

      // Prepare Headers & Rows
      final headers = data.isNotEmpty ? data.first.keys.toList() : <String>[];
      final rows = data.map((row) => row.values.toList()).toList();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('${widget.reportType} Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text('Date Range: ${widget.dateRange.start.toString().split(' ')[0]} to ${widget.dateRange.end.toString().split(' ')[0]}'),
                pw.SizedBox(height: 20),
                if (data.isNotEmpty)
                  pw.TableHelper.fromTextArray(
                    headers: headers,
                    data: rows,
                    border: pw.TableBorder.all(),
                    headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    cellAlignment: pw.Alignment.centerLeft,
                  )
                else
                  pw.Text('No data available for this report.'),
              ],
            );
          },
        ),
      );

      final bytes = await pdf.save();

      // Get Directory
      Directory? directory;
      if (Platform.isAndroid) {
         directory = await getExternalStorageDirectory();
         // fallback to app docs if external is null
         directory ??= await getApplicationDocumentsDirectory();
      } else {
         directory = await getApplicationDocumentsDirectory();
      }

      final String timeStamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = '${widget.reportType}_Report_$timeStamp.pdf';
      final String filePath = '${directory.path}/$fileName';

      final File file = File(filePath);
      await file.writeAsBytes(bytes);

      if (mounted) {
        // Using share_plus to invoke the OS target selection dialog
        // so the user can save to Files, Drive, Email, etc!
        await Share.shareXFiles([XFile(filePath)], text: '${widget.reportType} Report Generated!');
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report generated successfully! Select where to save or share it.', maxLines: 3), 
            duration: Duration(seconds: 4),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final startStr = widget.dateRange.start.toString().split(' ')[0];
    final endStr = widget.dateRange.end.toString().split(' ')[0];
    
    // Calculate end of day for the end date to include the entire last day
    final start = widget.dateRange.start;
    final end = widget.dateRange.end.add(const Duration(days: 1)); 
    
    List<Map<String, String>> data = [];

    if (widget.reportType == 'Production') {
      final filtered = globalProductions.where((p) => p.date.isAfter(start.subtract(const Duration(seconds: 1))) && p.date.isBefore(end)).toList();
      data = filtered.map((p) => {
        'Date': p.date.toString().split(' ')[0],
        'Machine': p.machineName,
        'Worker': p.workerName,
        'Taka No': p.takaNumber,
        'Meters': p.metersProduced.toStringAsFixed(1),
        'Earnings': '₹${p.earnings.toStringAsFixed(2)}',
      }).toList();
    } else if (widget.reportType == 'Workers') {
      data = globalWorkers.map((w) {
        final prods = globalProductions.where((p) => p.workerId == w.id && p.date.isAfter(start.subtract(const Duration(seconds: 1))) && p.date.isBefore(end));
        final totalMeters = prods.fold(0.0, (sum, p) => sum + p.metersProduced);
        final totalEarnings = prods.fold(0.0, (sum, p) => sum + p.earnings);
        return {
          'Name': w.name,
          'Shift': w.shift,
          'Total Meters': totalMeters.toStringAsFixed(1),
          'Earnings Generated': '₹${totalEarnings.toStringAsFixed(2)}',
        };
      }).toList();
    } else if (widget.reportType == 'Takas') {
      final filtered = globalTakas.where((t) => (t.startDate?.isBefore(end) ?? false) && (t.endDate == null || t.endDate!.isAfter(start.subtract(const Duration(seconds: 1))))).toList();
      data = filtered.map((t) {
        return {
          'Taka No': t.takaNumber,
          'Quality': t.qualityName,
          'Status': t.status,
          'Progress': '${t.totalMeters}/${t.targetMeters}m',
          'Earnings': '₹${t.totalEarnings.toStringAsFixed(2)}',
        };
      }).toList();
    } else {
      // Earnings Report
      final filtered = globalProductions.where((p) => p.date.isAfter(start.subtract(const Duration(seconds: 1))) && p.date.isBefore(end)).toList();
      
      // Group by Date
      Map<String, double> dailyEarnings = {};
      for (var p in filtered) {
        final dateStr = p.date.toString().split(' ')[0];
        dailyEarnings[dateStr] = (dailyEarnings[dateStr] ?? 0.0) + p.earnings;
      }
      
      final sortedDates = dailyEarnings.keys.toList()..sort();
      double totalPeriodEarnings = 0;
      
      data = sortedDates.map((dateStr) {
        final amt = dailyEarnings[dateStr]!;
        totalPeriodEarnings += amt;
        return {
          'Date': dateStr,
          'Amount': '₹${amt.toStringAsFixed(2)}',
        };
      }).toList();
      
      // Add a total row at the bottom
      if (data.isNotEmpty) {
        data.add({
          'Date': 'TOTAL',
          'Amount': '₹${totalPeriodEarnings.toStringAsFixed(2)}',
        });
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.reportType} Report'),
        actions: [
          _isDownloading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _downloadReport(data),
                )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                     Text(
                      '${widget.reportType} Summary',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('From: $startStr  To: $endStr'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: data.first.keys
                        .map((key) => DataColumn(label: Text(key, style: const TextStyle(fontWeight: FontWeight.bold))))
                        .toList(),
                    rows: data.map((row) {
                      return DataRow(
                        cells: row.values.map((value) => DataCell(Text(value))).toList(),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
