import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_pasantes/models/space.dart';

Space _space({
  required int id,
  int sectionId = 1,
  int? parentSpaceId,
  String? name,
}) =>
    Space(
      id: id,
      sectionId: sectionId,
      name: name ?? 'Espacio $id',
      description: '',
      emoji: '📦',
      parentSpaceId: parentSpaceId,
    );

void main() {
  group('jerarquía de espacios', () {
    final spaces = [
      _space(id: 1, name: 'Sala 1'),
      _space(id: 2, parentSpaceId: 1, name: 'Cajón A'),
      _space(id: 3, parentSpaceId: 2, name: 'Caja 3'),
      _space(id: 4, parentSpaceId: 1, name: 'Cajón B'),
      _space(id: 5, name: 'Sala 2'),
    ];

    test('construye la ruta completa sin importar la profundidad', () {
      final caja = spaces.firstWhere((space) => space.id == 3);
      expect(caja.pathLabel(spaces), 'Sala 1 / Cajón A / Caja 3');
    });

    test('detecta todos los descendientes de un espacio', () {
      expect(Space.descendantIdsOf(1, spaces), {2, 3, 4});
      expect(Space.descendantIdsOf(2, spaces), {3});
      expect(Space.descendantIdsOf(4, spaces), isEmpty);
    });

    test('detecta si un espacio está dentro de otro', () {
      final caja = spaces.firstWhere((space) => space.id == 3);
      expect(caja.isDescendantOf(1, spaces), isTrue);
      expect(caja.isDescendantOf(2, spaces), isTrue);
      expect(caja.isDescendantOf(5, spaces), isFalse);
    });

    test('interpreta parent_space_id 0 como espacio raíz', () {
      final space = Space.fromJson({
        'id': 7,
        'section_id': 1,
        'name': 'Sala',
        'parent_space_id': 0,
      });
      expect(space.parentSpaceId, isNull);
      expect(space.isRoot, isTrue);
    });

    test('no entra en bucle si los datos tienen un ciclo', () {
      final ciclo = [
        _space(id: 1, parentSpaceId: 2, name: 'A'),
        _space(id: 2, parentSpaceId: 1, name: 'B'),
      ];
      expect(ciclo.first.pathLabel(ciclo), 'B / A');
      expect(Space.descendantIdsOf(1, ciclo), {2});
    });
  });
}
