import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/data/bookings_repository.dart';
import '../../core/data/destinations_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

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
    setState(() => _isSubmitting = true);
    final totalPrice = price * _participants;
    final commission = totalPrice * 0.15;
    try {
      final bookingId = await ref
          .read(bookingsRepositoryProvider)
          .createBooking(
            experienceId: widget.experienceId,
            bookingDate: _selectedDate,
            numParticipants: _participants,
            totalPrice: totalPrice,
            commissionAmount: commission,
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
        error: (error, _) => Center(
          child: Text(
            'Could not load this experience.',
            style: AppTheme.poppins(color: AppColors.error),
          ),
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
                      const SizedBox(height: 16),
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
