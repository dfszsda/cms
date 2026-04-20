class CollegeModel {
  final String id;
  final String name;
  final String shortName;
  final String university;
  final String city;
  final String district;
  final String workingHoursWeekday;
  final String workingHoursSaturday;
  final String? logoUrl;

  CollegeModel({
    required this.id,
    required this.name,
    required this.shortName,
    required this.university,
    required this.city,
    required this.district,
    required this.workingHoursWeekday,
    required this.workingHoursSaturday,
    this.logoUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'shortName': shortName,
      'university': university,
      'city': city,
      'district': district,
      'workingHoursWeekday': workingHoursWeekday,
      'workingHoursSaturday': workingHoursSaturday,
      'logoUrl': logoUrl,
    };
  }

  factory CollegeModel.fromMap(Map<String, dynamic> map, String id) {
    return CollegeModel(
      id: id,
      name: map['name'] ?? '',
      shortName: map['shortName'] ?? '',
      university: map['university'] ?? '',
      city: map['city'] ?? '',
      district: map['district'] ?? '',
      workingHoursWeekday: map['workingHoursWeekday'] ?? '',
      workingHoursSaturday: map['workingHoursSaturday'] ?? '',
      logoUrl: map['logoUrl'],
    );
  }
}
