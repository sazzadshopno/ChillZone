class User {
  String id, name, email, photoUrl, createdAt;
  List<dynamic> friends, requests, sentRequests;
  User({
    this.id,
    this.name,
    this.email,
    this.photoUrl,
    this.createdAt,
    this.friends,
    this.requests,
    this.sentRequests,
  });
  User.fromJSON(data) {
    this.id = data['id'];
    this.name = data['name'];
    this.email = data['email'];
    this.photoUrl = data['photoUrl'];
    this.createdAt = data['createdAt'];
    this.friends = data['friends'];
    this.requests = data['requests'];
    this.sentRequests = data['sentRequests'];
  }
}
