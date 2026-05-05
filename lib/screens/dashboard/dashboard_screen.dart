import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/theme.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/quick_action_button.dart';
import '../../services/auth_service.dart';
import '../login/login_screen.dart';
import '../machine_list_screen.dart';
import '../../widgets/app_drawer.dart';
import '../analytics/analytics_dashboard_screen.dart';
import '../workers/worker_list_screen.dart';
import '../takas/taka_list_screen.dart';
import '../productions/production_list_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isRefreshing = false;

  void _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    // Simulate refresh delay
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dashboard refreshed!')),
      );
    }
  }

  void _handleLogout() async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();
      if (mounted) {
        // Navigate back to Login and remove all previous routes
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      body: CustomScrollView(
        slivers: [
          // Custom App Bar / Header
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            backgroundColor: Theme.of(context).primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Top row: avatar + refresh pinned to top
                    Positioned(
                      top: 60,
                      left: 24,
                      right: 24,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const CircleAvatar(
                            backgroundColor: Colors.white24,
                            child: Icon(Icons.person, color: Colors.white),
                          ),
                          IconButton(
                            icon: _isRefreshing
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.refresh, color: Colors.white),
                            onPressed: _handleRefresh,
                          ),
                        ],
                      ),
                    ),
                    // Bottom text: pinned to bottom
                    Positioned(
                      bottom: 24,
                      left: 24,
                      right: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Text(
                            'Welcome Back!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Monitor your looms in real-time',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final String? safeUserId = context.watch<AuthService>().currentUser?.uid;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85, 
                      children: [
                        safeUserId == null ? const SizedBox() : StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').doc(safeUserId).collection('machines').snapshots(),
                          builder: (context, snapshot) {
                            final count = (snapshot.data?.docs.length ?? 0);
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const MachineListScreen(),
                                  ),
                                );
                              },
                              child: StatCard(
                                title: 'Total Machines',
                                value: count.toString(), // Machines are fully synced to DatabaseService natively
                                subtitle: 'Registered',
                                icon: Icons.precision_manufacturing,
                                color: Colors.blue,
                                trendValue: '',
                                isTrendUp: true,
                              ),
                            );
                          },
                        ),
                        safeUserId == null ? const SizedBox() : StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').doc(safeUserId).collection('workers').snapshots(),
                          builder: (context, snapshot) {
                            final docs = snapshot.data?.docs ?? [];
                            final count = docs.isEmpty ? globalWorkers.length : docs.length; // Fallback to dummy data
                            return GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const WorkerListScreen(),
                                  ),
                                );
                                if (mounted) setState(() {});
                              },
                              child: StatCard(
                                title: 'Total Workers',
                                value: count.toString(),
                                subtitle: 'Active',
                                icon: Icons.people,
                                color: Colors.green,
                                trendValue: '',
                                isTrendUp: true,
                              ),
                            );
                          },
                        ),
                        safeUserId == null ? const SizedBox() : StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').doc(safeUserId).collection('takas').snapshots(),
                          builder: (context, snapshot) {
                            final docs = snapshot.data?.docs ?? [];
                            final count = docs.isEmpty ? globalTakas.length : docs.length; // Fallback to dummy data
                            return GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const TakaListScreen(),
                                  ),
                                );
                                if (mounted) setState(() {});
                              },
                              child: StatCard(
                                title: 'Active Takas',
                                value: count.toString(),
                                subtitle: 'In Production',
                                icon: Icons.inventory_2,
                                color: Colors.amber,
                                trendValue: '',
                                isTrendUp: false,
                              ),
                            );
                          },
                        ),
                        safeUserId == null ? const SizedBox() : StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('users').doc(safeUserId).collection('productions').snapshots(),
                          builder: (context, snapshot) {
                            final docs = snapshot.data?.docs ?? [];
                            int totalMeters = 0;
                            if (docs.isNotEmpty) {
                              for(var doc in docs) {
                                final data = doc.data() as Map<String, dynamic>;
                                if (data['meters'] != null) {
                                  totalMeters += (data['meters'] as num).toInt();
                                }
                              }
                            } else {
                              for(var prod in globalProductions) {
                                totalMeters += prod.metersProduced.toInt();
                              }
                            }
                            final displayVal = docs.isEmpty ? '${totalMeters}m' : '${totalMeters > 0 ? totalMeters : docs.length}m';
                            return GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProductionListScreen(),
                                  ),
                                );
                                if (mounted) setState(() {});
                              },
                              child: StatCard(
                                title: 'Today\'s Prod.',
                                value: displayVal,
                                subtitle: 'Meters / Logs',
                                icon: Icons.trending_up,
                                color: Colors.purple,
                                trendValue: '',
                                isTrendUp: true,
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  }
                ),

                const SizedBox(height: 24),

                // Quick Actions
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: QuickActionButton(
                          icon: Icons.add_circle,
                          label: 'Production',
                          color: const Color(0xFF3B82F6), // Blue
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProductionListScreen(),
                              ),
                            );
                            if (mounted) setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: QuickActionButton(
                          icon: Icons.assignment_ind,
                          label: 'Worker',
                          color: const Color(0xFF10B981), // Green
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const WorkerListScreen(),
                              ),
                            );
                            if (mounted) setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: QuickActionButton(
                          icon: Icons.bar_chart,
                          label: 'Analytics',
                          color: const Color(0xFF4F46E5), // Indigo
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AnalyticsDashboardScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                
                // Shift Summary Placeholder
                Text(
                  'Shift Summary',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildShiftCard(
                  'Day Shift',
                  '2,140m',
                  '₹6,420',
                  Colors.amber,
                  Icons.wb_sunny,
                ),
                const SizedBox(height: 12),
                _buildShiftCard(
                  'Night Shift',
                  '1,950m',
                  '₹5,850',
                  Colors.indigo,
                  Icons.nightlight_round,
                ),
                const SizedBox(height: 50), // Bottom padding
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftCard(String title, String production, String earnings, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                Text(
                  production,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Earnings',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              Text(
                earnings,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
