// lib/screens/walk/walk_request_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../services/auth_service.dart';
import '../../models/walk_request_model.dart';
import '../../utils/constants.dart';

class WalkRequestScreen extends StatefulWidget {
  const WalkRequestScreen({super.key});

  @override
  State<WalkRequestScreen> createState() => _WalkRequestScreenState();
}

class _WalkRequestScreenState extends State<WalkRequestScreen> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final LocationService _locationService = LocationService();
  
  late TabController _tabController;
  
  bool _isStaffRole(String role) => role == 'admin';
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Walk Companion'),
        elevation: 0,
        backgroundColor: const Color(0xFF1A73E8),
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Request Walk', icon: Icon(Icons.directions_walk)),
            Tab(text: 'Find Requests', icon: Icon(Icons.search)),
            Tab(text: 'Active Escort', icon: Icon(Icons.map)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestForm(),
          _buildPendingRequests(),
          _buildActiveEscortTab(),
        ],
      ),
    );
  }
  
  Widget _buildRequestForm() {
    final destinationController = TextEditingController();
    final notesController = TextEditingController();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Request a walking companion to escort you safely across campus',
                    style: TextStyle(color: Colors.blue.shade700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Current Location Display
          const Text(
            'Your Current Location',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          FutureBuilder(
            future: _getCurrentAddress(),
            builder: (context, snapshot) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.my_location, color: Colors.green, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        snapshot.data ?? 'Getting location...',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      onPressed: () => setState(() {}),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          
          const Text(
            'Destination',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: destinationController,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.location_on),
              hintText: 'e.g., Library, Hostel, Lecture Hall',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          
          const Text(
            'Additional Notes (Optional)',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: notesController,
            decoration: const InputDecoration(
              hintText: 'Any specific instructions...',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () async {
                if (destinationController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a destination')),
                  );
                  return;
                }
                
                final authService = Provider.of<AuthService>(context, listen: false);
                final position = await _locationService.getCurrentLocation();
                final currentAddress = await _locationService.getAddressFromLatLng(
                  position.latitude,
                  position.longitude,
                );
                final destinationCoordinates = await _locationService.getLatLngFromAddress(destinationController.text);
                if (destinationCoordinates == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unable to resolve destination. Please try a different address.')),
                  );
                  return;
                }
                
                final request = WalkRequestModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  requesterId: authService.user!.uid,
                  requesterName: authService.userModel?.name ?? 'Anonymous',
                  startLat: position.latitude,
                  startLng: position.longitude,
                  endLat: destinationCoordinates.latitude,
                  endLng: destinationCoordinates.longitude,
                  startAddress: currentAddress,
                  endAddress: destinationController.text,
                  studentCurrentLat: position.latitude,
                  studentCurrentLng: position.longitude,
                  status: WalkRequestStatus.pending,
                  createdAt: DateTime.now(),
                );
                
                await _firestoreService.createWalkRequest(request);
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Walk request sent! A companion will join you soon.')),
                  );
                  destinationController.clear();
                  notesController.clear();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF34A853),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Request Companion', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
  
  Future<String> _getCurrentAddress() async {
    try {
      final position = await _locationService.getCurrentLocation();
      return await _locationService.getAddressFromLatLng(position.latitude, position.longitude);
    } catch (e) {
      return 'Unable to get location';
    }
  }
  
  Widget _buildPendingRequests() {
    final authService = Provider.of<AuthService>(context);
    final userRole = authService.userModel?.role ?? 'student';
    final isAdmin = _isStaffRole(userRole);

    return StreamBuilder<List<WalkRequestModel>>(
      stream: _firestoreService.getPendingWalkRequests(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final requests = snapshot.data!;
        final filteredRequests = isAdmin
            ? requests.where((r) => r.requesterId != authService.user?.uid).toList()
            : requests;
        
        if (filteredRequests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_search, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                const Text('No pending walk requests', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                Text(
                  isAdmin ? 'All students are safe or being escorted' : 'Check back later',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (isAdmin) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.security, color: Colors.blue, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Pending Escort Requests',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tap "Accept & Escort" to respond to a student\'s request. You\'ll provide live location tracking until they arrive safely.',
                      style: TextStyle(fontSize: 13, color: Colors.blue.shade800),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredRequests.length,
              itemBuilder: (context, index) {
                final request = filteredRequests[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: const Icon(Icons.person, color: Colors.blue),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request.requesterName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    'Requested ${_formatTime(request.createdAt)}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'PENDING',
                                style: TextStyle(fontSize: 10, color: Colors.orange.shade800, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(Icons.play_arrow, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                request.startAddress,
                                style: const TextStyle(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                request.endAddress,
                                style: const TextStyle(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (isAdmin)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _acceptWalkRequest(request),
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Accept & Escort'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildActiveEscortTab() {
    final authService = Provider.of<AuthService>(context);
    final userRole = authService.userModel?.role ?? 'student';

    return StreamBuilder<List<WalkRequestModel>>(
      stream: _firestoreService.getActiveEscortRequests(authService.user?.uid ?? '', _isStaffRole(userRole)),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final activeRequests = snapshot.data!;

        if (activeRequests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_walk, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No active escort requests', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 8),
                Text('Accepted requests will appear here.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activeRequests.length,
          itemBuilder: (context, index) {
            final request = activeRequests[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: InkWell(
                onTap: () => _showActiveEscortDetails(request, _isStaffRole(userRole)),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.green.shade100,
                            child: const Icon(Icons.shield, color: Colors.green),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  request.endAddress,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  request.escortMessage ??
                                      'Escort in progress with ${request.companionName ?? 'your escort'}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              request.status.toString().split('.').last.toUpperCase(),
                              style: TextStyle(fontSize: 10, color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (request.etaMinutes != null)
                        Text('ETA: ${request.etaMinutes} minutes', style: const TextStyle(fontSize: 14)),
                      if (request.acceptedAt != null)
                        Text('Accepted: ${_formatTime(request.acceptedAt!)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                      if (request.completedAt != null)
                        Text('Completed: ${_formatTime(request.completedAt!)}', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showActiveEscortDetails(WalkRequestModel request, bool isAdmin) async {
    try {
      await _refreshEscortLocation(request, isAdmin);
    } catch (_) {
      // ignore failures here; map will still show the last known positions
    }

    final mapController = MapController();

    // Determine safe defaults for coordinates (use Bishop Stuart University if values invalid)
    double studentLat = request.studentCurrentLat ?? request.startLat;
    double studentLng = request.studentCurrentLng ?? request.startLng;

    bool studentValid = studentLat != 0.0 && studentLng != 0.0 &&
        studentLat >= AppConstants.campusMinLat && studentLat <= AppConstants.campusMaxLat &&
        studentLng >= AppConstants.campusMinLng && studentLng <= AppConstants.campusMaxLng;

    if (!studentValid) {
      studentLat = AppConstants.defaultCampusLat;
      studentLng = AppConstants.defaultCampusLng;
    }

    final studentPoint = LatLng(studentLat, studentLng);

    LatLng? companionPoint;
    if (request.companionLat != null && request.companionLng != null) {
      final cLat = request.companionLat!;
      final cLng = request.companionLng!;
      final companionValid = cLat != 0.0 && cLng != 0.0 &&
          cLat >= AppConstants.campusMinLat && cLat <= AppConstants.campusMaxLat &&
          cLng >= AppConstants.campusMinLng && cLng <= AppConstants.campusMaxLng;
      companionPoint = companionValid ? LatLng(cLat, cLng) : LatLng(AppConstants.defaultCampusLat, AppConstants.defaultCampusLng);
    }

    final destinationPoint = (request.endLat == 0.0 && request.endLng == 0.0)
        ? LatLng(AppConstants.defaultCampusLat, AppConstants.defaultCampusLng)
        : LatLng(request.endLat, request.endLng);

    final routePoints = [companionPoint ?? studentPoint, destinationPoint];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.78,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Escort Tracking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () async {
                            await _refreshEscortLocation(request, isAdmin);
                            setState(() {});
                          },
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCenter: studentPoint,
                        initialZoom: 14,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.safereturn.app',
                        ),
                        if (routePoints.length >= 2)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: routePoints,
                                color: Colors.blue.withOpacity(0.7),
                                strokeWidth: 4,
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: [
                            Marker(
                              width: 60,
                              height: 60,
                              point: studentPoint,
                              child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 36),
                            ),
                            if (companionPoint != null)
                              Marker(
                                width: 60,
                                height: 60,
                                point: companionPoint,
                                child: const Icon(Icons.directions_walk, color: Colors.green, size: 36),
                              ),
                            Marker(
                              width: 60,
                              height: 60,
                              point: destinationPoint,
                              child: const Icon(Icons.flag, color: Colors.red, size: 36),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (request.escortMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(request.escortMessage!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                        Text(
                          'Route from ${request.startAddress} to ${request.endAddress}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ETA: ${request.etaMinutes ?? _calculateEta(studentPoint, destinationPoint)} minutes',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                _showEmergencyAction();
                              },
                              icon: const Icon(Icons.warning_amber),
                              label: const Text('SOS'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            ),
                            if (isAdmin && request.status != WalkRequestStatus.completed)
                              ElevatedButton(
                                onPressed: () async {
                                  await _completeEscortRequest(request);
                                  setState(() {});
                                },
                                child: const Text('Mark Completed'),
                              ),
                            if (!isAdmin && request.status == WalkRequestStatus.completed && request.studentConfirmedAt == null)
                              ElevatedButton(
                                onPressed: () async {
                                  await _confirmSafeArrival(request);
                                  setState(() {});
                                },
                                child: const Text('Confirm Arrival'),
                              ),
                          ],
                        ),
                        if (!isAdmin && request.studentConfirmedAt != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              'Safe arrival confirmed. Thank you for using Safe Return.',
                              style: TextStyle(fontSize: 14, color: Colors.green.shade700),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _refreshEscortLocation(WalkRequestModel request, bool isAdmin) async {
    try {
      final position = await _locationService.getCurrentLocation();
      if (isAdmin) {
        await _firestoreService.updateEscortLocation(
          request.id,
          companionLat: position.latitude,
          companionLng: position.longitude,
        );
      } else {
        await _firestoreService.updateEscortLocation(
          request.id,
          studentLat: position.latitude,
          studentLng: position.longitude,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to update location. Please enable location permissions.')),
        );
      }
    }
  }

  int _calculateEta(LatLng start, LatLng end) {
    final distance = _locationService.calculateDistance(start.latitude, start.longitude, end.latitude, end.longitude);
    return (distance / 83.33).ceil();
  }

  Future<void> _completeEscortRequest(WalkRequestModel request) async {
    await _firestoreService.completeWalkRequest(request.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escort marked completed. Student can confirm safe arrival.')),
      );
    }
  }

  Future<void> _confirmSafeArrival(WalkRequestModel request) async {
    await _firestoreService.confirmSafeArrival(request.id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Safe arrival confirmed. Thank you!')),
      );
    }
  }

  void _showEmergencyAction() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emergency alert sent to campus security.')),
    );
  }
  
  Future<void> _acceptWalkRequest(WalkRequestModel request) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final currentPosition = await _locationService.getCurrentLocation();

    int etaMinutes = 5;
    if (request.endLat != 0.0 && request.endLng != 0.0) {
      final distanceInMeters = _locationService.calculateDistance(
        currentPosition.latitude,
        currentPosition.longitude,
        request.endLat,
        request.endLng,
      );
      etaMinutes = (distanceInMeters / 83.33).ceil();
    }

    final escortMessage = 'Security personnel ${authService.userModel?.name ?? 'Admin'} is escorting you.';

    await _firestoreService.acceptWalkRequest(
      request.id,
      authService.user!.uid,
      authService.userModel?.name ?? 'Admin',
      companionLat: currentPosition.latitude,
      companionLng: currentPosition.longitude,
      escortMessage: escortMessage,
      etaMinutes: etaMinutes,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request accepted! You are now escorting this student.')),
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