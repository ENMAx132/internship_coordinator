import 'package:flutter_test/flutter_test.dart';
import 'package:inventario_pasantes/data/tutorial_store.dart';
import 'package:inventario_pasantes/models/catalog.dart';
import 'package:inventario_pasantes/models/tutorial_pending.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const catalogs = Catalogs(
    categories: [
      CatalogEntry(id: 1, code: 'general', name: 'General'),
    ],
    statuses: [
      CatalogEntry(
        id: 5,
        code: 'in_review',
        name: 'En revisión',
        isInReview: true,
      ),
    ],
    sectionEmojis: ['🏢'],
    spaceEmojis: ['💻'],
  );

  TutorialPending sample({
    TutorialDecision decision = TutorialDecision.keep,
  }) =>
      TutorialPending(
        sectionName: 'Apartado de ejemplo',
        sectionDescription: 'Creado por el tutorial',
        sectionIcon: '🏢',
        spaceName: 'Espacio de ejemplo',
        spaceDescription: 'Creado por el tutorial',
        spaceEmoji: '💻',
        itemName: 'Objeto de ejemplo',
        itemCode: 'TUTORIAL-001',
        categoryCode: 'general',
        statusCode: 'in_review',
        value: 100,
        responsible: 'Tutorial',
        brand: 'Demo',
        createdAt: DateTime.utc(2026, 11, 13, 15, 30),
        decision: decision,
      );

  test('serialización mantiene decisión e IDs remotos', () {
    final pending = sample().copyWith(
      remoteSectionId: 10,
      remoteSpaceId: 20,
      remoteItemId: 30,
    );
    final restored = TutorialPending.fromJson(pending.toJson());

    expect(restored.decision, TutorialDecision.keep);
    expect(restored.remoteSectionId, 10);
    expect(restored.remoteSpaceId, 20);
    expect(restored.remoteItemId, 30);
    expect(restored.itemCode, 'TUTORIAL-001');
  });

  test('toSection/toSpace/toItem usan IDs locales y catálogos', () {
    final pending = sample();
    final section = pending.toSection();
    final space = pending.toSpace();
    final item = pending.toItem(catalogs);

    expect(section.id, TutorialPending.localSectionId);
    expect(space.id, TutorialPending.localSpaceId);
    expect(space.sectionId, TutorialPending.localSectionId);
    expect(item.id, TutorialPending.localItemId);
    expect(item.sectionId, TutorialPending.localSectionId);
    expect(item.spaceId, TutorialPending.localSpaceId);
    expect(item.status.isInReview, isTrue);
    expect(item.category.code, 'general');
  });

  test('TutorialStore guarda, carga y limpia el pendiente', () async {
    SharedPreferences.setMockInitialValues({});
    final store = TutorialStore();

    expect(await store.loadPending(), isNull);

    await store.savePending(sample(decision: TutorialDecision.delete));
    final loaded = await store.loadPending();
    expect(loaded, isNotNull);
    expect(loaded!.decision, TutorialDecision.delete);

    await store.clearPending();
    expect(await store.loadPending(), isNull);
  });

  test('TutorialStore guarda la bandera local de completado', () async {
    SharedPreferences.setMockInitialValues({});
    final store = TutorialStore();

    expect(await store.isCompletedLocally(), isFalse);
    await store.markCompletedLocally();
    expect(await store.isCompletedLocally(), isTrue);
    await store.clearCompletedLocally();
    expect(await store.isCompletedLocally(), isFalse);
  });
}
