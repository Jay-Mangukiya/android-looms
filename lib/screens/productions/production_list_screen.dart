import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';
import '../../models/production_model.dart';
import 'add_edit_production_screen.dart';

// Global dummy data so it persists across screen navigation
final List<Production> globalProductions = [
  Production(
    id: '1',
    date: DateTime.now(),
    machineId: 'm1',
    machineName: 'Loom 01',
    workerId: 'w1',
    workerName: 'Ram Kumar',
    takaId: 't1',
    takaNumber: 'Taka-101',
    shift: 'Day',
    metersProduced: 120.5,
    earnings: 1205.0,
  ),
  Production(
    id: '2',
    date: DateTime.now().subtract(const Duration(days: 1)),
    machineId: 'm2',
    machineName: 'Loom 02',
    workerId: 'w2',
    workerName: 'Shyam Singh',
    takaId: 't2',
    takaNumber: 'Taka-102',
    shift: 'Night',
    metersProduced: 115.0,
    earnings: 1150.0,
  ),
];

class ProductionListScreen extends StatefulWidget {
  const ProductionListScreen({super.key});

  @override
  State<ProductionListScreen> createState() => _ProductionListScreenState();
}

class _ProductionListScreenState extends State<ProductionListScreen> {
  // Use the global list
  final List<Production> productions = globalProductions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productions'),
      ),
      drawer: const AppDrawer(),
      body: ListView.builder(
        itemCount: productions.length,
        itemBuilder: (context, index) {
          final production = productions[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: production.shift == 'Day' ? Colors.orange[100] : Colors.blue[100],
                child: Icon(
                  production.shift == 'Day' ? Icons.wb_sunny : Icons.nightlight_round,
                  color: production.shift == 'Day' ? Colors.orange : Colors.blue,
                ),
              ),
              title: Text('${production.machineName} - ${production.workerName}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Taka: ${production.takaNumber} | Mtrs: ${production.metersProduced}'),
                  Text(
                    'Date: ${production.date.toString().split(' ')[0]}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '₹${production.earnings.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () async {
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AddEditProductionScreen(production: production),
                        ),
                      );
                      if (updated != null && updated is Production) {
                        setState(() {
                          final prodIndex = productions.indexWhere((p) => p.id == updated.id);
                          if (prodIndex != -1) {
                            productions[prodIndex] = updated;
                          }
                        });
                      }
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _confirmDelete(context, production);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newProduction = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditProductionScreen()),
          );
          if (newProduction != null && newProduction is Production) {
            setState(() {
              productions.add(newProduction);
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Production production) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Production'),
        content: const Text('Are you sure you want to delete this production record?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                productions.removeWhere((p) => p.id == production.id);
              });
              Navigator.pop(dialogContext); // Close dialog
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Production deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
