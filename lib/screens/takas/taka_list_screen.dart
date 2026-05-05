import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';
import '../../models/taka_model.dart';
import 'add_edit_taka_screen.dart';

// Global dummy data so it persists across screen navigation
final List<Taka> globalTakas = [
  Taka(
    id: '1',
    takaNumber: 'T-1001',
    machineId: 'm1',
    machineName: 'Loom 01',
    qualityId: 'q1',
    qualityName: 'Cotton 60s',
    targetMeters: 1000,
    totalMeters: 450.5,
    ratePerMeter: 12.5,
    status: 'Active',
    totalEarnings: 450.5 * 12.5,
    startDate: DateTime.now().subtract(const Duration(days: 2)),
  ),
  Taka(
    id: '2',
    takaNumber: 'T-1002',
    machineId: 'm2',
    machineName: 'Loom 02',
    qualityId: 'q2',
    qualityName: 'Polyester 40s',
    targetMeters: 1200,
    totalMeters: 1200,
    ratePerMeter: 9.75,
    status: 'Completed',
    totalEarnings: 1200 * 9.75,
    startDate: DateTime.now().subtract(const Duration(days: 5)),
    endDate: DateTime.now().subtract(const Duration(days: 1)),
  ),
];

class TakaListScreen extends StatefulWidget {
  const TakaListScreen({super.key});

  @override
  State<TakaListScreen> createState() => _TakaListScreenState();
}

class _TakaListScreenState extends State<TakaListScreen> {
  final List<Taka> takas = globalTakas;

  void _deleteTaka(String id) {
    setState(() {
      takas.removeWhere((t) => t.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Taka deleted')),
    );
  }

  Future<void> _navigateToAddEdit([Taka? taka]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditTakaScreen(taka: taka),
      ),
    );

    if (result != null && result is Taka) {
      setState(() {
        if (taka == null) {
          takas.add(result);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Taka added')),
          );
        } else {
          final index = takas.indexWhere((t) => t.id == taka.id);
          if (index != -1) {
            takas[index] = result;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Taka updated')),
            );
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Takas'),
      ),
      drawer: const AppDrawer(),
      body: ListView.builder(
        itemCount: takas.length,
        padding: const EdgeInsets.all(8.0),
        itemBuilder: (context, index) {
          final taka = takas[index];
          final progress = taka.targetMeters > 0 
              ? (taka.totalMeters / taka.targetMeters) 
              : 0.0;
              
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                     children: [
                       Expanded(child: Text(taka.takaNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                       Container(
                         padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                         decoration: BoxDecoration(
                           color: _getStatusColor(taka.status).withOpacity(0.1),
                           borderRadius: BorderRadius.circular(12),
                           border: Border.all(color: _getStatusColor(taka.status)),
                         ),
                         child: Text(
                           taka.status,
                           style: TextStyle(color: _getStatusColor(taka.status), fontSize: 12),
                         ),
                       ),
                       const SizedBox(width: 8),
                       InkWell(
                         onTap: () => _navigateToAddEdit(taka),
                         child: const Icon(Icons.edit, color: Colors.blue, size: 20),
                       ),
                       const SizedBox(width: 12),
                       InkWell(
                         onTap: () => _deleteTaka(taka.id),
                         child: const Icon(Icons.delete, color: Colors.red, size: 20),
                       ),
                     ],
                   ),
                   const SizedBox(height: 8),
                   Text('${taka.qualityName} | ${taka.machineName}'),
                   const SizedBox(height: 8),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text('Progress: ${(progress * 100).toStringAsFixed(1)}%'),
                       Text('${taka.totalMeters}/${taka.targetMeters} m'),
                     ],
                   ),
                   const SizedBox(height: 4),
                   LinearProgressIndicator(
                     value: progress.clamp(0.0, 1.0),
                     backgroundColor: Colors.grey[200],
                     color: _getStatusColor(taka.status),
                   ),
                    const SizedBox(height: 8),
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text('Rate: ₹${taka.ratePerMeter}'),
                       Text(
                         'Earned: ₹${taka.totalEarnings.toStringAsFixed(2)}',
                         style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                       ),
                     ],
                   ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToAddEdit(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active': return Colors.blue;
      case 'Completed': return Colors.purple;
      case 'Pending': return Colors.orange;
      case 'Cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }
}
