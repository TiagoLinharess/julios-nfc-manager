import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../app/presentation/app_shell.dart';
import '../data/auth_repository.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final AuthRepository _authRepository = AuthRepository();

  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authRepository.signInWithGoogle();
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Firebase Auth: ${error.code}';
      });
    } on GoogleSignInException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Google Sign-In: ${error.code.name}';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    await _authRepository.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authRepository.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return _LoginPage(
            isLoading: _isLoading,
            errorMessage: _errorMessage,
            onSignInWithGoogle: _signInWithGoogle,
          );
        }

        return AppShell(user: user, onSignOut: _signOut);
      },
    );
  }
}

class _LoginPage extends StatelessWidget {
  const _LoginPage({
    required this.isLoading,
    required this.errorMessage,
    required this.onSignInWithGoogle,
  });

  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onSignInWithGoogle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompactHeight = constraints.maxHeight < 620;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(isCompactHeight ? 20 : 28),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(24),
                                  child: Image.asset(
                                    'assets/branding/app_icon_1024.png',
                                    width: isCompactHeight ? 82 : 104,
                                    height: isCompactHeight ? 82 : 104,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                SizedBox(height: isCompactHeight ? 16 : 20),
                                Text(
                                  'NFC Manager',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.onPrimaryContainer,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Controle notas, produtos e devoluções com sincronização em tempo real.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: colorScheme.onPrimaryContainer
                                            .withValues(alpha: 0.78),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: isCompactHeight ? 18 : 24),
                        FilledButton.icon(
                          onPressed: isLoading ? null : onSignInWithGoogle,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                          ),
                          icon: isLoading
                              ? const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.login),
                          label: const Text('Entrar com Google'),
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(color: colorScheme.error),
                          ),
                        ],
                        SizedBox(height: isCompactHeight ? 20 : 28),
                        const _LoginFeatureStrip(),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoginFeatureStrip extends StatelessWidget {
  const _LoginFeatureStrip();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _LoginFeatureItem(
            icon: Icons.receipt_long_outlined,
            label: 'NFCs',
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _LoginFeatureItem(
            icon: Icons.people_outline,
            label: 'Clientes',
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _LoginFeatureItem(
            icon: Icons.inventory_2_outlined,
            label: 'Produtos',
          ),
        ),
      ],
    );
  }
}

class _LoginFeatureItem extends StatelessWidget {
  const _LoginFeatureItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.7),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Column(
          children: [
            Icon(icon, size: 22, color: colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}
