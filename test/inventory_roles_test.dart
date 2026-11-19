import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_pasantes/core/api_client.dart';
import 'package:inventario_pasantes/core/session.dart';
import 'package:inventario_pasantes/data/inventory_repository.dart';
import 'package:inventario_pasantes/data/inventory_store.dart';
import 'package:inventario_pasantes/data/local_inventory_cache.dart';
import 'package:inventario_pasantes/data/tutorial_store.dart';
import 'package:inventario_pasantes/models/account.dart';
import 'package:inventario_pasantes/models/catalog.dart';
import 'package:inventario_pasantes/models/inventory_item.dart';
import 'package:inventario_pasantes/models/section.dart';
import 'package:inventario_pasantes/models/space.dart';

InventoryStore _store(String role, {int userId = 10}) => InventoryStore(
      repository: InventoryRepository(
        ApiClient(apiRoot: 'https://example.com/api', token: 'token'),
      ),
      cache: LocalInventoryCache(userId: userId),
      session: Session(
        token: 'token',
        tokenType: 'bearer',
        user: SessionUser(
          id: userId,
          name: 'Usuario $role',
          email: 'user@example.com',
          role: role,
        ),
      ),
      sessionStore: SessionStore(),
      tutorialStore: TutorialStore(),
    );

Section _section({
  int id = 1,
  bool personal = false,
  int? ownerId,
  List<UserRef> assigned = const [],
}) =>
    Section(
      id: id,
      name: 'Apartado $id',
      description: '',
      icon: '🏢',
      sortOrder: 0,
      isPersonal: personal,
      owner: ownerId == null ? null : UserRef(id: ownerId, name: 'Owner'),
      assignedUsers: assigned,
    );

Space _space({int id = 1, int sectionId = 1}) => Space(
      id: id,
      sectionId: sectionId,
      name: 'Espacio $id',
      description: '',
      emoji: '📦',
    );

InventoryItem _item({int id = 1, int sectionId = 1, int spaceId = 1}) =>
    InventoryItem(
      id: id,
      code: 'ACT-00$id',
      name: 'Objeto $id',
      spaceId: spaceId,
      spaceName: 'Espacio',
      spaceEmoji: '📦',
      sectionId: sectionId,
      sectionName: 'Apartado',
      sectionIcon: '🏢',
      category: const CatalogEntry(id: 1, code: 'general', name: 'General'),
      status: const CatalogEntry(
        id: 1,
        code: 'excellent',
        name: 'Excelente',
      ),
      value: 0,
      responsible: 'Sin asignar',
      brand: '',
      registeredAt: DateTime(2026, 1, 1),
    );

