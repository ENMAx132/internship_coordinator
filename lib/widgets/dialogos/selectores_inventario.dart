import 'package:flutter/material.dart';

import '../../models/account.dart';

/// Selección múltiple de usuarios asignados (solo administradores).
class UsuariosAsignadosSelector extends StatelessWidget {
  const UsuariosAsignadosSelector({
    super.key,
    required this.accounts,
    required this.selectedIds,
    required this.onChanged,
  });

  final List<Account> accounts;
  final Set<int> selectedIds;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    if (accounts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No hay cuentas disponibles para asignar.',
          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          selectedIds.isEmpty
              ? 'Ningún usuario asignado'
              : '${selectedIds.length} usuario(s) asignado(s)',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: accounts.map((account) {
            final selected = selectedIds.contains(account.id);
            return FilterChip(
              label: Text(
                '${account.name} · ${account.roleLabel}',
                style: const TextStyle(fontSize: 11),
              ),
              selected: selected,
              onSelected: (value) {
                final next = {...selectedIds};
                if (value) {
                  next.add(account.id);
                } else {
                  next.remove(account.id);
                }
                onChanged(next);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Selector de responsable a partir de las cuentas de la API.
class ResponsableUsuarioSelector extends StatelessWidget {
  const ResponsableUsuarioSelector({
    super.key,
    required this.accounts,
    required this.selectedId,
    required this.onChanged,
    this.fallbackName,
    this.enabled = true,
    this.lockedName,
    this.label = 'Responsable',
  });

  final List<Account> accounts;
  final int? selectedId;
  final ValueChanged<int?> onChanged;
  final String? fallbackName;
  final bool enabled;

  /// Cuando no se puede elegir (USER), muestra este nombre en solo lectura.
  final String? lockedName;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          helperText: 'Los colaboradores solo pueden ser responsables ellos '
              'mismos.',
        ),
        child: Text(
          lockedName ?? 'Sin asignar',
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
      );
    }

    final exists = selectedId != null &&
        accounts.any((account) => account.id == selectedId);
    final value = exists ? selectedId! : 0;
    final items = <DropdownMenuItem<int>>[
      const DropdownMenuItem(value: 0, child: Text('Sin responsable')),
      if (selectedId != null && !exists)
        DropdownMenuItem(
          value: selectedId!,
          child: Text(fallbackName ?? 'Usuario $selectedId'),
        ),
      ...accounts.map(
        (account) => DropdownMenuItem(
          value: account.id,
          child: Text(
            '${account.name} · ${account.roleLabel}',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ];

    return DropdownButtonFormField<int>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: items,
      onChanged: (selected) => onChanged(selected == 0 ? null : selected),
    );
  }
}
