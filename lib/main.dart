import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'todo_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Todo App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          primary: Colors.blue,
          secondary: const Color(0xFF00E676),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const TodoHomeScreen(),
    );
  }
}

class TodoHomeScreen extends StatefulWidget {
  const TodoHomeScreen({super.key});

  @override
  State<TodoHomeScreen> createState() => _TodoHomeScreenState();
}

class _TodoHomeScreenState extends State<TodoHomeScreen> {
  List<Todo> _todos = [];
  bool _isLoading = true;
  bool _isSearchMode = false;
  String _searchQuery = '';

  final TextEditingController _searchFieldController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _loadTodos();
    _searchFieldController.addListener(() {
      setState(() {
        _searchQuery = _searchFieldController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchFieldController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<Todo> get _filteredTodos {
    if (_searchQuery.trim().isEmpty) {
      return _todos;
    }
    final query = _searchQuery.toLowerCase();
    return _todos.where((todo) {
      final titleMatch = todo.title.toLowerCase().contains(query);
      final descMatch = todo.description.toLowerCase().contains(query);
      return titleMatch || descMatch;
    }).toList();
  }

  Future<void> _loadTodos() async {
    try {
      setState(() {
        _isLoading = true;
      });
      final prefs = await SharedPreferences.getInstance();
      final todosString = prefs.getString('todos');
      if (todosString != null) {
        final List<dynamic> decodedList = json.decode(todosString);
        final loaded = decodedList
            .map((item) => Todo.fromMap(item as Map<String, dynamic>))
            .toList();
        loaded.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        setState(() {
          _todos = loaded;
        });
      }
    } catch (e) {
      debugPrint('Error loading todos: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encodedList = _todos.map((todo) => todo.toMap()).toList();
      await prefs.setString('todos', json.encode(encodedList));
    } catch (e) {
      debugPrint('Error saving todos: $e');
    }
  }

  Future<void> _addTodo(String title, String description) async {
    if (title.trim().isEmpty) return;

    final newTodo = Todo(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.trim(),
      description: description.trim(),
      createdAt: DateTime.now(),
    );

    setState(() {
      _todos.insert(0, newTodo);
    });
    await _saveTodos();
  }

  Future<void> _updateTodo(
    String id,
    String newTitle,
    String newDescription,
  ) async {
    if (newTitle.trim().isEmpty) return;

    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      setState(() {
        _todos[index] = _todos[index].copyWith(
          title: newTitle.trim(),
          description: newDescription.trim(),
        );
      });
      await _saveTodos();
    }
  }

  Future<void> _toggleTodoStatus(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      setState(() {
        _todos[index] = _todos[index].copyWith(
          isCompleted: !_todos[index].isCompleted,
        );
      });
      await _saveTodos();
    }
  }

  Future<void> _deleteTodo(String id) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index != -1) {
      setState(() {
        _todos.removeAt(index);
      });
      await _saveTodos();
    }
  }

  void _showTodoBottomSheet({Todo? todoToEdit}) {
    final titleController = TextEditingController(
      text: todoToEdit?.title ?? '',
    );
    final descController = TextEditingController(
      text: todoToEdit?.description ?? '',
    );
    final isEditing = todoToEdit != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20.0,
            right: 20.0,
            top: 24.0,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEditing ? 'Edit Task' : 'Create New Task',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter task title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.blue, width: 1),
                  ),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Enter task description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.blue, width: 1),
                  ),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final title = titleController.text.trim();
                      final desc = descController.text.trim();
                      if (title.isNotEmpty) {
                        if (isEditing) {
                          _updateTodo(todoToEdit.id, title, desc);
                        } else {
                          _addTodo(title, desc);
                        }
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      isEditing ? 'Save' : 'Create',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isSearching) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Text(
              isSearching ? 'No matching tasks found' : 'All caught up!',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try searching for something else or clear the search query.'
                  : 'Add a new task using the "+" button below to get started.',
              style: const TextStyle(fontSize: 14, color: Colors.black38),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodoCard(Todo todo) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: Key(todo.id),
        direction: DismissDirection.horizontal,
        background: Container(
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Row(
            children: [
              Icon(Icons.delete, color: Colors.white),
              SizedBox(width: 8),
              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        secondaryBackground: Container(
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.delete, color: Colors.white),
            ],
          ),
        ),
        onDismissed: (direction) {
          final title = todo.title;
          final description = todo.description;
          _deleteTodo(todo.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"$title" deleted'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  _addTodo(title, description);
                },
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showTodoBottomSheet(todoToEdit: todo),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                child: Row(
                  children: [
                    // Custom Checkbox
                    GestureDetector(
                      onTap: () => _toggleTodoStatus(todo.id),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: todo.isCompleted
                            ? const Icon(
                                Icons.check,
                                color: Colors.blue,
                                size: 28,
                              )
                            : Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFF00E676),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Title & Description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            todo.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: todo.isCompleted
                                  ? Colors.black38
                                  : Colors.black87,
                              decoration: todo.isCompleted
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          if (todo.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              todo.description,
                              style: TextStyle(
                                fontSize: 13,
                                color: todo.isCompleted
                                    ? Colors.black38
                                    : Colors.black54,
                                decoration: todo.isCompleted
                                    ? TextDecoration.lineThrough
                                    : TextDecoration.none,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAppBar() {
    return BottomAppBar(
      color: Colors.white,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      elevation: 8,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.black87),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.info_outline),
                              title: const Text('About Todo App'),
                              onTap: () {
                                Navigator.pop(context);
                                showAboutDialog(
                                  context: context,
                                  applicationName: 'Todo App',
                                  applicationVersion: '1.0.0',
                                  applicationIcon: const Icon(
                                    Icons.check_circle,
                                    color: Colors.blue,
                                    size: 40,
                                  ),
                                  children: const [
                                    Text(
                                      'A simple, beautiful Todo app built with Flutter.',
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
              const Text(
                'Todo',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.blue, size: 28),
            onPressed: () {
              setState(() {
                _isSearchMode = !_isSearchMode;
              });
              if (_isSearchMode) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _searchFocusNode.requestFocus();
                });
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final listToShow = _filteredTodos;
    final isSearching = _isSearchMode;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            if (isSearching)
              Container(
                margin: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: 8,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchFieldController,
                        focusNode: _searchFocusNode,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Search by title or description...',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    if (_searchFieldController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchFieldController.clear();
                        },
                      ),

                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _searchFieldController.clear();
                          _isSearchMode = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : listToShow.isEmpty
                  ? _buildEmptyState(isSearching)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: listToShow.length,
                      itemBuilder: (context, index) {
                        final todo = listToShow[index];
                        return _buildTodoCard(todo);
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAppBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTodoBottomSheet(),
        backgroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.blue, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