void main() {
  group('permisos por rol', () {
    test('ADMIN edita todo y administra asignaciones', () {
      final store = _store('ADMIN', userId: 1);
      final propia = _section(id: 1, personal: true, ownerId: 2);
      final compartida = _section(id: 2);
      final asignada = _section(
        id: 3,
        assigned: const [UserRef(id: 3, name: 'Ana')],
      );

      expect(store.canWrite, isTrue);
      expect(store.canManageAssignments, isTrue);
      expect(store.showHistory, isTrue);
      expect(store.canReorderSections, isTrue);
      expect(store.canEditSection(propia), isTrue);
      expect(store.canEditSection(compartida), isTrue);
      expect(store.canEditSection(asignada), isTrue);
      expect(store.canEditSpace(_space()), isTrue);
      expect(store.canEditItem(_item()), isTrue);
    });

    test('SUPERVISOR solo lectura, ve historial y filtros', () {
      final store = _store('SUPERVISOR');
      final personal = _section(personal: true, ownerId: 10);

      expect(store.canWrite, isFalse);
      expect(store.showHistory, isTrue);
      expect(store.canReorderSections, isFalse);
      expect(store.canManageAssignments, isFalse);
      expect(store.canEditSection(personal), isFalse);
      expect(store.canEditSpace(_space()), isFalse);
      expect(store.canEditItem(_item()), isFalse);
    });

    test('USER edita solo su inventario personal', () {
      final store = _store('USER', userId: 10);
      store.sections = [
        _section(id: 1, personal: true, ownerId: 10),
        _section(id: 2, personal: true, ownerId: 11),
        _section(
          id: 3,
          assigned: const [UserRef(id: 10, name: 'Yo')],
        ),
        _section(id: 4),
      ];
      store.spaces = [
        _space(id: 1, sectionId: 1),
        _space(id: 2, sectionId: 2),
        _space(id: 3, sectionId: 3),
      ];
      store.items = [
        _item(id: 1, sectionId: 1, spaceId: 1),
        _item(id: 2, sectionId: 2, spaceId: 2),
        _item(id: 3, sectionId: 3, spaceId: 3),
      ];

      expect(store.canWrite, isTrue);
      expect(store.showHistory, isFalse);
      expect(store.canReorderSections, isFalse);
      expect(store.canManageAssignments, isFalse);

      expect(store.canEditSection(store.sections[0]), isTrue);
      expect(store.canEditSection(store.sections[1]), isFalse);
      expect(store.canEditSection(store.sections[2]), isFalse);
      expect(store.canEditSection(store.sections[3]), isFalse);

      expect(store.canEditSpace(store.spaces[0]), isTrue);
      expect(store.canEditSpace(store.spaces[1]), isFalse);
      expect(store.canEditSpace(store.spaces[2]), isFalse);

      expect(store.canEditItem(store.items[0]), isTrue);
      expect(store.canEditItem(store.items[1]), isFalse);
      expect(store.canEditItem(store.items[2]), isFalse);

      expect(store.editableSections.map((s) => s.id), [1]);
      expect(store.editableSpaces.map((s) => s.id), [1]);
    });
  });

  group('sesión', () {
    test('USER accede al inventario y SHOWQR no', () {
      const user = SessionUser(
        id: 1,
        name: 'U',
        email: 'u@example.com',
        role: 'USER',
      );
      const showQr = SessionUser(
        id: 2,
        name: 'Q',
        email: 'q@example.com',
        role: 'SHOWQR',
      );
      const supervisor = SessionUser(
        id: 3,
        name: 'S',
        email: 's@example.com',
        role: 'SUPERVISOR',
      );

      expect(user.canAccessInventory, isTrue);
      expect(user.canWrite, isTrue);
      expect(showQr.canAccessInventory, isFalse);
      expect(showQr.canWrite, isFalse);
      expect(supervisor.canAccessInventory, isTrue);
      expect(supervisor.canWrite, isFalse);
      expect(supervisor.canViewHistory, isTrue);
    });
  });

  group('serialización de propiedad', () {
    test('Section conserva is_personal, owner y usuarios asignados', () {
      final section = Section.fromJson({
        'id': 7,
        'name': 'Mi mochila',
        'description': 'Personal',
        'icon': '🎒',
        'sort_order': 0,
        'is_personal': true,
        'owner': {'id': 10, 'name': 'Ana'},
        'assigned_users': [
          {'id': 11, 'name': 'Luis', 'role': 'USER'},
        ],
      });

      expect(section.isPersonal, isTrue);
      expect(section.owner?.id, 10);
      expect(section.isOwnedBy(10), isTrue);
      expect(section.assignedUsers.single.role, 'USER');

      final json = section.toJson();
      expect(json['is_personal'], isTrue);
      expect(json['owner']['id'], 10);
      expect(json['assigned_users'], hasLength(1));

      final restored = Section.fromJson(json);
      expect(restored.isPersonal, isTrue);
      expect(restored.owner?.name, 'Ana');
      expect(restored.assignedUsers.single.name, 'Luis');
    });

    test('Space interpreta subespacios, totales y asignaciones', () {
      final space = Space.fromJson({
        'id': 3,
        'section_id': 7,
        'parent_space_id': 2,
        'name': 'Cajón',
        'emoji': '📦',
        'item_count': 2,
        'subspace_count': 1,
        'total_item_count': 5,
        'is_personal': true,
        'assigned_users': [
          {'id': 11, 'name': 'Luis', 'role': 'USER'},
        ],
      });

      expect(space.parentSpaceId, 2);
      expect(space.subspaceCount, 1);
      expect(space.totalItemCount, 5);
      expect(space.isPersonal, isTrue);
      expect(space.assignedUsers.single.name, 'Luis');

      final restored = Space.fromJson(space.toJson());
      expect(restored.totalItemCount, 5);
      expect(restored.isPersonal, isTrue);
    });

    test('Item conserva responsable y usuarios asignados', () {
      final item = InventoryItem.fromJson({
        'id': 9,
        'code': 'ACT-009',
        'name': 'Laptop',
        'space_id': 3,
        'space': {'id': 3, 'name': 'Cajón', 'emoji': '📦'},
        'section_id': 7,
        'section': {'id': 7, 'name': 'Mi mochila', 'icon': '🎒'},
        'category': {'id': 1, 'code': 'general', 'name': 'General'},
        'status': {'id': 1, 'code': 'excellent', 'name': 'Excelente'},
        'value': 100,
        'responsible': 'Ana',
        'responsible_user': {'id': 10, 'name': 'Ana', 'role': 'USER'},
        'assigned_users': [
          {'id': 11, 'name': 'Luis', 'role': 'USER'},
        ],
        'brand': 'Lenovo',
        'is_personal': true,
        'registered_at': '2026-01-01T00:00:00.000000Z',
      });

      expect(item.isPersonal, isTrue);
      expect(item.responsibleUser?.id, 10);
      expect(item.displayResponsible, 'Ana');
      expect(item.assignedUsers.single.name, 'Luis');

      final restored = InventoryItem.fromJson(item.toJson());
      expect(restored.responsibleUser?.name, 'Ana');
      expect(restored.isPersonal, isTrue);
      expect(restored.assignedUsers, hasLength(1));
    });
  });
}
