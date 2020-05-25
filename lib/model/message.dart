class Message {
  String senderID, receiverID, message, timestamp;
  Message({
    this.senderID,
    this.receiverID,
    this.message,
    this.timestamp,
  });
  Message.fromJSON(data) {
    this.senderID = data['senderid'];
    this.receiverID = data['receiverid'];
    this.message = data['message'];
    this.timestamp = data['timestamp'];
  }
}
