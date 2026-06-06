import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../main.dart'; // Para navegar al MainShell

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int _currentStep = 1; // 1: Billing, 2: Payment, 3: Success
  bool _isProcessing = false;

  // Controladores Etapa 1
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rfcController = TextEditingController();

  // Controladores Etapa 2
  final _cardController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _rfcController.dispose();
    _cardController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _goToPayment() {
    if (_formKey1.currentState?.validate() ?? false) {
      setState(() {
        _currentStep = 2;
      });
    }
  }

  Future<void> _processPayment() async {
    if (_formKey2.currentState?.validate() ?? false) {
      setState(() {
        _isProcessing = true;
      });

      // Simular carga de 1.5 segundos
      await Future.delayed(const Duration(milliseconds: 1500));

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _currentStep = 3;
        });
      }
    }
  }

  void _finishCheckout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _buildCurrentStep(),
          ),
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentStep) {
      case 1:
        return 'Datos de Facturacion';
      case 2:
        return 'Pago Seguro';
      case 3:
        return 'Confirmacion';
      default:
        return 'Checkout';
    }
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return _buildStage1(key: const ValueKey(1));
      case 2:
        return _buildStage2(key: const ValueKey(2));
      case 3:
        return _buildStage3(key: const ValueKey(3));
      default:
        return const SizedBox.shrink();
    }
  }

  // ==========================================
  // ETAPA 1: DATOS DE FACTURACION
  // ==========================================
  Widget _buildStage1({Key? key}) {
    return Form(
      key: _formKey1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepIndicator(1, 'Facturacion'),
          const SizedBox(height: 32),
          Text(
            'Informacion Personal',
            style: AppTypography.tituloMd.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _nameController,
            label: 'Nombre completo',
            icon: Icons.person_outline,
            validator: (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Correo electronico',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            validator: (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: 'Telefono',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            validator: (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _rfcController,
            label: 'Identificacion Fiscal (RFC/ID)',
            icon: Icons.badge_outlined,
            validator: (val) => val == null || val.isEmpty ? 'Campo requerido' : null,
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _goToPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Continuar al Pago \u2192',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ETAPA 2: DATOS DE LA TARJETA
  // ==========================================
  Widget _buildStage2({Key? key}) {
    return Form(
      key: _formKey2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildStepIndicator(2, 'Pago'),
          const SizedBox(height: 32),
          Text(
            'Metodo de Pago',
            style: AppTypography.tituloMd.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 16),
          // Logos de tarjetas
          Row(
            children: [
              _buildCardLogo('Visa', Colors.indigo),
              const SizedBox(width: 8),
              _buildCardLogo('Mastercard', Colors.orange),
              const SizedBox(width: 8),
              _buildCardLogo('Amex', Colors.blue),
            ],
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _cardController,
            label: 'Numero de tarjeta',
            icon: Icons.credit_card_rounded,
            keyboardType: TextInputType.number,
            maxLength: 16,
            validator: (val) => val == null || val.length < 16 ? 'Tarjeta invalida' : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _expiryController,
                  label: 'Vencimiento',
                  hintText: 'MM/AA',
                  icon: Icons.calendar_today_rounded,
                  maxLength: 5,
                  validator: (val) => val == null || val.length < 5 ? 'Invalido' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _cvvController,
                  label: 'CVV',
                  icon: Icons.lock_outline_rounded,
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  obscureText: true,
                  validator: (val) => val == null || val.length < 3 ? 'Invalido' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen, // Verde oscuro
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Text(
                      'Procesar Pago Seguro',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ETAPA 3: PANTALLA DE EXITO
  // ==========================================
  Widget _buildStage3({Key? key}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 40),
        const Icon(
          Icons.check_circle_outline_rounded,
          color: AppColors.statusHealthyText,
          size: 100,
        ),
        const SizedBox(height: 24),
        Text(
          '\u00A1Pago Procesado\ncon Exito!',
          style: AppTypography.tituloLg.copyWith(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildReceiptRow('Referencia:', '#AG-2026-001'),
              const Divider(height: 24),
              _buildReceiptRow('Plan adquirido:', 'PLAN PRO', isHighlighted: true),
              const Divider(height: 24),
              _buildReceiptRow('Monto pagado:', '\$9.99'),
            ],
          ),
        ),
        const SizedBox(height: 48),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: _finishCheckout,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Comenzar a usar Pro',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // ==========================================
  // UTILIDADES VISUALES
  // ==========================================

  Widget _buildStepIndicator(int step, String label) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            step.toString(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: AppTypography.labelMd.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: Divider(color: AppColors.outlineVariant),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: AppColors.onSurfaceVariant),
        counterText: '',
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildCardLogo(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Text(
        name,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12, fontStyle: FontStyle.italic),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.bodyMd.copyWith(color: AppColors.onSurfaceVariant),
        ),
        Text(
          value,
          style: AppTypography.labelMd.copyWith(
            color: isHighlighted ? AppColors.forestGreen : AppColors.onSurface,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
