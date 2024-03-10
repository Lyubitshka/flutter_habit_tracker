import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:minimal_habit_tracker/models/app_settings.dart';
import 'package:minimal_habit_tracker/models/habit.dart';
import 'package:path_provider/path_provider.dart';

class HabitDb extends ChangeNotifier {
  static late Isar isar;
  //initialize:
  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [
        HabitSchema,
        AppSettingsSchema,
      ],
      directory: dir.path,
    );
  }

//for heatmap:
  Future<void> saveFirstLunchDate() async {
    final existingSettings = await isar.appSettings.where().findFirst();
    if (existingSettings == null) {
      final settings = AppSettings()..firstLunchDate = DateTime.now();
      await isar.writeTxn(() => isar.appSettings.put(settings));
    }
  }

  Future<DateTime?> getFirstLunchDate() async {
    final settings = await isar.appSettings.where().findFirst();
    return settings?.firstLunchDate;
  }

//List of habits
  final List<Habit> currentHabit = [];

/* 
    C R U D    operations:
*/
  Future<void> addHabit(String habitName) async {
    //create a new habit
    final newHabit = Habit()..title = habitName;
    //save habit to db
    await isar.writeTxn(() => isar.habits.put(newHabit));
    //re-read from db
    readHabits();
  }

  Future<void> readHabits() async {
    //fetch all habits from db:
    List<Habit> fetchedHabits = await isar.habits.where().findAll();
    //give to current habit:
    currentHabit.clear();
    currentHabit.addAll(fetchedHabits);
    //update UI
    notifyListeners();
  }

  Future<void> updateHabitCompletion(int id, bool isCompleted) async {
// find the specific habit:
    final habit = await isar.habits.get(id);
    // update completion status:
    if (habit != null) {
      await isar.writeTxn(() async {
        // if habit is completed -> add the current date to the completedDays List
        if (isCompleted && !habit.completedDays.contains(DateTime.now())) {
          final today = DateTime.now();

          habit.completedDays.add(DateTime(
            today.year,
            today.month,
            today.day,
          ));
        }
        // if the habit IS NOT completed ---> remove the current date from the list
        else {
          habit.completedDays.removeWhere((date) =>
              date.year == DateTime.now().year &&
              date.month == DateTime.now().month &&
              date.day == DateTime.now().day);
        }
        await isar.habits.put(habit);
      });
    }
// re-read from db:
    readHabits();
  }

  Future<void> updateHabitName(int id, String newTitle) async {
    final habit = await isar.habits.get(id);
    if (habit != null) {
      await isar.writeTxn(() async {
        habit.title = newTitle;
        await isar.habits.put(habit);
      });
    }
    readHabits();
  }

  Future<void> deleteHabit(int id) async {
    await isar.writeTxn(() async {
      await isar.habits.delete(id);
    });
    readHabits();
  }
}
