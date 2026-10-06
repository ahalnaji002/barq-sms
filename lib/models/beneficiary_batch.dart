class BeneficiaryBatch {
  final int? id;
  final String name;
  final String originalFileName;
  final String createdAt;

  const BeneficiaryBatch({
    this.id,
    required this.name,
    required this.originalFileName,
    required this.createdAt,
  });

  /// هل هذا الكشف مكرر؟
  bool get isDuplicate => name.contains('مكرر');

  BeneficiaryBatch copyWith({
    int? id,
    String? name,
    String? originalFileName,
    String? createdAt,
  }) {
    return BeneficiaryBatch(
      id: id ?? this.id,
      name: name ?? this.name,
      originalFileName: originalFileName ?? this.originalFileName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name.trim(),
      'original_file_name': originalFileName.trim(),
      'created_at': createdAt,
    };
  }

  factory BeneficiaryBatch.fromMap(Map<String, dynamic> map) {
    return BeneficiaryBatch(
      id: map['id'] as int?,
      name: map['name']?.toString() ?? '',
      originalFileName: map['original_file_name']?.toString() ?? '',
      createdAt: map['created_at']?.toString() ?? '',
    );
  }

  @override
  String toString() {
    return 'BeneficiaryBatch('
        'id: $id, '
        'name: $name, '
        'originalFileName: $originalFileName'
        ')';
  }
}
