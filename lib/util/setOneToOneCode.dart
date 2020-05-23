String oneTooneCode(String user1, String user2){
  return user1.hashCode < user2.hashCode? user1 + user2 : user2 + user1;
}