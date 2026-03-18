import 'package:camera/camera.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';

class CameraService {
  CameraController? controller;

  // ================================
  // INIT CAMERA (for in-app camera)
  // ================================

  Future<void> initCamera(List<CameraDescription> cameras) async {
    if (cameras.isEmpty) return;

    controller = CameraController(
      cameras[0],
      ResolutionPreset.high,
    );

    await controller!.initialize();
  }

  // ================================
  // TAKE PHOTO (inside app)
  // ================================

  Future<XFile?> takePhoto() async {
    if (controller == null) return null;

    if (!controller!.value.isInitialized) return null;

    return await controller!.takePicture();
  }

  // ================================
  // START VIDEO
  // ================================

  Future<void> startVideo() async {
    if (controller == null) return;

    if (!controller!.value.isInitialized) return;

    await controller!.startVideoRecording();
  }

  // ================================
  // STOP VIDEO
  // ================================

  Future<XFile?> stopVideo() async {
    if (controller == null) return null;

    return await controller!.stopVideoRecording();
  }

  // ================================
  // OPEN SYSTEM CAMERA
  // ================================

  Future<void> openCamera() async {
    // ignore: prefer_const_constructors
    final intent = AndroidIntent(
      action: 'android.media.action.IMAGE_CAPTURE',
      flags: const <int>[
        Flag.FLAG_ACTIVITY_NEW_TASK,
      ],
    );

    await intent.launch();
  }
}
