import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:splitly/providers.dart';
import 'package:splitly/ui/views/expenseForm/expense_form_page.dart';
import 'package:splitly/data/models/expense.dart';
import 'package:splitly/utils.dart';
import 'package:splitly/utils/friend_utils.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({
    super.key,
  });

  @override
  ConsumerState createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  late Stream<List<Expense>> expenseStream;
  late String selectedFriendId;

  @override
  void initState() {
    super.initState();

    final selectedFriend = FriendUtils.getSelectedFriend(ref);
    if (selectedFriend == null) {
      throw Exception('No friend selected!');
    }

    selectedFriendId = selectedFriend.id;

    final repository = ref.read(repositoryProvider.notifier);
    expenseStream = repository.watchFriendExpenses(selectedFriendId);
  }

  void deleteExpense(Expense expense) async {
    //todo: save index of deleted expense
    final repository = ref.read(repositoryProvider.notifier);
    repository.deleteExpense(expense);

    if (mounted) {
      showSnackBar(context, '${expense.name} deleted', 'Undo', () {
        repository.insertExpense(expense);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        appBar: AppBar(title: const Text('Splitly')),
        body: StreamBuilder(
            stream: expenseStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return const Text('Error loading expenses');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Text('No expenses available');
              } else {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    int reverseIndex = snapshot.data!.length - index - 1;
                    return _buildExpenseItem(snapshot.data![reverseIndex]);
                  },
                );
              }
            }),
      );
    } catch (e) {
      return const Scaffold(
        body: Center(child: Text('No friend selected!')),
      );
    }
  }

  Dismissible _buildExpenseItem(Expense expense) {
    return Dismissible(
      key: Key(expense.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        deleteExpense(expense);
      },
      background: _buildDeleteBackground(),
      child: GestureDetector(
        onTap: () => _showExpenseDetails(expense),
        child: _buildExpenseCard(expense: expense),
      ),
    );
  }

  Container _buildDeleteBackground() {
    return Container(
      color: Colors.red,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: const Icon(Icons.delete, color: Colors.white),
    );
  }

  Widget _buildExpenseCard({required Expense expense}) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        elevation: 10.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExpenseDetails(expense: expense),
              const Spacer(),
              _buildCostDetails(expense: expense),
            ],
          ),
        ),
      ),
    );
  }

  Column _buildExpenseDetails({required Expense expense}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          expense.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          formatDate(expense.date),
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Column _buildCostDetails({required Expense expense}) {
    return Column(
      children: [
        Text(
          '${expense.totalCost}\$',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          '(Paid by ${expense.payer})',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  void _showExpenseDetails(Expense expense) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildExpenseDetailsSheet(expense),
    );
  }

  Widget _buildExpenseDetailsSheet(Expense expense) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildExpenseDetailsTitle(expense),
          const SizedBox(height: 10.0),
          Text('Cost: ${expense.totalCost}\$',
              style: Theme
                  .of(context)
                  .textTheme
                  .titleSmall),
          const SizedBox(height: 10.0),
          Text('Paid by: ${expense.payer}',
              style: Theme
                  .of(context)
                  .textTheme
                  .titleSmall),
          const SizedBox(height: 4.0),
          Text('Your consumption: ${expense.shouldBePaidByUser}',
              style: Theme
                  .of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.grey)),
          Text('You paid: ${expense.paidByUser}'),
          Text('Their consumption: ${expense.shouldBePaidByFriend}',
              style: Theme
                  .of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(color: Colors.grey)),
          Text('They paid: ${expense.paidByFriend}'),
          ...?_buildExpenseDetailsDescription(expense),
        ],
      ),
    );
  }

  Row _buildExpenseDetailsTitle(Expense expense) {
    return Row(
      children: [
        Text(
          expense.name,
          style: const TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () async {
            Navigator.pop(context);
            final editedExpense = await Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => ExpenseFormPage(editExpense: expense)),
            );

            final repository = ref.read(repositoryProvider.notifier);
            if (editedExpense != null) {
              repository.editExpense(expense, editedExpense);
            }
          },
          icon: Icon(
            Icons.edit,
            color: Theme
                .of(context)
                .iconTheme
                .color,
          ),
        ),
      ],
    );
  }

  List<Widget>? _buildExpenseDetailsDescription(Expense expense) {
    if (expense.description != null) {
      return [
        const SizedBox(height: 10.0),
        Text(
          'Description: ${expense.description}',
          style: Theme
              .of(context)
              .textTheme
              .apply(displayColor: Theme
              .of(context)
              .colorScheme
              .onSurface)
              .bodySmall,
        ),
      ];
    }
    return null;
  }
}
