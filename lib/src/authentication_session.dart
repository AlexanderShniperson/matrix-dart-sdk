// Copyright (C) 2020  Wilko Manger
//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import 'package:meta/meta.dart';
import 'exception.dart';
import 'package:collection/collection.dart';

typedef _Submit = Future<AuthenticationSession> Function(
  Map<String, dynamic> json,
);

typedef Request = Future<Map<String, dynamic>> Function(
  Map<String, dynamic> auth,
);

typedef OnSuccess<T> = Future<T> Function(Map<String, dynamic> body);

@immutable
class AuthenticationSession<T> {
  final String key;
  final Iterable<Flow>? flows;

  /// Result of will be non-null if the authentication is successfully
  /// completed.
  final T? result;

  bool get isCompleted => result != null;

  final MatrixException? error;

  bool get hasError => error != null;

  AuthenticationSession._({
    required this.key,
    required this.flows,
    this.result,
    this.error,
  });

  factory AuthenticationSession.fromJson(
    Map<String, dynamic> json, {
    required Request request,
    required OnSuccess<T> onSuccess,
  }) {
    final flowsJson = json['flows'] as List<dynamic>;
    final key = json['session'];

    MatrixException? error;
    if (json.containsKey('error')) {
      error = MatrixException.fromJson(json);
    }

    return AuthenticationSession._(
      key: key,
      error: error,
      flows: flowsJson
          .map(
            (f) => Flow._fromJson(
              f,
              json['params'],
              json['completed'],
              submit: (json) async {
                final withSession = {...json, 'session': key};

                final response = await request(withSession);

                if (response.containsKey('flows')) {
                  return AuthenticationSession<T>.fromJson(
                    response,
                    request: request,
                    onSuccess: onSuccess,
                  );
                } else {
                  return AuthenticationSession<T>._(
                    key: key,
                    flows: null,
                    result: await onSuccess(response),
                  );
                }
              },
            ),
          )
          .toList(),
    );
  }
}

extension FlowSelector on Iterable<Flow> {
  Flow? shortestWithOnly(Iterable<Type> types) {
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

    return sortedWithOnlyTypes.firstWhereOrNull((f) => true);
  }
}

@immutable
class Flow {
  final Iterable<Stage> stages;
  final Iterable<Stage>? completedStages;

  final Stage currentStage;

  Flow._({
    required this.stages,
    this.completedStages,
    required this.currentStage,
  });

  factory Flow._fromJson(
    Map<String, dynamic> json,
    Map<String, dynamic> paramsJson,
    List<dynamic>? completedJson, {
    required _Submit submit,
  }) {
    final stagesJson = json['stages'] as List<dynamic>;

    final stages = stagesJson
        .map((s) => Stage._fromJson(s, paramsJson, submit: submit))
        .toList();

    final completed = completedJson
        ?.map((s) => Stage._fromJson(s, paramsJson, submit: submit))
        .toList();

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
  final _Submit _submit;

  final String _type;

  Stage._(this._submit, this._type);

  factory Stage._fromJson(
    String type,
    Map<String, dynamic> paramsJson, {
    required _Submit submit,
  }) {
    final relevantParams = paramsJson[type];

    switch (type) {
      case RecaptchaStage.__type:
        return RecaptchaStage._fromJson(relevantParams, submit: submit);
      case TermsStage.__type:
        return TermsStage._fromJson(relevantParams, submit: submit);
      case DummyStage.__type:
        return DummyStage._(submit);
      default:
        return RawStage._(submit: submit, type: type, params: relevantParams);
    }
  }

  Map<String, dynamic> _toSubmitJson() => {
        'type': _type,
      };

  /// Complete this stage by passing data.
  ///
  /// The [AuthenticationSession] is guaranteed to have a type parameter `T`
  /// of the original [AuthenticationSession]. Meaning this is safe:
  /// ```dart
  /// // Is a AuthenticationSession<MyUser>
  /// session = homeserver.register(..);
  ///
  /// // This is safe (assuming the stage is a DummyStage)
  /// session = session.flows.first.stages.first.complete();
  /// ```
  Future<AuthenticationSession> complete() => _submit(_toSubmitJson());
}

class RawStage extends Stage {
  final String type;

  final Map<String, dynamic> params;

  RawStage._({
    required _Submit submit,
    required this.type,
    Map<String, dynamic>? params,
  })  : params = params ?? {},
        super._(submit, type);

  @override
  Future<AuthenticationSession> complete([Map<String, dynamic>? params]) =>
      _submit({...super._toSubmitJson(), ...params ?? {}});

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

class DummyStage extends Stage {
  static const __type = 'm.login.dummy';

  DummyStage._(_Submit submit) : super._(submit, __type);

  @override
  bool operator ==(dynamic other) => other is DummyStage;

  @override
  int get hashCode => _type.hashCode;
}

class RecaptchaStage extends Stage {
  static const __type = 'm.login.recaptcha';

  final String publicKey;

  RecaptchaStage._(
    _Submit submit,
    this.publicKey,
  ) : super._(submit, __type);

  factory RecaptchaStage._fromJson(
    Map<String, dynamic> paramsJson, {
    required _Submit submit,
  }) {
    final publicKey = paramsJson['public_key'];

    return RecaptchaStage._(submit, publicKey);
  }

  /* TODO: wrong override implementation
  @override
  Future<AuthenticationSession> complete({
    required String response,
  }) =>
      _submit({...super._toSubmitJson(), 'response': response});
  */

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

class TermsStage extends Stage {
  static const __type = 'm.login.terms';

  /// Policies with a key, per language.
  final Map<String, List<Policy>> policies;

  TermsStage._(
    _Submit submit,
    this.policies,
  ) : super._(submit, __type);

  factory TermsStage._fromJson(
    Map<String, dynamic> paramsJson, {
    required _Submit submit,
  }) {
    final policiesJson = paramsJson['policies'] as Map<String, dynamic>;

    return TermsStage._(
      submit,
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
}

@immutable
class Policy {
  final String version;
  final String language;
  final String name;
  final Uri url;

  Policy({
    required this.version,
    required this.language,
    required this.name,
    required this.url,
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
