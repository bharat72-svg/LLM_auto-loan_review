import 'package:flutter/material.dart';
import '../models/contract_model.dart';
import 'chatbot_screen.dart';
import 'conversations_screen.dart';

class ResultsScreen extends StatelessWidget {
  final ContractAnalysis contract;

  const ResultsScreen({super.key, required this.contract});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lease Analysis', style: TextStyle(fontSize: 18)),
            Text(
              contract.filename,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.message),
            tooltip: 'Dealer Conversations',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ConversationsScreen(contract: contract),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.chat),
            tooltip: 'AI Assistant',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatbotScreen(contract: contract),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildFairnessScoreCard(context),
            _buildFinancialTermsCard(context),
            _buildUsageMileageCard(context),
            _buildInsuranceCard(context),
            _buildPenaltiesCard(context),
            if (contract.vehicleDetails.isNotEmpty)
              _buildVehicleDetailsCard(context),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatbotScreen(contract: contract),
            ),
          );
        },
        icon: const Icon(Icons.chat_bubble),
        label: const Text('Ask AI Assistant'),
      ),
    );
  }

  Widget _buildFairnessScoreCard(BuildContext context) {
    double score = double.tryParse(contract.fairnessScore) ?? 0;
    Color scoreColor = score >= 80 ? Colors.green : score >= 60 ? Colors.orange : Colors.red;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scoreColor.withOpacity(0.8), scoreColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            contract.fairnessScore,
            style: const TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Text(
            'Contract Fairness Score',
            style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            contract.timestamp.toString().split(' ')[0],
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialTermsCard(BuildContext context) {
    var sla = contract.slaAnalysis;
    
    return _buildCard(
      context,
      title: 'Financial Terms',
      icon: Icons.account_balance_wallet,
      color: Colors.blue,
      children: [
        _buildInfoTile(
          'Monthly Rental',
          _extractNestedValue(sla, ['emi_amount', 'monthly_payment', 'monthly_rental']),
          Icons.payments,
        ),
        _buildInfoTile(
          'Security Deposit',
          _extractNestedValue(sla, ['security_deposit', 'deposit']),
          Icons.shield,
        ),
        _buildInfoTile(
          'Advance Payment',
          _extractNestedValue(sla, ['down_payment', 'advance_payment', 'advance']),
          Icons.money,
        ),
        const Divider(height: 32),
        _buildInfoTile(
          'Lease Term',
          _extractNestedValue(sla, ['lease_term', 'tenure', 'contract_period']),
          Icons.calendar_today,
        ),
        _buildInfoTile(
          'Start Date',
          _extractNestedValue(sla, ['start_date', 'commencement_date', 'contract_start']),
          Icons.event_available,
        ),
        _buildInfoTile(
          'End Date',
          _extractNestedValue(sla, ['end_date', 'termination_date', 'contract_end']),
          Icons.event_busy,
        ),
        const Divider(height: 32),
        _buildInfoTile(
          'Purchase Option',
          _extractNestedValue(sla, ['purchase_option', 'buyback_price', 'purchase_price']),
          Icons.shopping_cart,
        ),
        _buildInfoTile(
          'Residual Value',
          _extractNestedValue(sla, ['residual_value', 'salvage_value']),
          Icons.trending_down,
        ),
      ],
    );
  }

  Widget _buildUsageMileageCard(BuildContext context) {
    var sla = contract.slaAnalysis;
    
    return _buildCard(
      context,
      title: 'Usage & Mileage',
      icon: Icons.speed,
      color: Colors.purple,
      children: [
        _buildInfoTile(
          'Annual Mileage',
          _extractNestedValue(sla, ['annual_mileage', 'yearly_km_limit', 'annual_km']),
          Icons.route,
        ),
        _buildInfoTile(
          'Excess Charge',
          _extractNestedValue(sla, ['excess_mileage_charge', 'per_km_charge', 'excess_charge']),
          Icons.money_off,
        ),
        _buildInfoTile(
          'Total Mileage',
          _extractNestedValue(sla, ['total_mileage', 'contract_km_limit', 'total_km']),
          Icons.speed,
        ),
      ],
    );
  }

  Widget _buildInsuranceCard(BuildContext context) {
    var sla = contract.slaAnalysis;
    
    return _buildCard(
      context,
      title: 'Insurance & Maintenance',
      icon: Icons.verified_user,
      color: Colors.green,
      children: [
        _buildInfoTile(
          'Insurance Requirements',
          _extractNestedValue(sla, ['insurance_mandatory', 'insurance_type', 'insurance_requirements']),
          Icons.security,
        ),
        _buildInfoTile(
          'Insurance Provider',
          _extractNestedValue(sla, ['insurance_provider', 'insurer']),
          Icons.business,
        ),
        const Divider(height: 32),
        _buildInfoTile(
          'Maintenance Responsibility',
          _extractNestedValue(sla, ['maintenance_responsibility', 'service_responsibility']),
          Icons.build,
        ),
        _buildInfoTile(
          'Routine Maintenance',
          _extractNestedValue(sla, ['routine_maintenance', 'service_package', 'routine_maintenance_included']),
          Icons.check_circle,
        ),
      ],
    );
  }

  Widget _buildPenaltiesCard(BuildContext context) {
    var sla = contract.slaAnalysis;
    
    return _buildCard(
      context,
      title: 'Penalties',
      icon: Icons.warning_amber,
      color: Colors.orange,
      children: [
        _buildWarningTile(
          'Early Termination Charge',
          _extractNestedValue(sla, ['termination_clause', 'early_exit_penalty', 'early_termination_charge']),
        ),
        _buildWarningTile(
          'Late Payment Fee',
          _extractNestedValue(sla, ['late_fee_penalty', 'delay_charges', 'late_payment_fee']),
        ),
        _buildWarningTile(
          'Excess Wear Charges',
          _extractNestedValue(sla, ['excess_wear_charges', 'damage_charges']),
        ),
      ],
    );
  }

  Widget _buildVehicleDetailsCard(BuildContext context) {
    var vehicle = contract.vehicleDetails;
    
    return _buildCard(
      context,
      title: '🚗 Vehicle Details',
      icon: Icons.directions_car,
      color: Colors.teal,
      children: [
        _buildInfoTile(
          'VIN',
          _extractVehicleValue(vehicle, ['vin', 'vehicle_vin', 'chassis_number']),
          Icons.fingerprint,
        ),
        _buildInfoTile(
          'Make & Model',
          _extractVehicleValue(vehicle, ['make_model', 'vehicle_make_model', 'make', 'model']),
          Icons.car_rental,
        ),
        _buildInfoTile(
          'Year',
          _extractVehicleValue(vehicle, ['year', 'model_year', 'manufacturing_year']),
          Icons.calendar_today,
        ),
        _buildInfoTile(
          'Color',
          _extractVehicleValue(vehicle, ['color', 'vehicle_color']),
          Icons.palette,
        ),
      ],
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.blue[700]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[900],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ IMPROVED: Try multiple key names and extract nested values
  String _extractNestedValue(Map<String, dynamic> data, List<String> possibleKeys) {
    // Try direct keys first
    for (String key in possibleKeys) {
      if (data.containsKey(key)) {
        var value = data[key];
        if (value == null) continue;
        
        // Handle nested objects with 'value' key
        if (value is Map) {
          if (value.containsKey('value')) {
            return value['value'].toString();
          }
          // Try to get any non-null value from the map
          for (var v in value.values) {
            if (v != null && v.toString().isNotEmpty && v.toString() != 'null') {
              return v.toString();
            }
          }
        }
        
        if (value.toString().isNotEmpty && value.toString() != 'null') {
          return value.toString();
        }
      }
    }
    
    // Search in nested 'sla_extraction' if exists
    if (data.containsKey('sla_extraction')) {
      var nested = data['sla_extraction'] as Map<String, dynamic>;
      return _extractNestedValue(nested, possibleKeys);
    }
    
    // Search in nested objects
    for (var entry in data.entries) {
      if (entry.value is Map<String, dynamic>) {
        var nestedResult = _extractNestedValue(entry.value as Map<String, dynamic>, possibleKeys);
        if (nestedResult != 'Not specified') {
          return nestedResult;
        }
      }
    }
    
    return 'Not specified';
  }

  String _extractVehicleValue(Map<String, dynamic> data, List<String> possibleKeys) {
    for (String key in possibleKeys) {
      if (data.containsKey(key)) {
        var value = data[key];
        if (value != null && value.toString().isNotEmpty && value.toString() != 'null') {
          return value.toString();
        }
      }
    }
    return 'Not available';
  }
}

