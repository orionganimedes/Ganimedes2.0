import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../theme/app_colors.dart';

class BarcodeScannerDialog extends StatefulWidget {
  final String title;

  const BarcodeScannerDialog({
    super.key,
    this.title = 'Escanear Código de Barras',
  });

  static Future<String?> show(BuildContext context, {String title = 'Escanear Código de Barras'}) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BarcodeScannerDialog(title: title),
    );
  }

  @override
  State<BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<BarcodeScannerDialog> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _isTorchOn = false;
  bool _hasDetected = false;
  final TextEditingController _manualInputController = TextEditingController();
  bool _showManualInput = false;

  @override
  void dispose() {
    _controller.dispose();
    _manualInputController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasDetected) return;
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      final code = barcode.rawValue ?? barcode.displayValue;
      if (code != null && code.trim().isNotEmpty) {
        setState(() => _hasDetected = true);
        HapticFeedback.mediumImpact();
        Navigator.of(context).pop(code.trim());
        break;
      }
    }
  }

  void _submitManual() {
    final text = _manualInputController.text.trim();
    if (text.isNotEmpty) {
      Navigator.of(context).pop(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark ? AppColors.surfaceContainer : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppColors.secondary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: AppColors.secondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scanner Body
            Flexible(
              child: ClipRRect(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Camera feed
                    MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                      errorBuilder: (context, error) {
                        return Container(
                          color: isDark ? AppColors.surface : Colors.grey.shade100,
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.no_photography_rounded,
                                  color: AppColors.error,
                                  size: 48,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Cámara no disponible',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Verifica los permisos o introduce el código manualmente abajo.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.onSurfaceVariant
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Cyber reticle overlay
                    Container(
                      width: 250,
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.6),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          // Scanner line animation aesthetic
                          Center(
                            child: Container(
                              height: 2,
                              color: AppColors.secondary.withValues(alpha: 0.8),
                            ),
                          ),
                          // Corner brackets
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: AppColors.secondary, width: 3),
                                  left: BorderSide(color: AppColors.secondary, width: 3),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: AppColors.secondary, width: 3),
                                  right: BorderSide(color: AppColors.secondary, width: 3),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            left: 4,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: AppColors.secondary, width: 3),
                                  left: BorderSide(color: AppColors.secondary, width: 3),
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: AppColors.secondary, width: 3),
                                  right: BorderSide(color: AppColors.secondary, width: 3),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Controls overlay (Torch & Flip)
                    Positioned(
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                _isTorchOn
                                    ? Icons.flash_on_rounded
                                    : Icons.flash_off_rounded,
                                color: _isTorchOn ? Colors.amber : Colors.white,
                                size: 22,
                              ),
                              onPressed: () async {
                                await _controller.toggleTorch();
                                setState(() => _isTorchOn = !_isTorchOn);
                              },
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(
                                Icons.flip_camera_ios_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                              onPressed: () => _controller.switchCamera(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Manual code fallback option
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_showManualInput)
                    TextButton.icon(
                      onPressed: () => setState(() => _showManualInput = true),
                      icon: const Icon(Icons.keyboard_rounded, size: 18),
                      label: const Text(
                        'Ingresar código manualmente',
                        style: TextStyle(fontSize: 13),
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _manualInputController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Ej. 7501030425123',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onSubmitted: (_) => _submitManual(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _submitManual,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryContainer,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
