/// Model representing a partial date (e.g., release dates where only year is known)
/// Matches the Kotlin FuzzyDate data class structure
class FuzzyDate {
  /// Required year value
  final int year;

  /// Optional month (1-12)
  final int? month;

  /// Optional day (1-31)
  final int? day;

  FuzzyDate({
    required this.year,
    this.month,
    this.day,
  });

  factory FuzzyDate.fromJson(Map<String, dynamic> json) {
    return FuzzyDate(
      year: json['year'] as int,
      month: json['month'] as int?,
      day: json['day'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'year': year,
      if (month != null) 'month': month,
      if (day != null) 'day': day,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FuzzyDate &&
        other.year == year &&
        other.month == month &&
        other.day == day;
  }

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => 'FuzzyDate(year: $year, month: $month, day: $day)';
}
