// lib/features/diary/diary_search_delegate.dart
import 'package:flutter/material.dart';

class DiarySearchDelegate extends SearchDelegate<String> {
  DiarySearchDelegate({required this.onSelect});
  final void Function(String id) onSelect;

  // 데모용 mock 데이터
  final _all = List.generate(
    50,
    (i) => {'id': '$i', 'title': 'Entry #$i', 'preview': 'This is diary $i'},
  );

  List<Map<String, String>> _filter(String q) {
    if (q.isEmpty) return _all.take(8).toList();
    final lq = q.toLowerCase();
    return _all
        .where(
          (e) =>
              e['title']!.toLowerCase().contains(lq) ||
              e['preview']!.toLowerCase().contains(lq),
        )
        .toList();
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = _filter(query);
    return _buildList(context, results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = _filter(query);
    return _buildList(context, results);
  }

  Widget _buildList(BuildContext context, List<Map<String, String>> items) {
    if (items.isEmpty) {
      return const Center(child: Text('No results'));
    }
    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final it = items[i];
        return ListTile(
          title: Text(it['title']!),
          subtitle: Text(
            it['preview']!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            onSelect(it['id']!);
            close(context, it['id']!);
          },
        );
      },
    );
  }
}
