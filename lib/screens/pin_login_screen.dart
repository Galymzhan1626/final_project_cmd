import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:invent_app_redesign/screens/home_screen.dart';

class PinLoginScreen extends StatefulWidget {
  const PinLoginScreen({Key? key}) : super(key: key);

  @override
  _PinLoginScreenState createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends State<PinLoginScreen> {
  final _storage = const FlutterSecureStorage();
  final _pinController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isPinSet = false;
  bool _isResetting = false;

  @override
  void initState() {
    super.initState();
    _checkIfPinIsSet();
  }

  Future<void> _checkIfPinIsSet() async {
    String? storedPin = await _storage.read(key: 'user_pin');
    setState(() {
      _isPinSet = storedPin != null;
    });
  }

  Future<void> _setPin(String pin) async {
    await _storage.write(key: 'user_pin', value: pin);
    setState(() {
      _isPinSet = true;
      _errorMessage = 'PIN set successfully!';
    });
    // Navigate to HomeScreen after setting PIN
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  Future<bool> _verifyPin(String pin) async {
    String? storedPin = await _storage.read(key: 'user_pin');
    return storedPin == pin;
  }

  void _onPinSubmitted(String pin) async {
    if (_isPinSet) {
      // Verify PIN for login
      bool isValid = await _verifyPin(pin);
      if (isValid) {
        setState(() {
          _errorMessage = null;
        });
        // Navigate to HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        setState(() {
          _errorMessage = 'Incorrect PIN';
        });
      }
    } else {
      // Set new PIN
      await _setPin(pin);
      _pinController.clear();
    }
  }

  Future<void> _resetPin() async {
    final user = FirebaseAuth.instance.currentUser;
    final prefs = await SharedPreferences.getInstance();
    final isGuest = prefs.getBool('isGuest') ?? false;

    if (isGuest || user == null) {
      // Guest mode: Confirm reset with dialog
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reset PIN'),
          content: const Text('As a guest, resetting the PIN will clear it without verification. Continue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Reset'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await _storage.delete(key: 'user_pin');
        setState(() {
          _isPinSet = false;
          _errorMessage = 'PIN reset. Please set a new PIN.';
          _pinController.clear();
        });
      }
    } else {
      // Firebase user: Prompt re-authentication
      setState(() {
        _isResetting = true;
      });
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Reset PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your email and password to verify your identity.'),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final credential = EmailAuthProvider.credential(
                    email: _emailController.text.trim(),
                    password: _passwordController.text.trim(),
                  );
                  await user.reauthenticateWithCredential(credential);
                  await _storage.delete(key: 'user_pin');
                  setState(() {
                    _isPinSet = false;
                    _errorMessage = 'PIN reset. Please set a new PIN.';
                    _pinController.clear();
                  });
                  Navigator.pop(context);
                } catch (e) {
                  setState(() {
                    _errorMessage = 'Authentication failed. Please try again.';
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Verify'),
            ),
          ],
        ),
      );
      setState(() {
        _isResetting = false;
        _emailController.clear();
        _passwordController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isPinSet ? 'Enter PIN' : 'Set PIN')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PinCodeTextField(
              appContext: context,
              length: 4,
              controller: _pinController,
              onCompleted: _onPinSubmitted,
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(5),
                fieldHeight: 50,
                fieldWidth: 40,
                activeFillColor: Colors.white,
              ),
              keyboardType: TextInputType.number,
              enabled: !_isResetting,
            ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: _errorMessage!.contains('success') ? Colors.green : Colors.red,
                  ),
                ),
              ),
            if (_isPinSet)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: TextButton(
                  onPressed: _isResetting ? null : _resetPin,
                  child: const Text(
                    'Forgot PIN?',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}