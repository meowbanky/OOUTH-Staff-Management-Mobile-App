// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../services/notification_service.dart';
import 'login_screen.dart';
import 'payslip_screen.dart';
import 'notifications_screen.dart';
import 'duty_rota_screen.dart';
import 'profile_screen.dart';
import 'pension_report_screen.dart';
import 'promotion_estimator_screen.dart';
import 'settings_screen.dart';
import 'annual_tax_summary_screen.dart';
import 'salary_certificate_screen.dart';
import 'earnings_history_screen.dart';
import 'deductions_tracker_screen.dart';
import 'payslip_comparison_screen.dart';
import 'pay_calendar_screen.dart';
import 'net_pay_trend_screen.dart';
import 'payslip_bundle_screen.dart';
import 'annual_income_statement_screen.dart';
import '../widgets/pay_day_countdown_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late NotificationService _notificationService;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadUnreadCount();
  }

  void _initializeServices() {
    final authProvider = context.read<AuthProvider>();
    _notificationService = NotificationService(
      baseUrl: 'https://oouthsalary.com.ng/auth_api',
      token: authProvider.token ?? '',
      userId: authProvider.user?.id ?? '', // Add this line
    );
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _notificationService.getUnreadCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      debugPrint('Error loading unread count: $e');
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Logout',
            style: TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final authProvider = context.read<AuthProvider>();
                await authProvider.logout();

                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
              child: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _handleCardTap(BuildContext context, String cardType) async {
    switch (cardType) {
      case 'payslip':
        try {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
              );
            },
          );

          await Future.delayed(const Duration(milliseconds: 500));

          if (context.mounted) {
            Navigator.pop(context);
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const PayslipScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
        break;

      case 'profile':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProfileScreen(),
          ),
        );
        break;

      case 'settings':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SettingsScreen(),
          ),
        );
        break;

      case 'rota':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DutyRotaScreen(),
          ),
        );
        break;

      case 'pension':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PensionReportScreen(),
          ),
        );
        break;

      case 'promotion':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PromotionEstimatorScreen(),
          ),
        );
        break;

      case 'tax':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AnnualTaxSummaryScreen(),
          ),
        );
        break;

      case 'certificate':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SalaryCertificateScreen(),
          ),
        );
        break;

      case 'earnings':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EarningsHistoryScreen(),
          ),
        );
        break;

      case 'deductions':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const DeductionsTrackerScreen(),
          ),
        );
        break;

      case 'compare':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PayslipComparisonScreen(),
          ),
        );
        break;

      case 'calendar':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PayCalendarScreen(),
          ),
        );
        break;

      case 'trend':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const NetPayTrendScreen(),
          ),
        );
        break;

      case 'bundle':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const PayslipBundleScreen(),
          ),
        );
        break;

      case 'statement':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AnnualIncomeStatementScreen(),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthProvider>().user;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.primaryColor,
                onRefresh: () async {
                  await _loadUnreadCount();
                  await Future.delayed(const Duration(seconds: 1));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildWelcomeCard(user?.name ?? 'Staff Member'),
                      const SizedBox(height: 16),
                      const PayDayCountdownWidget(),
                      const SizedBox(height: 24),
                      Text(
                        'Quick Actions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      _buildDashboardCards(context),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Continue in the same file...

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Hero(
            tag: 'app_logo',
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                'assets/images/oouth_logo.png',
                height: 32,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OOUTH',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Staff Portal',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  ).then((_) => _loadUnreadCount());
                },
                icon: const Icon(
                  Icons.notifications_none,
                  color: Colors.white,
                ),
                tooltip: 'Notifications',
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      _unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            onPressed: () => _showLogoutDialog(context),
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
            tooltip: 'Logout',
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(String userName) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back,',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          Text(
            userName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCards(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.1,
      children: [
        _buildCard(
          context,
          'View Payslip',
          Icons.description_outlined,
          AppTheme.primaryColor,
          () => _handleCardTap(context, 'payslip'),
        ),
        _buildCard(
          context,
          'Duty Rota',
          Icons.calendar_today,
          AppTheme.primaryColor,
          () => _handleCardTap(context, 'rota'),
        ),
        _buildCard(
          context,
          'Settings',
          Icons.settings_outlined,
          AppTheme.secondaryColor,
          () => _handleCardTap(context, 'settings'),
        ),
        _buildCard(
          context,
          'My Profile',
          Icons.person_outline,
          AppTheme.primaryColor,
          () => _handleCardTap(context, 'profile'),
        ),
        _buildCard(
          context,
          'Pension Report',
          Icons.account_balance_wallet,
          AppTheme.primaryColor,
          () => _handleCardTap(context, 'pension'),
        ),
        _buildCard(
          context,
          'Promotion Estimator',
          Icons.trending_up,
          Colors.green[700]!,
          () => _handleCardTap(context, 'promotion'),
        ),
        _buildCard(
          context,
          'Tax Summary',
          Icons.receipt_long_outlined,
          Colors.orange[700]!,
          () => _handleCardTap(context, 'tax'),
        ),
        _buildCard(
          context,
          'Salary Certificate',
          Icons.workspace_premium_outlined,
          Colors.teal[700]!,
          () => _handleCardTap(context, 'certificate'),
        ),
        _buildCard(
          context,
          'Earnings History',
          Icons.show_chart,
          Colors.indigo[600]!,
          () => _handleCardTap(context, 'earnings'),
        ),
        _buildCard(
          context,
          'Deductions Tracker',
          Icons.remove_circle_outline,
          Colors.red[700]!,
          () => _handleCardTap(context, 'deductions'),
        ),
        _buildCard(
          context,
          'Compare Payslips',
          Icons.compare_arrows,
          Colors.deepPurple[600]!,
          () => _handleCardTap(context, 'compare'),
        ),
        _buildCard(
          context,
          'Pay Calendar',
          Icons.calendar_month_outlined,
          Colors.cyan[700]!,
          () => _handleCardTap(context, 'calendar'),
        ),
        _buildCard(
          context,
          'Net Pay Trend',
          Icons.timeline,
          Colors.brown[600]!,
          () => _handleCardTap(context, 'trend'),
        ),
        _buildCard(
          context,
          'Payslip Bundle',
          Icons.picture_as_pdf_outlined,
          Colors.green[800]!,
          () => _handleCardTap(context, 'bundle'),
        ),
        _buildCard(
          context,
          'Income Statement',
          Icons.receipt_outlined,
          Colors.blueGrey[700]!,
          () => _handleCardTap(context, 'statement'),
        ),
      ],
    );
  }

  Widget _buildCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
