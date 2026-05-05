import 'package:flutter/material.dart';
import '../../widgets/app_drawer.dart';
import '../../models/worker_model.dart';
import 'add_edit_worker_screen.dart';

// Global dummy data so it persists across screen navigation
final List<Worker> globalWorkers = [
  Worker(
    id: '1',
    name: 'Rajesh Kumar',
    workerCode: 'W001',
    workerType: 'Permanent',
    shift: 'Day',
    phone: '9876543210',
  ),
  Worker(
    id: '2',
    name: 'Suresh Singh',
    workerCode: 'W002',
    workerType: 'Temporary',
    shift: 'Night',
  ),
  Worker(
    id: '3',
    name: 'Mahesh Babu',
    workerCode: 'W003',
    workerType: 'Permanent',
    shift: 'Both',
  ),
];

class WorkerListScreen extends StatefulWidget {
  const WorkerListScreen({super.key});

  @override
  State<WorkerListScreen> createState() => _WorkerListScreenState();
}

class _WorkerListScreenState extends State<WorkerListScreen> {
  // Use the global list
  final List<Worker> workers = globalWorkers;

  void _deleteWorker(String id) {
    setState(() {
      workers.removeWhere((w) => w.id == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Worker deleted')),
    );
  }

  Future<void> _navigateToAddEdit([Worker? worker]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditWorkerScreen(worker: worker),
      ),
    );

    if (result != null && result is Worker) {
      setState(() {
        if (worker == null) {
          workers.add(result);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Worker added')),
          );
        } else {
          final index = workers.indexWhere((w) => w.id == worker.id);
          if (index != -1) {
            workers[index] = result;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Worker updated')),
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
        title: const Text('Workers'),
      ),
      drawer: const AppDrawer(),
      body: ListView.builder(
        itemCount: workers.length,
        itemBuilder: (context, index) {
          final worker = workers[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            elevation: 2,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue[100],
                child: const Icon(Icons.person, color: Colors.blue),
              ),
              title: Text('${worker.name} (${worker.workerCode})'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('${worker.workerType} | ${worker.shift} Shift'),
                   if (worker.phone != null && worker.phone!.isNotEmpty) Text('Phone: ${worker.phone}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _navigateToAddEdit(worker),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteWorker(worker.id),
                  ),
                ],
              ),
              onTap: () => _navigateToAddEdit(worker),
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
}
