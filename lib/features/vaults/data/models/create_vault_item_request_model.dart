class CreateVaultItemRequestModel {
  const CreateVaultItemRequestModel({
    required this.type,
    required this.encryptedData,
    required this.iv,
    required this.tag,
  });

  final String type;
  final String encryptedData;
  final String iv;
  final String tag;

  Map<String, dynamic> toJson() => {
    'type': type,
    'encrypted_data': encryptedData,
    'iv': iv,
    'tag': tag,
  };
}
