import 'package:flutter/material.dart';
import 'signup.dart';
import 'dashboard.dart';
class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  bool _obscurePassword = true;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();


  @override
  void dispose(){
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
  void login(){
    print("Email: ${emailController.text}");
    print("Passwors: ${passwordController.text}");

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const Dashboard(),
      ),
    );
  }
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FF),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              const SizedBox(height: 20),

              // Back button
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_rounded),
                color: const Color(0xFF222033),
              ),

              const SizedBox(height: 25),

              // Logo
              const Center(
                child: Text(
                  "LexiCoach",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6547E8),
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Title
              const Text(
                "Welcome back 👋",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF222033),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "Ready to continue learning?",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF77718A),
                ),
              ),

              const SizedBox(height: 35),

              // Email
              const Text(
                "Email",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF222033),
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: inputDecoration(
                  hint: "your@email.com",
                  icon: Icons.email_outlined,
                ),
              ),

              const SizedBox(height: 22),

              // Password
              const Text(
                "Password",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF222033),
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: inputDecoration(
                  hint: "Enter your password",
                  icon: Icons.lock_outline_rounded,
                ).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Forgot password functionality later.
                  },
                  child: const Text(
                    "Forgot password?",
                    style: TextStyle(
                      color: Color(0xFF6547E8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Login button
              SizedBox(
                width: double.infinity,
                height: 60,

                child: ElevatedButton(
                  onPressed: login,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6547E8),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),

                  child: const Text(
                    "Log In",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 35),

              // Sign up
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      color: Color(0xFF77718A),
                    ),
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpPage(),
                        ),
                      );
                    },

                    child: const Text(
                      "Sign Up",
                      style: TextStyle(
                        color: Color(0xFF6547E8),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFAAA5B7),
      ),

      prefixIcon: Icon(
        icon,
        color: const Color(0xFF8A849B),
      ),

      filled: true,
      fillColor: Colors.white,

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFFE2DDF2),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFF6547E8),
          width: 1.5,
        ),
      ),

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
    );
  }
}