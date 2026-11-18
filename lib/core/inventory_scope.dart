import 'package:flutter/widgets.dart';

import '../data/inventory_store.dart';

/// Expone el [InventoryStore] a todo el árbol de widgets.
class InventoryScope extends InheritedNotifier<InventoryStore> {
  const InventoryScope({
    super.key,
    required InventoryStore store,
    required super.child,
  }) : super(notifier: store);

  static InventoryStore of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<InventoryScope>();
    assert(scope != null, 'InventoryScope no encontrado en el contexto');
    return scope!.notifier!;
  }

  /// Igual que [of], pero devuelve `null` si no hay scope en el árbol.
  static InventoryStore? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InventoryScope>()?.notifier;
}
