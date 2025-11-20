// lib/features/diary/presentation/hive_data_viewer_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class HiveDataViewerScreen extends ConsumerWidget {
  const HiveDataViewerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hive Data Viewer'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Diary Entries'),
              Tab(text: 'Purchased Diaries'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBoxViewer('diary_entries'),
            _buildBoxViewer('purchased_diaries'),
          ],
        ),
      ),
    );
  }

  Widget _buildBoxViewer(String boxName) {
    final box = Hive.box<Map>(boxName);

    return ListView.builder(
      itemCount: box.length,
      itemBuilder: (context, index) {
        final key = box.keyAt(index);
        final value = box.getAt(index);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ExpansionTile(
            title: Text('Key: $key'),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children:
                      value?.entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(entry.value.toString()),
                              ),
                            ],
                          ),
                        );
                      }).toList() ??
                      [],
                ),
              ),
              ButtonBar(
                children: [
                  TextButton(
                    onPressed: () => box.delete(key),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
