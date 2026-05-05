import 'dart:io';
import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/gradient_button.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

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
    
    // Generate dummy data based on report type
    List<Map<String, String>> data = [];
    if (widget.reportType == 'Production') {
      data = [
        {'Date': startStr, 'Machine': 'Loom 01', 'Meters': '450.5'},
        {'Date': startStr, 'Machine': 'Loom 02', 'Meters': '620.0'},
        {'Date': endStr, 'Machine': 'Loom 01', 'Meters': '490.2'},
      ];
    } else if (widget.reportType == 'Workers') {
      data = [
        {'Name': 'Rajesh Kumar', 'Shift': 'Day', 'Attendance': '95%'},
        {'Name': 'Suresh Singh', 'Shift': 'Night', 'Attendance': '88%'},
      ];
    } else if (widget.reportType == 'Takas') {
      data = [
        {'Taka No': 'T-1001', 'Status': 'Completed', 'Meters': '1000'},
        {'Taka No': 'T-1002', 'Status': 'Active', 'Meters': '450'},
      ];
    } else {
      data = [
        {'Date': startStr, 'Amount': '₹12,450'},
        {'Date': endStr, 'Amount': '₹14,200'},
      ];
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
