import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';

class BarcodeScannerWidget extends StatefulWidget {
  final Function(String) onScan;
  final VoidCallback onCancel;

  const BarcodeScannerWidget({
    super.key,
    required this.onScan,
    required this.onCancel,
  });

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> {
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScan());
  }

  Future<void> _startScan() async {
    if (_scanning) return;
    setState(() => _scanning = true);

    ScanResult result;
    try {
      result = await BarcodeScanner.scan(
        options: const ScanOptions(
          restrictFormat: [],
          useCamera: -1,
          autoEnableFlash: false,
          android: AndroidOptions(aspectTolerance: 0.00, useAutoFocus: true),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al abrir escáner: $e')),
        );
        widget.onCancel();
      }
      return;
    } finally {
      if (mounted) setState(() => _scanning = false);
    }

    if (!mounted) return;

    if (result.type == ResultType.Cancelled) {
      widget.onCancel();
      return;
    }

    if (result.type == ResultType.Error || result.rawContent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo leer el código')),
      );
      widget.onCancel();
      return;
    }

    widget.onScan(result.rawContent);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: widget.onCancel),
        title: const Text('Escanear código', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner, size: 80, color: Colors.white.withValues(alpha: 0.7)),
            const SizedBox(height: 24),
            Text(
              _scanning ? 'Abriendo escáner...' : 'Toca para escanear',
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (_scanning)
              const CircularProgressIndicator(color: Colors.white)
            else
              ElevatedButton.icon(
                onPressed: _startScan,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Escanear'),
              ),
          ],
        ),
      ),
    );
  }
}
