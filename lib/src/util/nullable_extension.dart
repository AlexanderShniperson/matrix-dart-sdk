typedef LetCallback<A, B> = B? Function(A value);

extension NullableExtension<A> on A? {
  B? let<B extends Object?>(LetCallback<A, B> fn) {
    if (this != null) {
      return fn(this!) as B;
    } else {
      return null as B;
    }
  }
}
