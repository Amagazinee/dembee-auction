/// Зөвхөн овог, нэр, portrait зураг — өөр профайл/auth хадгалахгүй.
class Submission {
  const Submission({
    required this.id,
    required this.lastName,
    required this.firstName,
    required this.imagePath,
    required this.submittedAt,
  });

  final String id;
  final String lastName;
  final String firstName;
  final String imagePath;
  final DateTime submittedAt;

  String get fullName => '$lastName $firstName'.trim();

  Map<String, dynamic> toJson() => {
        'id': id,
        'lastName': lastName,
        'firstName': firstName,
        'imagePath': imagePath,
        'submittedAt': submittedAt.toIso8601String(),
      };
}
