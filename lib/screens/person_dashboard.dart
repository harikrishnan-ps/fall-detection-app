import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../services/fall_detection_service.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../models/alert_model.dart';
import '../widgets/status_indicator.dart';
import '../widgets/custom_button.dart';
import '../widgets/alert_card.dart';
import '../utils/theme.dart';

class PersonDashboard extends StatefulWidget {
  const PersonDashboard({super.key});

  @override
  State<PersonDashboard> createState() => _PersonDashboardState();
}

class _PersonDashboardState extends State<PersonDashboard> {
  final DatabaseService _databaseService = DatabaseService();
  final NotificationService _notificationService = NotificationService();
  bool _showCountdownDialog = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _notificationService.initialize();
    
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.currentUser != null) {
      await _notificationService.saveTokenForUser(authService.currentUser!.uid);
    }

    // Set up fall detection callbacks
    final fallService = Provider.of<FallDetectionService>(context, listen: false);
    fallService.onFallConfirmed = _handleFallConfirmed;
    fallService.onAlertCancelled = _handleAlertCancelled;
  }

  Future<void> _handleFallConfirmed() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUserModel;
    
    if (user == null) return;

    // Get location
    Position? position;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.denied && 
            permission != LocationPermission.deniedForever) {
          position = await Geolocator.getCurrentPosition();
        }
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }

    // Create alert
    AlertModel alert = AlertModel(
      alertId: '',
      personId: user.uid,
      personName: user.name,
      timestamp: DateTime.now(),
      location: LocationData(
        latitude: position?.latitude ?? 0.0,
        longitude: position?.longitude ?? 0.0,
      ),
    );

    // Save to database
    await _databaseService.createAlert(alert);

    // Send notifications to caregivers
    await _notificationService.sendFallAlertToCaregivers(
      user.linkedUsers,
      alert,
    );

    // Show local notification
    await _notificationService.showLocalNotification(
      title: 'Fall Alert Sent',
      body: 'Your caregivers have been notified',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Alert sent to caregivers'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleAlertCancelled() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alert cancelled'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _sendManualAlert() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send SOS Alert'),
        content: const Text(
          'This will immediately notify your caregivers. Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accentColor),
            child: const Text('Send Alert'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _handleFallConfirmed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final fallService = Provider.of<FallDetectionService>(context);
    final user = authService.currentUserModel;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show countdown dialog
    if (fallService.state == FallDetectionState.countdownActive && !_showCountdownDialog) {
      _showCountdownDialog = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showFallDetectedDialog();
      });
    } else if (fallService.state != FallDetectionState.countdownActive) {
      _showCountdownDialog = false;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fall Detection'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${user.name}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your safety is being monitored',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Status card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Monitoring Status',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          StatusIndicator(
                            isActive: fallService.isMonitoring,
                            activeText: 'Active',
                            inactiveText: 'Inactive',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      CustomButton(
                        text: fallService.isMonitoring ? 'Stop Monitoring' : 'Start Monitoring',
                        icon: fallService.isMonitoring ? Icons.stop : Icons.play_arrow,
                        backgroundColor: fallService.isMonitoring 
                            ? AppTheme.accentColor 
                            : AppTheme.successColor,
                        onPressed: () {
                          if (fallService.isMonitoring) {
                            fallService.stopMonitoring();
                            _notificationService.cancelMonitoringNotification();
                          } else {
                            fallService.startMonitoring();
                            _notificationService.showMonitoringNotification();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Emergency SOS button
              Card(
                color: AppTheme.accentColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        size: 48,
                        color: AppTheme.accentColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Emergency SOS',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to manually alert your caregivers',
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      CustomButton(
                        text: 'Send SOS Alert',
                        icon: Icons.emergency,
                        backgroundColor: AppTheme.accentColor,
                        onPressed: _sendManualAlert,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Linked caregivers
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Linked Caregivers',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      if (user.linkedUsers.isEmpty)
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.person_add_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No caregivers linked yet',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: () {
                                  // Navigate to add caregiver screen
                                },
                                child: const Text('Add Caregiver'),
                              ),
                            ],
                          ),
                        )
                      else
                        Text('${user.linkedUsers.length} caregivers monitoring you'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Recent alerts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Alerts',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/alert-history');
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              StreamBuilder<List<AlertModel>>(
                stream: _databaseService.getAlertsForPerson(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Center(
                          child: Text(
                            'No alerts yet',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ),
                    );
                  }
                  
                  final alerts = snapshot.data!.take(3).toList();
                  return Column(
                    children: alerts
                        .map((alert) => AlertCard(alert: alert))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFallDetectedDialog() {
    final fallService = Provider.of<FallDetectionService>(context, listen: false);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Consumer<FallDetectionService>(
        builder: (context, service, child) {
          if (service.state != FallDetectionState.countdownActive) {
            Navigator.of(context).pop();
            return const SizedBox.shrink();
          }

          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppTheme.accentColor),
                const SizedBox(width: 12),
                const Text('Fall Detected!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Are you okay?',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                Text(
                  'Alert will be sent in',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${service.countdownSeconds}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('seconds'),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  service.cancelAlert();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.successColor,
                ),
                child: const Text("I'm Okay - Cancel Alert"),
              ),
            ],
          );
        },
      ),
    );
  }
}
