import 'package:flutter/material.dart';

class SearchHistoryView extends StatelessWidget {
  final List<String> searchHistory;
  final Function(String) onTermSelected;

  const SearchHistoryView({
    super.key,
    required this.searchHistory,
    required this.onTermSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (searchHistory.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Búsquedas recientes',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: searchHistory.map((term) {
              return ListTile(
                leading: const Icon(Icons.history, color: Colors.grey),
                title: Text(term),
                trailing: IconButton(
                  icon: const Icon(Icons.north_west, size: 18, color: Colors.grey),
                  onPressed: () => onTermSelected(term),
                ),
                onTap: () => onTermSelected(term),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}