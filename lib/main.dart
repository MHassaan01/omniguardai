import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:typed_data';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(OmniGuardMLApp(cameras: cameras));
}

class OmniGuardMLApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const OmniGuardMLApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OmniGuard AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
      ),
      home: WelcomeIntroScreen(cameras: cameras),
    );
  }
}

class WelcomeIntroScreen extends StatelessWidget {
  final List<CameraDescription> cameras;
  const WelcomeIntroScreen({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090D16),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Color(0x3338BDF8), blurRadius: 30, spreadRadius: 5)],
                ),
                child: const Icon(Icons.shield_outlined, size: 72, color: Color(0xFF38BDF8)),
              ),
              const SizedBox(height: 28),
              const Text(
                'OmniGuard AI',
                style: TextStyle(fontSize: 36, fontWeight: FontWeight.extrabold, color: Colors.white),
              ),
              const Text(
                'OFFLINE MATRIX EYES ACTIVE',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 2.0),
              ),
              const SizedBox(height: 32),
              Container(
                maxWidth: 460,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('System Target Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(height: 12),
                    Text(
                      'OmniGuard AI uses your native hardware camera plane linked directly to local neural architecture tensors.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8), height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF38BDF8),
                  foregroundColor: const Color(0xFF090D16),
                  minimumSize: const Size(260, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => CombinedConsoleDashboard(cameras: cameras)),
                  );
                },
                child: const Text('Initialize System', style: TextStyle(fontSize: 16, fontWeight: FontWeight.extrabold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CombinedConsoleDashboard extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CombinedConsoleDashboard({super.key, required this.cameras});

  @override
  State<CombinedConsoleDashboard> createState() => _CombinedConsoleDashboardState();
}

class _CombinedConsoleDashboardState extends State<CombinedConsoleDashboard> {
  String activePanel = 'live';
  CameraController? _cameraController;
  Interpreter? _aiInterpreter;
  bool isProcessingAI = false;
  List<String> eventLedger = [
    "[System Core] Initializing on-device local engine nodes...",
  ];

  @override
  void initState() {
    super.initState();
    _loadNeuralModel();
  }

  Future<void> _loadNeuralModel() async {
    try {
      _aiInterpreter = await Interpreter.fromAsset('yolov8n.tflite');
      setState(() {
        eventLedger.add("[Core Status] Local TFLite matrix maps constructed successfully.");
      });
      _initializeCamera();
    } catch (e) {
      setState(() {
        eventLedger.add("[Engine Fallback] Failed to attach model file. Error: $e");
      });
      _initializeCamera();
    }
  }

  void _initializeCamera() {
    if (widget.cameras.isNotEmpty) {
      _cameraController = CameraController(widget.cameras, ResolutionPreset.medium, enableAudio: false);
      _cameraController!.initialize().then((_) {
        if (!mounted) return;
        setState(() {
          eventLedger.add("[Video Core] Camera capturing feed stream successfully.");
        });
        _runNeuralPipeline();
      });
    }
  }

  void _runNeuralPipeline() {
    if (_cameraController == null || _aiInterpreter == null) return;
    
    _cameraController!.startImageStream((CameraImage image) async {
      if (isProcessingAI) return;
      isProcessingAI = true;

      try {
        var inputBytes = image.planes[0].bytes; 
        var outputBuffer = {0: List.generate(1, (_) => List.generate(84, (_) => List.filled(8400, 0.0)))};

        _aiInterpreter!.runForMultipleInputs([inputBytes], outputBuffer);

        setState(() {
          final timeStamp = DateTime.now().toLocal().toString().split(' ').substring(0, 8);
          eventLedger.add("[$timeStamp] ➔ Local matrix parse complete.");
        });
      } catch (e) {
        // Keeps the UI stream running if shapes mismatch during feed conversions
      } finally {
        isProcessingAI = false;
      }
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _aiInterpreter?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 260,
            color: const Color(0xFF0B0F19),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('OmniGuard AI', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 40),
                ListTile(title: const Text('🎥 Live Feed Grid'), onTap: () => setState(() => activePanel = 'live')),
                ListTile(title: const Text('📋 Matrix Logs'), onTap: () => setState(() => activePanel = 'alerts')),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(40.0),
              child: activePanel == 'live' ? _buildLiveGrid() : _buildAlertLedger(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildLiveGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Hardware Camera Target Grid', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 24),
        Expanded(
          child: (_cameraController != null && _cameraController!.value.isInitialized)
              ? ClipRRect(borderRadius: BorderRadius.circular(14), child: CameraPreview(_cameraController!))
              : const Center(child: Text('Connecting to Hardware Tensors...')),
        )
      ],
    );
  }

  Widget _buildAlertLedger() {
    return ListView.builder(
      itemCount: eventLedger.length,
      itemBuilder: (context, idx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Text(eventLedger[idx], style: const TextStyle(color: Color(0xFF38BDF8), fontFamily: 'Courier', fontSize: 13)),
      ),
    );
  }
}
