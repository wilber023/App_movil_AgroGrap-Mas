import 'package:flutter_test/flutter_test.dart';

import 'package:agrograp_movil/features/offline_knowledge/data/datasources/knowledge_local_datasource.dart';

void main() {
  test('vectores idénticos -> score 1.0', () {
    final a = [1.0, 2.0, 3.0];
    final b = [1.0, 2.0, 3.0];

    expect(cosineSimilarity(a, b), closeTo(1.0, 1e-9));
  });

  test('vectores ortogonales -> score 0.0', () {
    final a = [1.0, 0.0];
    final b = [0.0, 1.0];

    expect(cosineSimilarity(a, b), closeTo(0.0, 1e-9));
  });

  test('vectores opuestos -> score -1.0', () {
    final a = [1.0, 0.0, 0.0];
    final b = [-1.0, 0.0, 0.0];

    expect(cosineSimilarity(a, b), closeTo(-1.0, 1e-9));
  });

  test('vectores parcialmente similares -> score intermedio', () {
    final a = [1.0, 1.0, 0.0];
    final b = [1.0, 0.0, 0.0];

    // cos(45°) ≈ 0.7071
    expect(cosineSimilarity(a, b), closeTo(0.7071, 1e-3));
  });

  test('vector cero -> score 0.0 (evita división por cero)', () {
    final a = [0.0, 0.0, 0.0];
    final b = [1.0, 2.0, 3.0];

    expect(cosineSimilarity(a, b), 0.0);
  });
}
