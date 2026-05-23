// lib/screens/feed/safety_feed_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../services/auth_service.dart';
import '../../models/alert_model.dart';
import '../../widgets/alert_card.dart';
import '../../utils/constants.dart';

class SafetyFeedScreen extends StatefulWidget {
  const SafetyFeedScreen({super.key});

  @override
  State<SafetyFeedScreen> createState() => _SafetyFeedScreenState();
}

class _SafetyFeedScreenState extends State<SafetyFeedScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  
  LatLng? _currentLocation;
  final MapController _mapController = MapController();
  
  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }
  
  Future<void> _getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_currentLocation!, 15);
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() {
        _currentLocation = LatLng(
          AppConstants.defaultCampusLat,
          AppConstants.defaultCampusLng,
        );
      });
      _mapController.move(_currentLocation!, 15);
      // Show permission dialog but still display the campus map.
      _showLocationPermissionDialog();
    }
  }
  
  void _showLocationPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Needed'),
        content: const Text('Please enable location permissions to use safety features.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Feed'),
        elevation: 0,
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _getCurrentLocation,
          ),
        ],
      ),
      body: StreamBuilder<List<AlertModel>>(
        stream: _firestoreService.getActiveAlerts(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final alerts = snapshot.data!;
          
          return Column(
            children: [
              // Map View
              Expanded(
                flex: 2,
                child: _currentLocation == null
                    ? const Center(child: CircularProgressIndicator())
                    : FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _currentLocation!,
                          initialZoom: 15,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.safereturn.app',
                          ),
                          MarkerLayer(
                            markers: [
                              // User location marker
                              Marker(
                                width: 80,
                                height: 80,
                                point: _currentLocation!,
                                child: const Icon(
                                  Icons.my_location,
                                  color: Colors.blue,
                                  size: 32,
                                ),
                              ),
                              // Alert markers
                              ...alerts.map((alert) => Marker(
                                width: 80,
                                height: 80,
                                point: LatLng(alert.latitude, alert.longitude),
                                child: GestureDetector(
                                  onTap: () {
                                    _showAlertDetails(alert);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: _getAlertColor(alert.type).withOpacity(0.8),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: Icon(
                                      _getAlertIcon(alert.type),
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              )),
                            ],
                          ),
                        ],
                      ),
              ),
              
              // Alerts List
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: alerts.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_none, size: 48, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No active alerts', style: TextStyle(color: Colors.grey)),
                              SizedBox(height: 8),
                              Text('Tap + to report an alert', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: alerts.length,
                          itemBuilder: (context, index) {
                            return AlertCard(
                              alert: alerts[index],
                              onReport: () => _reportAlert(alerts[index].id),
                            );
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showReportAlertDialog,
        icon: const Icon(Icons.warning_amber),
        label: const Text('Report Alert'),
        backgroundColor: Colors.red,
      ),
    );
  }
  
  Color _getAlertColor(AlertType type) {
    switch (type) {
      case AlertType.danger:
        return Colors.red;
      case AlertType.warning:
        return Colors.orange;
      case AlertType.info:
        return Colors.blue;
    }
  }
  
  IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.danger:
        return Icons.warning;
      case AlertType.warning:
        return Icons.info_outline;
      case AlertType.info:
        return Icons.info;
    }
  }
  
  void _showAlertDetails(AlertModel alert) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _getAlertColor(alert.type).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_getAlertIcon(alert.type), color: _getAlertColor(alert.type)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert.title,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Reported by ${alert.userName} • ${_formatTime(alert.createdAt)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(alert.description),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _reportAlert(alert.id);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.flag),
                      label: Text('Report (${alert.reportCount})'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      label: const Text('Close'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
  
  void _showReportAlertDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    AlertType selectedType = AlertType.warning;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Report an Alert', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Help keep campus safe by reporting incidents', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 16),
                  const Text('Alert Type', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  SegmentedButton<AlertType>(
                    segments: const [
                      ButtonSegment(value: AlertType.danger, label: Text('Danger', style: TextStyle(fontSize: 12))),
                      ButtonSegment(value: AlertType.warning, label: Text('Warning', style: TextStyle(fontSize: 12))),
                      ButtonSegment(value: AlertType.info, label: Text('Info', style: TextStyle(fontSize: 12))),
                    ],
                    selected: {selectedType},
                    onSelectionChanged: (Set<AlertType> newSelection) {
                      setState(() {
                        selectedType = newSelection.first;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Brief description of the situation',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Provide more details...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (titleController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a title')),
                              );
                              return;
                            }
                            
                            final authService = Provider.of<AuthService>(context, listen: false);
                            final position = await _locationService.getCurrentLocation();
                            
                            final alert = AlertModel(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              userId: authService.user?.uid ?? 'unknown',
                              userName: authService.userModel?.name ?? 'Anonymous',
                              userRole: authService.userModel?.role ?? 'student',
                              title: titleController.text,
                              description: descriptionController.text,
                              type: selectedType,
                              status: AlertStatus.active,
                              latitude: position.latitude,
                              longitude: position.longitude,
                              createdAt: DateTime.now(),
                              reportCount: 0,
                            );
                            
                            await _firestoreService.addAlert(alert);
                            Navigator.pop(context);
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Alert reported successfully')),
                              );
                              titleController.clear();
                              descriptionController.clear();
                            }
                          },
                          child: const Text('Submit'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  Future<void> _reportAlert(String alertId) async {
    await _firestoreService.reportAlert(alertId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alert reported')),
      );
    }
  }
  
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} minutes ago';
    if (difference.inDays < 1) return '${difference.inHours} hours ago';
    return '${difference.inDays} days ago';
  }
}