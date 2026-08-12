import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/pay_status_service.dart';
import '../utils/app_theme.dart';

class PayDayCountdownWidget extends StatefulWidget {
  const PayDayCountdownWidget({super.key});

  @override
  State<PayDayCountdownWidget> createState() => _PayDayCountdownWidgetState();
}

class _PayDayCountdownWidgetState extends State<PayDayCountdownWidget> {
  late final PayStatusService _service;
  PayStatus? _status;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    final token = context.read<AuthProvider>().token ?? '';
    _service = PayStatusService(token);
    _load();
  }

  Future<void> _load() async {
    try {
      final status = await _service.getPayStatus();
      if (mounted) setState(() { _status = status; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _hasError = true; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return _skeleton();
    if (_hasError || _status == null) return const SizedBox.shrink();
    return _buildCard(_status!);
  }

  Widget _buildCard(PayStatus s) {
    if (s.salaryPaid) return _paidCard(s);
    if (s.daysUntilPay <= 0) return _processingCard(s);
    return _countdownCard(s);
  }

  // ── Salary already paid ───────────────────────────────────────────────────
  Widget _paidCard(PayStatus s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2ECC71).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Salary Credited',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${s.paidPeriod} salary has been processed',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Next pay day: ${_formatDate(s.nextPayDate)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              const Icon(Icons.account_balance_wallet,
                  color: Colors.white70, size: 20),
              const SizedBox(height: 4),
              Text(
                _daysLabel(s.daysUntilPay),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Countdown: salary not yet paid ────────────────────────────────────────
  Widget _countdownCard(PayStatus s) {
    final progress = _monthProgress();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.timer_outlined,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pay Day Countdown',
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${s.nextPeriodLabel} · ${_formatDate(s.nextPayDate)}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
              // Big day counter
              Column(
                children: [
                  Text(
                    '${s.daysUntilPay}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  const Text(
                    'days',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar: how far into the month we are
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Month progress',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 11),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Processing / expected today or overdue ────────────────────────────────
  Widget _processingCard(PayStatus s) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF39C12), Color(0xFFE67E22)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF39C12).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pending_outlined,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Salary Being Processed',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                Text(
                  '${s.currentMonth} payroll is being prepared',
                  style:
                      const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                const Text(
                  'You will be notified once it is ready',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _skeleton() {
    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  double _monthProgress() {
    final now = DateTime.now();
    final daysInMonth =
        DateTime(now.year, now.month + 1, 0).day.toDouble();
    return (now.day / daysInMonth).clamp(0.0, 1.0);
  }

  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return '';
    try {
      final d = DateTime.parse(isoDate);
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${d.day} ${months[d.month]} ${d.year}';
    } catch (_) {
      return isoDate;
    }
  }

  String _daysLabel(int days) {
    if (days <= 0) return 'Soon';
    return 'in\n$days days';
  }
}
