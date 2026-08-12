class SalaryCertificateEmployee {
  final String name;
  final String staffId;
  final String ppno;
  final String gender;
  final String email;
  final String department;
  final String salaryType;
  final String? grade;
  final String? step;
  final String? employmentDate;
  final String? confirmationDate;
  final String? postingDate;
  final String? levelOfAppointment;

  SalaryCertificateEmployee({
    required this.name,
    required this.staffId,
    required this.ppno,
    required this.gender,
    required this.email,
    required this.department,
    required this.salaryType,
    this.grade,
    this.step,
    this.employmentDate,
    this.confirmationDate,
    this.postingDate,
    this.levelOfAppointment,
  });

  factory SalaryCertificateEmployee.fromJson(Map<String, dynamic> j) =>
      SalaryCertificateEmployee(
        name: j['name']?.toString() ?? '',
        staffId: j['staff_id']?.toString() ?? '',
        ppno: j['ppno']?.toString() ?? '',
        gender: j['gender']?.toString() ?? '',
        email: j['email']?.toString() ?? '',
        department: j['department']?.toString() ?? '',
        salaryType: j['salary_type']?.toString() ?? '',
        grade: j['grade']?.toString(),
        step: j['step']?.toString(),
        employmentDate: j['employment_date']?.toString(),
        confirmationDate: j['confirmation_date']?.toString(),
        postingDate: j['posting_date']?.toString(),
        levelOfAppointment: j['level_of_appointment']?.toString(),
      );

  String get gradeStep =>
      (grade != null && step != null) ? 'Grade $grade Step $step' : '';
}

class SalaryCertificateSalary {
  final String? period;
  final double gross;
  final double deductions;
  final double net;

  SalaryCertificateSalary({
    this.period,
    required this.gross,
    required this.deductions,
    required this.net,
  });

  factory SalaryCertificateSalary.fromJson(Map<String, dynamic> j) =>
      SalaryCertificateSalary(
        period: j['period']?.toString(),
        gross: (j['gross'] as num?)?.toDouble() ?? 0,
        deductions: (j['deductions'] as num?)?.toDouble() ?? 0,
        net: (j['net'] as num?)?.toDouble() ?? 0,
      );
}

class SalaryCertificate {
  final String generatedDate;
  final String purpose;
  final SalaryCertificateEmployee employee;
  final SalaryCertificateSalary salary;

  SalaryCertificate({
    required this.generatedDate,
    required this.purpose,
    required this.employee,
    required this.salary,
  });

  factory SalaryCertificate.fromJson(Map<String, dynamic> json) {
    final d = json['data'] as Map<String, dynamic>;
    return SalaryCertificate(
      generatedDate: d['generated_date']?.toString() ?? '',
      purpose: d['purpose']?.toString() ?? '',
      employee: SalaryCertificateEmployee.fromJson(d['employee']),
      salary: SalaryCertificateSalary.fromJson(d['salary']),
    );
  }
}
