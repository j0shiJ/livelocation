import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchPage extends StatefulWidget {
  final String username;
  final String groupname;
  static final String id = 'search_screen';
  const SearchPage({Key? key, required this.username, required this.groupname})
      : super(key: key);
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin {
  static final GlobalKey<ScaffoldState> scaffoldKey =
      new GlobalKey<ScaffoldState>();
  final FirebaseAuth auth = FirebaseAuth.instance;
  late final User user;
  List<String> _usernames = <String>[];
  List<String> _selectedusernames = <String>[];
  Map<String, bool> _selectedusernamesbool = <String, bool>{};
  TextEditingController? _searchQuery;
  bool _isSearching = false;
  String searchQuery = "Search query";

  @override
  void initState() {
    super.initState();
    user = auth.currentUser!;
    _searchQuery = new TextEditingController();
  }

  void _startSearch() {
    print("open search box");
    ModalRoute.of(context)!
        .addLocalHistoryEntry(new LocalHistoryEntry(onRemove: _stopSearching));

    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearching() {
    _clearSearchQuery();

    setState(() {
      _isSearching = false;
    });
  }

  void _clearSearchQuery() {
    print("close search box");
    setState(() {
      _searchQuery!.clear();
      updateSearchQuery("Search query");
    });
  }

  Widget _buildTitle(BuildContext context) {
    var horizontalTitleAlignment =
        Platform.isIOS ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    return new InkWell(
      onTap: () => scaffoldKey.currentState!.openDrawer(),
      child: new Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: new Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: horizontalTitleAlignment,
          children: <Widget>[
            const Text('Search box'),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return new TextField(
        controller: _searchQuery,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Search by username',
          border: InputBorder.none,
          hintStyle: const TextStyle(color: Colors.white30),
        ),
        style: const TextStyle(color: Colors.white, fontSize: 16.0),
        onChanged: (text) {
          int i = 0;
          _usernames.clear();
          FirebaseFirestore.instance.collection('users').get().then((snapshot) {
            setState(() {
              snapshot.docs.forEach((element) {
                if (element['username'] != widget.username) {
                  if (!_usernames.contains(element['username'])) {
                    _usernames.insert(i, element['username']);
                    if (_selectedusernames.contains(element['username'])) {
                      _selectedusernamesbool.update(
                          element['username'], (value) => true,
                          ifAbsent: () => true);
                    } else {
                      _selectedusernamesbool.update(
                          element['username'], (value) => false,
                          ifAbsent: () => false);
                    }
                  }
                  i++;
                }
              });
            });
          });
        });
  }

  void updateSearchQuery(String newQuery) {
    setState(() {
      searchQuery = newQuery;
    });
    print("search query " + newQuery);
  }

  List<Widget> _buildActions() {
    if (_isSearching) {
      return <Widget>[
        new IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            if (_searchQuery == null || _searchQuery!.text.isEmpty) {
              Navigator.pop(context);
              return;
            }
            _clearSearchQuery();
          },
        ),
      ];
    }
    return <Widget>[
      new IconButton(
        icon: const Icon(Icons.search),
        onPressed: _startSearch,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        leading: _isSearching ? const BackButton() : null,
        title: _isSearching ? _buildSearchField() : _buildTitle(context),
        actions: _buildActions(),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 1.0, horizontal: 4.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: Wrap(
                    spacing: 6.0,
                    runSpacing: 6.0,
                    children: _selectedusernames
                        .map(
                          (item) => _buildChip(
                            item,
                          ),
                        )
                        .toList()
                        .cast<Widget>()),
              ),
            ),
            Container(
                child: _selectedusernames.isEmpty
                    ? null
                    : Divider(thickness: 1.0)),
            ListView.builder(
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              itemCount: _usernames.length,
              itemBuilder: (context, index) {
                return Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 1.0, horizontal: 4.0),
                    child: Card(
                        color: _selectedusernamesbool[_usernames[index]]!
                            ? Color(0xff9EA6BA).withOpacity(0.3)
                            : Colors.white,
                        child: ListTile(
                            onTap: () {
                              setState(() {
                                if (!_selectedusernamesbool[
                                    _usernames[index]]!) {
                                  _selectedusernames.insert(
                                      _selectedusernames.length,
                                      _usernames[index]);
                                  _selectedusernamesbool.update(
                                      _usernames[index], (value) => true,
                                      ifAbsent: () => true);
                                } else {
                                  _deleteselected(_usernames[index]);
                                }
                              });
                            },
                            leading: CircleAvatar(
                              backgroundColor: Colors.black,
                              child: Text(_usernames[index][0].toUpperCase()),
                            ),
                            title: Text(_usernames[index]),
                            trailing: _selectedusernamesbool[_usernames[index]]!
                                ? Icon(Icons.check)
                                : null)));
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.check),
        onPressed: createcollectiongroup,
      ),
    );
  }

  Widget _buildChip(String label) {
    return Chip(
      labelPadding: EdgeInsets.all(2.0),
      avatar: CircleAvatar(
        backgroundColor: Colors.black,
        child: Text(label[0].toUpperCase()),
      ),
      label: Text(
        label,
        style: TextStyle(
          color: Colors.white,
        ),
      ),
      deleteIcon: Icon(
        Icons.close,
      ),
      onDeleted: () => _deleteselected(label),
      backgroundColor: Colors.deepOrangeAccent,
      elevation: 6.0,
      shadowColor: Colors.grey[60],
      padding: EdgeInsets.all(8.0),
    );
  }

  void _deleteselected(String label) {
    setState(
      () {
        _selectedusernamesbool.update(label, (value) => false,
            ifAbsent: () => false);
        _selectedusernames.removeAt(_selectedusernames.indexOf(label));
      },
    );
  }

  void createcollectiongroup() {
    _selectedusernames.insert(_selectedusernames.length, widget.username);
    Map<String, dynamic> mapgroups = {
      'groupname': widget.groupname,
      'users': _selectedusernames,
    };
    try {
      FirebaseFirestore.instance
          .collection('groups')
          .doc(widget.groupname)
          .set(mapgroups);
      Navigator.of(context).pop();
      Navigator.of(context).pop();
      setState(() {
        _selectedusernames.clear();
        _selectedusernamesbool.clear();
      });
      print('Group created');
    } catch (e) {
      print('Failed to create group ${e}');
    }
  }
}
