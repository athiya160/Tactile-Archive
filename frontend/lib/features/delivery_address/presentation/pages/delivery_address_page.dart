import 'package:google_fonts/google_fonts.dart';
import 'package:libri_flow/core/widgets/ivory_scaffold.dart';

import 'package:flutter/material.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:go_router/go_router.dart';


import '../../domain/entities/address.dart';

import '../bloc/address_bloc.dart';

import '../bloc/address_event.dart';

import '../bloc/address_state.dart';

import '../widgets/address_radio_card.dart';

import '../widgets/map_preview.dart';

import '../widgets/add_address_form.dart';

import 'package:libri_flow/core/design_system/design_system.dart';

class DeliveryAddressPage extends StatefulWidget {
  final VoidCallback? onConfirm;
  const DeliveryAddressPage({super.key, this.onConfirm});

  @override
  State<DeliveryAddressPage> createState() => _DeliveryAddressPageState();
}

class _DeliveryAddressPageState extends State<DeliveryAddressPage> {
  final GlobalKey<AddAddressFormState> _addAddressFormKey = GlobalKey();
  bool _isSubmittingNewAddress = false;
  void _onContinuePressed() {
    final formState = _addAddressFormKey.currentState;
    if (formState != null && formState.hasData()) {
      if (formState.submit()) {
        setState(() {
          _isSubmittingNewAddress = true;
        });
      }
    } else {
      context.read<AddressBloc>().add(ConfirmAddressPressed());
    }
  }

  void _showEditAddressDialog(BuildContext context, Address address) {
    final formKey = GlobalKey<AddAddressFormState>();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DSRadius.lg),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Edit Address',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: DSColors.deepForestGreen,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(dialogContext).pop(),
              ),
            ],
          ),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: AddAddressForm(key: formKey, addressToEdit: address),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  color: Color(0xFF586159),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final formState = formKey.currentState;
                if (formState != null) {
                  if (formState.submitForEdit(address.id)) {
                    Navigator.of(dialogContext).pop();
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DSColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DSRadius.sm),
                ),
              ),
              child: const Text(
                'SAVE CHANGES',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return IvoryScaffold(
      title: 'Delivery Address',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, size: 24),
        onPressed: () => Navigator.of(context).pop(),
      ),
      body: BlocConsumer<AddressBloc, AddressState>(
        listener: (context, state) {
          if (state.status == AddressStatus.failure) {
            if (_isSubmittingNewAddress) {
              setState(() {
                _isSubmittingNewAddress = false;
              });
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage ?? 'Error')),
            );
          }
          if (_isSubmittingNewAddress &&
              state.status == AddressStatus.success) {
            setState(() {
              _isSubmittingNewAddress = false;
            });
            context.read<AddressBloc>().add(ConfirmAddressPressed());
          }
          if (state.status == AddressStatus.confirmed) {
            if (widget.onConfirm != null) {
              context.pop();
              widget.onConfirm!();
            } else {
              context.push('/buy-now-checkout', extra: {'mode': 'cart'});
            }
          }
        },
        builder: (context, state) {
          if (state.status == AddressStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == AddressStatus.failure &&
              state.addresses.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(DSSpacing.xxl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: DSColors.error,
                    ),
                    const SizedBox(height: DSSpacing.md),
                    Text(
                      'Failed to load addresses',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: DSSpacing.sm),
                    Text(
                      state.errorMessage ??
                          'An error occurred while fetching your addresses.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: DSColors.textLight),
                    ),
                    const SizedBox(height: DSSpacing.xl),
                    ElevatedButton.icon(
                      onPressed: () =>
                          context.read<AddressBloc>().add(AddressStarted()),
                      icon: const Icon(Icons.refresh),
                      label: const Text('RETRY'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DSColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(DSRadius.lg),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              top: 100 + MediaQuery.of(context).padding.top,
              left: DSSpacing.lg,
              right: DSSpacing.lg,
              bottom: 140,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saved Addresses',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: DSColors.primary,
                  ),
                ),
                const SizedBox(height: DSSpacing.xl),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: state.addresses.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: DSSpacing.md),
                  itemBuilder: (context, index) {
                    final address = state.addresses[index];
                    return AddressRadioCard(
                      address: address,
                      isSelected: state.selectedAddressId == address.id,
                      onTap: () => context.read<AddressBloc>().add(
                        AddressSelected(address.id),
                      ),
                      onEdit: () => _showEditAddressDialog(context, address),
                      onDelete: () => context.read<AddressBloc>().add(
                        AddressDeletePressed(address.id),
                      ),
                    );
                  },
                ),
                const SizedBox(height: DSSpacing.xl),
                const _NewDestinationSeparator(),
                const SizedBox(height: DSSpacing.xl),
                Text(
                  'Add New Address',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: DSColors.primary,
                  ),
                ),
                const SizedBox(height: DSSpacing.xl),
                AddAddressForm(key: _addAddressFormKey),
                const SizedBox(height: DSSpacing.xl),
                const MapPreview(),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _ConfirmBottomBar(
        formKey: _addAddressFormKey,
        onConfirm: widget.onConfirm,
        onTap: _onContinuePressed,
      ),
    );
  }
}

class _NewDestinationSeparator extends StatelessWidget {
  const _NewDestinationSeparator();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFC3C8C1).withValues(alpha: 0.3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'NEW DESTINATION',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 2.0,
              fontSize: 10,
              color: DSColors.textLight,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: const Color(0xFFC3C8C1).withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}

class _ConfirmBottomBar extends StatelessWidget {
  final GlobalKey<AddAddressFormState> formKey;
  final VoidCallback? onConfirm;
  final VoidCallback onTap;
  const _ConfirmBottomBar({
    required this.formKey,
    this.onConfirm,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        DSSpacing.lg,
        DSSpacing.md,
        DSSpacing.lg,
        MediaQuery.of(context).padding.bottom + DSSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: DSColors.surface,
        border: Border(
          top: BorderSide(
            color: DSColors.borderLight.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: DSColors.primary,
          borderRadius: BorderRadius.circular(DSRadius.lg),
          boxShadow: DSShadows.md,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(DSRadius.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Continue',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
