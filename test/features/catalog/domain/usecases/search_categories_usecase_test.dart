import 'package:flutter_test/flutter_test.dart';
import 'package:guiautomotriz_mobile/features/catalog/domain/entities/category_node.dart';
import 'package:guiautomotriz_mobile/features/catalog/domain/usecases/search_categories_usecase.dart';

void main() {
  late SearchCategoriesUseCase useCase;

  setUp(() {
    useCase = const SearchCategoriesUseCase();
  });

  final sampleTree = [
    const CategoryNode(
      id: 'cat-1',
      name: 'Frenos',
      children: [
        CategoryNode(
          id: 'cat-1-1',
          name: 'Disco y Pastillas',
          parentId: 'cat-1',
          children: [
            CategoryNode(
              id: 'cat-1-1-1',
              name: 'Pastillas cerámicas',
              parentId: 'cat-1-1',
            ),
            CategoryNode(
              id: 'cat-1-1-2',
              name: 'Discos ventilados',
              parentId: 'cat-1-1',
            ),
          ],
        ),
      ],
    ),
    const CategoryNode(
      id: 'cat-2',
      name: 'Motor',
      children: [
        CategoryNode(
          id: 'cat-2-1',
          name: 'Filtros de aceite',
          parentId: 'cat-2',
        ),
      ],
    ),
  ];

  test('should return empty list when query is empty or less than 2 characters', () {
    expect(useCase(sampleTree, ''), isEmpty);
    expect(useCase(sampleTree, 'a'), isEmpty);
  });

  test('should find matching nodes recursively and build accurate breadcrumbs', () {
    final results = useCase(sampleTree, 'past');

    expect(results.length, equals(2));
    expect(results[0].node.name, equals('Disco y Pastillas'));
    expect(results[0].breadcrumbLabel, equals('Frenos'));

    expect(results[1].node.name, equals('Pastillas cerámicas'));
    expect(results[1].breadcrumbLabel, equals('Frenos / Disco y Pastillas'));
  });

  test('should perform case-insensitive matching', () {
    final results = useCase(sampleTree, 'FRENOS');

    expect(results.isNotEmpty, isTrue);
    expect(results[0].node.name, equals('Frenos'));
  });
}
