import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:move_to_background/move_to_background.dart';
import 'package:passwordmanager/constants.dart';
import 'package:passwordmanager/repository/data_repository.dart';
import 'package:passwordmanager/screens/generate.dart';
import 'package:passwordmanager/screens/home_body.dart';
import 'package:passwordmanager/screens/settings.dart';

final repository = DataRepository();

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedTabIndex = 0;

  late final PageController pageController;

  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    pageController = PageController(
      initialPage: selectedTabIndex,
      keepPage: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final body = PageView(
      controller: pageController,
      onPageChanged: (index) {
        _bottomNavigationKey.currentState!.setPage(index);
        setState(() => selectedTabIndex = index);
      },
      children: [
        HomeBody(size: size),
        const Generate(generateType: GenerateType.password),
        Settings(),
      ],
    );

    return WillPopScope(
      onWillPop: () async {
        MoveToBackground.moveTaskToBack();
        return false;
      },
      child: Scaffold(
        body: body,
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
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          animationCurve: Curves.decelerate,
          animationDuration: const Duration(milliseconds: 400),
          height: 65,
          onTap: (int index) {
            setState(() {
              selectedTabIndex = index;
              pageController.jumpToPage(index);
            });
          },
        ),
      ),
    );
  }
}
