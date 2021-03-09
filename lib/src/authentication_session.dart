// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:meta/meta.dart';

import 'exception.dart';

typedef Request = Future<Map<String, dynamic>> Function(
  Map<String, dynamic> auth,
);

typedef OnSuccess<T> = Future<T> Function(Map<String, dynamic> body);

@immutable
class AuthenticationSession<T> {
  final String key;
  final Iterable<Flow> flows;

  /// Result will be non-null if the authentication is successfully
  /// completed.
  final T result;

  bool get isCompleted => result != null;

  final MatrixException error;

  bool get hasError => error != null;

  final Request _request;
  final OnSuccess<T> _onSuccess;

  AuthenticationSession._({
    @required this.key,
    @required this.flows,
    this.result,
    this.error,
    Request request,
    OnSuccess<T> onSuccess,
  })  : _request = request,
        _onSuccess = onSuccess;

  factory AuthenticationSession.fromJson(
    Map<String, dynamic> json, {
    @required Request request,
    @required OnSuccess<T> onSuccess,
  }) {
    final flowsJson = json['flows'] as List<dynamic>;
    final key = json['session'];

    MatrixException error;
    if (json.containsKey('error')) {
      error = MatrixException.fromJson(json);
    }

    return AuthenticationSession._(
      key: key,
      error: error,
      request: request,
      flows: flowsJson
          .map(
            (f) => Flow._fromJson(
              f,
              json['params'],
              json['completed'],
            ),
          )
          .toList(),
    );
  }

  /// Complete a stage of this session.
  Future<AuthenticationSession<T>> complete(StageResponse data) async {
    final withSession = {...data.toJson(), 'session': key};

    final response = await _request(withSession);

    if (response.containsKey('flows')) {
      return AuthenticationSession<T>.fromJson(
        response,
        request: _request,
        onSuccess: _onSuccess,
      );
    } else {
      return AuthenticationSession<T>._(
        key: key,
        flows: null,
        result: await _onSuccess(response),
        request: _request,
        onSuccess: _onSuccess,
      );
    }
  }
}

extension FlowSelector on Iterable<Flow> {
  Flow shortestWithOnly(Iterable<Type> types) {
    final sortedWithOnlyTypes = where(
      (f) => f.stages.every(
        (stage) => types.contains(stage.runtimeType),
      ),
    ).toList();

    sortedWithOnlyTypes.sort(
      (a, b) {
        int calcLength(int length) {
          if (a.stages.any((stage) => stage is DummyStage)) {
            return length--;
          }

          return length;
        }

        return calcLength(a.stages.length).compareTo(
          calcLength(b.stages.length),
        );
      },
    );

    return sortedWithOnlyTypes.firstWhere((f) => true, orElse: () => null);
  }
}

@immutable
class Flow {
  final Iterable<Stage> stages;
  final Iterable<Stage> completedStages;

  final Stage currentStage;

  Flow._({
    @required this.stages,
    @required this.completedStages,
    @required this.currentStage,
  });

