import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

class _CountryNumbers {
  const _CountryNumbers({
    required this.police,
    required this.ambulance,
    required this.fire,
    required this.embassy,
  });

  final String police;
  final String ambulance;
  final String fire;
  final String embassy;
}

const _emergencyNumbers = {
  'United States': _CountryNumbers(
    police: '911',
    ambulance: '911',
    fire: '911',
    embassy: '+1-202-501-4444',
  ),
  'United Kingdom': _CountryNumbers(
    police: '999',
    ambulance: '999',
    fire: '999',
    embassy: '+44-20-7499-9000',
  ),
  'France': _CountryNumbers(
    police: '17',
    ambulance: '15',
    fire: '18',
    embassy: '+33-1-43-12-22-22',
  ),
  'Germany': _CountryNumbers(
    police: '110',
    ambulance: '112',
    fire: '112',
    embassy: '+49-30-8305-0',
  ),
  'Japan': _CountryNumbers(
    police: '110',
    ambulance: '119',
    fire: '119',
    embassy: '+81-3-3224-5000',
  ),
  'Australia': _CountryNumbers(
    police: '000',
    ambulance: '000',
    fire: '000',
    embassy: '+61-2-6214-5600',
  ),
  'Canada': _CountryNumbers(
    police: '911',
    ambulance: '911',
    fire: '911',
    embassy: '+1-613-238-5335',
  ),
  'Spain': _CountryNumbers(
    police: '091',
    ambulance: '061',
    fire: '080',
    embassy: '+34-91-587-2200',
  ),
  'Italy': _CountryNumbers(
    police: '112',
    ambulance: '118',
    fire: '115',
    embassy: '+39-06-46741',
  ),
  'Thailand': _CountryNumbers(
    police: '191',
    ambulance: '1669',
    fire: '199',
    embassy: '+66-2-205-4000',
  ),
  'Singapore': _CountryNumbers(
    police: '999',
    ambulance: '995',
    fire: '995',
    embassy: '+65-6476-9100',
  ),
  'Mexico': _CountryNumbers(
    police: '911',
    ambulance: '911',
    fire: '911',
    embassy: '+52-55-5080-2000',
  ),
  'Brazil': _CountryNumbers(
    police: '190',
    ambulance: '192',
    fire: '193',
    embassy: '+55-61-3312-7000',
  ),
  'India': _CountryNumbers(
    police: '100',
    ambulance: '102',
    fire: '101',
    embassy: '+91-11-2419-8000',
  ),
  'China': _CountryNumbers(
    police: '110',
    ambulance: '120',
    fire: '119',
    embassy: '+86-10-8531-3000',
  ),
};

class EmergencyContactsScreen extends StatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  State<EmergencyContactsScreen> createState() =>
      _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  String _selectedCountry = 'United States';

  Future<void> _call(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    final launched = await canLaunchUrl(uri) && await launchUrl(uri);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the phone dialer.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final numbers = _emergencyNumbers[_selectedCountry]!;
    final countries = _emergencyNumbers.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Important emergency numbers for your destination',
              style: AppTheme.poppins(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () async {
                final selected = await showModalBottomSheet<String>(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => DraggableScrollableSheet(
                    initialChildSize: 0.6,
                    expand: false,
                    builder: (context, scrollController) => ListView.builder(
                      controller: scrollController,
                      itemCount: countries.length,
                      itemBuilder: (context, index) => ListTile(
                        title: Text(countries[index]),
                        selected: countries[index] == _selectedCountry,
                        onTap: () =>
                            Navigator.of(context).pop(countries[index]),
                      ),
                    ),
                  ),
                );
                if (selected != null) {
                  setState(() => _selectedCountry = selected);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _selectedCountry,
                        style: AppTheme.fredoka(fontSize: 16),
                      ),
                    ),
                    const Icon(LucideIcons.mapPin),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _EmergencyCard(
              title: 'Police',
              number: numbers.police,
              onCall: () => _call(numbers.police),
            ),
            _EmergencyCard(
              title: 'Ambulance',
              number: numbers.ambulance,
              onCall: () => _call(numbers.ambulance),
            ),
            _EmergencyCard(
              title: 'Fire Department',
              number: numbers.fire,
              onCall: () => _call(numbers.fire),
            ),
            _EmergencyCard(
              title: 'Embassy',
              number: numbers.embassy,
              onCall: () => _call(numbers.embassy),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyCard extends StatelessWidget {
  const _EmergencyCard({
    required this.title,
    required this.number,
    required this.onCall,
  });

  final String title;
  final String number;
  final VoidCallback onCall;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.poppins(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(number, style: AppTheme.fredoka(fontSize: 20)),
              ],
            ),
          ),
          IconButton.filled(
            onPressed: onCall,
            icon: const Icon(LucideIcons.phone),
          ),
        ],
      ),
    );
  }
}
