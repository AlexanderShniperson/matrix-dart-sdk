pub run build_runner build

# The dartanalyzer exclude functionality currently does not work (see https://github.com/dart-lang/sdk/issues/25551),
# therefore the generated files are formatted and have extra linter ignore statements added

echo '// ignore_for_file: avoid_catches_without_on_clauses,type_annotate_public_apis,lines_longer_than_80_chars,avoid_equals_and_hash_code_on_mutable_classes' \
	| tee -a lib/src/api/*.chopper.dart lib/src/store/moor/*.g.dart

dartfmt lib/src/api/*.chopper.dart lib/src/store/moor/*.g.dart -w --fix
