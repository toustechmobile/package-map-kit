import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:map_kit/core/ui_map_camera.dart';
import 'package:map_kit/core/ui_map_controller.dart';
import 'package:map_kit/enums/map_provider.dart';
import 'package:map_kit/models/circle_model.dart';
import 'package:map_kit/models/map_bounds_model.dart';
import 'package:map_kit/models/marker_model.dart';
import 'package:map_kit/models/move_model.dart';
import 'package:map_kit/models/poly_line_model.dart';

import '../../models/user_marker.dart';

class FlutterMapWidget extends StatefulWidget {
  final PopupController popupController = PopupController();

  UiMapController? uiMapController;
  List<MarkerModel>? markers;
  List<PolyLineModel>? polyLines;
  List<CircleModel>? circles;
  UserMarkerModel? userMarker;
  LatLng? initialCenter;
  bool? isDarkMode;
  double? zoom;
  final void Function(LatLng point)? onTap;
  final void Function(LatLng point)? onLongPress;
  final void Function(MarkerModel data, LatLng point)? onMarkerTap;
  final void Function(CircleModel data, LatLng? point)? onCircleTap;
  final void Function(dynamic data, LatLng? point)? onPolylineTap;

  MapProvider? mapProvider;

  FlutterMapWidget({
    super.key,
    this.uiMapController,
    this.markers,
    this.polyLines,
    this.circles,
    this.initialCenter,
    this.isDarkMode,
    this.zoom,
    this.onTap,
    this.onLongPress,
    this.onMarkerTap,
    this.onCircleTap,
    this.mapProvider,
    this.onPolylineTap,
  });

  @override
  State<FlutterMapWidget> createState() => _FlutterMapWidgetState();
}

class _FlutterMapWidgetState extends State<FlutterMapWidget> {
  final MapController _mapController = MapController();
  String tileUrl = '';
  final Set<MarkerModel> _circleMarkers = {};
  MarkerModel? _lastTappedMarker;
  bool _popupVisible = false;

  @override
  void initState() {
    super.initState();

    if (widget.initialCenter == null || widget.initialCenter!.latitude.isNaN || widget.initialCenter!.longitude.isNaN) {
      widget.initialCenter = const LatLng(35.6892, 51.3890);
    }

    widget.markers?.removeWhere((m) => m.latitude.isNaN || m.longitude.isNaN);
    widget.circles?.removeWhere((c) => c.latitude.isNaN || c.longitude.isNaN);
    widget.polyLines?.removeWhere((line) {
      if (line.points == null || line.points!.isEmpty) return true;
      return line.points!.any((p) => p.latitude.isNaN || p.longitude.isNaN);
    });
    if (widget.userMarker != null && (widget.userMarker!.latitude.isNaN || widget.userMarker!.longitude.isNaN)) {
      widget.userMarker = null;
    }

    if (widget.uiMapController != null) {
      widget.uiMapController!.addMarkers = (List<MarkerModel> markers) {
        if (!mounted) return;
        final safeMarkers = markers.where((m) => !m.latitude.isNaN && !m.longitude.isNaN).toList();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.markers!.addAll(safeMarkers);
          setState(() {});
        });
      };

