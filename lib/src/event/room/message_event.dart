// Copyright (C) 2019  Wilko Manger
// Copyright (C) 2019  Mathieu Velten
// Copyright (C) 2020  Cyril Dutrieux <cyril@cdutrieux.fr>
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:meta/meta.dart';
import 'package:quiver/core.dart';

import '../event.dart';
import 'room_event.dart';
import '../../identifier.dart';

class MessageEvent extends RoomEvent {
  static const matrixType = 'm.room.message';

  @override
  final String type = matrixType;

  @override
  final MessageEventContent? content;

  MessageEvent._(
    RoomEventArgs args, {
    this.content,
  }) : super(args);

  static MessageEvent? instance(
    RoomEventArgs args, {
    MessageEventContent? content,
  }) {
    if (content is TextMessage) {
      return TextMessageEvent(args, content: content);
    } else if (content is EmoteMessage) {
      return EmoteMessageEvent(args, content: content);
    } else if (content is ImageMessage) {
      return ImageMessageEvent(args, content: content);
    } else if (content is VideoMessage) {
      return VideoMessageEvent(args, content: content);
    } else if (content is AudioMessage) {
      return AudioMessageEvent(args, content: content);
    } else if (content == null) {
      return MessageEvent._(args, content: null);
    } else {
      // TODO: Raw/custom message events
      return null;
    }
  }
}

@immutable
abstract class MessageEventContent extends EventContent {
  @protected
  String get type;

  EventId? get inReplyToId;

  EventId? get inReplacementToId;

  MessageEventContent();

  static MessageEventContent? fromJson(Map<String, dynamic>? content) {
    if (content == null) {
      return null;
    }

    final msgtype = content['msgtype'];

    EventId? inReplyTo;
    if (content.containsKey('m.relates_to') &&
        content['m.relates_to']?.containsKey('m.in_reply_to') == true) {
      final repliesTo = content['m.relates_to']['m.in_reply_to']['event_id'];
      inReplyTo = EventId(repliesTo);
    }

    EventId? inReplacementToId;
    if (content.containsKey('m.relates_to') &&
        content['m.relates_to'] is Map<String, dynamic>) {
      final Map<String, dynamic> infoMap = content['m.relates_to'];

      if (infoMap.containsKey('rel_type') &&
          infoMap['rel_type'] == 'm.replace') {
        final replacement = infoMap['event_id'];
        inReplacementToId = EventId(replacement);
      }
    }

    switch (msgtype) {
      case ImageMessage.matrixMessageType:
        final body = content['body'];

        var url = content['url'];
        if (url == null) {
          return null;
        }

        var info = content['info'];
        if (info != null) {
          var width = info['w'];
          var height = info['h'];

          if (width is! int) {
            width = width?.round();
          }

          if (height is! int) {
            height = height?.round();
          }

          info = ImageInfo(width: width, height: height);
        }

        url = Uri.tryParse(url);

        return ImageMessage(
          body: body,
          url: url,
          info: info,
          inReplyToId: inReplyTo,
          inReplacementToId: inReplacementToId,
        );
      case AudioMessage.matrixMessageType:
        final body = content['body'];

        var url = content['url'];
        if (url == null) {
          return null;
        }

        var info = content['info'];
        if (info != null) {
          info = AudioInfo(
            duration: info['duration'] != null
                ? Duration(milliseconds: info['duration'].round())
                : null,
            mimetype: info['mimetype'],
            size: info['size'],
          );
        }

        url = Uri.tryParse(url);
        return AudioMessage(
          body: body,
          url: url,
          info: info,
          inReplyToId: inReplyTo,
          inReplacementToId: inReplacementToId,
        );
      case VideoMessage.matrixMessageType:
        return VideoMessage.fromJson(content);
      case TextMessage.matrixMessageType:
      case EmoteMessage.matrixMessageType:
      default:
        final body = content['body'];
        final formattedBody = content['formatted_body'];
        final format = content['format'];

        if (msgtype == EmoteMessage.matrixMessageType) {
          return EmoteMessage(
            body: body,
            format: format,
            formattedBody: formattedBody,
            inReplyToId: inReplyTo,
            inReplacementToId: inReplacementToId,
          );
        } else {
          return TextMessage(
            body: body,
            format: format,
            formattedBody: formattedBody,
            inReplyToId: inReplyTo,
            inReplacementToId: inReplacementToId,
          );
        }
    }
  }

  @override
  bool operator ==(dynamic other) =>
      other is MessageEventContent &&
      type == other.type &&
      inReplyToId == other.inReplyToId;

