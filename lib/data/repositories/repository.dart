import '../models/models.dart';

abstract class Repository {
  Stream<List<FriendProfile>> watchAllFriends();

  Stream<List<Expense>> watchAllExpenses();

  Stream<List<Expense>> watchFriendExpenses(String friendId);

  Future<double> calculateFriendBalance(String friendId);

  Future<List<FriendProfile>> findAllFriends();

  Future<Expense> findExpenseById(String id);

  Future<FriendProfile?> findFriendById(String id);

  Future<List<Expense>> findAllExpenses();

  Future<List<Expense>> findFriendExpenses(String friendId);

  Future<int> insertFriend(FriendProfile friend);

  Future<int> insertExpense(Expense expense);

  Future<void> editFriendName(FriendProfile friend, String newName);

  Future<void> editFriendPicture(FriendProfile friend, String newPicture);

  Future<void> editExpense(Expense oldExpense, Expense newExpense);

  Future<void> deleteFriend(FriendProfile friend);

  Future<void> deleteExpense(Expense expense);

  Future<void> deleteExpenses(List<Expense> expenses);

  Future<void> deleteFriendExpenses(String friendId);

  Future init();
  void close();

}