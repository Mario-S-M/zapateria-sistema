import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraPermissionGate extends StatefulWidget {
  final Widget child;

  const CameraPermissionGate({super.key, required this.child});

  @override
  State<CameraPermissionGate> createState() => _CameraPermissionGateState();
}

class _CameraPermissionGateState extends State<CameraPermissionGate> {
  _PermState _state = _PermState.checking;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      if (mounted) setState(() => _state = _PermState.granted);
      return;
    }
    final result = await Permission.camera.request();
    if (!mounted) return;
    if (result.isGranted) {
      setState(() => _state = _PermState.granted);
    } else if (result.isPermanentlyDenied) {
      setState(() => _state = _PermState.permanentlyDenied);
    } else {
      setState(() => _state = _PermState.denied);
    }
  }

  @override
  Widget build(BuildContext context) {
    return switch (_state) {
      _PermState.checking => const Center(child: CircularProgressIndicator()),
      _PermState.granted => widget.child,
      _PermState.denied => _buildDenied(context, permanent: false),
      _PermState.permanentlyDenied => _buildDenied(context, permanent: true),
    };
  }

  Widget _buildDenied(BuildContext context, {required bool permanent}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              permanent
                  ? 'Permiso de cámara bloqueado. Ábrelo en Ajustes del teléfono.'
                  : 'Se necesita permiso de cámara para escanear.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            permanent
                ? ElevatedButton(
                    onPressed: openAppSettings,
                    child: const Text('Abrir Ajustes'),
                  )
                : ElevatedButton(
                    onPressed: _check,
                    child: const Text('Conceder permiso'),
                  ),
          ],
        ),
      ),
    );
  }
}

enum _PermState { checking, granted, denied, permanentlyDenied }
