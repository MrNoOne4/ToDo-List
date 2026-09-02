import 'package:flutter/material.dart';

// Entry point of the app, this is where everything starts running.
void main() {
  runApp(const MyApp());
}

// ============================================================
// MyApp
// This sets up the whole app: the title, the colors (theme),
// and which screen opens first (the ToDo List screen).
// ============================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToDo List', // App name (shows up in the task switcher)
      debugShowCheckedModeBanner: false, // Removes the "DEBUG" banner in the corner


      theme: ThemeData(
        // Base color scheme for the whole app, built from one "seed" color
        colorScheme: ColorScheme.fromSeed(
          seedColor: const  Color(0xFF6A1B9A),
          primary: const Color(0xFF6A1B9A), // Dark Purple - main color
          secondary: const Color(0xFFF3C6D8), // Pink - accent color
        ),

        scaffoldBackgroundColor: Colors.white, // White background on every screen
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6A1B9A), // App bar color (purple)
          foregroundColor: Colors.white, // Text/icon color on the app bar
          elevation: 0, // No shadow under the app bar
          centerTitle: true, // Keep the title text centered
        ),
        // Custom text styles used across the app (this is what satisfies
        // the "custom fonts / text styles" part of theming).
        textTheme: const TextTheme(
          titleLarge: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF6A1B9A),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ),


      home: const ToDoListScreen(), // First screen shown when the app opens
    );
  }
}

// This turns a TimeOfDay into readable text like "6:00 AM"
// without needing a BuildContext (safe to call from initState).
String formatTime(TimeOfDay t) {
  final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod; // Convert to 12-hour format
  final minute = t.minute.toString().padLeft(2, '0'); // Always show 2 digits (ex: "05")
  final period = t.period == DayPeriod.am ? 'AM' : 'PM'; // Figure out AM or PM
  return '$hour:$minute $period';
}

// ============================================================
// Task
// This is the "blueprint" for one task. It stores the
// title, description, date, time, category,
// and whether it is done or not.
// ============================================================


class Task {
  String title; // Title of the task
  String description; // Extra details for the task (can be empty)
  DateTime date; // Date the task is scheduled for
  TimeOfDay time; // Time the task is scheduled for
  String category; // Category/label for the task
  bool isCompleted; // True if the task has been finished

  // Constructor - this is how a new Task object gets created
  Task({
    required this.title,
    this.description = '',
    required this.date,
    required this.time,
    this.category = '',
    this.isCompleted = false

  });

  // This turns the date and time into a readable text,
  // like "1:00 PM • Aug 26, 2026".

  String get formattedDateTime  {
    final month = monthName(date.month); // Get the short month name (ex: "Aug")
    return '${formatTime(time)} • $month ${date.day}, ${date.year}';
  }

   // This just converts a month number (1-12) into its short name.
  String monthName(int month){
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[month - 1]; // -1 because list index starts at 0, but months start at 1
  }
}

// ============================================================
// ToDoListScreen
// This is the MAIN screen. It shows the pink banner at the
// top, the list of tasks, and the + button to add a new task.
// ============================================================
class ToDoListScreen extends StatefulWidget {
  const ToDoListScreen({super.key});


  @override
  State<ToDoListScreen> createState() => ToDoListScreenState();
}

class ToDoListScreenState extends State<ToDoListScreen> {
  // This is the list that holds all the tasks. It starts
  // with 4 sample tasks so the app has something to show.

  // DUMMY DATA IN LIST ARRAY
  final List<Task> tasks = [
    Task(
      title: 'Wuwa Time',
      date: DateTime(2026, 8, 26),
      time: const TimeOfDay(hour: 20, minute: 0),
      category: 'Fun',
    ),

    Task(
      title: 'Night Walk with Self',
      date: DateTime(2026, 8, 30),
      time: const TimeOfDay(hour: 23, minute: 0),
      category: 'Health',
    ),

    Task(
      title: 'Assessment Project',
      date: DateTime(2026, 9, 2),
      time: const TimeOfDay(hour: 7, minute: 30),
      category: 'School',
    ),

    Task(
      title: 'Study Flutter',
      description: 'Review widgets, state management, and UI layout.',
      date: DateTime(2026, 9, 3),
      time: const TimeOfDay(hour: 6, minute: 0),
      category: 'School',
      isCompleted: true,
    ),
  ];

