class ChatUser {
  String id, name, email, photoUrl, createdAt;
  List<dynamic> friends, requests, sentRequests;
  ChatUser({
    this.id,
    this.name,
    this.email,
    this.photoUrl,
    this.createdAt,
    this.friends,
    this.requests,
    this.sentRequests,
  });
  ChatUser.fromJSON(data) {
    this.id = data.data()['id'];
    this.name = data.data()['name'];
    this.email = data.data()['email'];
    this.photoUrl = data.data()['photoUrl'];
    this.createdAt = data.data()['createdAt'];
    this.friends = data.data()['friends'];
    this.requests = data.data()['requests'];
    this.sentRequests = data.data()['sentRequests'];
  }
}
