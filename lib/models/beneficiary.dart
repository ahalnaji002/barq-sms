class Beneficiary {
  final int? id;
  final int serialNumber;
  final String name;
  final String nationalId;
  final String phoneNumber;
  final String area;
  final int familyMembers;
  final String studentName;
  final String guardianName;

  const Beneficiary({
    this.id,
    required this.serialNumber,
    required this.name,
    required this.nationalId,
    required this.phoneNumber,
    required this.area,
    required this.familyMembers,
    this.studentName = '',
    this.guardianName = '',
  });

  Beneficiary copyWith({
    int? id,
    int? serialNumber,
    String? name,
    String? nationalId,
    String? phoneNumber,
    String? area,
    int? familyMembers,
    String? studentName,
    String? guardianName,
  }) {
    return Beneficiary(
      id: id ?? this.id,
      serialNumber: serialNumber ?? this.serialNumber,
      name: name ?? this.name,
      nationalId: nationalId ?? this.nationalId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      area: area ?? this.area,
      familyMembers: familyMembers ?? this.familyMembers,
      studentName: studentName ?? this.studentName,
      guardianName: guardianName ?? this.guardianName,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serial_number': serialNumber,
      'name': name.trim(),
      'national_id': normalizeNationalId(nationalId),
      'phone_number': normalizePhoneNumber(phoneNumber),
      'area': area.trim(),
      'family_members': familyMembers,
      'student_name': studentName.trim(),
      'guardian_name': guardianName.trim(),
    };
  }

  factory Beneficiary.fromMap(Map<String, dynamic> map) {
    return Beneficiary(
      id: map['id'] as int?,
      serialNumber: _parseInt(map['serial_number']),
      name: map['name']?.toString().trim() ?? '',
      nationalId: normalizeNationalId(
        map['national_id']?.toString() ?? '',
      ),
      phoneNumber: normalizePhoneNumber(
        map['phone_number']?.toString() ?? '',
      ),
      area: map['area']?.toString().trim() ?? '',
      familyMembers: _parseInt(map['family_members']),
      studentName: map['student_name']?.toString().trim() ?? '',
      guardianName: map['guardian_name']?.toString().trim() ?? '',
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(value?.toString().trim() ?? '') ?? 0;
  }

  static String normalizePhoneNumber(String value) {
    var phone = convertArabicNumbersToEnglish(value);

    phone = phone.trim();

    phone = phone.replaceAll(
      RegExp(r'[^0-9+]'),
      '',
    );

    if (phone.startsWith('+970')) {
      phone = phone.substring(4);
    } else if (phone.startsWith('00970')) {
      phone = phone.substring(5);
    } else if (phone.startsWith('970')) {
      phone = phone.substring(3);
    }

    if (phone.startsWith('0') && phone.length == 10) {
      return phone;
    }

    if (phone.length == 9 &&
        (phone.startsWith('59') || phone.startsWith('56'))) {
      return '0$phone';
    }

    return phone;
  }

  static String normalizeNationalId(String value) {
    var nationalId = convertArabicNumbersToEnglish(value);

    nationalId = nationalId.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );

    return nationalId;
  }

  static String convertArabicNumbersToEnglish(String value) {
    const arabicNumbers = {
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
      '۰': '0',
      '۱': '1',
      '۲': '2',
      '۳': '3',
      '۴': '4',
      '۵': '5',
      '۶': '6',
      '۷': '7',
      '۸': '8',
      '۹': '9',
    };

    var result = value;

    arabicNumbers.forEach((arabic, english) {
      result = result.replaceAll(arabic, english);
    });

    return result;
  }

  static bool isValidPhoneNumber(String value) {
    final phone = normalizePhoneNumber(value);

    return RegExp(r'^05[69][0-9]{7}$').hasMatch(phone);
  }

  static bool isValidNationalId(String value) {
    final nationalId = normalizeNationalId(value);

    return RegExp(r'^[0-9]{9}$').hasMatch(nationalId);
  }

  static bool isValidName(String value) {
    return value.trim().length >= 2;
  }

  static bool isValidFamilyMembers(int value) {
    return value >= 0;
  }

  bool get hasValidPhoneNumber {
    return isValidPhoneNumber(phoneNumber);
  }

  bool get hasValidNationalId {
    return isValidNationalId(nationalId);
  }

  bool get hasValidName {
    return isValidName(name);
  }

  bool get isValid {
    return hasValidName &&
        hasValidPhoneNumber &&
        hasValidNationalId &&
        isValidFamilyMembers(familyMembers);
  }

  List<String> get validationErrors {
    final errors = <String>[];

    if (!hasValidName) {
      errors.add('اسم المستفيد غير صحيح');
    }

    if (!hasValidPhoneNumber) {
      errors.add('رقم الجوال غير صحيح');
    }

    if (!hasValidNationalId) {
      errors.add('رقم الهوية يجب أن يتكون من 9 أرقام');
    }

    if (!isValidFamilyMembers(familyMembers)) {
      errors.add('عدد أفراد الأسرة غير صحيح');
    }

    return errors;
  }

  Beneficiary normalized() {
    return copyWith(
      name: name.trim(),
      nationalId: normalizeNationalId(nationalId),
      phoneNumber: normalizePhoneNumber(phoneNumber),
      area: area.trim(),
    );
  }

  @override
  String toString() {
    return 'Beneficiary('
        'id: $id, '
        'name: $name, '
        'nationalId: $nationalId, '
        'phoneNumber: $phoneNumber'
        ')';
  }
}
