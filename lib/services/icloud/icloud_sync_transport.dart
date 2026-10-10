import 'package:flutter/services.dart';

class ICloudTransportStatus {
  const ICloudTransportStatus({
    required this.available,
    this.accountId,
    this.deviceName,
    this.installationIdentity,
  });

  final bool available;
  final String? accountId;
  final String? deviceName;
  final String? installationIdentity;
}

class ICloudRemoteFile {
  const ICloudRemoteFile({
    required this.path,
    this.bytes,
    this.uploaded,
    this.uploadError,
  });

  final String path;
  final int? bytes;
  final bool? uploaded;
  final String? uploadError;
}

class ICloudWriteResult {
  const ICloudWriteResult({required this.uploaded, this.uploadError});
  final bool uploaded;
  final String? uploadError;
}

abstract interface class ICloudSyncTransport {
  Future<ICloudTransportStatus> status();
  Future<List<ICloudRemoteFile>> list({required String accountId});
  Future<String> read({
    required String path,
    required String destinationPath,
    required String accountId,
  });
  Future<ICloudWriteResult> write({
    required String path,
    required String sourcePath,
    required String accountId,
  });
}

class MethodChannelICloudSyncTransport implements ICloudSyncTransport {
  MethodChannelICloudSyncTransport({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('com.niki.xxread/icloud_sync');

  final MethodChannel _channel;

  @override
  Future<ICloudTransportStatus> status() async {
    final raw = await _channel.invokeMapMethod<String, Object?>('status');
    if (raw == null || raw['available'] is! bool) {
      throw const FormatException('Invalid iCloud status');
    }
    return ICloudTransportStatus(
      available: raw['available']! as bool,
      accountId: _optionalString(raw['accountId']),
      deviceName: _optionalString(raw['deviceName']),
      installationIdentity: _optionalString(raw['installationIdentity']),
    );
  }

  @override
  Future<List<ICloudRemoteFile>> list({required String accountId}) async {
    final raw = await _channel.invokeListMethod<Object?>('list', {
      'accountId': accountId,
    });
    if (raw == null) return const [];
    return raw
        .map((item) {
          if (item is! Map) {
            throw const FormatException('Invalid iCloud listing');
          }
          final map = Map<Object?, Object?>.from(item);
          final path = map['path'];
          final bytes = map['bytes'];
          final uploaded = map['uploaded'];
          final uploadError = map['uploadError'];
          if (path is! String ||
              path.isEmpty ||
              (bytes != null && bytes is! int) ||
              (uploaded != null && uploaded is! bool) ||
              (uploadError != null && uploadError is! String)) {
            throw const FormatException('Invalid iCloud listing');
          }
          return ICloudRemoteFile(
            path: path,
            bytes: bytes as int?,
            uploaded: uploaded as bool?,
            uploadError: _optionalString(uploadError),
          );
        })
        .toList(growable: false);
  }

  @override
  Future<String> read({
    required String path,
    required String destinationPath,
    required String accountId,
  }) async {
    final result = await _channel.invokeMethod<Object?>('read', {
      'path': path,
      'destinationPath': destinationPath,
      'accountId': accountId,
    });
    if (result is! String || result.isEmpty) {
      throw const FormatException('Invalid iCloud read result');
    }
    return result;
  }

  @override
  Future<ICloudWriteResult> write({
    required String path,
    required String sourcePath,
    required String accountId,
  }) async {
    final raw = await _channel.invokeMapMethod<String, Object?>('write', {
      'path': path,
      'sourcePath': sourcePath,
      'accountId': accountId,
    });
    if (raw == null || raw['uploaded'] is! bool) {
      throw const FormatException('Invalid iCloud write result');
    }
    final uploadError = raw['uploadError'];
    if (uploadError != null && uploadError is! String) {
      throw const FormatException('Invalid iCloud write result');
    }
    return ICloudWriteResult(
      uploaded: raw['uploaded']! as bool,
      uploadError: _optionalString(uploadError),
    );
  }

  static String? _optionalString(Object? value) =>
      value is String && value.isNotEmpty ? value : null;
}
