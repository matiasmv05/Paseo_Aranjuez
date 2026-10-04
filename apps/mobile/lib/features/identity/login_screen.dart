import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import 'identity_state.dart';
import '../customer/profile_screen.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key? key, IdentityNotifier? notifier})
    : notifier =
          notifier ??
          IdentityNotifier(
            InjectionContainer.authRepository,
            tokenStorage: InjectionContainer.tokenStorage,
          ),
      super(key: key);

  final IdentityNotifier notifier;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    final state = widget.notifier.value;
    if (!mounted) {
      return;
    }
    if (state is OtpVerified || state is IdentityAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _navigatorKey.currentState?.push(
          MaterialPageRoute<Widget>(builder: (_) => ProfileScreen()),
        );
      });
    }
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onStateChanged);
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      home: Scaffold(
        appBar: AppBar(title: const Text('Login Screen')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                key: const Key('loginPhoneField'),
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              TextField(
                key: const Key('loginCodeField'),
                controller: _codeController,
                maxLength: 6,
                decoration: const InputDecoration(labelText: 'OTP'),
                keyboardType: TextInputType.number,
                obscureText: true,
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<IdentityState>(
                valueListenable: widget.notifier,
                builder: (context, state, _) {
                  return Column(
                    children: [
                      if (state is IdentityFailure)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(
                            state.message,
                            key: const Key('loginErrorText'),
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      if (state is IdentityLoading)
                        const CircularProgressIndicator()
                      else
                        ElevatedButton(
                          key: const Key('loginButton'),
                          onPressed: () async {
                            await widget.notifier.verifyOtp(
                              _phoneController.text,
                              _codeController.text,
                            );
                          },
                          child: const Text('Login'),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
