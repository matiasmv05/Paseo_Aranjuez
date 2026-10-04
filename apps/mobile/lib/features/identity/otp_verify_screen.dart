import 'package:flutter/material.dart';

import 'data/mock_auth_repository.dart';
import 'identity_state.dart';
import 'login_screen.dart';

class OtpVerifyScreen extends StatefulWidget {
  OtpVerifyScreen({Key? key, this.phone = '', IdentityNotifier? notifier})
    : notifier = notifier ?? IdentityNotifier(MockAuthRepository()),
      super(key: key);

  final String phone;
  final IdentityNotifier notifier;

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final TextEditingController _otpController = TextEditingController();
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
    if (state is OtpVerified) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _navigatorKey.currentState?.push(
          MaterialPageRoute<Widget>(builder: (_) => const LoginScreen()),
        );
      });
    }
  }

  @override
  void dispose() {
    widget.notifier.removeListener(_onStateChanged);
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      home: Scaffold(
        appBar: AppBar(title: const Text('Verify OTP')),
        body: Builder(
          builder: (context) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  key: const Key('otpField'),
                  controller: _otpController,
                  maxLength: 6,
                  decoration: const InputDecoration(labelText: 'OTP'),
                  keyboardType: TextInputType.number,
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
                              key: const Key('otpErrorText'),
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        if (state is IdentityLoading)
                          const CircularProgressIndicator()
                        else
                          ElevatedButton(
                            key: const Key('verifyOtpButton'),
                            onPressed: () async {
                              await widget.notifier.verifyOtp(
                                widget.phone,
                                _otpController.text,
                              );
                            },
                            child: const Text('Verify'),
                          ),
                      ],
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
