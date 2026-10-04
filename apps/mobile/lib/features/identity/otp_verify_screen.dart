import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/di/injection.dart';
import 'identity_state.dart';
import 'login_screen.dart';

class OtpVerifyScreen extends StatefulWidget {
  OtpVerifyScreen({Key? key, this.phone = '', IdentityNotifier? notifier})
    : notifier =
          notifier ??
          IdentityNotifier(
            InjectionContainer.authRepository,
            tokenStorage: InjectionContainer.tokenStorage,
          ),
      super(key: key);

  final String phone;
  final IdentityNotifier notifier;

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  static const _resendCooldownSeconds = 60;

  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  Timer? _resendTimer;
  int _secondsRemaining = _resendCooldownSeconds;

  @override
  void initState() {
    super.initState();
    widget.notifier.addListener(_onStateChanged);
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _secondsRemaining = _resendCooldownSeconds;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        }
        if (_secondsRemaining == 0) {
          timer.cancel();
        }
      });
    });
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
          MaterialPageRoute<Widget>(builder: (_) => LoginScreen()),
        );
      });
    }
  }

  Future<void> _resendCode(BuildContext context) async {
    await widget.notifier.sendOtp(widget.phone);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Código reenviado con éxito')));
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
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
                const SizedBox(height: 8),
                Text(
                  _secondsRemaining > 0
                      ? 'Reenviar código en ${_secondsRemaining}s'
                      : '¿No recibiste el código?',
                  key: const Key('resendCountdownText'),
                ),
                TextButton(
                  key: const Key('resendOtpButton'),
                  onPressed: _secondsRemaining > 0
                      ? null
                      : () => _resendCode(context),
                  child: const Text('Reenviar código'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