  // --- Functions that change the task list ---

  // Toggle button for a task's completed status
  void toggleCompleted(Task task){
    setState((){
      task.isCompleted = !task.isCompleted; // Flip the status (done <-> not done)
    });
    // Short confirmation so the user knows the tap/double-tap actually
    // did something, instead of the checkbox just silently changing.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(task.isCompleted
            ? 'Marked "${task.title}" as done!'
            : 'Marked "${task.title}" as not done'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  // Delete function for a task
  void deleteTask(Task task){
    setState((){
      tasks.remove(task); // Remove the task from the list
    });
    // Confirmation for the long-press-to-delete gesture.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${task.title}"'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Task Detail popup function for one task
  Future<void> openTaskDetail(Task task) async {
    // Open the TaskDetailsDialog popup, and wait (await) for what it
    // sends back when it closes (delete, toggle, or nothing/null)
    final result = await showDialog<String>(
      context: context,
      builder: (context) => TaskDetailsDialog(task: task),
    );

    if (result == 'delete') {
      // If "delete" was sent back, remove the task
      deleteTask(task);
    } else {
      // If it was "toggle" (mark as completed) or came back from editing,
      // just refresh the screen so any changes show up right away
      setState((){});
    }
  }
  
  // Add Task popup function
  Future<void> openAddTask() async {
    // Open the AddTaskDialog popup and wait for it to return a new
    // Task (null if the user cancelled/closed it)
    final newTask = await showDialog<Task>(
      context: context,
      builder: (context) => const AddTaskDialog(),
    );

    if (newTask != null) {
      setState(() {
        tasks.add(newTask); // Add the new task to the list
      });
      // Confirmation that the form submission actually created a task.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${newTask.title}" added!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    // Count how many tasks are done, for the "x/x done" text
    final doneCount = tasks.where((t) => t.isCompleted).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TODO List')),
        
          // The round + button in the bottom-right corner of the screen
          floatingActionButton: FloatingActionButton(
          onPressed: openAddTask, // Tap it to open the Add Task popup
          backgroundColor: const Color(0xFF6A1B9A),
          child: const Icon(Icons.add, color: Colors.white),
      ),

      // The decorative border strip at the very bottom of the screen.
      // Flutter automatically floats the FAB above this bar, so the
      // strip ends up sitting right below the add button.
       bottomNavigationBar: Container(
        height: 30, // Height of the border strip
        decoration: const BoxDecoration(
          image: DecorationImage(
            // ResizeImage controls the size of ONE tile before it repeats.
            // (DecorationImage itself has no width/height property.)
            image: ResizeImage(
              AssetImage('assets/images/border_strip.jpg'),
              width: 124, // Width of ONE tile (keeps the pixel-art crisp)
              height: 30, // Height of ONE tile
            ),
            repeat: ImageRepeat.repeatX, // Tile the image sideways to fill the width
            alignment: Alignment.topCenter,
          ),
        ),
      ),

      
     
      body: Column(
        children: [
          // --- Pink banner at the top (title + "x/x done") ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF3C6D8), // Pink background for the banner
                borderRadius: BorderRadius.circular(20), // Rounded corners
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ToDo List', // Banner title
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6A1B9A),
                          ),
                        ),
                        const SizedBox(height: 4), // Small gap between texts
                        const Text(
                          'Get things done, one task at a time', // Subtitle
                          style: TextStyle(color: Color(0xFF6A1B9A)),
                        ),
                        const SizedBox(height: 12),
                        // The small pill that says "x/x done".
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white70, // Slightly see-through white
                            borderRadius: BorderRadius.circular(20), // Pill shape
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_outline,
                                  size: 16, color: Color(0xFF6A1B9A)),
                              const SizedBox(width: 6),
                              Text('$doneCount/${tasks.length} done', // Ex: "2/4 done"
                                  style: const TextStyle(
                                      color: Color(0xFF6A1B9A))),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Placeholder photo, shown as a small circle.
                  // Swap 'assets/images/paw_photo.png' for your own photo later.
                  ClipOval(
                    child: Image.asset(
                      'assets/LOGOFINAL.png',
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
            ),
          ),
 
          // --- The scrollable list of tasks ---
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: tasks.length, // How many tasks to show
              itemBuilder: (context, index) {
                final task = tasks[index]; // Get the task at this index
 
                // GestureDetector lets one task row react to 3
                // different touches:
                // - Tap once -> open the details popup
                // - Tap twice fast -> mark done/not done
                // - Press and hold -> delete the task
                return GestureDetector(
                  onTap: () => openTaskDetail(task), // Single tap -> open details popup
                  onDoubleTap: () => toggleCompleted(task), // Double tap -> mark done/not done
                  onLongPress: () => deleteTask(task), // Press and hold -> delete it
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16, top: 6), // Space around each row
                    // Stack lets us float the little category badge on top
                    // of the corner of the card, instead of squeezing it
                    // into the Row layout below.
                    child: Stack(
                      clipBehavior: Clip.none, // Let the badge stick out past the edge
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            // Filled pink if done, white if not done yet.
                            color: task.isCompleted
                                ? const Color(0xFFF3C6D8)
                                : Colors.white,
                            border: Border.all(color: const Color(0xFF6A1B9A)), // Purple border
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              // Checkbox also toggles done/not done.
                              Checkbox(
                                value: task.isCompleted,
                                activeColor: const Color(0xFF6A1B9A),
                                onChanged: (_) => toggleCompleted(task), // Tap to toggle status
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title, // Task title
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.access_time,
                                            size: 14, color: Color(0xFF6A1B9A)),
                                        const SizedBox(width: 4),
                                        Text(task.formattedDateTime, // Task date and time
                                            style: const TextStyle(fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // The small category badge, only shown if a
                        // category was actually typed in.
                        if (task.category.isNotEmpty)
                          Positioned(
                            top: -6,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6A1B9A),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                task.category,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
 
// ============================================================
// PopupShell
// A shared "card popup" frame used by both AddTaskDialog and
// TaskDetailsDialog, styled like the reference screenshot:
// a rounded white card centered on a dimmed background, with
// a bold title, a close (X) button, and scrollable content.
// ============================================================
class PopupShell extends StatelessWidget {
  final String title; // Title shown at the top of the popup
  final Widget child; // Content to place inside the popup
  final double maxWidth; // Largest width the popup can be
 
  const PopupShell({
    super.key,
    required this.title,
    required this.child,
    this.maxWidth = 480,
  });
 
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white, // White background for the popup card
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // Rounded corners
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24), // Space from screen edges
      child: ConstrainedBox(
        // MediaQuery makes this popup responsive: it will never be
        // taller than 85% of whatever screen it's shown on.
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Header row: title + close (X) button ---
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A1B9A),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    color: Colors.grey,
                    onPressed: () => Navigator.pop(context), // Close the popup
                  ),
                ],
              ),
              const Divider(height: 16), // Line under the header
              // --- Scrollable body so long content never overflows ---
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(right: 8, top: 4),
                  child: child, // The actual content of the popup goes here
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
 
// ============================================================
// AddTaskDialog
// This popup has ONE job, but TWO uses:
//  1. Adding a brand new task (existingTask is left empty/null)
//  2. Editing a task that already exists (existingTask is
//     passed in, so the form starts already filled in)
//
// The Form below has 5 TextFormFields: Title, Description,
// Category, Date, and Time — each one checked by a validator
// before the task can be saved.
// ============================================================
class AddTaskDialog extends StatefulWidget {
  // If this is null, we are ADDING a new task.
  // If this has a task in it, we are EDITING that task.
  final Task? existingTask;
 
  const AddTaskDialog({super.key, this.existingTask});
 
  @override
  State<AddTaskDialog> createState() => AddTaskDialogState();
}
 
class AddTaskDialogState extends State<AddTaskDialog> {
  final formKey = GlobalKey<FormState>(); // Key used to validate the form
  final titleController = TextEditingController(); // Controller for the title field
  final descriptionController = TextEditingController(); // Controller for the description field
  final categoryController = TextEditingController(); // Controller for the category field
  final dateController = TextEditingController(); // Controller that just DISPLAYS the picked date as text
  final timeController = TextEditingController(); // Controller that just DISPLAYS the picked time as text
 
  DateTime selectedDate = DateTime.now(); // Currently selected date
  TimeOfDay selectedTime = TimeOfDay.now(); // Currently selected time
 
  // Quick helper so we don't have to type "widget.existingTask != null"
  // everywhere below.
  bool get isEditing => widget.existingTask != null;
 
  @override
  void initState() {
    super.initState();
    // If we were given a task to edit, fill in every field with
    // that task's current information so the user sees it already
    // filled in, instead of starting blank.
    if (isEditing) {
      final task = widget.existingTask!;
      titleController.text = task.title; // Fill in the title field
      descriptionController.text = task.description; // Fill in the description field
      categoryController.text = task.category; // Fill in the category field
      selectedDate = task.date; // Use the task's existing date
      selectedTime = task.time; // Use the task's existing time
    }
    // Show the starting date/time as text in their own fields.
    dateController.text =
        '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}';
    timeController.text = formatTime(selectedTime);
  }
 
  @override
  void dispose() {
    // Clean up the controllers when they're no longer needed
    // (this avoids memory leaks)
    titleController.dispose();
    descriptionController.dispose();
    categoryController.dispose();
    dateController.dispose();
    timeController.dispose();
    super.dispose();
  }
 
  // Opens the calendar popup so the user can pick a date.
  Future<void> pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        selectedDate = picked; // Update the selected date
        dateController.text =
            '${picked.month}/${picked.day}/${picked.year}'; // Show it in the text field
      });
    }
  }
 
