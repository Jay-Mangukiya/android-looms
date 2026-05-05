import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../services/notification_service.dart';
import '../../widgets/app_drawer.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();
  List<PendingNotificationRequest> _pendingNotifications = [];
  String? _fcmToken;
  bool _permissionGranted = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
    _loadData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final token = await _notificationService.getFCMToken();
    final pending = await _notificationService.getPendingNotifications();
    if (mounted) {
      setState(() {
        _fcmToken = token;
        _pendingNotifications = pending;
      });
    }
  }

  Future<void> _requestPermission() async {
    final granted = await _notificationService.requestPermission();
    setState(() => _permissionGranted = granted);
    _showSnackBar(
      granted ? '✅ Notification permission granted!' : '❌ Permission denied',
      granted ? Colors.green : Colors.red,
    );
  }

  // ── Instant notification ──────────────────────────────────────────────────
  Future<void> _showInstantNotification() async {
    await _notificationService.showInstantNotification(
      id: 1,
      title: '🏭 Production Alert',
      body: 'Machine #12 has completed today\'s production target of 500m!',
      payload: '/dashboard',
    );
    _showSnackBar('Instant notification sent!', const Color(0xFF4F46E5));
  }

  // ── Scheduled – 10 seconds ────────────────────────────────────────────────
  Future<void> _scheduleIn10Seconds() async {
    await _notificationService.scheduleNotification(
      id: 2,
      title: '⏰ Shift Reminder',
      body: 'Your Night Shift starts in 30 minutes. Please prepare the looms.',
      delay: const Duration(seconds: 10),
      payload: '/dashboard',
    );
    _showSnackBar('Notification scheduled in 10 seconds!', Colors.orange);
    await _refreshPending();
  }

  // ── Scheduled – 1 minute ─────────────────────────────────────────────────
  Future<void> _scheduleIn1Minute() async {
    await _notificationService.scheduleNotification(
      id: 3,
      title: '📋 Task Due',
      body: 'Taka #47 quality check is due. Review the production report.',
      delay: const Duration(minutes: 1),
      payload: '/dashboard',
    );
    _showSnackBar('Notification scheduled in 1 minute!', Colors.orange);
    await _refreshPending();
  }

  // ── Daily morning reminder ────────────────────────────────────────────────
  Future<void> _scheduleDailyReminder() async {
    await _notificationService.scheduleDailyReminder(
      id: 10,
      title: '🌅 Good Morning – Looms',
      body: 'Day shift starts soon. Check today\'s production plan.',
      hour: 8,
      minute: 0,
      payload: '/dashboard',
    );
    _showSnackBar('Daily 8:00 AM reminder set!', Colors.teal);
    await _refreshPending();
  }

  // ── Worker shift reminder ─────────────────────────────────────────────────
  Future<void> _scheduleShiftReminder() async {
    await _notificationService.scheduleDailyReminder(
      id: 11,
      title: '🌙 Night Shift Alert',
      body: 'Night shift begins soon. Handover notes from day workers.',
      hour: 20,
      minute: 0,
      payload: '/dashboard',
    );
    _showSnackBar('Daily 8:00 PM shift reminder set!', Colors.deepPurple);
    await _refreshPending();
  }

  // ── Cancel all ────────────────────────────────────────────────────────────
  Future<void> _cancelAll() async {
    await _notificationService.cancelAllNotifications();
    _showSnackBar('All notifications cancelled.', Colors.grey);
    await _refreshPending();
  }

  Future<void> _refreshPending() async {
    final pending = await _notificationService.getPendingNotifications();
    setState(() => _pendingNotifications = pending);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      drawer: const AppDrawer(),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 160,
              pinned: true,
              floating: false,
              backgroundColor: const Color(0xFF4F46E5),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -30,
                        right: -30,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.07),
                          ),
                        ),
                      ),
                      const Positioned(
                        bottom: 24,
                        left: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Notifications',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Manage local & push alerts',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
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

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── STEP 1: Permission ─────────────────────────────────────
                  _sectionTitle('STEP 1 – Request Permission'),
                  _actionCard(
                    icon: _permissionGranted
                        ? Icons.notifications_active
                        : Icons.notifications_active,
                    title: _permissionGranted
                        ? 'Permission Granted ✅'
                        : 'Enable Notifications',
                    subtitle: 'Grant POST_NOTIFICATIONS permission (Android 13+)',
                    color: _permissionGranted
                        ? const Color(0xFF059669)
                        : const Color(0xFFDC2626),
                    onTap: _requestPermission,
                    buttonLabel: _permissionGranted ? 'Granted' : 'Request',
                  ),
                  const SizedBox(height: 20),

                  // ── STEP 3: Instant Notification ──────────────────────────
                  _sectionTitle('STEP 3 – Instant Notification'),
                  _actionCard(
                    icon: Icons.flash_on,
                    title: 'Show Instant Notification',
                    subtitle: 'Triggers a high-priority notification immediately',
                    color: const Color(0xFF4F46E5),
                    onTap: _showInstantNotification,
                    buttonLabel: 'Send Now',
                  ),
                  const SizedBox(height: 20),

                  // ── STEP 4: Scheduled Notifications ─────────────────────────
                  _sectionTitle('STEP 4 – Scheduled Notifications'),
                  _twoColumnRow(
                    _miniActionCard(
                      icon: Icons.schedule,
                      title: 'In 10 Seconds',
                      subtitle: 'Shift reminder',
                      color: Colors.orange,
                      onTap: _scheduleIn10Seconds,
                    ),
                    _miniActionCard(
                      icon: Icons.timer,
                      title: 'In 1 Minute',
                      subtitle: 'Task due alert',
                      color: Colors.deepOrange,
                      onTap: _scheduleIn1Minute,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _twoColumnRow(
                    _miniActionCard(
                      icon: Icons.wb_sunny,
                      title: 'Daily 8:00 AM',
                      subtitle: 'Morning reminder',
                      color: Colors.amber,
                      onTap: _scheduleDailyReminder,
                    ),
                    _miniActionCard(
                      icon: Icons.nightlight_round,
                      title: 'Daily 8:00 PM',
                      subtitle: 'Night shift',
                      color: Colors.indigo,
                      onTap: _scheduleShiftReminder,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── STEP 5: FCM Token ───────────────────────────────────────
                  _sectionTitle('STEP 5 – FCM Push (Device Token)'),
                  _fcmTokenCard(),
                  const SizedBox(height: 20),

                  // ── Pending Notifications ────────────────────────────────────
                  _sectionTitle('Pending Scheduled Notifications'),
                  _pendingCard(),
                  const SizedBox(height: 20),

                  // ── Cancel All ──────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _cancelAll,
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                      label: const Text(
                        'Cancel All Notifications',
                        style: TextStyle(color: Colors.red),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────────────

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required String buttonLabel,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style:
                        TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(buttonLabel,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _miniActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11)),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Schedule',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _twoColumnRow(Widget left, Widget right) {
    return Row(
      children: [left, const SizedBox(width: 12), right],
    );
  }

  Widget _fcmTokenCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5).withOpacity(0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF4F46E5).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.key, color: Color(0xFF4F46E5), size: 20),
              const SizedBox(width: 8),
              const Text('FCM Device Token',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, color: Color(0xFF4F46E5))),
              const Spacer(),
              GestureDetector(
                onTap: _loadData,
                child: const Icon(Icons.refresh,
                    size: 18, color: Color(0xFF4F46E5)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _fcmToken == null
              ? const Text('Loading token...',
                  style: TextStyle(color: Colors.grey, fontSize: 12))
              : SelectableText(
                  _fcmToken!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: Color(0xFF374151),
                    height: 1.5,
                  ),
                ),
          const SizedBox(height: 10),
          const Text(
            '💡 Use this token in Firebase Console → Cloud Messaging to send a push notification to this device.',
            style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _pendingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pending_actions, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                '${_pendingNotifications.length} Pending',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _refreshPending,
                child: const Icon(Icons.refresh, size: 18, color: Colors.grey),
              ),
            ],
          ),
          if (_pendingNotifications.isEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'No pending scheduled notifications.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ] else ...[
            const SizedBox(height: 8),
            ..._pendingNotifications.map((n) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '[ID: ${n.id}] ${n.title ?? 'No title'}',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
