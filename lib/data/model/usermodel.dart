class Usermodel {
  final String email;
  final String username;
  final String bio;
  final String profile;
  final String coverImage;
  final List followers;
  final List following;

  Usermodel({
    required this.email,
    required this.username,
    required this.bio,
    required this.profile,
    required this.coverImage,
    required this.followers,
    required this.following,
  });
}