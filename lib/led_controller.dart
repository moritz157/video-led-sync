import 'dart:io';
import 'dart:math';

import 'package:csv/csv.dart';

class LedController {
  int currentKeyframeIndex = 0;
  final List<LEDKeyframe> keyframes;

  LedController(this.keyframes);

  List<RGBValue> getCurrentValues(Duration currentTime) {
    // If currentTime is before the previous keyframe, reset the keyframe index to 0. The while loop after will then return to the current position
    if (currentTime
            .compareTo(keyframes[max(currentKeyframeIndex - 1, 0)].time) <
        0) {
      currentKeyframeIndex = 0;
    }

    // If currentTime is after the current keyframe, step to next keyframe
    while (currentTime.compareTo(keyframes[currentKeyframeIndex].time) > 0) {
      if (currentKeyframeIndex + 1 >= keyframes.length) {
        return keyframes.last.values;
      }
      currentKeyframeIndex++;
    }

    return _interpolate(keyframes[max(currentKeyframeIndex - 1, 0)],
        keyframes[currentKeyframeIndex], currentTime);
  }

  List<RGBValue> _interpolate(
      LEDKeyframe a, LEDKeyframe b, Duration currentTime) {
    switch (b.interpolation) {
      case Interpolation.linear:
        final relativePosition =
            (currentTime.inMilliseconds - a.time.inMilliseconds) /
                (b.time.inMilliseconds - a.time.inMilliseconds);

        List<RGBValue> result = [];
        for (int i = 0; i < a.values.length; i++) {
          result.add(RGBValue(
              (a.values[i].r +
                      relativePosition * (b.values[i].r - a.values[i].r))
                  .round(),
              (a.values[i].g +
                      relativePosition * (b.values[i].g - a.values[i].g))
                  .round(),
              (a.values[i].b +
                      relativePosition * (b.values[i].b - a.values[i].b))
                  .round()));
        }
        return result;
      case Interpolation.none:
      default:
        return a.values;
    }
  }

  LedController.fromCSV(File file) : keyframes = _keyframesFromCSV(file);

  static List<LEDKeyframe> _keyframesFromCSV(File file) {
    final csv =
        const CsvToListConverter(eol: "\n").convert(file.readAsStringSync());
    List<LEDKeyframe> result = [];

    for (int i = 0; i < csv.length; i++) {
      if (csv[i].length < 4) {
        throw 'too few columns';
      }

      result.add(LEDKeyframe(_parseDurationFromString(csv[i][0]),
          [RGBValue(csv[i][1], csv[i][2], csv[i][3])],
          interpolation: Interpolation.linear));
    }
    return result;
  }

  static Duration _parseDurationFromString(String str) {
    final segs = str.split(":");

    return Duration(
        minutes: int.parse(segs[0]),
        seconds: segs.length > 1 ? int.parse(segs[1]) : 0,
        milliseconds: segs.length > 2
            ? int.parse(segs[2]) * pow(10, (3 - segs[2].length)).round()
            : 0);
  }
}

class LEDKeyframe {
  final Duration time;
  final Interpolation interpolation;
  final List<RGBValue> values;

  const LEDKeyframe(this.time, this.values,
      {this.interpolation = Interpolation.none});
}

class RGBValue {
  final int r;
  final int g;
  final int b;

  const RGBValue(this.r, this.g, this.b);
}

enum Interpolation { none, linear }
