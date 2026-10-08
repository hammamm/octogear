class UpdateCustomerProfileCommand {
  const UpdateCustomerProfileCommand({
    required this.fullName,
    required this.cityId,
  });

  final String fullName;
  final int cityId;
}