      widget.uiMapController!.addCircles = (List<CircleModel> circles) {
        if (!mounted) return;
        final safeCircles = circles.where((m) => !m.latitude.isNaN && !m.longitude.isNaN).toList();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.circles!.addAll(safeCircles);
          // also add new hidden markers for the new circles
          _circleMarkers.addAll(safeCircles.map((circle) => MarkerModel(
                latitude: circle.latitude,
                longitude: circle.longitude,
                data: '',
                icon: '',
                snippetTitle: circle.snippetTitle,
                snippetDescription: circle.snippetDescription,
              )));
          setState(() {});
        });
      };

      widget.uiMapController!.addPolyline = (List<PolyLineModel> polyLines) {
        if (!mounted) return;
        final safePolyLines = polyLines.where((line) {
          if (line.points == null || line.points!.isEmpty) return false;
          return !line.points!.any((point) => point.latitude.isNaN || point.longitude.isNaN);
        }).toList();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.polyLines!.addAll(safePolyLines);
          setState(() {});
        });
      };

      widget.uiMapController!.moveCamera = (MoveModel moveModel) {
        if (!mounted) return;
        if (moveModel.latitude.isNaN || moveModel.longitude.isNaN) {
          debugPrint('CRITICAL: Attempted to move camera to NaN coordinates.');
          return;
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _mapController.move(
            LatLng(moveModel.latitude, moveModel.longitude),
            moveModel.zoom ?? widget.zoom ?? _mapController.camera.zoom,
          );
          setState(() {});
        });
      };

      widget.uiMapController!.fitBounds = (MapBoundsModel mapBoundsModel) {
        if (!mounted || mapBoundsModel.points.isEmpty) return;

        final validPoints = mapBoundsModel.points.where((p) => !p.latitude.isNaN && !p.longitude.isNaN).toList();

        if (validPoints.isEmpty) return;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || mapBoundsModel.points.isEmpty) return;
          _mapController.fitCamera(
            CameraFit.bounds(
              bounds: LatLngBounds.fromPoints(validPoints),
              padding: EdgeInsets.all(mapBoundsModel.padding),
              maxZoom: 18
            ),
          );
        });
      };

      widget.uiMapController!.setUserLocation = (userMarker) {
        if (!mounted) return;
        if (userMarker.latitude.isNaN || userMarker.longitude.isNaN) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.userMarker = userMarker;
          setState(() {});
        });
      };

      widget.uiMapController!.removeMarkers = (List<MarkerModel> markers) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.markers!.removeWhere((marker) => markers.contains(marker));
          setState(() {});
        });
      };

      widget.uiMapController!.removeCircles = (List<CircleModel> circles) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.circles!.removeWhere((circle) => circles.contains(circle));
          setState(() {});
        });
      };

      widget.uiMapController!.removeAllMarkers = () {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.markers!.removeRange(0, widget.markers!.length);
          setState(() {});
        });
      };

      widget.uiMapController!.removeAllCircles = () {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.circles!.clear();
          setState(() {});
        });
      };

      widget.uiMapController!.removePolyLines = (List<PolyLineModel> polyLinesToRemove) {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;

          widget.polyLines!.removeWhere((existingLine) {
            return polyLinesToRemove.any((lineToRemove) {
              if (existingLine.points == null || existingLine.points!.isEmpty) return false;
              if (lineToRemove.points == null || lineToRemove.points!.isEmpty) return false;

              return existingLine.points!.first.latitude == lineToRemove.points!.first.latitude &&
                  existingLine.points!.first.longitude == lineToRemove.points!.first.longitude;
            });
          });

          setState(() {});
        });
      };

      widget.uiMapController!.removeAllPolyLines = () {
        if (!mounted) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          widget.polyLines!.clear();
          setState(() {});
        });
      };

      widget.uiMapController!.cameraCallback = () async {
        return UiMapCamera(
          _mapController.camera.zoom,
          _mapController.camera.center,
        );
      };
    }

    _initializeHiddenMarkers();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.mapProvider == MapProvider.mapIr) {
      tileUrl = "https://map.ir/shiveh/xyz/1.0.0/Shiveh:Shiveh@EPSG:3857@png/{z}/{x}/{y}.png"
          "?x-api-key=eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiIsImp0aSI6IjAwN2VjZjAzNGM3MTVkYmRjMTI1ZWIxNzA4YWNiMzY4MGRkMzk5NzQ3Y2Q4ZjhhMTYwZWNiYTZmNDYzNTRlNmI0ZDFjNzE0M2RkOWRjYzM1In0.eyJhdWQiOiIzMDM4MCIsImp0aSI6IjAwN2VjZjAzNGM3MTVkYmRjMTI1ZWIxNzA4YWNiMzY4MGRkMzk5NzQ3Y2Q4ZjhhMTYwZWNiYTZmNDYzNTRlNmI0ZDFjNzE0M2RkOWRjYzM1IiwiaWF0IjoxNzM2MjQ1MjYzLCJuYmYiOjE3MzYyNDUyNjMsImV4cCI6MTczODc1MDg2Mywic3ViIjoiIiwic2NvcGVzIjpbImJhc2ljIl19.JjWf4g8nNKq4NzgIcrps-K8TAQoS6P9_dA9SNL-b9H2Z4XFiAZQUT5V8tifr-utfsMUhZ0VAMfL1yKUJwDgYnanpKqWSRkolbpGYG3rE4vdatSY6gmt5s7YLPrhgaQY3r5S28cTjOxCH68SSmclekQDXhnUmnMBnP2708WCV2QsR3_-kqC6ElrYoZvRIU1RbFaeeP8PKhwcKGzxuwYm6Er_aJPI7lu040z4AtSY7m1ALPnm7TtZ00hbAA76srmqVROHQ4Tmh1fxGRfPOnRStXDxWzwMQ24mAeKAsjvaB9W7SAfbhfXCpF51NgMRJy695kA5JFsdoatVK7zxG9MT-rw";
    } else {
      tileUrl = "https://tile.openstreetmap.org/{z}/{x}/{y}.png";
    }

    return _child();
  }

  Widget _child() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        // onPositionChanged: (camera, hasGesture) {
        //   print("Testtt");
        //   print("zoom: ${camera.zoom}");
        //   print("center: ${camera.center.toString()}");
        //   print("rotation: ${camera.rotation}");
        //   print("crs: ${camera.crs.toString()}");
        //   print("visibleBounds: ${camera.visibleBounds}");
        //   print(hasGesture);
        // },
          initialCenter: widget.initialCenter!,
          initialZoom: widget.zoom ?? 13,
          minZoom: 2,
          maxZoom: 18,
          onTap: _handleMapTap,
          onLongPress: _handleMapLongPress,
          onMapEvent: (MapEvent event) {
            widget.zoom = event.camera.zoom;
            if (event is MapEventMoveStart) {
              widget.popupController.hideAllPopups();
              _lastTappedMarker = null;
              _popupVisible = false;
            }
          }),
      children: [
        TileLayer(
          urlTemplate:
              widget.isDarkMode ?? false ? "https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png" : tileUrl,
          subdomains: const ['a', 'b', 'c'],
        ),
        CircleLayer(
          circles: widget.circles!.map((circleModel) => circleModel.toFlutterCircleMarker()).toList(),
        ),
        PolylineLayer(
          polylines: [
            ...widget.polyLines!.map((polyLineModel) {
              final modifiedModel = polyLineModel.copyWith(
                color: polyLineModel.strokeColor ?? polyLineModel.color.withAlpha(100),
                strokeWidth: polyLineModel.strokeWidth! + 5,
              );
              return modifiedModel.toFlutterPolyLine();
            }),
            ...widget.polyLines!.map((polyLineModel) => polyLineModel.toFlutterPolyLine()),
          ],
        ),
        _buildPopupMarkerLayer(),
        if (widget.userMarker != null) widget.userMarker!.toUserMarker(),
      ],
    );
  }

  void _initializeHiddenMarkers() {
    _circleMarkers.addAll(
      widget.circles!.map(
        (circle) => MarkerModel(
          latitude: circle.latitude,
          longitude: circle.longitude,
          data: '',
          icon: '',
          snippetTitle: circle.snippetTitle,
          snippetDescription: circle.snippetDescription,
        ),
      ),
    );
  }

  PopupMarkerLayer _buildPopupMarkerLayer() {
    final combinedMarkers = [
      ...?widget.markers,
      ..._circleMarkers,
    ];
    return PopupMarkerLayer(
      options: PopupMarkerLayerOptions(
        popupController: widget.popupController,
        markers: [
          ...widget.markers!.map((markerModel) => markerModel.toFlutterMarker()),
          ..._circleMarkers.map((markerModel) => markerModel.toFlutterMarker()),
        ],
        popupDisplayOptions: PopupDisplayOptions(
          builder: (BuildContext context, Marker marker) {
            final tappedMarker = combinedMarkers.firstWhere(
              (m) => m.latitude == marker.point.latitude && m.longitude == marker.point.longitude && m.icon.isNotEmpty,
              orElse: () {
                final tappedMarker = combinedMarkers.firstWhere((m) =>
                    m.latitude == marker.point.latitude && m.longitude == marker.point.longitude && m.icon.isEmpty);
                return MarkerModel(
                    latitude: marker.point.latitude,
                    longitude: marker.point.longitude,
                    icon: '',
                    snippetTitle: tappedMarker.snippetTitle,
                    snippetDescription: tappedMarker.snippetDescription);
              },
            );

            if (!_popupVisible ||
                _lastTappedMarker == null ||
                _lastTappedMarker!.latitude != tappedMarker.latitude ||
                _lastTappedMarker!.longitude != tappedMarker.longitude) {
              if (tappedMarker.icon.isNotEmpty) {
                widget.onMarkerTap?.call(tappedMarker, LatLng(tappedMarker.latitude, tappedMarker.longitude));
              } else {
                final tappedCircle = widget.circles!.firstWhere(
                  (c) => c.latitude == marker.point.latitude && c.longitude == marker.point.longitude,
                );
                widget.onCircleTap?.call(tappedCircle, LatLng(marker.point.latitude, marker.point.longitude));
              }
              _lastTappedMarker = tappedMarker;
              _popupVisible = true;
            }

            return _buildPopupContent(tappedMarker);
          },
        ),
      ),
    );
  }

  Widget _buildPopupContent(MarkerModel marker) {
    return Visibility(
      visible: marker.snippetTitle != null || marker.snippetDescription != null,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Wrap(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (marker.snippetTitle != null) Text(marker.snippetTitle!),
                if (marker.snippetDescription != null) Text(marker.snippetDescription!),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _handleMapTap(TapPosition tapPosition, LatLng point) {
    widget.popupController.hideAllPopups();
    _lastTappedMarker = null;
    _popupVisible = false;

    final circle = widget.circles?.firstWhere(
      (circle) =>
          const Distance().as(
            LengthUnit.Meter,
            LatLng(circle.latitude, circle.longitude),
            point,
          ) <=
          circle.radius,
      orElse: () => CircleModel(
        latitude: 0,
        longitude: 0,
        radius: 0,
        color: Colors.red,
        borderColor: Colors.red,
      ),
    );

    if (circle != null && circle.longitude != 0) {
      widget.onCircleTap?.call(circle, point);
      return;
    }

    PolyLineModel? tappedPolyline;
    double currentZoom = _mapController.camera.zoom;

    for (final polyline in widget.polyLines ?? []) {
      if (polyline.isPointNear(point, currentZoom)) {
        tappedPolyline = polyline;
        break;
      }
    }

    if (tappedPolyline != null) {
      widget.onPolylineTap?.call(tappedPolyline.data, point);
      return;
    }

    widget.onTap?.call(point);
  }

  void _handleMapLongPress(TapPosition tapPosition, LatLng point) {
    widget.popupController.hideAllPopups();
    _lastTappedMarker = null;
    _popupVisible = false;
    widget.onLongPress?.call(point);
  }
}