  // Opens the clock popup so the user can pick a time.
  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null) {
      setState(() {
        selectedTime = picked; // Update the selected time
        timeController.text = formatTime(picked); // Show it in the text field
      });
    }
  }
 
  // Runs when the user taps the big purple button at the bottom.
  // It checks the form is valid, then either UPDATES the existing
  // task (edit mode) or CREATES a new task (add mode).
  void submit() {
    if (!formKey.currentState!.validate()) {
      return; // If the form is invalid (ex: no title), stop here
    }
 
    if (isEditing) {
      // Edit mode: change the values on the SAME task object that
      // was passed in. Because it's the same object the list is
      // already pointing to, the list updates automatically.
      final task = widget.existingTask!;
      task.title = titleController.text;
      task.description = descriptionController.text;
      task.category = categoryController.text;
      task.date = selectedDate;
      task.time = selectedTime;
 
      // Close the popup and send the updated task along, so the
      // previous screen knows something changed.
      Navigator.pop(context, task);
    } else {
      // Add mode: build a brand new Task from the form fields.
      final newTask = Task(
        title: titleController.text,
        description: descriptionController.text,
        category: categoryController.text,
        date: selectedDate,
        time: selectedTime,
      );
      Navigator.pop(context, newTask); // Close popup and return the new task
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return PopupShell(
      title: isEditing ? 'Edit Task' : 'Add Task', // Change the title based on the mode
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1) Title field (required) ---
            const Text('Title', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextFormField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: 'Enter task title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title'; // Error message if title is empty
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
 
            // --- 2) Description field (optional, no validator needed) ---
            const Text('Description',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextFormField(
              controller: descriptionController,
              maxLines: 3, // Allow multi-line text
              decoration: const InputDecoration(
                hintText: 'Enter description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
 
            // --- 3) Category field (required) ---
            const Text('Category',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextFormField(
              controller: categoryController,
              decoration: const InputDecoration(
                hintText: 'e.g. School, Health, Fun',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a category'; // Error message if category is empty
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
 
            // --- 4) Date field (required, tap to open calendar) ---
            const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextFormField(
              controller: dateController,
              readOnly: true, // User can't type here, only pick from the calendar
              onTap: pickDate, // Tap the field to open the date picker
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today, size: 18),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a date';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
 
            // --- 5) Time field (required, tap to open clock) ---
            const Text('Time', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            TextFormField(
              controller: timeController,
              readOnly: true, // User can't type here, only pick from the clock
              onTap: pickTime, // Tap the field to open the time picker
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time, size: 18),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select a time';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
 
            // --- Save button (text changes for add vs edit) ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: submit, // Tap to save/add the task
                child: Text(
                  isEditing ? 'Save Changes' : 'Add Task', // Change the text based on the mode
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
// ============================================================
// TaskDetailsDialog
// This popup shows the full info for ONE task, plus three
// buttons: Mark as Completed, Edit Task, and Delete Task.
// ============================================================
class TaskDetailsDialog extends StatefulWidget {
  final Task task; // The specific task being shown
 
  const TaskDetailsDialog({super.key, required this.task});
 
  @override
  State<TaskDetailsDialog> createState() => TaskDetailsDialogState();
}
 
class TaskDetailsDialogState extends State<TaskDetailsDialog> {
  // Opens the Add Task popup in "edit mode" for this task, on top
  // of this details popup. After it closes, we refresh this popup
  // so any new title, date, etc. show up right away.
  Future<void> editTask() async {
    final updated = await showDialog<Task>(
      context: context,
      builder: (context) => AddTaskDialog(existingTask: widget.task),
    );
    setState(() {}); // Redraw this popup with the updated task info

    // Confirmation that the edit form submission actually saved.
    // (updated is null if the user closed the edit popup with X instead.)
    if (updated != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${updated.title}" updated!'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final task = widget.task; // Get the task being shown
 
    return PopupShell(
      title: 'Task Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- Card with the task's title, date/time, category, description ---
          // Using the Card widget here (instead of a plain Container)
          // still gets us the purple border look via its shape.
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Color(0xFF6A1B9A)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        task.isCompleted
                            ? Icons.check_box
                            : Icons.check_box_outline_blank, // Change icon based on status
                        color: const Color(0xFF6A1B9A),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(task.title, // Task title
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 16, color: Color(0xFF6A1B9A)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(task.formattedDateTime)), // Date and time
                    ],
                  ),
                  if (task.category.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.label_outline,
                            size: 16, color: Color(0xFF6A1B9A)),
                        const SizedBox(width: 6),
                        Text(task.category), // Category
                      ],
                    ),
                  ],
                  const Divider(height: 24),
                  Text(task.description.isEmpty
                      ? 'No description added.' // Fallback text if there's no description
                      : task.description),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
 
          // --- Card with the 3 action buttons ---
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Color(0xFF6A1B9A)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // Tapping this closes this popup and sends 'toggle'
                  // back to the list screen, which flips the task
                  // between done/not done.
                  actionRow(
                    icon: Icons.check_circle_outline,
                    label: 'Mark as Completed',
                    onTap: () => Navigator.pop(context, 'toggle'),
                  ),
                  const Divider(),
 
                  // Tapping this opens the edit popup for this task.
                  actionRow(
                    icon: Icons.edit,
                    label: 'Edit Task',
                    onTap: editTask,
                  ),
                  const Divider(),
 
                  // Tapping this closes this popup and sends 'delete'
                  // back to the list screen, which removes this task.
                  actionRow(
                    icon: Icons.delete,
                    label: 'Delete Task',
                    color: Colors.red,
                    onTap: () => Navigator.pop(context, 'delete'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
 
  // Small helper that builds one tappable row (icon + text)
  // so we don't repeat the same layout code 3 times.
  Widget actionRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.black,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}