import 'dart:io';
import 'dart:typed_data';

import '../config/app_config.dart';

class Id3CoverExtractor {
  static Future<Uint8List?> fromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return null;
    }

    final length = await file.length();
    if (length == 0) {
      return null;
    }

    final readLength = length < AppConfig.maxCoverHeaderBytes
        ? length
        : AppConfig.maxCoverHeaderBytes;
    final bytes = await file.openRead(0, readLength).fold<BytesBuilder>(
      BytesBuilder(copy: false),
      (builder, chunk) => builder..add(chunk),
    );

    return fromBytes(bytes.takeBytes());
  }

  static Uint8List? fromBytes(Uint8List bytes) {
    final fromTag = _fromId3Tag(bytes);
    if (fromTag != null) {
      return fromTag;
    }
    return _scanForEmbeddedImage(bytes);
  }

  static Uint8List? _fromId3Tag(Uint8List bytes) {
    if (bytes.length < 10 ||
        bytes[0] != 0x49 ||
        bytes[1] != 0x44 ||
        bytes[2] != 0x33) {
      return null;
    }

    final version = bytes[3];
    if (version != 2 && version != 3 && version != 4) {
      return null;
    }

    final tagSize =
        ((bytes[6] & 0x7F) << 21) |
        ((bytes[7] & 0x7F) << 14) |
        ((bytes[8] & 0x7F) << 7) |
        (bytes[9] & 0x7F);
    final tagEnd = (10 + tagSize).clamp(10, bytes.length);

    var offset = 10;
    while (offset < tagEnd) {
      if (version == 2) {
        if (offset + 6 > tagEnd) {
          break;
        }
        final frameId = String.fromCharCodes(bytes.sublist(offset, offset + 3));
        final frameSize =
            (bytes[offset + 3] << 16) |
            (bytes[offset + 4] << 8) |
            bytes[offset + 5];
        if (frameSize <= 0) {
          break;
        }
        final payloadStart = offset + 6;
        final payloadEnd = (payloadStart + frameSize).clamp(payloadStart, tagEnd);
        if (frameId == 'PIC') {
          return _extractImageBytes(bytes.sublist(payloadStart, payloadEnd));
        }
        offset = payloadEnd;
        continue;
      }

      if (offset + 10 > tagEnd) {
        break;
      }

      final frameId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final frameSize = version == 4
          ? ((bytes[offset + 4] & 0x7F) << 21) |
                ((bytes[offset + 5] & 0x7F) << 14) |
                ((bytes[offset + 6] & 0x7F) << 7) |
                (bytes[offset + 7] & 0x7F)
          : (bytes[offset + 4] << 24) |
                (bytes[offset + 5] << 16) |
                (bytes[offset + 6] << 8) |
                bytes[offset + 7];

      if (frameId.trim().isEmpty || frameSize <= 0) {
        break;
      }

      final payloadStart = offset + 10;
      final payloadEnd = (payloadStart + frameSize).clamp(payloadStart, tagEnd);
      if (frameId == 'APIC') {
        return _extractImageBytes(bytes.sublist(payloadStart, payloadEnd));
      }

      offset = payloadEnd;
    }

    return null;
  }

  static Uint8List? _scanForEmbeddedImage(Uint8List bytes) {
    final jpgStart = _indexOfBytes(bytes, [0xFF, 0xD8, 0xFF]);
    if (jpgStart != -1) {
      final jpgEnd = _lastIndexOfBytes(bytes, [0xFF, 0xD9]);
      if (jpgEnd > jpgStart) {
        return Uint8List.fromList(bytes.sublist(jpgStart, jpgEnd + 2));
      }
    }

    final pngStart = _indexOfBytes(bytes, [
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
    ]);
    if (pngStart != -1) {
      final pngEnd = _indexOfBytes(bytes, [
        0x49,
        0x45,
        0x4E,
        0x44,
        0xAE,
        0x42,
        0x60,
        0x82,
      ]);
      if (pngEnd > pngStart) {
        return Uint8List.fromList(bytes.sublist(pngStart, pngEnd + 8));
      }
    }

    return null;
  }

  static Uint8List? _extractImageBytes(Uint8List payload) {
    final fromPayload = _scanForEmbeddedImage(payload);
    if (fromPayload != null) {
      return fromPayload;
    }
    return null;
  }

  static int _indexOfBytes(Uint8List bytes, List<int> pattern) {
    for (var i = 0; i <= bytes.length - pattern.length; i++) {
      var matched = true;
      for (var j = 0; j < pattern.length; j++) {
        if (bytes[i + j] != pattern[j]) {
          matched = false;
          break;
        }
      }
      if (matched) {
        return i;
      }
    }
    return -1;
  }

  static int _lastIndexOfBytes(Uint8List bytes, List<int> pattern) {
    for (var i = bytes.length - pattern.length; i >= 0; i--) {
      var matched = true;
      for (var j = 0; j < pattern.length; j++) {
        if (bytes[i + j] != pattern[j]) {
          matched = false;
          break;
        }
      }
      if (matched) {
        return i;
      }
    }
    return -1;
  }
}
