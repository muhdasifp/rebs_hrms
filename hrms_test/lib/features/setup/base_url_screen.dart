import 'package:flutter/material.dart';
import 'package:hrms_test/core/theme/app_colors.dart';
import 'package:hrms_test/data/const/app_constant.dart';
import 'package:hrms_test/features/root/view/root_screen.dart';

class BaseUrlScreen extends StatefulWidget {
  const BaseUrlScreen({super.key});

  @override
  State<BaseUrlScreen> createState() => _BaseUrlScreenState();
}

class _BaseUrlScreenState extends State<BaseUrlScreen> {
  final _ctrl = TextEditingController(text: AppConstant.defaultUrl);
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final url = _ctrl.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Please enter a valid URL');
      return;
    }
    if (!url.startsWith('http')) {
      setState(() => _error = 'URL must start with http:// or https://');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    await AppConstant.setBaseUrl(url);
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RootScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4361EE), Color(0xFF3A0CA3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.dns_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Configure API Server',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the base URL for the REBS HRMS mock API server.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.text2,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _ctrl,
                keyboardType: TextInputType.url,
                autocorrect: false,
                style: const TextStyle(fontSize: 15, color: AppColors.text),
                decoration: InputDecoration(
                  labelText: 'Base URL',
                  hintText: 'http://192.168.1.5:3000/api',
                  filled: true,
                  fillColor: AppColors.surface,
                  prefixIcon: const Icon(
                    Icons.link_rounded,
                    color: AppColors.text3,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.accent,
                      width: 1.5,
                    ),
                  ),
                  errorText: _error,
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.accent,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Example: http://192.168.1.5:3000/api\n'
                        "Use your machine's LAN IP when testing on a device.",
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.accent,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save & Continue',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
