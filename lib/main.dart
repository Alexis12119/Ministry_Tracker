import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:clipboard/clipboard.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Ministry Tracker',
      home: TimerScreen(),
    );
  }
}

class Task {
  String type;
  String name;
  String age;
  String phoneNumber;
  String date;
  String question;
  String place;
  double? latitude;
  double? longitude;

  Task({
    required this.type,
    required this.name,
    required this.age,
    required this.phoneNumber,
    String date = "",
    required this.question,
    required this.place,
    this.latitude,
    this.longitude,
  }) : date = DateFormat('yyyy-MM-dd').format(DateTime.now());

  // Update the factory method to handle the optional date field
  factory Task.fromJson(String jsonString) {
    Map<String, dynamic> jsonData = jsonDecode(jsonString);
    return Task(
      type: jsonData['type'],
      name: jsonData['name'],
      phoneNumber: jsonData['phoneNumber'],
      date: jsonData['date'],
      age: jsonData['age'],
      question: jsonData['question'],
      place: jsonData['place'],
      latitude: jsonData['latitude'],
      longitude: jsonData['longitude'],
    );
  }

  String toJson() {
    return jsonEncode({
      'type': type,
      'name': name,
      'age': age,
      'phoneNumber': phoneNumber,
      'date': date,
      'question': question,
      'place': place,
      'latitude': latitude,
      'longitude': longitude,
    });
  }
}

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  _TimerScreenState createState() => _TimerScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> _tasks = [];
  List<Task> _filteredTasks = [];
  final List<String> _taskTypes = ['Return Visit', 'Bible Study'];
  String _selectedTaskType = 'Return Visit';
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks List', style: TextStyle(fontSize: 20)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _filterTasks(value);
              },
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredTasks.length,
              itemBuilder: (context, index) {
                Task task = _filteredTasks[index];
                return GestureDetector(
                  onTap: () {
                    _startEditingTask(task);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      title: Text(
                        task.type,
                        style: const TextStyle(fontSize: 18),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Name: ${task.name}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Age: ${task.age}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Phone Number: ${task.phoneNumber}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Date: ${task.date}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Question: ${task.question}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Text(
                            'Place: ${task.place}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          Row(
                            children: [
                              Text(
                                'Location: ${task.latitude ?? 'Not set'}, ${task.longitude ?? 'Not set'}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(
                                  width:
                                      8), // Add spacing between location text and button
                              // "Copy Location" button
                              if (task.latitude != null &&
                                  task.longitude != null)
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  onPressed: () {
                                    String locationString =
                                        '${task.latitude}, ${task.longitude}';
                                    FlutterClipboard.copy(locationString).then(
                                      (value) => ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Location copied to clipboard'),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          _removeTask(task);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Task removed: ${task.type}'),
                          ));
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open a new screen to add a task
          _showAddTaskDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  void _addTask(Task task) {
    setState(() {
      _tasks.add(task);
      _filteredTasks.add(task); // Add to filteredTasks as well
    });
    _saveTasks();
  }

  void _filterTasks(String query) {
    _filteredTasks = _tasks
        .where((task) =>
            task.type.toLowerCase().contains(query.toLowerCase()) ||
            task.name.toLowerCase().contains(query.toLowerCase()) ||
            task.date.toLowerCase().contains(query.toLowerCase()) ||
            task.question.toLowerCase().contains(query.toLowerCase()) ||
            task.place.toLowerCase().contains(query.toLowerCase()))
        .toList();
    setState(() {});
  }

  void _loadTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedTasks = prefs.getStringList('tasks') ?? [];

    setState(() {
      _tasks =
          savedTasks.map((jsonString) => Task.fromJson(jsonString)).toList();
      _filteredTasks = List.from(_tasks); // Initialize filteredTasks
    });
  }

  void _removeTask(Task task) {
    setState(() {
      _tasks.remove(task);
      _filteredTasks.remove(task); // Remove from filteredTasks as well
    });
    _saveTasks();
  }

  void _saveTasks() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> jsonList = _tasks.map((task) => task.toJson()).toList();
    prefs.setStringList('tasks', jsonList);
  }

  void _showAddTaskDialog(BuildContext context) async {
    TextEditingController nameController = TextEditingController();
    TextEditingController ageController = TextEditingController();
    TextEditingController phoneNumberController = TextEditingController();
    TextEditingController questionController = TextEditingController();
    TextEditingController placeController = TextEditingController();

    double? latitudeValue;
    double? longitudeValue;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Task'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _selectedTaskType,
                  items: _taskTypes.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      _selectedTaskType = value ?? 'Return Visit';
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  // Set maxLines to null for multiline support
                  maxLines: null,
                ),
                TextField(
                  controller: ageController,
                  decoration: const InputDecoration(labelText: 'Age'),
                ),
                TextField(
                  controller: phoneNumberController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                ),
                TextField(
                  controller: questionController,
                  decoration: const InputDecoration(labelText: 'Question'),
                  // Set maxLines to null for multiline support
                  maxLines: null,
                ),
                TextField(
                  controller: placeController,
                  decoration: const InputDecoration(labelText: 'Place'),
                  // Set maxLines to null for multiline support
                  maxLines: null,
                ),
                // "Get Location" button
                ElevatedButton(
                  onPressed: () async {
                    // Check if location permission is granted
                    var status = await Permission.location.request();

                    if (status == PermissionStatus.granted) {
                      // Location permission granted, proceed with getting location
                      Position position = await Geolocator.getCurrentPosition();
                      setState(() {
                        latitudeValue = position.latitude;
                        longitudeValue = position.longitude;
                      });
                    } else {
                      // Location permission denied
                      // Handle the case where the user denied location permission
                      // You can show a message or handle it according to your app's requirements
                    }
                  },
                  child: const Text('Get Location'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Add the task and dismiss the dialog
                Task newTask = Task(
                  type: _selectedTaskType,
                  name: nameController.text,
                  age: ageController.text,
                  phoneNumber: phoneNumberController.text,
                  question: questionController.text,
                  place: placeController.text,
                  latitude: latitudeValue,
                  longitude: longitudeValue,
                );
                _addTask(newTask);
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _startEditingTask(Task task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Task'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                // Similar form fields as the Add Task dialog
                DropdownButtonFormField<String>(
                  value: task.type,
                  items: _taskTypes.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      task.type = value ?? 'Return Visit';
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Type'),
                ),
                TextField(
                  controller: TextEditingController(text: task.name),
                  decoration: const InputDecoration(labelText: 'Name'),
                  // Set maxLines to null for multiline support
                  maxLines: null,
                  onChanged: (value) {
                    setState(() {
                      task.name = value;
                    });
                  },
                ),
                TextField(
                  controller: TextEditingController(text: task.age),
                  decoration: const InputDecoration(labelText: 'Age'),
                  // Set maxLines to null for multiline support
                  maxLines: null,
                  onChanged: (value) {
                    setState(() {
                      task.age = value;
                    });
                  },
                ),
                TextField(
                  controller: TextEditingController(text: task.phoneNumber),
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  // Set maxLines to null for multiline support
                  maxLines: null,
                  onChanged: (value) {
                    setState(() {
                      task.phoneNumber = value;
                    });
                  },
                ),
                TextField(
                  controller: TextEditingController(text: task.question),
                  decoration: const InputDecoration(labelText: 'Question'),
                  // Set maxLines to null for multiline support
                  maxLines: null,
                  onChanged: (value) {
                    setState(() {
                      task.question = value;
                    });
                  },
                ),
                TextField(
                  controller: TextEditingController(text: task.place),
                  decoration: const InputDecoration(labelText: 'Place'),
                  // Set maxLines to null for multiline support
                  maxLines: null,
                  onChanged: (value) {
                    setState(() {
                      task.place = value;
                    });
                  },
                ),
                // "Copy Location" button
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Update the task and dismiss the dialog
                _saveTasks();
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}

class MonthlyTotal {
  final String monthKey;
  int totalSeconds;
  int showedVideosCounter;
  int placementsCounter;
  int bibleStudiesCounter;
  int returnVisitsCounter;

  MonthlyTotal({
    required this.monthKey,
    required this.totalSeconds,
    required this.showedVideosCounter,
    required this.placementsCounter,
    required this.bibleStudiesCounter,
    required this.returnVisitsCounter,
  });

  Map<String, dynamic> toJson() {
    return {
      'monthKey': monthKey,
      'totalSeconds': totalSeconds,
      'showedVideosCounter': showedVideosCounter,
      'placementsCounter': placementsCounter,
      'bibleStudiesCounter': bibleStudiesCounter,
      'returnVisitsCounter': returnVisitsCounter,
    };
  }

  factory MonthlyTotal.fromJson(String jsonString) {
    Map<String, dynamic> jsonData = jsonDecode(jsonString);

    return MonthlyTotal(
      monthKey: jsonData['monthKey'],
      totalSeconds: jsonData['totalSeconds'] ?? 0,
      showedVideosCounter: jsonData['showedVideosCounter'] ?? 0,
      placementsCounter: jsonData['placementsCounter'] ?? 0,
      bibleStudiesCounter: jsonData['bibleStudiesCounter'] ?? 0,
      returnVisitsCounter: jsonData['returnVisitsCounter'] ?? 0,
    );
  }

  String get formattedTotal => _formatTime(totalSeconds);

  String get monthName {
    List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    List<String> parts = monthKey.split('_');
    int monthIndex = int.parse(parts[1]) - 1;
    return months[monthIndex];
  }

  int get year => int.parse(monthKey.split('_')[0]);

  setTotalSeconds(int seconds) {
    totalSeconds = seconds;
  }

  String _formatTime(int timeInSeconds) {
    Duration duration = Duration(seconds: timeInSeconds);
    String hours = duration.inHours.remainder(24).toString().padLeft(2, '0');
    String minutes =
        duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

class MonthlyTotalsScreen extends StatefulWidget {
  final List<MonthlyTotal> monthlyTotals;
  final int showedVideosCounter;
  final int placementsCounter;
  final int bibleStudiesCounter;
  final int returnVisitsCounter;
  final bool isPioneerEnabled;

  const MonthlyTotalsScreen({
    super.key,
    required this.monthlyTotals,
    required this.showedVideosCounter,
    required this.placementsCounter,
    required this.bibleStudiesCounter,
    required this.returnVisitsCounter,
    required this.isPioneerEnabled,
  });

  @override
  _MonthlyTotalsScreenState createState() => _MonthlyTotalsScreenState(
      monthlyTotals: monthlyTotals,
      showedVideosCounter: showedVideosCounter,
      placementsCounter: placementsCounter,
      bibleStudiesCounter: bibleStudiesCounter,
      returnVisitsCounter: returnVisitsCounter,
      isPioneerEnabled: isPioneerEnabled);
}

class _MonthlyTotalsScreenState extends State<MonthlyTotalsScreen> {
  List<MonthlyTotal> monthlyTotals;
  List<MonthlyTotal> filteredMonthlyTotals;
  TextEditingController searchController = TextEditingController();
  int showedVideosCounter;
  int placementsCounter;
  int bibleStudiesCounter;
  int returnVisitsCounter;
  bool isPioneerEnabled;

  _MonthlyTotalsScreenState({
    required this.monthlyTotals,
    required this.showedVideosCounter,
    required this.placementsCounter,
    required this.bibleStudiesCounter,
    required this.returnVisitsCounter,
    required this.isPioneerEnabled,
  }) : filteredMonthlyTotals = List.from(monthlyTotals);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Monthly Hours', style: TextStyle(fontSize: 20)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                _filterMonths(value);
              },
              decoration: const InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredMonthlyTotals.length,
              itemBuilder: (context, index) {
                MonthlyTotal monthlyTotal = filteredMonthlyTotals[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        title: Text(
                          '${monthlyTotal.monthName}, ${monthlyTotal.year} - ${monthlyTotal.formattedTotal}',
                          style: const TextStyle(fontSize: 18),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _removeMonth(monthlyTotal.monthKey);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  'Month removed: ${monthlyTotal.monthName}, ${monthlyTotal.year}'),
                            ));
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton(
                          onPressed: () {
                            _showMonthlyActivityPopup(context, monthlyTotal);
                          },
                          child: const Text(
                            'This Month Activity',
                            style: TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showMonthlyActivityPopup(
      BuildContext context, MonthlyTotal selectedTotal) {
    // Retrieve the selected monthly total or use a default value
    MonthlyTotal currentMonthTotal = monthlyTotals.firstWhere(
      (total) => total.monthKey == selectedTotal.monthKey,
      orElse: () => MonthlyTotal(
        monthKey: selectedTotal.monthKey,
        placementsCounter: selectedTotal.placementsCounter,
        showedVideosCounter: selectedTotal.showedVideosCounter,
        bibleStudiesCounter: bibleStudiesCounter,
        returnVisitsCounter: returnVisitsCounter,
        totalSeconds: 0,
      ),
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('This Month Activity'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActivityRow(
                  'Video Showed', currentMonthTotal.showedVideosCounter),
              _buildActivityRow(
                  'Placements', currentMonthTotal.placementsCounter),
              _buildActivityRow('Conducted Bible Studies',
                  currentMonthTotal.bibleStudiesCounter),
              _buildActivityRow(
                  'Return Visits', currentMonthTotal.returnVisitsCounter),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActivityRow(String activity, int value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(activity),
        Text(value.toString()),
      ],
    );
  }

  void _filterMonths(String query) {
    filteredMonthlyTotals = monthlyTotals
        .where((total) =>
            total.monthKey.toLowerCase().contains(query.toLowerCase()) ||
            total.monthName.toLowerCase().contains(query.toLowerCase()) ||
            total.year.toString().contains(query))
        .toList();
    setState(() {});
  }

  void _removeMonth(String monthKey) {
    setState(() {
      monthlyTotals.removeWhere((total) => total.monthKey == monthKey);
      filteredMonthlyTotals.removeWhere((total) => total.monthKey == monthKey);
    });
    _saveMonthlyTotals();
  }

  void _saveMonthlyTotals() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> jsonList =
        monthlyTotals.map((total) => jsonEncode(total.toJson())).toList();
    prefs.setStringList('monthlyTotals', jsonList);
  }
}

class _TimerScreenState extends State<TimerScreen> {
  late Timer _timer;
  int _serviceTime = 0;
  DateTime _lastStartTime = DateTime.now();
  bool _isTimerRunning = false;
  List<MonthlyTotal> _monthlyTotals = [];

  // Add counters for each activity
  int showedVideosCounter = 0;
  int placementsCounter = 0;
  int bibleStudiesCounter = 0;
  int returnVisitsCounter = 0;

  // Add a boolean variable for the switch state
  bool isPioneerEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ministry Tracker', style: TextStyle(fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.access_time),
            onPressed: () {
              _showMonthlyTotalsScreen(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.assignment),
            onPressed: () {
              _showTaskListScreen(context);
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Service Time: ${_formatTime(_serviceTime)}',
                style: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            _isTimerRunning
                ? ElevatedButton(
                    onPressed: _stopTimer,
                    child: const Text(
                      'Stop Timer',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _startTimerAction,
                    child: const Text(
                      'Start Timer',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
            // Switch widget
            Switch(
              value: isPioneerEnabled,
              onChanged: (value) {
                setState(() {
                  isPioneerEnabled = value;
                });
                _savePioneerMode(); // Save Pioneer mode state when it changes
              },
              activeTrackColor: Colors.lightGreenAccent,
              activeColor: Colors.green,
            ),
            // "Pioneer mode" text
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Pioneer Mode: ${isPioneerEnabled ? 'Enabled' : 'Disabled'}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
            // Conditionally show the button based on the switch state
            if (isPioneerEnabled && _monthlyTotals.isNotEmpty)
              ElevatedButton(
                onPressed: () {
                  if (_monthlyTotals.isNotEmpty) {
                    _showCountersDialog(context, _monthlyTotals.last.monthKey);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Start the timer first'),
                      ),
                    );
                  }
                },
                child: const Text(
                  'Show Activity',
                  style: TextStyle(fontSize: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showMonthlyTotalsScreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (BuildContext context) => MonthlyTotalsScreen(
        monthlyTotals: _monthlyTotals,
        showedVideosCounter: showedVideosCounter,
        placementsCounter: placementsCounter,
        bibleStudiesCounter: bibleStudiesCounter,
        returnVisitsCounter: returnVisitsCounter,
        isPioneerEnabled: isPioneerEnabled,
      ),
    ));
  }

  @override
  void initState() {
    super.initState();
    _loadServiceTime();
    _loadMonthlyTotals();
    _loadPioneerMode();
    _loadCounters();
    _checkMonthChange();
  }

  void _loadPioneerMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isPioneerEnabled = prefs.getBool('isPioneerEnabled') ?? false;
    });
  }

  void _savePioneerMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isPioneerEnabled', isPioneerEnabled);
  }

  void _loadCounters() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      showedVideosCounter = prefs.getInt('showedVideosCounter') ?? 0;
      placementsCounter = prefs.getInt('placementsCounter') ?? 0;
      bibleStudiesCounter = prefs.getInt('bibleStudiesCounter') ?? 0;
      returnVisitsCounter = prefs.getInt('returnVisitsCounter') ?? 0;
    });
  }

  void _saveCounters() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('showedVideosCounter', showedVideosCounter);
    prefs.setInt('placementsCounter', placementsCounter);
    prefs.setInt('bibleStudiesCounter', bibleStudiesCounter);
    prefs.setInt('returnVisitsCounter', returnVisitsCounter);
  }

  Widget _buildCounterRow(
    String activity,
    int counter,
    VoidCallback onIncrement,
    VoidCallback onDecrement,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(activity, style: const TextStyle(fontSize: 16)),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: onIncrement,
            ),
            Text('$counter', style: const TextStyle(fontSize: 16)),
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: onDecrement,
            ),
          ],
        ),
      ],
    );
  }

  void _checkMonthChange() {
    DateTime now = DateTime.now();
    String newMonthKey = '${now.year}_${now.month}';

    MonthlyTotal existingEntry = _monthlyTotals.firstWhere(
      (total) => total.monthKey == newMonthKey,
      orElse: () => MonthlyTotal(
        monthKey: newMonthKey,
        placementsCounter: 0,
        showedVideosCounter: 0,
        bibleStudiesCounter: 0,
        returnVisitsCounter: 0,
        totalSeconds: 0,
      ),
    );

    // Reset counters and switch state when a new month begins
    if (_monthlyTotals.isEmpty || _monthlyTotals.last.monthKey != newMonthKey) {
      setState(() {
        showedVideosCounter = 0;
        placementsCounter = 0;
        bibleStudiesCounter = 0;
        returnVisitsCounter = 0;
        isPioneerEnabled = false;
      });
    }

    _monthlyTotals.remove(existingEntry);
    setState(() {
      _monthlyTotals.add(existingEntry);
    });

    _saveMonthlyTotals();
  }

  String _formatTime(int timeInSeconds) {
    Duration duration = Duration(seconds: timeInSeconds);
    String hours = duration.inHours.remainder(24).toString().padLeft(2, '0');
    String minutes =
        duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    String seconds =
        duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  void _incrementCounter(
      String counterType, String monthKey, StateSetter setState) {
    setState(() {
      switch (counterType) {
        case 'showedVideos':
          showedVideosCounter++;
          break;
        case 'placements':
          placementsCounter++;
          break;
        case 'bibleStudies':
          bibleStudiesCounter++;
          break;
        case 'returnVisits':
          returnVisitsCounter++;
          break;
      }

      // Find the MonthlyTotal for the selected monthKey
      MonthlyTotal currentMonthTotal = _monthlyTotals.firstWhere(
        (total) => total.monthKey == monthKey,
        orElse: () => MonthlyTotal(
          monthKey: monthKey,
          totalSeconds: 0,
          showedVideosCounter: 0,
          placementsCounter: 0,
          bibleStudiesCounter: 0,
          returnVisitsCounter: 0,
        ),
      );

      // Update counters in currentMonthTotal
      currentMonthTotal.showedVideosCounter = showedVideosCounter;
      currentMonthTotal.placementsCounter = placementsCounter;
      currentMonthTotal.bibleStudiesCounter = bibleStudiesCounter;
      currentMonthTotal.returnVisitsCounter = returnVisitsCounter;

      // Update or add the current month's MonthlyTotal in _monthlyTotals
      int index =
          _monthlyTotals.indexWhere((total) => total.monthKey == monthKey);
      if (index != -1) {
        _monthlyTotals[index] = currentMonthTotal;
      } else {
        _monthlyTotals.add(currentMonthTotal);
      }
    });

    _saveCounters(); // Save counters when they change
    _saveMonthlyTotals(); // Save monthly totals after updating
  }

  void _decrementCounter(
      String counterType, String monthKey, StateSetter setState) {
    setState(() {
      switch (counterType) {
        case 'showedVideos':
          if (showedVideosCounter > 0) showedVideosCounter--;
          break;
        case 'placements':
          if (placementsCounter > 0) placementsCounter--;
          break;
        case 'bibleStudies':
          if (bibleStudiesCounter > 0) bibleStudiesCounter--;
          break;
        case 'returnVisits':
          if (returnVisitsCounter > 0) returnVisitsCounter--;
          break;
      }

      // Find the MonthlyTotal for the selected monthKey
      MonthlyTotal currentMonthTotal = _monthlyTotals.firstWhere(
        (total) => total.monthKey == monthKey,
        orElse: () => MonthlyTotal(
          monthKey: monthKey,
          totalSeconds: 0,
          showedVideosCounter: 0,
          placementsCounter: 0,
          bibleStudiesCounter: 0,
          returnVisitsCounter: 0,
        ),
      );

      // Update counters in currentMonthTotal
      currentMonthTotal.showedVideosCounter = showedVideosCounter;
      currentMonthTotal.placementsCounter = placementsCounter;
      currentMonthTotal.bibleStudiesCounter = bibleStudiesCounter;
      currentMonthTotal.returnVisitsCounter = returnVisitsCounter;

      // Update or add the current month's MonthlyTotal in _monthlyTotals
      int index =
          _monthlyTotals.indexWhere((total) => total.monthKey == monthKey);
      if (index != -1) {
        _monthlyTotals[index] = currentMonthTotal;
      } else {
        _monthlyTotals.add(currentMonthTotal);
      }
    });

    _saveCounters(); // Save counters when they change
    _saveMonthlyTotals(); // Save monthly totals after updating
  }

  void _loadServiceTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int savedTime = prefs.getInt('serviceTime') ?? 0;

    setState(() {
      _serviceTime = savedTime;
    });
  }

  void _loadMonthlyTotals() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> savedMonthlyTotals =
        prefs.getStringList('monthlyTotals') ?? [];

    setState(() {
      _monthlyTotals = savedMonthlyTotals
          .map((jsonString) => MonthlyTotal.fromJson(jsonString))
          .toList();
    });
  }

  void _saveserviceTime() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('serviceTime', _serviceTime);
  }

  void _saveMonthlyTotals() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> jsonList =
        _monthlyTotals.map((total) => jsonEncode(total.toJson())).toList();
    prefs.setStringList('monthlyTotals', jsonList);
  }

  void _showCountersDialog(BuildContext context, String monthKey) {
    bool isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Activity Counters'),
              content: SizedBox(
                width:
                    isPortrait ? null : MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCounterRow(
                      'Showed Videos ',
                      showedVideosCounter,
                      () =>
                          _incrementCounter('showedVideos', monthKey, setState),
                      () =>
                          _decrementCounter('showedVideos', monthKey, setState),
                    ),
                    _buildCounterRow(
                      'Placements',
                      placementsCounter,
                      () => _incrementCounter('placements', monthKey, setState),
                      () => _decrementCounter('placements', monthKey, setState),
                    ),
                    _buildCounterRow(
                      'Conducted Bible Studies',
                      bibleStudiesCounter,
                      () =>
                          _incrementCounter('bibleStudies', monthKey, setState),
                      () =>
                          _decrementCounter('bibleStudies', monthKey, setState),
                    ),
                    _buildCounterRow(
                      'Return Visits',
                      returnVisitsCounter,
                      () =>
                          _incrementCounter('returnVisits', monthKey, setState),
                      () =>
                          _decrementCounter('returnVisits', monthKey, setState),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTaskListScreen(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (BuildContext context) => const TaskListScreen(),
    ));
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      setState(() {
        _serviceTime = DateTime.now().difference(_lastStartTime).inSeconds;
      });
    });
  }

  void _startTimerAction() {
    _checkMonthChange();

    DateTime currentTime = DateTime.now();
    Duration timeDifference = currentTime.difference(_lastStartTime);

    // Check if there's a significant time difference (e.g., negative difference)
    if (timeDifference.isNegative || timeDifference.inMinutes > 5) {
      // Reset service time to zero if cheating is detected
      setState(() {
        _serviceTime = 0;
        _isTimerRunning = true;
        _lastStartTime = currentTime;
      });
      _startTimer();
    } else {
      setState(() {
        _isTimerRunning = true;
        _lastStartTime = currentTime;
      });
      _startTimer();
    }
  }

  void _stopTimer() {
    if (_isTimerRunning) {
      _checkMonthChange();
      setState(() {
        _isTimerRunning = false;
        int serviceSeconds =
            DateTime.now().difference(_lastStartTime).inSeconds;
        _monthlyTotals.last.totalSeconds += serviceSeconds;
        _serviceTime = 0; // Reset service time to 0
        _lastStartTime = DateTime.now();
      });
      _timer.cancel();
      _saveserviceTime();
      _saveMonthlyTotals();
    }
  }
}
