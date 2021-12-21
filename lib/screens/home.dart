import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:passwordmanager/components/password_widget.dart';
import 'package:passwordmanager/constants.dart';
import 'package:passwordmanager/models/password_entry.dart';
import 'package:passwordmanager/repository/data_repository.dart';
import 'package:passwordmanager/screens/generate.dart';
import 'package:passwordmanager/screens/home_body.dart';
import 'package:passwordmanager/screens/item_screen.dart';
import 'package:passwordmanager/utils.dart';

final repository = DataRepository();

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedTabIndex = 0;
  late final List<PasswordWidget> entries;
  late List<PasswordWidget> filteredEntries;

  late final PageController pageController;

  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    entries = <PasswordWidget>[];
    filteredEntries = <PasswordWidget>[];
    pageController = PageController(
      initialPage: selectedTabIndex,
      keepPage: true,
    );
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

  Widget _buildList(BuildContext context, List<DocumentSnapshot>? snapshots,
      bool isSearching) {
    return FutureBuilder(
      future: Future.wait(snapshots!
          .map((data) async => await _buildListItem(context, data))
          .toList()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Align(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.only(top: 20.0),
          children: isSearching ? filteredEntries : entries,
        );
      },
    );
  }

  Future<Widget> _buildListItem(
      BuildContext context, DocumentSnapshot snapshot) async {
    final passwordEntry = PasswordEntry.fromSnapshot(
      snapshot,
      key: generateKey(
        await getMasterPassword(),
        dotenv.env['PEPPER']!,
        (snapshot.data() as Map<String, dynamic>)['createdAt'],
      ),
    );
    final widget = PasswordWidget(
      entry: passwordEntry,
      onView: () {
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
    final Size size = MediaQuery.of(context).size;
    final homeBody = PageView(
      controller: pageController,
      onPageChanged: (index) {
        _bottomNavigationKey.currentState!.setPage(index);
        setState(() => selectedTabIndex = index);
      },
      children: [
        HomeBody(size: size, buildList: _buildList, search: _search),
        const Generate(generateType: GenerateType.password),
        const Icon(Icons.admin_panel_settings_outlined),
      ],
    );

    return Scaffold(
      body: homeBody,
      bottomNavigationBar: CurvedNavigationBar(
        key: _bottomNavigationKey,
        items: const [
          Icon(
            Icons.lock_outline_rounded,
            color: Colors.white,
          ),
          Icon(
            Icons.repeat_outlined,
            color: Colors.white,
          ),
          Icon(
            Icons.settings_outlined,
            color: Colors.white,
          ),
        ],
        color: purpleMaterialColor,
        backgroundColor: Colors.white,
        animationCurve: Curves.decelerate,
        animationDuration: const Duration(milliseconds: 400),
        height: 60,
        onTap: (int index) {
          setState(() {
            selectedTabIndex = index;
            pageController.jumpToPage(index);
          });
        },
      ),
    );
  }
}
