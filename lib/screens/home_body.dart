import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart'
    show DocumentSnapshot, QuerySnapshot;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lottie/lottie.dart';
import 'package:passwordmanager/components/password_widget.dart';
import 'package:passwordmanager/components/rounded_textfield.dart';
import 'package:passwordmanager/constants.dart'
    show darkBlueishColor, purpleMaterialColor;
import 'package:passwordmanager/models/password_entry.dart';
import 'package:passwordmanager/screens/home.dart' show repository;
import 'package:passwordmanager/screens/item_screen.dart';
import 'package:passwordmanager/utils.dart';

class HomeBody extends StatefulWidget {
  final Size size;

  const HomeBody({Key? key, required this.size}) : super(key: key);

  @override
  _HomeBodyState createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody>
    with AutomaticKeepAliveClientMixin {
  late List<PasswordWidget> entries;
  late List<PasswordWidget> filteredEntries;
  late final Map<String, Uint8List> _keys;
  final TextEditingController _controller = TextEditingController();
  late Stream<QuerySnapshot<Object?>> _stream;

  bool isSearching = false;

  @override
  void initState() {
    super.initState();
    _stream = repository.getStream();
    entries = <PasswordWidget>[];
    filteredEntries = <PasswordWidget>[];
    _keys = <String, Uint8List>{};
  }

  void _search(String query) {
    setState(() {
      filteredEntries = entries
          .where((element) =>
              element.entry.name.contains(query) ||
              element.entry.email.contains(query))
          .toList(growable: false);
    });
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot>? snapshots) {
    final size = MediaQuery.of(context).size;
    if (snapshots!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              "assets/images/no_data_found.svg",
              height: size.height * 0.3,
            ),
            SizedBox(height: size.height * 0.03),
            Text("No data found", style: Theme.of(context).textTheme.subtitle1),
          ],
        ),
      );
    }

    if (isSearching) {
      if (filteredEntries.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                "assets/images/void.svg",
                height: size.height * 0.3,
              ),
              SizedBox(height: size.height * 0.03),
              Text("No matching entries found",
                  style: Theme.of(context).textTheme.subtitle1),
            ],
          ),
        );
      }
      return ListView.separated(
        separatorBuilder: (BuildContext context, int index) {
          return Divider(color: Colors.grey.shade500);
        },
        itemCount: filteredEntries.length,
        itemBuilder: (BuildContext context, int index) {
          return filteredEntries[index];
        },
      );
    }
    return ListView.separated(
      separatorBuilder: (BuildContext context, int index) {
        return Divider(color: Colors.grey.shade500);
      },
      itemCount: snapshots.length,
      itemBuilder: (BuildContext context, int index) {
        final _listItem = _buildListItem(context, snapshots[index]);
        return FutureBuilder(
          future: _listItem,
          builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
            if (snapshot.hasData) return snapshot.data!;
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Future<Widget> _buildListItem(
      BuildContext context, DocumentSnapshot snapshot) async {
    final passwordEntry = PasswordEntry.fromSnapshot(
      snapshot,
      key: await _keys.putIfAbsentAsync(
        snapshot.reference.id,
        () async => generateKey(
          await getMasterPassword(),
          pepper,
          (snapshot.data() as Map<String, dynamic>)['createdAt'],
        ),
      ),
    );
    final widget = PasswordWidget(
      entry: passwordEntry,
      passwordKey: _keys[passwordEntry.referenceId]!,
      onView: () {
        FocusScope.of(context).unfocus();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemScreen(
              isEditable: false,
              passwordEntry: passwordEntry,
              onSave: repository.updateEntry,
              onDelete: repository.deleteEntry,
            ),
          ),
        );
      },
    );
    if (!entries.contains(widget)) entries.add(widget);
    return widget;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        toolbarHeight: 60,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        title: RoundedTextFormField(
          constraints: const BoxConstraints(minHeight: 40, maxHeight: 40),
          controller: _controller,
          style: const TextStyle(
            fontSize: 18,
          ),
          hintText: "Search password",
          icon: Icons.search_outlined,
          suffixIcon: isSearching
              ? IconButton(
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.close_outlined),
                  onPressed: () {
                    _controller.clear();
                    setState(() {
                      isSearching = false;
                    });
                  },
                )
              : null,
          color: darkBlueishColor,
          onChanged: (value) {
            _search(value);
            setState(() => isSearching = value.isNotEmpty);
          },
        ),
        automaticallyImplyLeading: false,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: StreamBuilder(
            stream: _stream,
            builder: (BuildContext context, AsyncSnapshot snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Tooltip(
                    message: snapshot.error.toString(),
                    margin: EdgeInsets.symmetric(horizontal: size.width * 0.05),
                    padding: EdgeInsets.all(size.width * 0.05),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          "assets/images/server_down.svg",
                          height: size.height * 0.3,
                        ),
                        SizedBox(height: size.height * 0.03),
                        Text("Couldn't fetch your data",
                            style: Theme.of(context).textTheme.subtitle1),
                      ],
                    ),
                  ),
                );
              }
              if (snapshot.hasData) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Tooltip(
                    message: "Loading...",
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.only(left: size.width * 0.1),
                        child: Lottie.asset(
                          "assets/lottie/loading_animation_lottie.json",
                          height: size.height * 0.4,
                        ),
                      ),
                    ),
                  );
                }
              }
              return _buildList(context, snapshot.data?.docs ?? []);
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "add",
        backgroundColor: purpleMaterialColor,
        child: const Icon(Icons.add_outlined),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemScreen(
              isEditable: true,
              onSave: (PasswordEntry entry) => repository.addEntry(entry),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
