import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/home_model.dart';
import '../../data/models/home_update_model.dart';
import '../../data/repositories/home_repository.dart';

final _homeRepo = HomeRepository();

class EditHomeScreen extends ConsumerStatefulWidget {
  final Home home;

  const EditHomeScreen({super.key, required this.home});

  @override
  ConsumerState<EditHomeScreen> createState() => _EditHomeScreenState();
}

class _EditHomeScreenState extends ConsumerState<EditHomeScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _districtController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _pincodeController;
  late final TextEditingController _countryController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.home.name);
    _districtController = TextEditingController(text: widget.home.district ?? '');
    _cityController = TextEditingController(text: widget.home.city ?? '');
    _stateController = TextEditingController(text: widget.home.state ?? '');
    _pincodeController = TextEditingController(text: widget.home.pincode ?? '');
    _countryController = TextEditingController(text: widget.home.country ?? '');
    _addressController = TextEditingController(text: widget.home.address ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _submitUpdate() async {
    final dto = HomeUpdateDto(
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pincode: _pincodeController.text.trim(),
      country: _countryController.text.trim(),
      district: _districtController.text.trim(),
    );

    try {
      await _homeRepo.updateHome(dto);
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Home updated successfully!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Failed to update home. Please try again.",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Home"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // Inside your `build` method:

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600), // ✅ Max width constraint added here
            child: Column(
              children: [
                Card(
                  shape: theme.cardTheme.shape,
                  color: theme.cardTheme.color,
                  elevation: theme.cardTheme.elevation,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        _buildField(_nameController, "Home Name", Icons.home),
                        _buildField(_addressController, "Address", Icons.home_work, inputType: TextInputType.multiline, maxLines: 4),
                        _buildField(_districtController, "District", Icons.location_searching),
                        _buildField(_cityController, "City", Icons.location_city),
                        _buildField(_stateController, "State", Icons.map),
                        _buildField(
                          _pincodeController,
                          "Pincode",
                          Icons.pin_drop,
                          inputType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        ),
                        _buildField(_countryController, "Country", Icons.flag),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text("Update"),
                          onPressed: _submitUpdate,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            textStyle: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
      TextEditingController controller,
      String label,
      IconData icon, {
        TextInputType inputType = TextInputType.text,
        List<TextInputFormatter>? inputFormatters,
        int maxLines = 1, // ✅ Add this default param
      }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
      controller: controller,
      keyboardType: inputType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(), // Same as chore screen
      ),
    ),
    );
  }
}
