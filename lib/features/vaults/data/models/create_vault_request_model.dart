class CreateVaultRequestModel {
  const CreateVaultRequestModel({required this.name, this.description});

  final String name;
  final String? description;

  Map<String, dynamic> toJson() => {'name': name};
}
