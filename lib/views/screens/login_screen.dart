import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/auth_controller.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'PlayStream',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 48),
              Text(
                'Stream your favorite movies and shows',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              authState.when(
                data: (user) {
                  if (user != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      context.go('/home');
                    });
                    return const CircularProgressIndicator();
                  }
                  return ElevatedButton(
                    onPressed: () async {
                      await ref.read(authControllerProvider.notifier).login();
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      child: Text('Login with Auth0'),
                    ),
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (error, _) => Column(
                  children: [
                    Text('Error: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        await ref.read(authControllerProvider.notifier).login();
                      },
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
