import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/theme.dart';
import '../../domain/entities/address.dart';
import '../../presentation/bloc/address_bloc.dart';
import '../../presentation/bloc/address_event.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class AddAddressForm extends StatefulWidget {
  final Address? addressToEdit;
  const AddAddressForm({super.key, this.addressToEdit});

  @override
  State<AddAddressForm> createState() => AddAddressFormState();
}

class AddAddressFormState extends State<AddAddressForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _flatController;
  late final TextEditingController _areaController;
  late final TextEditingController _landmarkController;
  late final TextEditingController _cityController;
  late final TextEditingController _pinController;

  String _country = 'India';
  String _state = 'Select';
  bool _isDefault = false;

  static const List<String> _statesList = [
    'Select',
    'Andhra Pradesh',
    'Arunachal Pradesh',
    'Assam',
    'Bihar',
    'Chhattisgarh',
    'Goa',
    'Gujarat',
    'Haryana',
    'Himachal Pradesh',
    'Jharkhand',
    'Karnataka',
    'Kerala',
    'Madhya Pradesh',
    'Maharashtra',
    'Manipur',
    'Meghalaya',
    'Mizoram',
    'Nagaland',
    'Odisha',
    'Punjab',
    'Rajasthan',
    'Sikkim',
    'Tamil Nadu',
    'Telangana',
    'Tripura',
    'Uttar Pradesh',
    'Uttarakhand',
    'West Bengal',
    'Delhi',
    'Andaman and Nicobar Islands',
    'Chandigarh',
    'Dadra and Nagar Haveli and Daman and Diu',
    'Lakshadweep',
    'Puducherry',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.addressToEdit?.recipientName ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.addressToEdit?.phoneNumber ?? '',
    );

    // Split street into Flat, Area, Landmark
    final streetText = widget.addressToEdit?.street ?? '';
    final parts = streetText.split(', ');
    _flatController = TextEditingController(
      text: parts.isNotEmpty ? parts[0] : '',
    );
    _areaController = TextEditingController(
      text: parts.length > 1 ? parts[1] : '',
    );
    _landmarkController = TextEditingController(
      text: parts.length > 2 ? parts.sublist(2).join(', ') : '',
    );

    _cityController = TextEditingController(
      text: widget.addressToEdit?.city ?? '',
    );
    _pinController = TextEditingController(
      text: widget.addressToEdit?.zipCode ?? '',
    );

    _isDefault = widget.addressToEdit?.isDefault ?? false;

    final savedState = widget.addressToEdit?.state ?? '';
    if (_statesList.contains(savedState)) {
      _state = savedState;
    } else if (savedState.isNotEmpty) {
      _state = savedState;
    } else {
      _state = 'Select';
    }

    _pinController.addListener(_onPinChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _flatController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateControllerDispose();
    _pinController.dispose();
    super.dispose();
  }

  void _stateControllerDispose() {
    // Helper to keep lifecycle consistent
  }

  bool hasData() {
    return _nameController.text.isNotEmpty ||
        _phoneController.text.isNotEmpty ||
        _flatController.text.isNotEmpty ||
        _areaController.text.isNotEmpty ||
        _pinController.text.isNotEmpty ||
        _cityController.text.isNotEmpty ||
        _state != 'Select';
  }

  bool submit() {
    if (_formKey.currentState!.validate()) {
      final streetParts = [
        if (_flatController.text.isNotEmpty) _flatController.text,
        if (_areaController.text.isNotEmpty) _areaController.text,
        if (_landmarkController.text.isNotEmpty) _landmarkController.text,
      ];
      final street = streetParts.join(', ');

      final address = Address(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        label: 'Other',
        recipientName: _nameController.text,
        phoneNumber: _phoneController.text,
        street: street,
        city: _cityController.text,
        state: _state == 'Select' ? '' : _state,
        zipCode: _pinController.text,
        isDefault: _isDefault,
      );
      context.read<AddressBloc>().add(AddAddressPressed(address));
      return true;
    }
    return false;
  }

  bool submitForEdit(String id) {
    if (_formKey.currentState!.validate()) {
      final streetParts = [
        if (_flatController.text.isNotEmpty) _flatController.text,
        if (_areaController.text.isNotEmpty) _areaController.text,
        if (_landmarkController.text.isNotEmpty) _landmarkController.text,
      ];
      final street = streetParts.join(', ');

      final address = Address(
        id: id,
        label: 'Other',
        recipientName: _nameController.text,
        phoneNumber: _phoneController.text,
        street: street,
        city: _cityController.text,
        state: _state == 'Select' ? '' : _state,
        zipCode: _pinController.text,
        isDefault: _isDefault,
      );
      context.read<AddressBloc>().add(EditAddressPressed(address));
      return true;
    }
    return false;
  }

  void _onPinChanged() {
    final pin = _pinController.text;
    if (pin.length >= 6) {
      _lookupPinCode(pin);
    }
  }

  void _lookupPinCode(String pin) {
    // Mock lookup logic
    final mockData = {
      '110001': {'city': 'New Delhi', 'state': 'Delhi'},
      '400001': {'city': 'Mumbai', 'state': 'Maharashtra'},
      '560001': {'city': 'Bengaluru', 'state': 'Karnataka'},
      '600001': {'city': 'Chennai', 'state': 'Tamil Nadu'},
      '700001': {'city': 'Kolkata', 'state': 'West Bengal'},
      '122002': {'city': 'Gurugram', 'state': 'Haryana'},
      '577301': {'city': 'Shimoga', 'state': 'Karnataka'},
    };

    if (mockData.containsKey(pin)) {
      setState(() {
        _cityController.text = mockData[pin]!['city']!;
        final resolvedState = mockData[pin]!['state']!;
        if (_statesList.contains(resolvedState)) {
          _state = resolvedState;
        } else {
          _state = resolvedState;
        }
      });
    }
  }

  List<DropdownMenuItem<String>> _buildStateDropdownItems() {
    final items = _statesList.map((s) {
      return DropdownMenuItem(
        value: s,
        child: Text(s, style: GoogleFonts.inter()),
      );
    }).toList();

    if (_state != 'Select' && !_statesList.contains(_state)) {
      items.add(
        DropdownMenuItem(
          value: _state,
          child: Text(_state, style: GoogleFonts.inter()),
        ),
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDropdownField(
            label: 'Country/Region',
            value: _country,
            items: ['India', 'United States', 'United Kingdom', 'Canada'],
            onChanged: (v) => setState(() => _country = v!),
          ),
          const SizedBox(height: DSSpacing.lg),
          _buildField(
            label: 'Full name (First and Last name)',
            placeholder: '',
            controller: _nameController,
            onChanged: (_) {},
          ),
          const SizedBox(height: DSSpacing.lg),
          _buildField(
            label: 'Mobile number',
            placeholder: '',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            onChanged: (_) {},
            helperText: const Padding(
              padding: EdgeInsets.only(top: 4.0, left: 4.0),
              child: Text(
                'May be used to assist delivery',
                style: TextStyle(fontSize: 12, color: DSColors.textLight),
              ),
            ),
          ),
          const SizedBox(height: DSSpacing.lg),
          _buildField(
            label: 'Flat, House no., Building, Company, Apartment',
            placeholder: '',
            controller: _flatController,
            onChanged: (_) {},
          ),
          const SizedBox(height: DSSpacing.lg),
          _buildField(
            label: 'Area, Street, Sector, Village',
            placeholder: '',
            controller: _areaController,
            onChanged: (_) {},
          ),
          const SizedBox(height: DSSpacing.lg),
          _buildField(
            label: 'Landmark',
            placeholder: 'E.g. near apollo hospital',
            controller: _landmarkController,
            isRequired: false,
            onChanged: (_) {},
          ),
          const SizedBox(height: DSSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildField(
                  label: 'Pincode',
                  placeholder: '6-digit Pincode',
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) {},
                ),
              ),
              const SizedBox(width: DSSpacing.lg),
              Expanded(
                child: _buildField(
                  label: 'Town/City',
                  placeholder: '',
                  controller: _cityController,
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
          const SizedBox(height: DSSpacing.lg),
          _buildStateDropdown(),
          const SizedBox(height: DSSpacing.lg),
          CheckboxListTile(
            title: Text(
              'Make this my default address',
              style: GoogleFonts.inter(fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            value: _isDefault,
            onChanged: (val) {
              setState(() {
                _isDefault = val ?? false;
              });
            },
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            activeColor: DSColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String placeholder,
    required ValueChanged<String> onChanged,
    TextEditingController? controller,
    TextInputType? keyboardType,
    bool isRequired = true,
    Widget? helperText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            label,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold,
              fontSize: 14,
              color: DSColors.textDark,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: IvoryTheme.hintText,
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DSRadius.sm),
              borderSide: const BorderSide(
                color: DSColors.borderLight,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DSRadius.sm),
              borderSide: const BorderSide(color: DSColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DSRadius.sm),
              borderSide: const BorderSide(color: DSColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DSRadius.sm),
              borderSide: const BorderSide(color: DSColors.error, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          validator: (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return 'Please enter some text';
            }
            return null;
          },
        ),
        ?helperText,
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            label,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold,
              fontSize: 14,
              color: DSColors.textDark,
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(
                    e,
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.expand_more, color: DSColors.textLight),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DSRadius.sm),
              borderSide: const BorderSide(
                color: DSColors.borderLight,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DSRadius.sm),
              borderSide: const BorderSide(color: DSColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStateDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            'State',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold,
              fontSize: 14,
              color: DSColors.textDark,
            ),
          ),
        ),
        DropdownButtonFormField<String>(
          initialValue: _state,
          items: _buildStateDropdownItems(),
          onChanged: (v) {
            setState(() {
              _state = v ?? 'Select';
            });
          },
          icon: const Icon(Icons.expand_more, color: DSColors.textLight),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DSRadius.sm),
              borderSide: const BorderSide(
                color: DSColors.borderLight,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DSRadius.sm),
              borderSide: const BorderSide(color: DSColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          validator: (value) {
            if (value == null || value == 'Select') {
              return 'Please select a state';
            }
            return null;
          },
        ),
      ],
    );
  }
}
