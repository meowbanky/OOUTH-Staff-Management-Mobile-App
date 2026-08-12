/// Labels for anywhere the app shows a staff member's grade.
///
/// A grade on its own does not say which scale it belongs to, so these build
/// the label from the pay scale instead: 'CONHESS/Step' for non-clinical
/// staff, 'CONMESS/Step' for doctors, and likewise for the smaller LOCUM and
/// CONTIPSOL scales.
///
/// The scale always comes from the API, which resolves it from tbl_salaryType.
/// It is deliberately not inferred here from the grade string. The grade alone
/// cannot identify LOCUM or CONTIPSOL staff, who carry ordinary CONHESS and
/// CONMESS grade codes; and proration appends 'P' to the step ('06P'), so any
/// client-side letter test applied to a combined "11/06P" would read that 'P'
/// as a CONMESS marker and mislabel a prorated CONHESS payslip.
///
/// Each falls back to its original generic label when the scale is unknown, so
/// nothing is ever labelled with a guess.
library;

/// 'CONHESS/Step', or 'Grade/Step' when [scheme] is empty.
String gradeStepLabel(String? scheme) {
  final s = (scheme ?? '').trim();
  return s.isEmpty ? 'Grade/Step' : '$s/Step';
}

/// 'CONHESS 11 / Step 06', or 'Grade 11 / Step 06' when [scheme] is empty.
///
/// For places that spell the grade and step out in the value itself rather
/// than pairing a label with a bare '11/06'.
String gradeStepValue(String? scheme, String grade, String step) {
  final s = (scheme ?? '').trim();
  return '${s.isEmpty ? 'Grade' : s} $grade / Step $step';
}