  @override
  int get hashCode => hashObjects([type, inReplyToId]);

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'msgtype': type};

    Map<String, dynamic> relates = {};

    if (inReplyToId != null) {
      relates.addAll({
        'm.in_reply_to': {
          'event_id': inReplyToId.toString(),
        }
      });
    }

    if (inReplacementToId != null) {
      relates.addAll(
          {'event_id': inReplacementToId.toString(), 'rel_type': 'm.replace'});
    }

    if (relates.isNotEmpty) {
      json['m.relates_to'] = relates;
    }

    return json;
  }
}

class TextMessage extends MessageEventContent {
  static const String matrixMessageType = 'm.text';

  @override
  final String type = matrixMessageType;

  final String body;
  final String? format;
  final String? formattedBody;

  @override
  final EventId? inReplyToId;

  @override
  final EventId? inReplacementToId;

  TextMessage({
    required this.body,
    this.format,
    this.formattedBody,
    this.inReplyToId,
    this.inReplacementToId,
  });

  @override
  bool operator ==(dynamic other) =>
      other is TextMessage &&
      super == other &&
      body == other.body &&
      formattedBody == other.formattedBody;

  @override
  int get hashCode => hashObjects([super.hashCode, body, formattedBody]);

  @override
  Map<String, dynamic> toJson() =>
      super.toJson()..addAll({'body': body, 'formatted_body': formattedBody});
}

class TextMessageEvent extends MessageEvent {
  @override
  final TextMessage content;

  TextMessageEvent(
    RoomEventArgs args, {
    required this.content,
  }) : super._(args, content: content);
}

class EmoteMessage extends TextMessage {
  static const String matrixMessageType = 'm.emote';

  @override
  final String type = matrixMessageType;

  EmoteMessage({
    required String body,
    String? format,
    String? formattedBody,
    EventId? inReplyToId,
    EventId? inReplacementToId,
  }) : super(
          body: body,
          format: format,
          formattedBody: formattedBody,
          inReplyToId: inReplyToId,
          inReplacementToId: inReplacementToId,
        );
}

class EmoteMessageEvent extends TextMessageEvent {
  @override
  final EmoteMessage content;

  EmoteMessageEvent(
    RoomEventArgs args, {
    required this.content,
  }) : super(args, content: content);
}

class ImageMessage extends MessageEventContent {
  static const String matrixMessageType = 'm.image';

  @override
  final String type = matrixMessageType;

  final String body;
  final Uri? url;
  final ImageInfo? info;

  @override
  final EventId? inReplyToId;

  @override
  final EventId? inReplacementToId;

  ImageMessage({
    required this.body,
    this.url,
    this.info,
    this.inReplyToId,
    this.inReplacementToId,
  });

  @override
  bool operator ==(dynamic other) =>
      other is ImageMessage &&
      super == other &&
      body == other.body &&
      url == other.url &&
      info == other.info;

  @override
  int get hashCode => hashObjects([super.hashCode, body, url, info]);

  @override
  Map<String, dynamic> toJson() {
    final json = super.toJson()
      ..addAll({
        'body': body,
        'url': url?.toString(),
      });

    if (info != null) {
      final jsonInfo = json['info'] = {};

      if (info?.width != null) {
        jsonInfo['w'] = info!.width;
      }

      if (info?.height != null) {
        jsonInfo['h'] = info!.height;
      }
    }

    return json;
  }
}

class ImageInfo {
  final int? width;
  final int? height;

  ImageInfo({this.width, this.height});
}

class ImageMessageEvent extends MessageEvent {
  @override
  final ImageMessage? content;

  ImageMessageEvent(
    RoomEventArgs args, {
    required this.content,
  }) : super._(args, content: content);
}

class VideoMessage extends MessageEventContent {
  static const String matrixMessageType = 'm.video';

  @override
  final String type = matrixMessageType;

  final String body;
  final Uri? url;
  final VideoInfo? info;

  @override
  final EventId? inReplyToId;

  @override
  final EventId? inReplacementToId;

  VideoMessage({
    required this.body,
    this.url,
    this.info,
    this.inReplyToId,
    this.inReplacementToId,
  });

  static VideoMessage? fromJson(
    Map<String, dynamic> json, {
    EventId? inReplyToId,
  }) {
    final body = json['body'];

    var url = json['url'];
    if (url == null) {
      return null;
    }

    url = Uri.tryParse(url);
    return VideoMessage(
      body: body,
      url: url,
      info: VideoInfo.fromJson(json['info']),
      inReplyToId: inReplyToId,
    );
  }

  @override
  bool operator ==(dynamic other) =>
      other is VideoMessage &&
      super == other &&
      body == other.body &&
      url == other.url &&
      info == other.info;

