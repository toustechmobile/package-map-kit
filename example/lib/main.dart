import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:map_kit/core/ui_map_controller.dart';
import 'package:map_kit/enums/map_provider.dart';
import 'package:map_kit/models/circle_model.dart';
import 'package:map_kit/models/map_bounds_model.dart';
import 'package:map_kit/models/marker_model.dart';
import 'package:map_kit/models/move_model.dart';
import 'package:map_kit/models/poly_line_model.dart';
import 'package:map_kit/models/poly_line_point_model.dart';
import 'package:map_kit/models/circle_polyline_model.dart';
import 'package:map_kit/models/user_marker.dart';
import 'package:map_kit/ui_map.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Map Kit Comprehensive Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MapExampleScreen(),
    );
  }
}

class MapExampleScreen extends StatefulWidget {
  const MapExampleScreen({super.key});

  @override
  State<MapExampleScreen> createState() => _MapExampleScreenState();
}

class _MapExampleScreenState extends State<MapExampleScreen> {
  late final UiMapController mapController;
  MapProvider currentProvider = MapProvider.neshan;
  bool isDarkMode = false;
  List<CirclePolylineModel> circlePolylines = [];

  final LatLng initialCenter = const LatLng(36.3156692, 59.5405541);

  final List<MarkerModel> initialMarkers = [
    MarkerModel(
      latitude: 36.3156692,
      longitude: 59.5405541,
      data: "Center Marker",
      icon: 'ic_map_tour_waiting_icon.svg',
      iconSize: 28,
      markerContent: 'C',
      snippetTitle: 'Center Marker',
      snippetDescription: 'This is the initial center point.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    mapController = UiMapController();
  }

  Future<void> requestEnableGps() async {
    Location location = Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }
  }

