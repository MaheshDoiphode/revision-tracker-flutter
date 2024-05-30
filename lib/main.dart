import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:myapp/mongo_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MongoService().init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Revision Tracker App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Category> categories = [];
  TextEditingController dataController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  String selectedUser = 'User1';
  String selectedCategory = 'UPSC';
  String selectedSubcategory = 'Polity';

  final List<String> users = ['User1', 'User2', 'User3'];
  final List<String> availableCategories = ['UPSC', 'GATE', 'CAT'];
  final Map<String, List<String>> availableSubcategories = {
    'UPSC': ['Polity', 'Geography', 'History'],
    'GATE': ['CS', 'ME', 'EC'],
    'CAT': ['Quant', 'Verbal', 'DI'],
  };

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    try {
      print('Connecting to MongoDB...');
      var db = await mongo.Db.create(
          'mongodb+srv://admin:1234@flutter-revision.vpnokco.mongodb.net/?retryWrites=true&w=majority&appName=flutter-revision');
      await db.open();
      print('Connected to MongoDB');
      var collection = db.collection('users');
      var result = await collection.findOne({'user': selectedUser});

      if (result != null) {
        setState(() {
          categories = (result['categories'] as List)
              .map((category) => Category.fromMap(category))
              .toList();
        });
        print('Categories fetched: ${categories.length}');
      }
    } catch (e) {
      print('Error fetching records: $e');
    }
  }

  Future<void> _addRecord() async {
    var newRecord = Record(
      data: dataController.text,
      date: selectedDate,
      revisionDates: _calculateRevisionDates(selectedDate),
    );

    try {
      print('Adding record to MongoDB...');
      var db = await mongo.Db.create(
          'mongodb+srv://admin:1234@flutter-revision.vpnokco.mongodb.net/?retryWrites=true&w=majority&appName=flutter-revision');
      await db.open();
      print('Connected to MongoDB');
      var collection = db.collection('users');
      var userDoc = await collection.findOne({'user': selectedUser});
      if (userDoc == null) {
        var newCategory =
            Category(categoryName: selectedCategory, subcategories: [
          Subcategory(
              subcategoryName: selectedSubcategory, records: [newRecord])
        ]);
        await collection.insertOne({
          'user': selectedUser,
          'categories': [newCategory.toMap()]
        });
      } else {
        var categories = (userDoc['categories'] as List)
            .map((category) => Category.fromMap(category))
            .toList();
        var category = categories.firstWhere(
            (category) => category.categoryName == selectedCategory,
            orElse: () =>
                Category(categoryName: selectedCategory, subcategories: []));
        if (category.subcategories.isEmpty) {
          categories
              .add(Category(categoryName: selectedCategory, subcategories: [
            Subcategory(
                subcategoryName: selectedSubcategory, records: [newRecord])
          ]));
        } else {
          var subcategory = category.subcategories.firstWhere(
              (subcategory) =>
                  subcategory.subcategoryName == selectedSubcategory,
              orElse: () => Subcategory(
                  subcategoryName: selectedSubcategory, records: []));
          if (subcategory.records.isEmpty) {
            category.subcategories.add(Subcategory(
                subcategoryName: selectedSubcategory, records: [newRecord]));
          } else {
            subcategory.records.add(newRecord);
          }
        }
        await collection.updateOne(
          {'user': selectedUser},
          mongo.modify
              .set('categories', categories.map((cat) => cat.toMap()).toList()),
        );
      }
      dataController.clear();
      _fetchRecords();
    } catch (e) {
      print('Error adding record: $e');
    }
  }

  List<DateTime> _calculateRevisionDates(DateTime startDate) {
    return [
      startDate.add(Duration(days: 1)),
      startDate.add(Duration(days: 3)),
      startDate.add(Duration(days: 7)),
      startDate.add(Duration(days: 14)),
      startDate.add(Duration(days: 21)),
      startDate.add(Duration(days: 60)),
    ];
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Revision Tracker App'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedUser,
              onChanged: (String? newValue) {
                setState(() {
                  selectedUser = newValue!;
                  _fetchRecords();
                });
              },
              items: users.map<DropdownMenuItem<String>>((String user) {
                return DropdownMenuItem<String>(
                  value: user,
                  child: Text(user),
                );
              }).toList(),
            ),
            DropdownButton<String>(
              value: selectedCategory,
              onChanged: (String? newValue) {
                setState(() {
                  selectedCategory = newValue!;
                  selectedSubcategory =
                      availableSubcategories[selectedCategory]![0];
                });
              },
              items: availableCategories
                  .map<DropdownMenuItem<String>>((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
            ),
            DropdownButton<String>(
              value: selectedSubcategory,
              onChanged: (String? newValue) {
                setState(() {
                  selectedSubcategory = newValue!;
                });
              },
              items: availableSubcategories[selectedCategory]!
                  .map<DropdownMenuItem<String>>((String subcategory) {
                return DropdownMenuItem<String>(
                  value: subcategory,
                  child: Text(subcategory),
                );
              }).toList(),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return ExpansionTile(
                    title: Text(category.categoryName),
                    children: category.subcategories.map((subcategory) {
                      return ExpansionTile(
                        title: Text(subcategory.subcategoryName),
                        children: subcategory.records.map((record) {
                          return ListTile(
                            title: Text(record.data ?? ''),
                            subtitle:
                                Text(record.date?.toLocal().toString() ?? ''),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: dataController,
                    decoration: InputDecoration(labelText: 'Enter data'),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _selectDate(context),
                    child: Text('Select Date'),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _addRecord,
                    child: Text('Add Record'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Record {
  String? data;
  DateTime? date;
  List<DateTime> revisionDates;

  Record({
    this.data,
    this.date,
    required this.revisionDates,
  });

  Record.fromMap(Map<String, dynamic> map)
      : data = map['data'],
        date = map['date'] != null ? DateTime.tryParse(map['date']) : null,
        revisionDates = (map['revisionDates'] as List)
            .map((date) => DateTime.tryParse(date)!)
            .whereType<DateTime>()
            .toList();

  Map<String, dynamic> toMap() {
    return {
      'data': data,
      'date': date?.toIso8601String(),
      'revisionDates':
          revisionDates.map((date) => date.toIso8601String()).toList(),
    };
  }
}

class Subcategory {
  String subcategoryName;
  List<Record> records;

  Subcategory({
    required this.subcategoryName,
    required this.records,
  });

  Subcategory.fromMap(Map<String, dynamic> map)
      : subcategoryName = map['subcategoryName'],
        records = (map['records'] as List)
            .map((record) => Record.fromMap(record))
            .toList();

  Map<String, dynamic> toMap() {
    return {
      'subcategoryName': subcategoryName,
      'records': records.map((record) => record.toMap()).toList(),
    };
  }
}

class Category {
  String categoryName;
  List<Subcategory> subcategories;

  Category({
    required this.categoryName,
    required this.subcategories,
  });

  Category.fromMap(Map<String, dynamic> map)
      : categoryName = map['categoryName'],
        subcategories = (map['subcategories'] as List)
            .map((subcategory) => Subcategory.fromMap(subcategory))
            .toList();

  Map<String, dynamic> toMap() {
    return {
      'categoryName': categoryName,
      'subcategories':
          subcategories.map((subcategory) => subcategory.toMap()).toList(),
    };
  }
}
