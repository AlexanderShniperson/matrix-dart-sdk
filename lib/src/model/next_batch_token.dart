import 'package:matrix_sdk/src/model/models.dart';

class NextBatchToken implements Contextual<NextBatchToken> {
  final String token;

  @override
  final Context? context;

  NextBatchToken(this.token): context = null;

  @override
  NextBatchToken? delta() => NextBatchToken(token);

  @override
  NextBatchToken? propertyOf(MyUser user) => NextBatchToken(token);
}