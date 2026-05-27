import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../models/bike.dart';
import '../../viewmodels/bike_viewmodel.dart';

class AddBikeView extends StatefulWidget {
  const AddBikeView({super.key});

  @override
  State<AddBikeView> createState() => _AddBikeViewState();
}

class _AddBikeViewState extends State<AddBikeView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  BikeType _selectedType = BikeType.mountain;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Bike')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bike Name',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: _inputDecoration('Enter bike nickname'),
                style: const TextStyle(color: AppColors.white),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a name'
                    : null,
              ),
              const SizedBox(height: 24),
              const Text(
                'Bike Type',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<BikeType>(
                value: _selectedType,
                dropdownColor: AppColors.navyBlue,
                decoration: _inputDecoration('Select type'),
                items: BikeType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(
                          type.name.toUpperCase(),
                          style: const TextStyle(color: AppColors.white),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => _selectedType = val!),
              ),
              const SizedBox(height: 24),
              const Text(
                'Purchase Date',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}',
                        style: const TextStyle(color: AppColors.white),
                      ),
                      const Icon(
                        Icons.calendar_today_rounded,
                        color: AppColors.electricBlue,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveBike,
                  child: const Text('Save to Garage'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: AppColors.textBody.withOpacity(0.5)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.electricBlue),
      ),
    );
  }

  void _saveBike() {
    if (_formKey.currentState!.validate()) {
      final bike = Bike(
        name: _nameController.text,
        type: _selectedType,
        purchaseDate: _selectedDate,
        totalKilometers: 0.0,
        maintenanceStatus: 'Good',
      );
      context.read<BikeViewModel>().addBike(bike);
      Navigator.pop(context);
    }
  }
}
