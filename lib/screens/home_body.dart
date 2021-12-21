import 'package:cloud_firestore/cloud_firestore.dart' show DocumentSnapshot;
import 'package:flutter/material.dart';
import 'package:passwordmanager/components/rounded_textfield.dart';
import 'package:passwordmanager/constants.dart'
    show darkBlueishColor, purpleMaterialColor;
import 'package:passwordmanager/models/password_entry.dart';
import 'package:passwordmanager/screens/home.dart' show repository;
import 'package:passwordmanager/screens/item_screen.dart';

class HomeBody extends StatefulWidget {
  final void Function(String) search;
  final Size size;
  final Widget Function(BuildContext, List<DocumentSnapshot>?, bool) buildList;

  const HomeBody({
    Key? key,
    required this.search,
    required this.size,
    required this.buildList,
  }) : super(key: key);

  @override
  _HomeBodyState createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _controller = TextEditingController();

  bool isSearching = false;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: RoundedTextFormField(
          controller: _controller,
          style: const TextStyle(
            fontSize: 18,
          ),
          hintText: "Search password",
          icon: Icons.search_outlined,
          suffixIcon: isSearching
              ? IconButton(
                  icon: const Icon(
                    Icons.close_outlined,
                    color: darkBlueishColor,
                  ),
                  onPressed: () {
                    _controller.clear();
                    setState(() => isSearching = false);
                  },
                )
              : null,
          color: darkBlueishColor,
          onChanged: (value) {
            widget.search(value);
            setState(() => isSearching = value.isNotEmpty);
          },
        ),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: StreamBuilder(
          stream: repository.getStream(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (!snapshot.hasData) {
              return const Align(child: CircularProgressIndicator());
            }

            return widget.buildList(
                context, snapshot.data?.docs ?? [], isSearching);
          },
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
