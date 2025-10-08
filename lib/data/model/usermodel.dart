class Usermodel {
   String email;
    String username;
    String bio;
    String profile;
    List followers;
    List following;
    Usermodel({
      required this.email,
      required this.username,
      required this.bio,
      required this.profile,
      required this.followers,
      required this.following,
    });
}