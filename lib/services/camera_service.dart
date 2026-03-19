import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:camera/camera.dart';

class CameraService {
  CameraController? _controller;

  CameraController? get controller => _controller;

  bool get isInitialized =>
      _controller != null && _controller!.value.isInitialized;

  bool get isRecordingVideo =>
      _controller != null && _controller!.value.isRecordingVideo;

  // ================================
  // INIT CAMERA (for in-app camera)
  // ================================

  Future<void> initCamera(
    List<CameraDescription> cameras, {
    ResolutionPreset resolution = ResolutionPreset.high,
    bool useFrontCamera = false,
  }) async {
    if (cameras.isEmpty) {
      return;
    }

    final selectedCamera = _selectCamera(
      cameras,
      useFrontCamera: useFrontCamera,
    );

    if (_controller != null) {
      await dispose();
    }

    final controller = CameraController(
      selectedCamera,
      resolution,
      enableAudio: true,
    );

    await controller.initialize();
    _controller = controller;
  }

  // ================================
  // TAKE PHOTO (inside app)
  // ================================

  Future<XFile?> takePhoto() async {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return null;
    }

    if (controller.value.isTakingPicture) {
      return null;
    }

    return controller.takePicture();
  }

  // ================================
  // START VIDEO
  // ================================

  Future<bool> startVideo() async {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return false;
    }

    if (controller.value.isRecordingVideo) {
      return false;
    }

    await controller.startVideoRecording();
    return true;
  }

  // ================================
  // STOP VIDEO
  // ================================

  Future<XFile?> stopVideo() async {
    final controller = _controller;

    if (controller == null || !controller.value.isInitialized) {
      return null;
    }

    if (!controller.value.isRecordingVideo) {
      return null;
    }

    return controller.stopVideoRecording();
  }

  // ================================
  // OPEN SYSTEM CAMERA
  // ================================

  Future<bool> openCamera() async {
    const intent = AndroidIntent(
      action: 'android.media.action.IMAGE_CAPTURE',
      flags: <int>[
        Flag.FLAG_ACTIVITY_NEW_TASK,
      ],
    );

    try {
      await intent.launch();
      return true;
    } catch (_) {
      return false;
    }
  }
  // ================================
  // DISPOSE
  // ================================

  Future<void> dispose() async {
    final controller = _controller;
    _controller = null;

    if (controller != null) {
      await controller.dispose();
    }
  }

  // ================================
  // HELPERS
  // ================================

  CameraDescription _selectCamera(
    List<CameraDescription> cameras, {
    required bool useFrontCamera,
  }) {
    final preferredLensDirection =
        useFrontCamera ? CameraLensDirection.front : CameraLensDirection.back;

    for (final camera in cameras) {
      if (camera.lensDirection == preferredLensDirection) {
        return camera;
      }
    }

    return cameras.first;
  }
}
