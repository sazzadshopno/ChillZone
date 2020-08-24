class Message {
  String senderID, receiverID, message, timestamp;
  Message({
    this.senderID,
    this.receiverID,
    this.message,
    this.timestamp,
  });
  Message.fromJSON(data) {
    this.senderID = data.data()['senderid'];
    this.receiverID = data.data()['receiverid'];
    this.message = data.data()['message'];
    this.timestamp = data.data()['timestamp'];
  }
}
