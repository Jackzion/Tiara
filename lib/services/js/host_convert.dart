import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Convert 的 Host 实现（utf8/base64/md5/sha1/sha256/hmac）
class HostConvert {
  Object? handle(Map<String, dynamic> data) {
    final type = data['type'] as String;
    final value = data['value'];
    final isEncode = data['isEncode'] as bool? ?? true;
    switch (type) {
      case 'utf8':
        return isEncode ? utf8.encode(value) : utf8.decode(value);
      case 'base64':
        return isEncode ? base64Encode(value) : base64Decode(value);
      case 'md5':
        return Uint8List.fromList(md5.convert(value).bytes);
      case 'sha1':
        return Uint8List.fromList(sha1.convert(value).bytes);
      case 'sha256':
        return Uint8List.fromList(sha256.convert(value).bytes);
      case 'hmac':
        final hash = switch (data['hash']) {
          'md5' => md5,
          'sha1' => sha1,
          'sha256' => sha256,
          final h => throw 'Unsupported hash: $h',
        };
        final digest = Hmac(hash, data['key']).convert(value);
        return data['isString'] == true
            ? digest.toString()
            : Uint8List.fromList(digest.bytes);
      default:
        throw 'Host API 未实现: convert/$type';
    }
  }
}
