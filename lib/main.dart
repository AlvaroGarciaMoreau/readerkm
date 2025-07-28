import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'screens/home_screen.dart';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Fijar orientación en modo vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Inicializar las cámaras
  try {
    cameras = await availableCameras();
  } catch (e) {
    cameras = [];
  }
  
  runApp(const ReaderKMApp());
}

class ReaderKMApp extends StatelessWidget {
  const ReaderKMApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReaderKM',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
