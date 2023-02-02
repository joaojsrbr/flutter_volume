import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'src/audio_stream.dart';
import 'src/constants.dart';

/// Um plugin Flutter para controlar o volume do sistema e ouvir as mudanças de volume em diferentes plataformas.
class FlutterVolumeController {
  const FlutterVolumeController._();

  @visibleForTesting
  static const MethodChannel methodChannel = MethodChannel('com.jsr.flutter_volume/method');

  @visibleForTesting
  static const EventChannel eventChannel = EventChannel('com.jsr.flutter_volume/event');

  /// Ouvinte para eventos de alteração de volume
  static StreamSubscription<double>? _volumeListener;

  /// Obtém o nível de volume atual. De 0.0 a 1.0.
  /// Use [stream] para definir o tipo de fluxo de áudio no Android.
  static Future<double?> getVolume({
    AudioStream stream = AudioStream.music,
  }) async {
    final receivedValue = await methodChannel.invokeMethod<String>(
      MethodName.getVolume,
      {
        if (Platform.isAndroid) MethodArg.audioStream: stream.index,
      },
    );

    return receivedValue != null ? double.parse(receivedValue) : null;
  }

  /// Definir o nível de volume. De 0.0 a 1.0.
  /// Use [stream] para definir o tipo de fluxo de áudio no Android.
  static Future<void> setVolume(
    double volume, {
    AudioStream stream = AudioStream.music,
    bool showSystemUI = true,
  }) async {
    await methodChannel.invokeMethod(
      MethodName.setVolume,
      {
        MethodArg.volume: volume,
        if (Platform.isAndroid || Platform.isIOS) MethodArg.showSystemUI: showSystemUI,
        if (Platform.isAndroid) MethodArg.audioStream: stream.index
      },
    );
  }

  static Future<void> setSystemUI([bool showSystemUI = true]) async {
    await methodChannel.invokeMethod(
      MethodName.setSystemUI,
      {
        MethodArg.showSystemUI: showSystemUI,
      },
    );
  }

  /// Aumente o nível de volume em [step]. De 0.0 a 1.0.
  /// No Android e no Windows, quando [step] estiver definido como nulo, ele usará o
  /// valor de passo padrão do sistema.
  /// No iOS, macOS, Linux, se [step] não for definido, o padrão
  /// o valor do passo é definido como 0.15.
  /// Use [stream] para definir o tipo de fluxo de áudio no Android.
  static Future<void> raiseVolume(
    double? step, {
    AudioStream stream = AudioStream.music,
    bool showSystemUI = true,
  }) async {
    await methodChannel.invokeMethod(
      MethodName.raiseVolume,
      {
        if (Platform.isAndroid || Platform.isIOS) MethodArg.showSystemUI: showSystemUI,
        if (step != null) MethodArg.step: step,
        if (Platform.isAndroid) MethodArg.audioStream: stream.index
      },
    );
  }

  /// Diminuir o nível de volume em [step]. De 0.0 a 1.0.
  /// No Android e no Windows, quando [step] estiver definido como nulo, ele usará o
  /// valor de passo padrão do sistema.
  /// No iOS, macOS, Linux, se [step] não for definido, o padrão
  /// o valor do passo é definido como 0.15.
  /// Use [stream] para definir o tipo de fluxo de áudio no Android.
  static Future<void> lowerVolume(
    double? step, {
    AudioStream stream = AudioStream.music,
    bool showSystemUI = true,
  }) async {
    await methodChannel.invokeMethod(
      MethodName.lowerVolume,
      {
        if (Platform.isAndroid || Platform.isIOS) MethodArg.showSystemUI: showSystemUI,
        if (step != null) MethodArg.step: step,
        if (Platform.isAndroid) MethodArg.audioStream: stream.index
      },
    );
  }

  /// Verifique se o volume está mudo.
  /// No Android e iOS, verificamos se o nível de volume atual já está
  /// caiu para zero.
  /// No macOS, Windows, Linux, verificamos se o botão mudo está ativado.
  /// Use [stream] para definir o tipo de fluxo de áudio no Android.
  static Future<bool?> getMute({
    AudioStream stream = AudioStream.music,
  }) async {
    return await methodChannel.invokeMethod<bool>(
      MethodName.getMute,
      {
        if (Platform.isAndroid) MethodArg.audioStream: stream.index,
      },
    );
  }

  /// Silenciar ou ativar o volume.
  /// No Android e iOS, definimos o volume para zero ou voltamos ao nível anterior.
  /// No macOS, Windows, Linux, controlamos o botão mudo. O volume será restaurado
  /// uma vez ativado o som.
  /// Use [stream] para definir o tipo de fluxo de áudio no Android.
  static Future<void> setMute(
    bool isMuted, {
    AudioStream stream = AudioStream.music,
    bool showSystemUI = true,
  }) async {
    await methodChannel.invokeMethod(
      MethodName.setMute,
      {
        MethodArg.isMuted: isMuted,
        if (Platform.isAndroid || Platform.isIOS) MethodArg.showSystemUI: showSystemUI,
        if (Platform.isAndroid) MethodArg.audioStream: stream.index
      },
    );
  }

  /// Alternar entre o estado de silenciar e ativar o volume.
  /// Consulte [setMute] para conhecer os comportamentos da plataforma.
  /// Use [stream] para definir o tipo de fluxo de áudio no Android.
  static Future<void> toggleMute({
    AudioStream stream = AudioStream.music,
    bool showSystemUI = true,
  }) async {
    await methodChannel.invokeMethod(
      MethodName.toggleMute,
      {if (Platform.isAndroid || Platform.isIOS) MethodArg.showSystemUI: showSystemUI, if (Platform.isAndroid) MethodArg.audioStream: stream.index},
    );
  }

  /// Defina o fluxo de áudio padrão no Android.
  /// Este método deve ser chamado para garantir que os controles de volume ajustem o fluxo correto.
  /// Use [stream] para definir o tipo de fluxo de áudio no Android.
  static Future<void> setAndroidAudioStream({
    AudioStream stream = AudioStream.music,
  }) async {
    if (Platform.isAndroid) {
      await methodChannel.invokeMethod(
        MethodName.setAndroidAudioStream,
        {MethodArg.audioStream: stream.index},
      );
    }
  }

  /// Ouça as mudanças de volume.
  /// Use [emitOnStart] para controlar se o valor do volume deve ser emitido
  /// imediatamente logo após o ouvinte ser anexado.
  /// Use [stream] para definir o tipo de fluxo de áudio no Android.
  static StreamSubscription<double> addListener(
    ValueChanged<double> onChanged, {
    AudioStream stream = AudioStream.music,
    bool emitOnStart = true,
  }) {
    if (_volumeListener != null) {
      removeListener();
    }

    final listener = eventChannel
        .receiveBroadcastStream({
          if (Platform.isAndroid) MethodArg.audioStream: stream.index,
          MethodArg.emitOnStart: emitOnStart,
        })
        .distinct()
        .map((volume) => double.parse(volume))
        .listen(onChanged);

    _volumeListener = listener;
    return listener;
  }

  /// Remova o ouvinte de volume.
  static void removeListener() {
    _volumeListener?.cancel();
    _volumeListener = null;
  }
}
