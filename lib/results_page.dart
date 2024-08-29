import 'package:flutter/material.dart';

class ClassDetailPage extends StatelessWidget {
  final String className;
  final int classIndex;

  ClassDetailPage({required this.className, required this.classIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Text(
          className,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3, // 30% of the width
            child: Container(
              margin: EdgeInsets.all(10),
              child: Column(
                children: [
                  ExpansionTile(
                    leading: const Icon(Icons.search),
                    title: Text('Search'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: ListTile(
                          leading: SizedBox(
                            width: 25,
                          ),
                          title: const Text('Subject'),
                          onTap: () {
                            Navigator.pop(context);
                            // Handle tap here
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: ListTile(
                          leading: SizedBox(
                            width: 25,
                          ),
                          title: const Text('Student'),
                          onTap: () {
                            Navigator.pop(context);
                            // Handle tap here
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 7, // 80% of the width
            child: Container(
              margin: EdgeInsets.all(10),
              child: Column(
                children: [],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SearchDropdown extends StatefulWidget {
  @override
  _SearchDropdownState createState() => _SearchDropdownState();
}

class _SearchDropdownState extends State<SearchDropdown> {
  String _selectedSearchCriteria = 'Name';

  final List<String> _searchCriteria = ['Name', 'Class', 'Subject'];

  @override
  Widget build(BuildContext context) {
    return DropdownMenu<String>(
      initialSelection: _searchCriteria.first,
      onSelected: (String? value) {
        // This is called when the user selects an item.
        setState(() {
          _selectedSearchCriteria = value!;
        });
      },
      dropdownMenuEntries:
          _searchCriteria.map<DropdownMenuEntry<String>>((String value) {
        return DropdownMenuEntry<String>(value: value, label: value);
      }).toList(),
    );
  }
}
