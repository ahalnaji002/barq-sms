import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_security_provider.dart';

class AppLockGate extends StatefulWidget {
  final Widget child;

  const AppLockGate({super.key, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      context.read<AppSecurityProvider>().lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final security = context.watch<AppSecurityProvider>();
    if (!security.initialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!security.isUnlocked) return const AppLockScreen();
    return widget.child;
  }
}

class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _checking = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    final success =
        await context.read<AppSecurityProvider>().unlock(_controller.text);
    if (!mounted || success) return;
    setState(() {
      _checking = false;
      _error = 'رمز PIN غير صحيح';
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 42,
                      backgroundColor: Color(0xFFFFE7A0),
                      child: Icon(Icons.lock_rounded,
                          size: 43, color: Color(0xFF202020)),
                    ),
                    const SizedBox(height: 24),
                    const Text('Barq SMS مقفل',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    const Text('أدخل رمز PIN للوصول إلى بيانات المستفيدين'),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _controller,
                      autofocus: true,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      maxLength: 8,
                      onSubmitted: (_) => _unlock(),
                      decoration: InputDecoration(
                        labelText: 'رمز PIN',
                        errorText: _error,
                        prefixIcon: const Icon(Icons.password_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: _checking ? null : _unlock,
                        icon: _checking
                            ? const SizedBox.square(
                                dimension: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.lock_open_rounded),
                        label: const Text('فتح التطبيق'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