  @override
  int get hashCode => hashObjects([super.hashCode, body, url, info]);

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'body': body,
      'url': url?.toString(),
      'info': info?.toJson(),
    });
}

@immutable
class VideoInfo {
  final Duration? duration;
  final int? width;
  final int? height;
  final int size;

  final String mimeType;
  final ThumbnailInfo? thumbnail;

  VideoInfo({
    this.duration,
    this.width,
    this.height,
    required this.size,
    required this.mimeType,
    this.thumbnail,
  });

  @override
  bool operator ==(dynamic other) =>
      other is VideoInfo &&
      duration == other.duration &&
      width == other.width &&
      height == other.height &&
      size == other.size &&
      mimeType == other.mimeType &&
      thumbnail == other.thumbnail;

  @override
  int get hashCode => hashObjects([
        duration,
        width,
        height,
        size,
        mimeType,
        thumbnail,
      ]);

  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    return VideoInfo(
      duration: json['duration'] != null
          ? Duration(milliseconds: json['duration'].round())
          : null,
      width: json['w']?.round(),
      height: json['h']?.round(),
      size: json['size'],
      mimeType: json['mimetype'],
      thumbnail: ThumbnailInfo.fromJson(
        json['thumbnail_info'],
        url: json['thumbnail_url'],
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'duration': duration?.inMilliseconds,
        'w': width,
        'h': height,
        'mimetype': mimeType,
        'size': size,
        'thumbnail_info': thumbnail?.toJson(),
        'thumbnail_url': thumbnail?.url.toString(),
      };
}

@immutable
class ThumbnailInfo {
  final Uri url;
  final int? width;
  final int? height;
  final int? size;
  final String mimeType;

  ThumbnailInfo({
    required this.url,
    this.width,
    this.height,
    this.size,
    required this.mimeType,
  });

  @override
  bool operator ==(dynamic other) =>
      other is ThumbnailInfo &&
      url == other.url &&
      width == other.width &&
      height == other.height &&
      size == other.size &&
      mimeType == other.mimeType;

  @override
  int get hashCode => hashObjects([url, width, height, size, mimeType]);

  /// Note: Accroding to the spec, [url] is not included.
  Map<String, dynamic> toJson() => {
        'w': width,
        'h': height,
        'size': size,
        'mimetype': mimeType,
      };

  static ThumbnailInfo? fromJson(
    Map<String, dynamic> json, {
    String? url,
  }) {
    final parsedUrl = url != null ? Uri.tryParse(url) : null;
    if (parsedUrl == null) {
      return null;
    }

    return ThumbnailInfo(
      url: parsedUrl,
      width: json['w']?.round(),
      height: json['h']?.round(),
      size: json['size']?.round(),
      mimeType: json['mimetype'],
    );
  }
}

class VideoMessageEvent extends MessageEvent {
  @override
  final VideoMessage content;

  VideoMessageEvent(
    RoomEventArgs args, {
    required this.content,
  }) : super._(args, content: content);
}

class AudioMessage extends MessageEventContent {
  static const String matrixMessageType = 'm.audio';

  @override
  final String type = matrixMessageType;

  @override
  final EventId? inReplacementToId;

  final String body;
  final Uri? url;
  final AudioInfo? info;

  @override
  final EventId? inReplyToId;

  AudioMessage({
    required this.body,
    this.url,
    this.info,
    this.inReplyToId,
    this.inReplacementToId,
  });

  @override
  bool operator ==(dynamic other) =>
      other is AudioMessage &&
      super == other &&
      body == other.body &&
      url == other.url &&
      info == other.info;

  @override
  int get hashCode => hashObjects([super.hashCode, body, url, info]);

  @override
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'body': body,
      'url': url?.toString(),
    };

    if (info != null) {
      json['info'] = {
        'duration': info!.duration?.inMilliseconds,
        'mimetype': info!.mimetype,
        'size': info!.size,
      };
    }
    return super.toJson()..addAll(json);
  }
}

@immutable
class AudioInfo {
  final Duration? duration;
  final String mimetype;
  final int size;

  AudioInfo({
    this.duration,
    required this.mimetype,
    required this.size,
  });

  @override
  bool operator ==(dynamic other) =>
      other is AudioInfo &&
      duration == other.duration &&
      mimetype == other.mimetype &&
      size == other.size;

  @override
  int get hashCode => hashObjects([duration, mimetype, size]);
}

class AudioMessageEvent extends MessageEvent {
  @override
  final AudioMessage content;

  AudioMessageEvent(
    RoomEventArgs args, {
    required this.content,
  }) : super._(args, content: content);
}