  void _showSnackBar(String message, [BuildContext? c]) {
    ScaffoldMessenger.of(c ?? context).clearSnackBars();
    ScaffoldMessenger.of(c ?? context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  void _addMoreMarkers() {
    mapController.addMarkers([
      MarkerModel(
        latitude: 36.324915,
        longitude: 59.549043,
        data: "Dynamic Marker 1",
        markerContent: '1',
        iconSize: 28,
        icon: 'ic_map_tour_waiting_icon.svg',
        snippetTitle: 'Added Marker',
      ),
    ]);
    _showSnackBar("Markers Added");
  }

  void _addCircles() {
    mapController.addCircles([
      CircleModel(
        latitude: 36.322098,
        longitude: 59.523694,
        radius: 700,
        color: Colors.blue.withOpacity(0.5),
        borderColor: Colors.blue,
        data: 'Blue Circle',
        snippetTitle: 'Blue Zone',
        snippetDescription: 'Dynamic radius zone',
      ),
      CircleModel(
        latitude: 36.333773,
        longitude: 59.545900,
        radius: 500,
        color: Colors.deepOrange.withOpacity(0.5),
        borderColor: Colors.deepOrange,
        data: 'Orange Circle',
      )
    ]);
    _showSnackBar("Circles Added");
  }

  void _addPolyline() {
    mapController.addPolyline([
      PolyLineModel(points: [
        PolyLinePointModel(36.319613, 59.527629, 0),
        PolyLinePointModel(36.320350, 59.525429, 45),
        PolyLinePointModel(36.321328, 59.525154, 90),
        PolyLinePointModel(36.322913, 59.525892, 120),
      ], color: Colors.blue, strokeWidth: 5, strokeColor: Colors.red, data: "Polyline Data"),
    ]);
    _showSnackBar("Polyline Added");
  }

  void _moveCamera() {
    mapController.moveCamera(
      MoveModel(latitude: 36.3219744, longitude: 59.5381364, zoom: 16),
    );
    _showSnackBar("Camera Moved");
  }

  void _fitBounds() {
    mapController.fitBounds(
      MapBoundsModel(
        points: [
          const LatLng(36.319613, 59.527629),
          const LatLng(36.322913, 59.525892),
        ],
        padding: 50,
      ),
    );
    _showSnackBar("Camera Fit to Bounds");
  }

  void _setMockUserLocation() {
    mapController.setUserLocation!(
      UserMarkerModel(latitude: 36.318000, longitude: 59.535000, accuracy: 1),
    );
    _showSnackBar("Mock User Location Set");
  }

  void _toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
    mapController.setDarkMode(isDarkMode);
    _showSnackBar(isDarkMode ? "Dark Mode Enabled" : "Light Mode Enabled");
  }

  void _getCurrentCameraState() async {
    try {
      // 1. Await the getter seamlessly!
      final currentCamera = await mapController.camera;

      final lat = currentCamera.center.latitude.toStringAsFixed(4);
      final lng = currentCamera.center.longitude.toStringAsFixed(4);
      final zoom = currentCamera.zoom.toStringAsFixed(1);

      _showSnackBar("Camera Target: $lat, $lng | Zoom: $zoom");
    } catch (e) {
      _showSnackBar("Failed to get camera: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Kit'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<MapProvider>(
              value: currentProvider,
              dropdownColor: Theme.of(context).colorScheme.surface,
              underline: const SizedBox(),
              items: MapProvider.values.map((provider) {
                return DropdownMenuItem(
                  value: provider,
                  child: Text(provider.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (newProvider) {
                if (newProvider != null) {
                  setState(() => currentProvider = newProvider);
                  _showSnackBar("Switched to ${newProvider.name}");
                }
              },
            ),
          )
        ],
      ),
      body: Stack(
        children: [
          UiMap(
            key: ValueKey(currentProvider.toString()),
            mapProvider: currentProvider,
            controller: mapController,
            initialCenter: initialCenter,
            isDarkMode: isDarkMode,
            zoom: 15,
            markers: List.from(initialMarkers),
            onMarkerTap: (markerData, point) {
              if (markerData is MarkerModel) {
                _showSnackBar("Tapped Marker: ${markerData.data ?? 'Unknown'}", context);
                return;
              }
              _showSnackBar("Tapped Circle: ${markerData ?? 'Unknown'}", context);
            },
            onCircleTap: (circleData, point) {
              if (circleData is CircleModel) {
                _showSnackBar("Tapped Circle: ${circleData.data ?? 'Unknown'}", context);
                return;
              }
              _showSnackBar("Tapped Circle: ${circleData ?? 'Unknown'}", context);
            },
            onTap: (LatLng point) {
              for (var e in circlePolylines) {
                if (e.isPointInside(point)) {
                  _showSnackBar(
                      "${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)} inside of circle polyline ${e.data}");
                } else {
                  _showSnackBar(
                      "${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)} outside of circle");
                }
              }

              mapController.addMarkers([
                MarkerModel(
                  latitude: point.latitude,
                  longitude: point.longitude,
                  data: "Tap Dropped Marker",
                  iconSize: 40,
                  icon: 'ic_map_tour_icon.svg',
                )
              ]);
              // _showSnackBar(
              //     "Dropped Marker at ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)}");
            },
            onLongPress: (LatLng point) {
              CirclePolylineModel e = CirclePolylineModel(
                  center: point,
                  radius: 500,
                  strokeWidth: 1,
                  strokeColor: Colors.purple,
                  color: Colors.purple,
                  data: circlePolylines.length + 1);
              circlePolylines.add(e);
              mapController.addPolyline([e]);
              // mapController.addCircles([
              //   CircleModel(
              //     latitude: point.latitude,
              //     longitude: point.longitude,
              //     radius: 150,
              //     borderColor: Colors.purple,
              //     color: Colors.purple.withOpacity(.5),
              //     borderStroke: 2,
              //     data: "Long Press Circle",
              //   )
              // ]);
              // _showSnackBar("Dropped Circle at ${point.latitude.toStringAsFixed(4)}");
            },
            onPolylineTap: (data, point) {
              print("Polyline$point");
              _showSnackBar("Tapped Polyline: ${data ?? 'Unknown'}", context);
            },
          ),
          Positioned(
            bottom: 24,
            left: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 8,
              children: [
                FloatingActionButton(
                  onPressed: requestEnableGps,
                  child: const Icon(Icons.gps_fixed_rounded),
                ),
                FloatingActionButton.extended(
                  onPressed: _openControlPanel,
                  icon: const Icon(Icons.dashboard_customize),
                  label: const Text("Controls"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openControlPanel() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      "Map Controllers",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Divider(height: 30),
                  const Text("Add Elements", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(label: const Text('+ Markers'), onPressed: _addMoreMarkers),
                      ActionChip(label: const Text('+ Circles'), onPressed: _addCircles),
                      ActionChip(label: const Text('+ Polyline'), onPressed: _addPolyline),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text("Clear Elements", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        label: const Text('Clear Markers'),
                        backgroundColor: Colors.red.shade50,
                        onPressed: () {
                          mapController.removeAllMarkers();
                          _showSnackBar("All Markers Cleared");
                        },
                      ),
                      ActionChip(
                        label: const Text('Clear Circles'),
                        backgroundColor: Colors.red.shade50,
                        onPressed: () {
                          mapController.removeAllCircles();
                          _showSnackBar("All Circles Cleared");
                        },
                      ),
                      ActionChip(
                        label: const Text('Clear Polylines'),
                        backgroundColor: Colors.red.shade50,
                        onPressed: () {
                          mapController.removeAllPolyLines();
                          circlePolylines.clear();
                          _showSnackBar("All Polylines Cleared");
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text("Camera & State", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(label: const Text('Move Camera'), onPressed: _moveCamera),
                      ActionChip(label: const Text('Fit Bounds'), onPressed: _fitBounds),
                      ActionChip(label: const Text('Set User Loc'), onPressed: _setMockUserLocation),
                      ActionChip(
                          label: const Text('Get Camera Info'),
                          backgroundColor: Colors.blue.shade50,
                          onPressed: () {
                            Navigator.pop(context);
                            _getCurrentCameraState();
                          }),
                      ActionChip(
                        label: Text(isDarkMode ? 'Light Mode' : 'Dark Mode'),
                        onPressed: () {
                          Navigator.pop(context);
                          _toggleDarkMode();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
