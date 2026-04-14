import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../services/map_navigation.dart';

/// Bản đồ nhúng (Google Maps) cho một địa chỉ — dùng geocoding hệ thống.
class PersonAddressMapPage extends StatefulWidget {
  const PersonAddressMapPage({
    super.key,
    required this.title,
    required this.address,
  });

  final String title;
  final String address;

  @override
  State<PersonAddressMapPage> createState() => _PersonAddressMapPageState();
}

class _PersonAddressMapPageState extends State<PersonAddressMapPage> {
  LatLng? _target;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    try {
      final locations = await locationFromAddress(widget.address.trim());
      if (!mounted) return;
      if (locations.isEmpty) {
        setState(() {
          _loading = false;
          _error = 'Không tìm thấy tọa độ cho địa chỉ này.';
        });
        return;
      }
      final loc = locations.first;
      setState(() {
        _target = LatLng(loc.latitude, loc.longitude);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            tooltip: 'Mở Google Maps',
            icon: const Icon(Icons.open_in_new),
            onPressed: () => openGoogleMapsExternal(widget.address),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: () =>
                              openGoogleMapsExternal(widget.address),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Mở trên Google Maps'),
                        ),
                      ],
                    ),
                  ),
                )
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _target!,
                    zoom: 15,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('person_address'),
                      position: _target!,
                      infoWindow: InfoWindow(title: widget.title),
                    ),
                  },
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: true,
                ),
    );
  }
}
