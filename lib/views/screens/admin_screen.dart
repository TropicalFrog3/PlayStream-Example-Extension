import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/auth_controller.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;
    
    if (user == null || !user.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Panel')),
        body: const Center(
          child: Text('Access Denied: Admin privileges required'),
        ),
      );
    }
    
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Panel'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Users'),
              Tab(text: 'Featured'),
              Tab(text: 'Content Filter'),
              Tab(text: 'Dev Tools'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Users management
            _UsersTab(),
            
            // Featured content management
            _FeaturedTab(),
            
            // Content filtering
            _ContentFilterTab(),
            
            // Developer tools
            _DevToolsTab(),
          ],
        ),
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Total Users'),
            subtitle: const Text('View and manage all users'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement user list
            },
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.person_remove),
            title: const Text('Delete User'),
            subtitle: const Text('Remove users from the system'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement user deletion
            },
          ),
        ),
      ],
    );
  }
}

class _FeaturedTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.star),
            title: const Text('Featured Movies'),
            subtitle: const Text('Manage featured content on home screen'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement featured management
            },
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.trending_up),
            title: const Text('Trending Override'),
            subtitle: const Text('Manually set trending content'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement trending override
            },
          ),
        ),
      ],
    );
  }
}

class _ContentFilterTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.filter_list),
            title: const Text('Content Filters'),
            subtitle: const Text('Set age ratings and content restrictions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement content filtering
            },
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Blocked Content'),
            subtitle: const Text('View and manage blocked movies/shows'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Implement blocked content management
            },
          ),
        ),
      ],
    );
  }
}

class _DevToolsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: const Icon(Icons.extension),
            title: const Text('Extension Manager'),
            subtitle: const Text('Manage installed extensions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              context.push('/extensions');
            },
          ),
        ),
      ],
    );
  }
}
