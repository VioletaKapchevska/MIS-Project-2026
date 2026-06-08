import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscure = true;
  bool loading = false;
  String? errorText;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      loading = true;
      errorText = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      // AuthGate автоматски ќе префрли на Home.
    } on FirebaseAuthException catch (e) {
      setState(() => errorText = _friendlyError(e.code));
    } catch (_) {
      setState(() => errorText = "Нешто тргна наопаку. Пробај повторно.");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Invalid email.';
      case 'user-not-found':
        return 'There is no user with this email.';
      case 'wrong-password':
        return 'Wrong password.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      default:
        return 'Error: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary_color_bg  = Colors.blue.shade600;

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        backgroundColor: primary_color_bg,
        centerTitle: true,
        title: const Text("Login", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white,)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  const Text(
                    "Welcome back 🐶🐱",
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold,color: Color(0xFF1F2D5A)),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: emailController,
                    //keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: "Email",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: Icon(Icons.email, color: primary_color_bg),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primary_color_bg),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return "Enter email";
                      if (!value.contains('@') || !value.contains('.')) return "Email не е валиден";
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: passwordController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: "Password",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: Icon(Icons.lock, color: primary_color_bg),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: primary_color_bg),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () => setState(() => obscure = !obscure),
                        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: primary_color_bg),
                      ),
                    ),
                    validator: (v) {
                      final value = v ?? '';
                      if (value.isEmpty) return "Enter password";
                      return null;
                    },
                  ),

                  const SizedBox(height: 14),

                  if (errorText != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.25)),
                      ),
                      child: Text(errorText!, style: const TextStyle(color: Colors.red)),
                    ),

                  const SizedBox(height: 14),
                  //login btn
                  SizedBox(
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.green.shade400],
                        ),
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: loading ? null : login,
                        child: loading
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Text(
                          "Login",
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: loading ? null : (){
                      Navigator.push(context, MaterialPageRoute(builder: (_)=> const RegisterScreen()));
                    },
                    child: Text("Don't have an account? Register", style: TextStyle(color: primary_color_bg,
                      fontWeight: FontWeight.w600
                   ),),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}