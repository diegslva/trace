import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'main.dart';
import 'portfolio_page.dart';
import 'portfolio/transaction_sheet.dart';
import 'market_page.dart';

class Tabs extends StatefulWidget {
  Tabs(
      this.toggleTheme,
      this.savePreferences,
      this.handleUpdate,
      this.darkEnabled,
      this.themeMode,
      );

  final Function toggleTheme;
  final Function handleUpdate;
  final Function savePreferences;

  final bool darkEnabled;
  final String themeMode;

  @override
  TabsState createState() => new TabsState();
}

class TabsState extends State<Tabs> with SingleTickerProviderStateMixin {
  TabController _tabController;
  TextEditingController _textController = new TextEditingController();
  int _tabIndex = 0;

  Map portfolioMap;
  List portfolioTotalsList;

  bool isSearching = false;
  String filter;

  _handleFilter(value) {
    if (value == null) {
      isSearching = false;
      filter = null;
    } else {
      filter = value;
      isSearching = true;
    }
    setState(() {});
  }

  _startSearch() {
    setState(() {
      isSearching = true;
    });
  }

  _stopSearch() {
    setState(() {
      isSearching = false;
      filter = null;
      _textController.clear();
    });
  }

  _handleTabChange() {
    _tabIndex = _tabController.animation.value.round();
    if (isSearching) {
      _stopSearch();
    } else {
      setState(() {});
    }
  }

  _loadProfileJson() async {
    getApplicationDocumentsDirectory().then((Directory directory) {
      File jsonFile = new File(directory.path + "/portfolio.json");
      if (jsonFile.existsSync()) {
        print("file exists");
        portfolioMap = json.decode(jsonFile.readAsStringSync());
      } else {
        print("creating file");
        jsonFile.createSync();
        jsonFile.writeAsStringSync("{}");
      }

      print("loaded contents: " + portfolioMap.toString());

      _makeTotals();
      setState(() {});
    });
  }

  _makeTotals() {
    portfolioTotalsList = [];

    if (portfolioMap != null) {
      portfolioMap.forEach((coin, transactions) {
        num quantityTotal = 0;

        transactions.forEach((value) {
          quantityTotal += value["quantity"];
        });

        portfolioTotalsList.add({
          "symbol":coin,
          "total_quantity":quantityTotal
        });

      });
    }

    print(portfolioTotalsList);
  }

  @override
  void initState() {
    super.initState();
    print("INIT TABS");

    _loadProfileJson();

    _tabController = new TabController(length: 3, vsync: this);
    _tabController.animation.addListener(() {
      if (_tabController.animation.value.round() != _tabIndex) {
        _handleTabChange();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _tabController.animation.removeListener(_handleTabChange);
    super.dispose();
  }

  final PageStorageKey _marketKey = new PageStorageKey("market");
  final PageStorageKey _portfolioKey = new PageStorageKey("portfolio");

  ScrollController _scrollController = new ScrollController();

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {

    print("[T] built tabs");

    return new Scaffold(
      key: _scaffoldKey,
        drawer: new Drawer(
            child: new Scaffold(
                bottomNavigationBar: new Container(
                    decoration: new BoxDecoration(
                        border: new Border(
                            top: new BorderSide(color: Theme.of(context).dividerColor),
                        )
                    ),
                    child: new ListTile(
                      onTap: widget.toggleTheme,
                      leading: new Icon(widget.darkEnabled ? Icons.brightness_3 : Icons.brightness_7, color: Theme.of(context).buttonColor),
                      title: new Text(widget.themeMode, style: Theme.of(context).textTheme.body2.apply(color: Theme.of(context).buttonColor)),
                    )
                ),
                body: new ListView(
                  children: <Widget>[
                    new ListTile(
                      leading: new Icon(Icons.settings),
                      title: new Text("Settings"),
                      onTap: () => Navigator.pushNamed(context, "/settings"),
                    ),
                    new ListTile(
                      leading: new Icon(Icons.timeline),
                      title: new Text("Portfolio Timeline"),
                      onTap: () => Navigator.pushNamed(context, "/portfolioTimeline"),
                    ),
                    new ListTile(
                      leading: new Icon(Icons.pie_chart_outlined),
                      title: new Text("Portfolio Breakdown"),
                      onTap: () => Navigator.pushNamed(context, "/portfolioBreakdown"),
                    ),
                    new ListTile(
                      leading: new Icon(Icons.short_text),
                      title: new Text(shortenOn ? "Full Numbers" : "Abbreviate Numbers"),
                      onTap: () {
                        setState(() {
                          shortenOn = !shortenOn;
                        });
                        widget.savePreferences();
                      },
                    )
                  ],
                )
            )
        ),

//        floatingActionButton: [
//          new PortfolioFAB(),
//          null,
//          null
//        ][_tabIndex],
        floatingActionButton: new PortfolioFAB(_scaffoldKey),

        body: new NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              new SliverAppBar(
                title: [
                  new Text("Portfolio"),

                  isSearching ? new TextField(
                    controller: _textController,
                    autocorrect: false,
                    keyboardType: TextInputType.text,
                    style: Theme.of(context).textTheme.subhead,
                    onChanged: (value) => _handleFilter(value),
                    autofocus: true,
                    decoration: new InputDecoration.collapsed(
                        hintText: 'Search names and symbols...'
                    ),
                  ) :
                  new GestureDetector(
                    onTap: () => _startSearch(),
                    child: new Text("Aggregate Markets"),
                  ),

                  new Text("Alerts")
                ][_tabIndex],

                actions: <Widget>[
                  [
                    new Container(),

                    isSearching ? new IconButton(
                        icon: new Icon(Icons.close),
                        onPressed: () => _stopSearch()
                    ) :
                    new IconButton(
                        icon: new Icon(Icons.search, color: Theme.of(context).primaryIconTheme.color),
                        onPressed: () => _startSearch()
                    ),

                    new Container()
                  ][_tabIndex],
                ],

                pinned: true,
                floating: true,
                titleSpacing: 3.0,
                elevation: appBarElevation,
                forceElevated: innerBoxIsScrolled,

                bottom: new PreferredSize(
                    preferredSize: const Size.fromHeight(45.0),
                    child: new Container(
                      height: 45.0,
                      child: new TabBar(
                        controller: _tabController,
                        indicatorColor: Theme.of(context).accentIconTheme.color,
                        unselectedLabelColor: Theme.of(context).disabledColor,
                        labelColor: Theme.of(context).accentIconTheme.color,
                        tabs: <Tab>[
                          new Tab(icon: new Icon(Icons.person)),
                          new Tab(icon: new Icon(Icons.menu)),
                          new Tab(icon: new Icon(Icons.notifications))
                        ],
                      ),
                    )
                ),
              )

            ];
          },

          body: new TabBarView(
            controller: _tabController,
            children: <Widget>[
              new PortfolioPage(portfolioMap, portfolioTotalsList, key: _portfolioKey),
              new MarketPage(filter, isSearching, key: _marketKey),
              new Container(),
            ],
          ),
        )

    );
  }
}