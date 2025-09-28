import 'package:flutter/material.dart';

class UserProfileForm extends StatelessWidget {
  final TextEditingController mobileCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController addressCtrl;
  final DateTime? selectedDob;
  final List<String> genderOptions;
  final List<String> countryOptions;
  final String selectedGender;
  final String selectedCountry;
  final Function(DateTime?) onDobChanged;
  final Function(String) onGenderChanged;
  final Function(String) onCountryChanged;

  const UserProfileForm({
    super.key,
    required this.mobileCtrl,
    required this.cityCtrl,
    required this.addressCtrl,
    required this.selectedDob,
    required this.genderOptions,
    required this.countryOptions,
    required this.selectedGender,
    required this.selectedCountry,
    required this.onDobChanged,
    required this.onGenderChanged,
    required this.onCountryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.colorScheme.onSurface;

    return Column(
      children: [
        _buildTextField(context, mobileCtrl, 'Mobile', TextInputType.phone),
        _buildDropdown(context, 'Gender', genderOptions, selectedGender, onGenderChanged),
        _buildDatePicker(context, textColor),
        _buildTextField(context, addressCtrl, 'Address', TextInputType.text),
        _buildTextField(context, cityCtrl, 'City', TextInputType.text),
        _buildDropdown(context, 'Country', countryOptions, selectedCountry, onCountryChanged),
      ],
    );
  }

  Widget _buildTextField(BuildContext context, TextEditingController ctrl, String label,
      TextInputType keyboardType) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: theme.textTheme.bodyMedium,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) =>
        (value == null || value.trim().isEmpty) ? '$label is required' : null,
      ),
    );
  }

  Widget _buildDropdown(BuildContext context, String label, List<String> items, String selected,
      Function(String) onChanged) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField<String>(
        value: selected,
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (val) => onChanged(val!),
        validator: (value) =>
        value == null || value.isEmpty ? '$label is required' : null,
        style: theme.textTheme.bodyMedium,
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, Color textColor) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: selectedDob ?? DateTime(2000),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: theme.colorScheme,
                  textTheme: theme.textTheme,
                ),
                child: child!,
              );
            },
          );
          if (picked != null) onDobChanged(picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Date of Birth',
            labelStyle: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            selectedDob != null
                ? selectedDob!.toIso8601String().split('T').first
                : 'Tap to select',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }
}
