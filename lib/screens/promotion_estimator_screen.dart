import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/promotion_service.dart';
import '../models/promotion_estimate.dart';
import '../utils/salary_scheme.dart';
import '../utils/app_theme.dart';
import '../utils/number_formatter.dart';

class PromotionEstimatorScreen extends StatefulWidget {
  const PromotionEstimatorScreen({super.key});

  @override
  State<PromotionEstimatorScreen> createState() =>
      _PromotionEstimatorScreenState();
}

class _PromotionEstimatorScreenState extends State<PromotionEstimatorScreen> {
  late final PromotionService _promotionService;
  int _gradePlus = 1;
  int _stepPlus = 0;
  PromotionEstimate? _result;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    _promotionService = PromotionService(auth.token ?? '');
  }

  Future<void> _estimate() async {
    final staffId = context.read<AuthProvider>().user?.id;
    if (staffId == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      final result = await _promotionService.estimate(
        staffId: staffId,
        gradePlus: _gradePlus,
        stepPlus: _stepPlus,
      );
      setState(() => _result = result);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Promotion Estimator',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoBanner(),
            const SizedBox(height: 16),
            _buildIncrementCard(),
            const SizedBox(height: 16),
            _buildEstimateButton(),
            if (_isLoading) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorCard(_errorMessage!),
            ],
            if (_result != null) ...[
              const SizedBox(height: 16),
              _buildSummaryCard(_result!),
              const SizedBox(height: 16),
              _buildBreakdownCard(_result!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'See how much your salary would change if you were promoted. '
              'Adjust the grade and step increments below.',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncrementCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Increment Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
            ),
            const SizedBox(height: 20),
            _buildStepper(
              label: 'Grade Increment',
              subtitle: 'Number of grade levels to move up',
              value: _gradePlus,
              min: 0,
              max: 5,
              onChanged: (v) => setState(() => _gradePlus = v),
            ),
            const Divider(height: 28),
            _buildStepper(
              label: 'Step Increment',
              subtitle: 'Number of steps to move up',
              value: _stepPlus,
              min: 0,
              max: 10,
              onChanged: (v) => setState(() => _stepPlus = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper({
    required String label,
    required String subtitle,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
              Text(subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
        Row(
          children: [
            _stepperButton(
              icon: Icons.remove,
              onTap: value > min ? () => onChanged(value - 1) : null,
            ),
            Container(
              width: 44,
              alignment: Alignment.center,
              child: Text(
                '+$value',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            _stepperButton(
              icon: Icons.add,
              onTap: value < max ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _stepperButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Material(
      color: onTap != null
          ? AppTheme.primaryColor.withOpacity(0.1)
          : Colors.grey[200],
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: onTap != null ? AppTheme.primaryColor : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildEstimateButton() {
    return ElevatedButton.icon(
      onPressed:
          (_gradePlus == 0 && _stepPlus == 0) || _isLoading ? null : _estimate,
      icon: const Icon(Icons.calculate_outlined),
      label: const Text('Calculate Estimated Salary'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildErrorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(PromotionEstimate result) {
    final isIncrease = result.diff >= 0;
    final diffColor = isIncrease ? Colors.green : Colors.red;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Salary Summary',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              result.name,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
            const Divider(height: 24),
            // Grade/Step row
            Row(
              children: [
                Expanded(
                  child: _buildGradeStepBox(
                    label: 'Current',
                    scheme: result.gradeScheme,
                    grade: result.currentGrade,
                    step: result.currentStep.toString(),
                    color: Colors.grey[700]!,
                    bgColor: Colors.grey[100]!,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward,
                      color: AppTheme.primaryColor, size: 22),
                ),
                Expanded(
                  child: _buildGradeStepBox(
                    label: 'Projected',
                    scheme: result.gradeScheme,
                    grade: result.newGrade,
                    step: result.newStep,
                    color: AppTheme.primaryColor,
                    bgColor: AppTheme.primaryColor.withOpacity(0.08),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Salary comparison
            Row(
              children: [
                Expanded(
                  child: _buildSalaryBox(
                    label: 'Current Gross',
                    amount: result.currentTotal,
                    color: Colors.grey[700]!,
                    bgColor: Colors.grey[100]!,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSalaryBox(
                    label: 'Projected Gross',
                    amount: result.newTotal,
                    color: AppTheme.primaryColor,
                    bgColor: AppTheme.primaryColor.withOpacity(0.08),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Difference chip
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: diffColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: diffColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isIncrease ? Icons.trending_up : Icons.trending_down,
                    color: diffColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${isIncrease ? '+' : ''}${NumberFormatter.formatCurrency(result.diff)} per month',
                    style: TextStyle(
                      color: diffColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradeStepBox({
    required String label,
    required String scheme,
    required String grade,
    required String step,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          const SizedBox(height: 4),
          Text(
            gradeStepValue(scheme, grade, step),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSalaryBox({
    required String label,
    required double amount,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          const SizedBox(height: 6),
          Text(
            NumberFormatter.formatCurrency(amount),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownCard(PromotionEstimate result) {
    if (result.breakdown.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Allowance Breakdown',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'How each allowance changes',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 16),
            // Header row
            Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text('Allowance',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey)),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Current',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey[600])),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Projected',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey[600])),
                ),
                Expanded(
                  flex: 2,
                  child: Text('Change',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey[600])),
                ),
              ],
            ),
            const Divider(height: 12),
            ...result.breakdown.map(
              (item) => _buildBreakdownRow(item),
            ),
            const Divider(height: 20),
            // Totals row
            Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text('TOTAL',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    NumberFormatter.formatCurrency(result.currentTotal),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    NumberFormatter.formatCurrency(result.newTotal),
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    '${result.diff >= 0 ? '+' : ''}${NumberFormatter.formatCurrency(result.diff)}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: result.diff >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(PromotionBreakdownItem item) {
    final hasChange = item.diff != 0;
    final diffColor = item.diff > 0
        ? Colors.green
        : item.diff < 0
            ? Colors.red
            : Colors.grey;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              item.name,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              NumberFormatter.formatCurrency(item.current),
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              NumberFormatter.formatCurrency(item.newValue),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: hasChange ? AppTheme.primaryColor : Colors.grey[700],
                fontWeight: hasChange ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              hasChange
                  ? '${item.diff > 0 ? '+' : ''}${NumberFormatter.formatCurrency(item.diff)}'
                  : '—',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                color: diffColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
