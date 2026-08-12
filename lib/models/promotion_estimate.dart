class PromotionBreakdownItem {
  final String name;
  final double current;
  final double newValue;
  final double diff;

  PromotionBreakdownItem({
    required this.name,
    required this.current,
    required this.newValue,
    required this.diff,
  });

  factory PromotionBreakdownItem.fromJson(Map<String, dynamic> json) {
    return PromotionBreakdownItem(
      name: json['name']?.toString() ?? '',
      current: (json['current'] as num?)?.toDouble() ?? 0.0,
      newValue: (json['new'] as num?)?.toDouble() ?? 0.0,
      diff: (json['diff'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class PromotionEstimate {
  final String staffId;
  final String name;
  final String currentGrade;
  final int currentStep;
  final String newGrade;
  final String newStep;

  /// Pay scale both the current and projected grade sit on. A promotion moves
  /// grade and step, never the scale. Empty when unknown.
  final String gradeScheme;
  final int gradeIncrement;
  final int stepIncrement;
  final double currentTotal;
  final double newTotal;
  final double diff;
  final List<PromotionBreakdownItem> breakdown;

  PromotionEstimate({
    required this.staffId,
    required this.name,
    required this.currentGrade,
    required this.currentStep,
    required this.newGrade,
    required this.newStep,
    required this.gradeScheme,
    required this.gradeIncrement,
    required this.stepIncrement,
    required this.currentTotal,
    required this.newTotal,
    required this.diff,
    required this.breakdown,
  });

  factory PromotionEstimate.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    return PromotionEstimate(
      staffId: data['staff_id']?.toString() ?? '',
      name: data['name']?.toString() ?? '',
      currentGrade: data['current_grade']?.toString() ?? '',
      currentStep: (data['current_step'] as num?)?.toInt() ?? 0,
      newGrade: data['new_grade']?.toString() ?? '',
      newStep: data['new_step']?.toString() ?? '',
      gradeScheme: data['grade_scheme']?.toString() ?? '',
      gradeIncrement: (data['grade_increment'] as num?)?.toInt() ?? 0,
      stepIncrement: (data['step_increment'] as num?)?.toInt() ?? 0,
      currentTotal: (data['current_total_raw'] as num?)?.toDouble() ?? 0.0,
      newTotal: (data['new_total_raw'] as num?)?.toDouble() ?? 0.0,
      diff: (data['diff_raw'] as num?)?.toDouble() ?? 0.0,
      breakdown: (data['breakdown'] as List<dynamic>?)
              ?.map((e) =>
                  PromotionBreakdownItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
