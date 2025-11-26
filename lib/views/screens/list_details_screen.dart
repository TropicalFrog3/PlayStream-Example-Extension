import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../models/trakt/trakt_list.dart';
import '../../services/trakt/trakt_client.dart';

final listItemsProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, Map<String, String>>((ref, params) async {
  final client = TraktClient();
  return await client.lists.getListItems(
    username: params['username']!,
    listId: params['listId']!,
    extended: 'full',
  );
});

class ListDetailsScreen extends ConsumerWidget {
  final TraktList list;
  
  const ListDetailsScreen({super.key, required this.list});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listItemsAsync = ref.watch(listItemsProvider({
      'username': list.user.username,
      'listId': list.ids.slug,
    }));
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(list.name),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // List header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (list.description != null) ...[
                  Text(
                    list.description!,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey[400], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      list.user.username,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.favorite, color: Colors.red, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${list.likes}',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.list, color: Colors.grey[400], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${list.itemCount} items',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: Colors.grey),
          // List items
          Expanded(
            child: listItemsAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text(
                      'No items in this list',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _buildListItem(context, item);
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
              ),
              error: (error, stack) => Center(
                child: Text(
                  'Error loading list items: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildListItem(BuildContext context, Map<String, dynamic> item) {
    final type = item['type'] as String?;
    final movie = item['movie'];
    final show = item['show'];
    
    String? title;
    String? subtitle;
    double? rating;
    String? slug;
    
    if (type == 'movie' && movie != null) {
      title = movie['title'];
      subtitle = movie['year']?.toString();
      rating = movie['rating']?.toDouble();
      slug = movie['ids']?['slug'];
    } else if (type == 'show' && show != null) {
      title = show['title'];
      subtitle = show['year']?.toString();
      rating = show['rating']?.toDouble();
      slug = show['ids']?['slug'];
    }
    
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () {
          if (slug != null) {
            if (type == 'movie') {
              context.push('/movie/$slug');
            } else if (type == 'show') {
              context.push('/show/$slug');
            }
          }
        },
        leading: Container(
          width: 50,
          height: 75,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            type == 'movie' ? Icons.movie : Icons.tv,
            color: Colors.grey[600],
          ),
        ),
        title: Text(
          title ?? 'Unknown',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Row(
          children: [
            if (subtitle != null) ...[
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(width: 8),
            ],
            if (rating != null && rating > 0) ...[
              const Icon(Icons.star, color: Colors.amber, size: 14),
              const SizedBox(width: 2),
              Text(
                rating.toStringAsFixed(1),
                style: TextStyle(color: Colors.grey[400]),
              ),
            ],
          ],
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: Colors.grey[600],
        ),
      ),
    );
  }
}
