import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import 'identity_state.dart';
import 'otp_verify_screen.dart';

class RegistrationScreen extends StatefulWidget {
  RegistrationScreen({Key? key, IdentityNotifier? notifier})
    : notifier =
          notifier ?? IdentityNotifier(InjectionContainer.authRepository),
      super(key: key);

  final IdentityNotifier notifier;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    final state = widget.notifier.value;
    if (state is OtpSentSuccess && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _navigatorKey.currentState?.push(
          MaterialPageRoute<Widget>(
            builder: (_) => OtpVerifyScreen(
              phone: _phoneController.text,
              notifier: widget.notifier,
            ),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onStateChanged);
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      home: Scaffold(
        body: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  key: const Key('phoneField'),
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const TextField(
                  key: Key('emailField'),
                  decoration: InputDecoration(labelText: 'Email'),
                ),
                const TextField(
                  key: Key('passwordField'),
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                ValueListenableBuilder<IdentityState>(
                  valueListenable: widget.notifier,
                  builder: (context, state, _) {
                    if (state is IdentityLoading) {
                      return const CircularProgressIndicator();
                    }
                    return ElevatedButton(
                      key: const Key('registerButton'),
                      onPressed: () async {
                        await widget.notifier.sendOtp(_phoneController.text);
                      },
                      child: const Text('Register'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
