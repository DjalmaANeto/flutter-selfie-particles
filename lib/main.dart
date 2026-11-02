import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint('Erro ao obter câmeras: $e');
  }
  runApp(const SelfieParticlesApp());
}

class SelfieParticlesApp extends StatelessWidget {
  const SelfieParticlesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Selfie Partículas 3D',
      theme: ThemeData.dark(),
      home: const ParticleCameraScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ParticleCameraScreen extends StatefulWidget {
  const ParticleCameraScreen({super.key});

  @override
  State<ParticleCameraScreen> createState() => _ParticleCameraScreenState();
}

class _ParticleCameraScreenState extends State<ParticleCameraScreen> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  int _selectedCameraIdx = 0;
  int _particleStyle = 0; // 0: Grid, 1: Floating
  String _statusMessage = 'Solicitando permissões...';

  @override
  void initState() {
    super.initState();
    _initPermissionsAndCamera();
  }

  Future<void> _initPermissionsAndCamera() async {
    var status = await Permission.camera.request();
    if (status.isGranted) {
      _initCamera(_selectedCameraIdx);
    } else {
      setState(() {
        _statusMessage = 'Permissão de câmera negada.';
      });
    }
  }

  Future<void> _initCamera(int cameraIdx) async {
    if (cameras.isEmpty) {
      setState(() => _statusMessage = 'Nenhuma câmera encontrada.');
      return;
    }

    if (cameraIdx >= cameras.length) {
      cameraIdx = 0;
    }

    final CameraDescription cameraDescription = cameras[cameraIdx];
    final CameraController cameraController = CameraController(
      cameraDescription,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _controller = cameraController;

    try {
      await cameraController.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
        _statusMessage = 'Câmera ativa! Toque para alternar estilo.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Erro ao iniciar câmera: $e';
      });
    }
  }

  void _switchCamera() async {
    if (cameras.length < 2) return;
    _selectedCameraIdx = (_selectedCameraIdx + 1) % cameras.length;
    await _controller?.dispose();
    setState(() {
      _isCameraInitialized = false;
    });
    _initCamera(_selectedCameraIdx);
  }

  void _toggleStyle() {
    setState(() {
      _particleStyle = (_particleStyle + 1) % 2;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Visualização de Partículas 3D Simuladas / Câmera
          _isCameraInitialized && _controller != null
              ? Positioned.fill(
                  child: CustomPaint(
                    painter: ParticlePainter(
                      style: _particleStyle,
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    _statusMessage,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),

          // Informações no topo
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ),

          // Painel de Controle Inferior
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _toggleStyle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.style),
                  label: Text(_particleStyle == 0 ? 'Estilo: Grade' : 'Estilo: Flutuante'),
                ),
                ElevatedButton.icon(
                  onPressed: cameras.length > 1 ? _switchCamera : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.switch_camera),
                  label: const Text('Trocar Câmera'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final int style;
  ParticlePainter({required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;
    final int cols = 35;
    final int rows = 25;
    final double spacingX = size.width / cols;
    final double spacingY = size.height / rows;

    final double time = DateTime.now().millisecondsSinceEpoch * 0.003;

    for (int y = 0; y < rows; y++) {
      for (int x = 0; x < cols; x++) {
        double posX = x * spacingX + spacingX / 2;
        double posY = y * spacingY + spacingY / 2;

        if (style == 1) {
          posX += math.sin(time + x * 0.2) * 10;
          posY += math.cos(time + y * 0.2) * 10;
        }

        // Cores vibrantes baseadas na posição e tempo
        paint.color = HSLColor.fromAHSL(
          0.8,
          (x * 10 + y * 5 + time * 50) % 360,
          0.8,
          0.6,
        ).toColor();

        double radius = ((math.sin(time + x * 0.3) + 1) * 2) + 2;

        if (style == 0) {
          canvas.drawRect(
            Rect.fromCenter(center: Offset(posX, posY), width: radius * 1.5, height: radius * 1.5),
            paint,
          );
        } else {
          canvas.drawCircle(Offset(posX, posY), radius, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
