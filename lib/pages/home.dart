import 'package:flutter/material.dart';
import 'package:minimal_habit_tracker/components/my_drawer.dart';
import 'package:minimal_habit_tracker/components/my_habit_tile.dart';
import 'package:minimal_habit_tracker/components/my_heatmap.dart';
import 'package:minimal_habit_tracker/db/habit_db.dart';
import 'package:minimal_habit_tracker/models/habit.dart';
import 'package:minimal_habit_tracker/utils/habit_util.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController textController = TextEditingController();

  @override
  void initState() {
    Provider.of<HabitDb>(context, listen: false).readHabits();
    super.initState();
  }

  void createNewHabit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: "Create a new habit",
          ),
        ),
        actions: [
          // save button:
          MaterialButton(
            onPressed: () {
              // get the new habit name:
              final newHabitTitle = textController.text;
              // save to db:
              context.read<HabitDb>().addHabit(newHabitTitle);
              //clear controller:
              textController.clear();
              Navigator.pop(context);
            },
            child: Text('Add a new habit'),
          ),
          //cancel button:
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              textController.clear();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void toggleHabit(bool? value, Habit habit) {
    if (value != null) {
      context.read<HabitDb>().updateHabitCompletion(
            habit.id,
            value,
          );
    }
  }

  void editHabit(Habit habit) {
    //set controller text to the current habit's name:
    textController.text = habit.title;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(
          controller: textController,
        ),
        actions: [
          MaterialButton(
            onPressed: () {
              // get the new habit name:
              final newHabitTitle = textController.text;
              // save to db:
              context.read<HabitDb>().updateHabitName(habit.id, newHabitTitle);
              //clear controller:
              textController.clear();
              Navigator.pop(context);
            },
            child: const Text('Edit'),
          ),
          //cancel button:
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              textController.clear();
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void deleteHabitBox(Habit habit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure you want delete this habit?'),
        actions: [
          MaterialButton(
            onPressed: () {
              // delete from db:
              context.read<HabitDb>().deleteHabit(habit.id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
          //cancel button:
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              textController.clear();
            },
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
      ),
      drawer: const MyDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewHabit,
        elevation: 0,
        // backgroundColor: Theme.of(context).colorScheme.tertiary,
        child: const Icon(Icons.add_box),
      ),
      body: ListView(
        children: [
          _buildHeatMap(),
          _buildHabitList(),
        ],
      ),
    );
  }

  Widget _buildHeatMap() {
    final habitsDb = context.watch<HabitDb>();
    List<Habit> currentHabits = habitsDb.currentHabit;
    return FutureBuilder<DateTime?>(
        future: habitsDb.getFirstLunchDate(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return MyHeatMap(
                startDate: snapshot.data!,
                datasets: prepHeatMapDataset(currentHabits));
          } else {
            return Container();
          }
        });
  }

  Widget _buildHabitList() {
    final habitDb = context.watch<HabitDb>();
    List<Habit> currentHabits = habitDb.currentHabit;
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: currentHabits.length,
      itemBuilder: (context, index) {
        //get each individual habit:
        final habit = currentHabits[index];
        //check if the habit is completed today
        bool isCompletedToday = isHabitCompletedToday(habit.completedDays);
        //return habit tile UI
        return MyHabitTile(
          text: habit.title,
          isCompleted: isCompletedToday,
          onChanged: (value) => toggleHabit(value, habit),
          editHabit: (context) => editHabit(habit),
          deleteHabit: (context) => deleteHabitBox(habit),
        );
      },
    );
  }
}
