import 'package:drift/drift.dart' show Value;
import 'package:drift_sqlite_test/data/database.dart';
import 'package:drift_sqlite_test/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        brightness: Brightness.dark,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Drift Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Consumer(
              builder: (context, ref, child) {
                final db = ref.read(dbProvider);
                return Expanded(
                  child: StreamBuilder<List<Task>>(
                    stream: db.watchAllTasks(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return ListView.builder(
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final task = snapshot.data![index];
                            return Dismissible(
                              key: ValueKey(task.id),
                              onDismissed: (direction) {
                                db.deleteTask(
                                    TasksCompanion(id: Value(task.id)));
                              },
                              child: ListTile(
                                title: Text(task.name),
                                subtitle: Text(task.date.toString()),
                                trailing: Checkbox(
                                  value: task.completed,
                                  onChanged: (value) {
                                    db.updateTask(
                                      TasksCompanion(
                                        id: Value(task.id),
                                        name: Value(task.name),
                                        date: Value(task.date),
                                        completed: Value(value!),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        );
                      } else {
                        return const CircularProgressIndicator();
                      }
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            context: context,
            builder: (context) => const NewInputField(),
          );
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class NewInputField extends StatefulWidget {
  const NewInputField({
    Key? key,
  }) : super(key: key);

  @override
  State<NewInputField> createState() => _NewInputFieldState();
}

class _NewInputFieldState extends State<NewInputField> {
  late TextEditingController taskNameController;
  DateTime? newTaskDate;

  @override
  void initState() {
    taskNameController = TextEditingController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: taskNameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter task name',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                onPressed: () async {
                  newTaskDate = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2050),
                  );
                },
                icon: const Icon(Icons.calendar_month),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Consumer(builder: (context, ref, child) {
            return ElevatedButton(
              onPressed: () {
                if (taskNameController.text.isEmpty || newTaskDate == null) {
                  return;
                } else {
                  final task = TasksCompanion(
                    name: Value(taskNameController.text),
                    date: Value(newTaskDate),
                  );
                  ref.read(dbProvider).insertTask(task);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            );
          }),
        ],
      ),
    );
  }
}
