import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/bookings_repository.dart';
import '../../core/data/destinations_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/error_view.dart';

class BookingFlowScreen extends ConsumerStatefulWidget {
  const BookingFlowScreen({super.key, required this.experienceId});

  final String experienceId;

  @override
  ConsumerState<BookingFlowScreen> createState() => _BookingFlowScreenState();
}

class _BookingFlowScreenState extends ConsumerState<BookingFlowScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  int _participants = 1;
  bool _isSubmitting = false;

  final _cardNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();

  @override
  void dispose() {
    _cardNameController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  String? _validatePayment() {
    if (_cardNameController.text.trim().isEmpty) {
      return 'Enter the name on the card.';
    }
    final digits = _cardNumberController.text.replaceAll(' ', '');
    if (digits.length < 15 ||
        digits.length > 16 ||
        int.tryParse(digits) == null) {
      return 'Enter a valid card number.';
    }
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(_cardExpiryController.text.trim())) {
      return 'Enter expiry as MM/YY.';
    }
    if (!RegExp(r'^\d{3,4}$').hasMatch(_cardCvvController.text.trim())) {
      return 'Enter a valid CVV.';
    }
    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _confirmBooking(double price) async {
    final paymentError = _validatePayment();
    if (paymentError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(paymentError)));
      return;
    }

    setState(() => _isSubmitting = true);
    final totalPrice = price * _participants;
    final commission = totalPrice * 0.15;
    try {
      // Simulates a payment processor round-trip. No real charge is made —
      // this app has no payment gateway wired up.
      await Future.delayed(const Duration(milliseconds: 900));
      final bookingId = await ref
          .read(bookingsRepositoryProvider)
          .createBooking(
            experienceId: widget.experienceId,
            bookingDate: _selectedDate,
            numParticipants: _participants,
            totalPrice: totalPrice,
            commissionAmount: commission,
            paymentStatus: 'paid',
          );
      if (mounted) context.go('/booking-success/$bookingId');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not complete your booking. Try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final experienceAsync = ref.watch(
      experienceDetailProvider(widget.experienceId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Complete Booking')),
      body: experienceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ErrorView(
          message: 'Could not load this experience.',
          onRetry: () =>
              ref.invalidate(experienceDetailProvider(widget.experienceId)),
        ),
        data: (experience) {
          final totalPrice = experience.price * _participants;
          final commission = totalPrice * 0.15;
          final maxParticipants = experience.maxParticipants ?? 10;

          return SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      Text(
                        experience.title,
                        style: AppTheme.fredoka(fontSize: 18),
                      ),
                      if (experience.category != null)
                        Text(
                          experience.category!,
                          style: AppTheme.poppins(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      const SizedBox(height: 24),
                      _SectionHeader(
                        icon: LucideIcons.calendar,
                        title: 'Select Date',
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton(
                        onPressed: _pickDate,
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        child: Text(
                          DateFormat.yMMMMd().format(_selectedDate),
                          style: AppTheme.poppins(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SectionHeader(
                        icon: LucideIcons.users,
                        title: 'Number of Participants',
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton.filled(
                            onPressed: _participants > 1
                                ? () => setState(() => _participants--)
                                : null,
                            icon: const Icon(Icons.remove),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              '$_participants',
                              style: AppTheme.fredoka(fontSize: 18),
                            ),
                          ),
                          IconButton.filled(
                            onPressed: _participants < maxParticipants
                                ? () => setState(() => _participants++)
                                : null,
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SectionHeader(
                        icon: LucideIcons.creditCard,
                        title: 'Price Breakdown',
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            _PriceRow(
                              label:
                                  '\$${experience.price.toStringAsFixed(0)} × '
                                  '$_participants participant${_participants > 1 ? 's' : ''}',
                              value: totalPrice,
                            ),
                            _PriceRow(
                              label: 'Service fee (15%)',
                              value: commission,
                            ),
                            const Divider(height: 24),
                            _PriceRow(
                              label: 'Total',
                              value: totalPrice,
                              isTotal: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _SectionHeader(
                        icon: LucideIcons.creditCard,
                        title: 'Payment Details',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This is a simulated payment for demo purposes — no '
                        'real charge is made.',
                        style: AppTheme.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _cardNameController,
                        decoration: const InputDecoration(
                          hintText: 'Name on card',
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _cardNumberController,
                        decoration: const InputDecoration(
                          hintText: 'Card number',
                        ),
                        keyboardType: TextInputType.number,
                        maxLength: 19,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _cardExpiryController,
                              decoration: const InputDecoration(
                                hintText: 'MM/YY',
                              ),
                              keyboardType: TextInputType.number,
                              maxLength: 5,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _cardCvvController,
                              decoration: const InputDecoration(
                                hintText: 'CVV',
                              ),
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              maxLength: 4,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'By confirming this booking, you agree to our Terms of '
                        'Service and Cancellation Policy. You can cancel free of '
                        'charge up to 24 hours before the experience.',
                        style: AppTheme.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total',
                              style: AppTheme.poppins(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '\$${totalPrice.toStringAsFixed(2)}',
                              style: AppTheme.fredoka(fontSize: 18),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => _confirmBooking(experience.price),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Confirm Booking'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: AppTheme.fredoka(fontSize: 15)),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final double value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final style = isTotal
        ? AppTheme.fredoka(fontSize: 16)
        : AppTheme.poppins(color: AppColors.textSecondary);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: style)),
          Text('\$${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}
