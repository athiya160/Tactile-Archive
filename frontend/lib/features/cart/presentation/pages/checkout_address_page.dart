import 'package:libri_flow/core/widgets/ivory_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class CheckoutAddressPage extends StatefulWidget {
  const CheckoutAddressPage({super.key});

  @override
  State<CheckoutAddressPage> createState() => _CheckoutAddressPageState();
}

class _CheckoutAddressPageState extends State<CheckoutAddressPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _proceedToPayment() {
    if (_formKey.currentState?.validate() ?? false) {
      context.push('/buy-now-checkout', extra: {'mode': 'cart'});
    }
  }

  @override
  Widget build(BuildContext context) {
    return IvoryScaffold(
      title: 'Checkout (1/2)',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.pop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(DSSpacing.xl),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delivery Address', style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: DSSpacing.lg),
                  _buildTextField('Full Name', _nameController, Icons.person_outline),
                  const SizedBox(height: DSSpacing.md),
                  _buildTextField('Phone Number', _phoneController, Icons.phone_outlined, keyboardType: TextInputType.phone),
                  const SizedBox(height: DSSpacing.md),
                  _buildTextField('Street Address', _addressController, Icons.location_on_outlined, maxLines: 2),
                  const SizedBox(height: DSSpacing.md),
                  Row(
                    children: [
                      Expanded(child: _buildTextField('City', _cityController, null)),
                      const SizedBox(width: DSSpacing.md),
                      Expanded(child: _buildTextField('State', _stateController, null)),
                    ],
                  ),
                  const SizedBox(height: DSSpacing.md),
                  _buildTextField('Pincode / ZIP', _pincodeController, Icons.pin_drop_outlined, keyboardType: TextInputType.number),
                  const SizedBox(height: DSSpacing.xxl),
                  SizedBox(
                    width: double.infinity,
                    child: DSButton(
                      text: 'CONTINUE TO PAYMENT',
                      onPressed: _proceedToPayment,
                    ),
                  ),
                  const SizedBox(height: DSSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData? icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: DSColors.border) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DSRadius.lg),
          borderSide: BorderSide(color: DSColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DSRadius.lg),
          borderSide: BorderSide(color: DSColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DSRadius.lg),
          borderSide: const BorderSide(color: DSColors.primary, width: 2),
        ),
        filled: true,
        fillColor: DSColors.surface,
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your $label';
        }
        return null;
      },
    );
  }
}