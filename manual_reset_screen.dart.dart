import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';
import 'main.dart';
import 'signin.dart';
import 'weather_main.dart';

class ManualResetScreen extends StatefulWidget {
  final String email;

  const ManualResetScreen({required this.email, Key? key}) : super(key: key);

  @override
  _ManualResetScreenState createState() => _ManualResetScreenState();
}

class _ManualResetScreenState extends State<ManualResetScreen> {
  final _otpControllers = List.generate(6, (_) => TextEditingController());
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _successMessage;
  Timer? _resendTimer;
  int _resendCooldown = 60;

  String get _enteredOtp =>
      _otpControllers.map((controller) => controller.text).join();

  @override
  void initState() {
    super.initState();
    _startResendCooldown();
  }

  void _startResendCooldown() {
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 0) {
        timer.cancel();
        if (mounted) setState(() {});
        return;
      }
      if (mounted) setState(() => _resendCooldown--);
    });
  }

  Future<void> _resendOtp() async {
    if (_resendCooldown > 0) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(widget.email);
      setState(() {
        _resendCooldown = 60;
        _startResendCooldown();
      });
      _showSnack('✅ New OTP sent to ${widget.email}');
    } catch (e) {
      _showSnack('❌ Failed to resend OTP: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _enteredOtp.length < 6) {
      if (_enteredOtp.length < 6) {
        _showSnack('❌ Veuillez entrer un code OTP complet à 6 chiffres');
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final client = Supabase.instance.client;
      final newPassword = _newPasswordController.text.trim();

      // Step 1: Verify OTP
      final authResponse = await client.auth.verifyOTP(
        email: widget.email,
        token: _enteredOtp,
        type: OtpType.recovery,
      );

      // Step 2: If OTP is valid, update password
      if (authResponse.session != null) {
        // Update password first
        await client.auth.updateUser(UserAttributes(password: newPassword));

        // Show success message
        _showSnack('✅ Mot de passe réinitialisé avec succès');

        // Optional: Sign out to clear the session
        await client.auth.signOut();

        // Navigate after successful password update
        if (mounted) {
          // Small delay to allow snackbar to be visible
          await Future.delayed(const Duration(milliseconds: 500));

          Navigator.of(context).pushAndRemoveUntil(
            PageRouteBuilder(
              pageBuilder:
                  (context, animation, secondaryAnimation) => LoginScreen(),
              transitionsBuilder: (
                context,
                animation,
                secondaryAnimation,
                child,
              ) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: Duration(milliseconds: 300),
            ),
            (route) => false,
          );
        }
      } else {
        throw AuthException('Code OTP invalide');
      }
    } on AuthException catch (e) {
      _showSnack('❌ ${e.message}');
    } catch (e) {
      _showSnack('❌ Erreur: ${e.toString()}');
      debugPrint('Reset error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),

        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height * 0.1,
          left: 20,
          right: 20,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var c in _otpControllers) {
      c.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildOtpFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verification Code',
          style: GoogleFonts.robotoSlab(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) {
            return SizedBox(
              width: 45,
              child: TextFormField(
                controller: _otpControllers[index],
                textAlign: TextAlign.center,
                maxLength: 1,
                keyboardType: TextInputType.number,
                style:  GoogleFonts.robotoSlab(fontSize: 20),
                decoration: InputDecoration(
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Color(0xFF0D8BFF),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value.isNotEmpty && index < 5) {
                    FocusScope.of(context).nextFocus();
                  } else if (value.isEmpty && index > 0) {
                    FocusScope.of(context).previousFocus();
                  }
                  if (value.isNotEmpty && index == 5) {
                    FocusScope.of(context).unfocus();
                  }
                },
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _newPasswordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'New Password',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() => _obscurePassword = !_obscurePassword);
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return 'Password is required';
        if (value.length < 8) return 'Minimum 8 characters';
        if (!value.contains(RegExp(r'[A-Z]')))
          return 'Include uppercase letter';
        if (!value.contains(RegExp(r'[0-9]'))) return 'Include number';
        if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
          return 'Include special character';
        }
        return null;
      },
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
          },
        ),
      ),
      validator: (value) {
        if (value != _newPasswordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildResendButton() {
    return Center(
      child: TextButton(
        onPressed: _resendCooldown > 0 ? null : _resendOtp,
        child: Text(
          _resendCooldown > 0
              ? 'Resend OTP in $_resendCooldown seconds'
              : 'Resend OTP',
          style: GoogleFonts.robotoSlab(
            color: _resendCooldown > 0 ? Colors.grey : const Color(0xFF0D8BFF),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/backimg.png',
              opacity: const AlwaysStoppedAnimation(.3),
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppBar(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            leading: IconButton(
                              icon: const Icon(
                                Icons.arrow_back,
                                color: Colors.black,
                              ),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Reset Password',
                            style: GoogleFonts.robotoSlab(
                              color: const Color(0xFF0D8BFF),
                              fontWeight: FontWeight.bold,
                              fontSize: 37,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Enter the 6-digit OTP sent to ${widget.email}',
                            style: GoogleFonts.robotoSlab(
                              color: Colors.black,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                _buildOtpFields(),
                                _buildResendButton(),
                                const SizedBox(height: 20),
                                _buildPasswordField(),
                                const SizedBox(height: 20),
                                _buildConfirmPasswordField(),
                                const SizedBox(height: 30),
                                if (_successMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: Text(
                                      _successMessage!,
                                      style: GoogleFonts.robotoSlab(
                                        color: Colors.green,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0D8BFF),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child:
                                        _isLoading
                                            ? const CircularProgressIndicator(
                                              color: Colors.white,
                                            )
                                            : Text(
                                              'Reset Password',
                                              style: GoogleFonts.robotoSlab(
                                                color: Colors.white,
                                                fontSize: 18,
                                              ),
                                            ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