  factory Flow._fromJson(
    Map<String, dynamic> json,
    Map<String, dynamic> paramsJson,
    List<dynamic> completedJson,
  ) {
    final stagesJson = json['stages'] as List<dynamic>;

    final stages = stagesJson
        .map((s) => Stage._fromJson(s, paramsJson))
        .where((s) => s != null)
        .toList();

    final completed = completedJson
        ?.map((s) => Stage._fromJson(s, paramsJson))
        ?.where((s) => s != null)
        ?.toList();

    return Flow._(
      stages: stages,
      completedStages: completed,
      currentStage: completed == null || completed.isEmpty
          ? stages.first
          : stages.firstWhere((stage) => !completed.contains(stage)),
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (other is Flow) {
      return stages == other.stages && currentStage == other.currentStage;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => stages.hashCode + currentStage.hashCode;
}

@immutable
abstract class Stage {
  final String _type;

  Stage._(this._type);

  factory Stage._fromJson(
    String type,
    Map<String, dynamic> paramsJson,
  ) {
    final relevantParams = paramsJson[type];

    switch (type) {
      case RecaptchaStage.__type:
        return RecaptchaStage._fromJson(relevantParams);
      case TermsStage.__type:
        return TermsStage._fromJson(relevantParams);
      case DummyStage.__type:
        return DummyStage._();
      default:
        return RawStage._(
          type: type,
          params: relevantParams,
        );
    }
  }

  StageResponse respond();
}

@immutable
class StageResponse {
  final String _type;

  StageResponse(this._type);

  Map<String, dynamic> toJson() => {
        'type': _type,
      };
}

class RawStage extends Stage {
  final String type;

  final Map<String, dynamic> params;

  RawStage._({
    @required this.type,
    @required Map<String, dynamic> params,
  })  : params = params ?? {},
        super._(type);

  @override
  RawStageResponse respond([Map<String, dynamic> params]) =>
      RawStageResponse._(_type, params);

  @override
  bool operator ==(dynamic other) {
    if (other is RawStage) {
      return type == other.type && params == other.params;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => type.hashCode + params.hashCode;
}

@immutable
class RawStageResponse extends StageResponse {
  final Map<String, dynamic> params;

  RawStageResponse._(String type, this.params) : super(type);

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        ...params,
      };
}

class DummyStage extends Stage {
  static const __type = 'm.login.dummy';

  DummyStage._() : super._(__type);

  @override
  bool operator ==(dynamic other) => other is DummyStage;

  @override
  int get hashCode => _type.hashCode;

  @override
  DummyStageResponse respond() => DummyStageResponse._();
}

@immutable
class DummyStageResponse extends StageResponse {
  DummyStageResponse._() : super(DummyStage.__type);
}

class RecaptchaStage extends Stage {
  static const __type = 'm.login.recaptcha';

  final String publicKey;

  RecaptchaStage._(this.publicKey) : super._(__type);

  factory RecaptchaStage._fromJson(Map<String, dynamic> paramsJson) {
    final publicKey = paramsJson['public_key'];

    return RecaptchaStage._(publicKey);
  }

  @override
  RecaptchaStageResponse respond({@required String response}) =>
      RecaptchaStageResponse._(response);

  @override
  bool operator ==(dynamic other) {
    if (other is RecaptchaStage) {
      return publicKey == other.publicKey;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => publicKey.hashCode;
}

@immutable
class RecaptchaStageResponse extends StageResponse {
  final String response;

  RecaptchaStageResponse._(this.response) : super(RecaptchaStage.__type);

  @override
  Map<String, dynamic> toJson() => {
        ...super.toJson(),
        'response': response,
      };
}

class TermsStage extends Stage {
  static const __type = 'm.login.terms';

  /// Policies with a key, per language.
  final Map<String, List<Policy>> policies;

  TermsStage._(this.policies) : super._(__type);

  factory TermsStage._fromJson(Map<String, dynamic> paramsJson) {
    final policiesJson = paramsJson['policies'] as Map<String, dynamic>;

    return TermsStage._(
      policiesJson.map(
        (key, value) {
          final json = value as Map<String, dynamic>;

          final version = json['version'];

          final byLanguage = Map.fromEntries(
            json.entries.where((e) => e.key != 'version'),
          );

          return MapEntry(
            key,
            byLanguage.entries
                .map(
                  (e) => Policy(
                    version: version,
                    language: e.key,
                    name: (e.value as Map<String, dynamic>)['name'],
                    url: Uri.parse((e.value as Map<String, dynamic>)['url']),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }

  @override
  bool operator ==(dynamic other) {
    if (other is TermsStage) {
      return policies == other.policies;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => policies.hashCode;

  @override
  TermsStageResponse respond() => TermsStageResponse._();
}

@immutable
class Policy {
  final String version;
  final String language;
  final String name;
  final Uri url;

  Policy({
    @required this.version,
    @required this.language,
    @required this.name,
    @required this.url,
  });

  @override
  bool operator ==(dynamic other) {
    if (other is Policy) {
      return version == other.version &&
          language == other.language &&
          name == other.name &&
          url == other.url;
    } else {
      return false;
    }
  }

  @override
  int get hashCode =>
      version.hashCode + language.hashCode + name.hashCode + url.hashCode;
}

@immutable
class TermsStageResponse extends StageResponse {
  TermsStageResponse._() : super(TermsStage.__type);
}
