import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

final client = http.Client();
int creds = 1000;

String int2creds(int v) {
  return "❖ ${v.toString() /*.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')*/}";
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: ':)',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF014566),
      ),
      routes: {
        "/listings": (context) => Scaffold(
            appBar: AppBar(
              backgroundColor: const Color(0xFF014566),
            ),
            body: Container(
            child: const Listings(),
          )
        ),
        "/offer": (context) => const OfferPage(),
      },
      home: Scaffold(
        appBar: null,
        backgroundColor: const Color(0xFF014566),
        body: Stack(
          children: [
            Positioned(
              top: 50, // (padsize-fontsize)/2 = (128-14*2.0)/2 = 50
              left: 16,
              child: Text(
                int2creds(creds),
                textScaleFactor: 2.0,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 128),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16.0)),
                      color: Colors.white,
                      boxShadow: kElevationToShadow[32],
                    ),
                    child: Stack(
                      alignment: Alignment.topCenter,
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          top: -40.0,
                          child: Container(
                            height: 40.0,
                            width: 100.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(32.0),
                              boxShadow: kElevationToShadow[4],
                              color: Colors.white,
                            ),
                            child: const Center(child: Text("Rewards")),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const <Widget>[
                            SizedBox(height: 32),
                            Text(
                              "Zain",
                              textScaleFactor: 2.0,
                            ),
                            Section(
                              title: "Popular",
                              child: Popular(),
                            ),
                            Section(
                              title: "Categories",
                              child: Categories(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Popular extends StatefulWidget {
  const Popular({Key? key}) : super(key: key);

  @override
  State<Popular> createState() => PopularState();
}

class Reward {
  final String name;
  final String description;
  final int value;
  final int sales;
  final ImageProvider<Object> thumbnail;

  const Reward(
      {required this.name,
      required this.description,
      required this.value,
      required this.sales,
      required this.thumbnail});

  factory Reward.fromJson(Map<String, dynamic> raw) => Reward(
        name: raw["name"]!,
        description: raw["description"]!,
        value: raw["value"]!,
        sales: raw["sales"]!,
        thumbnail: NetworkImage(
            "http://127.0.0.1:3000/thumbnails/${raw['thumbnail']!}"),
      );
}

class PopularState extends State<Popular> {
  List<Reward> rewards = [];
  Future<List<Reward>>? _fut;

  Future<List<Reward>> _getResults() async {
    http.Response res = await client.get(
        Uri(scheme: "http", host: "127.0.0.1", port: 3000, path: "/popular"));
    if (res.statusCode != 200) throw "netfail: ${res.statusCode}";
    return jsonDecode(res.body)
        .cast<Map<String, dynamic>>()
        .map(Reward.fromJson)
        .toList()
        .cast<Reward>();
  }

  @override
  void initState() {
    super.initState();
    _fut = _getResults();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _fut,
      initialData: const <Reward>[],
      builder: (BuildContext context, AsyncSnapshot<List<Reward>> snapshot) {
        if (snapshot.hasData) {
          var data = snapshot.data!;
          var w = MediaQuery.of(context).size.width;
          return SizedBox(
            width: w,
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: data.length,
              itemBuilder: (BuildContext context, int i) {
                var offer = data[i];
                return GestureDetector(
                  onTap: () => Navigator.pushNamed(
                    context,
                    "/offer",
                    arguments: offer, 
                  ),
                  child: Card(
                    elevation: 2.0,
                    clipBehavior: Clip.antiAlias,
                    child: ImageContainer(
                      image: offer.thumbnail,
                      child: Container(
                        width: 240,
                        alignment: AlignmentDirectional.bottomStart,
                        child: ListTile(
                          title: Text(
                            offer.name.toUpperCase(),
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            int2creds(offer.value),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              shrinkWrap: true,
            ),
          );
        } else if (snapshot.hasError) {
          print(snapshot.error);
          print(snapshot.stackTrace);
          return Text(snapshot.error.toString());
        } else {
          return const Text("Loading");
        }
      },
    );
  }
}

class Section extends StatelessWidget {
  final String title;
  final Widget child;

  const Section({Key? key, required this.child, required this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class Categories extends StatefulWidget {
  const Categories({Key? key}) : super(key: key);

  @override
  State<Categories> createState() => CategoriesState();
}

class Category {
  final String name;
  final NetworkImage thumbnail;

  const Category({required this.name, required this.thumbnail});

  factory Category.fromJson(String raw) => Category(
        name: raw,
        thumbnail: NetworkImage("http://127.0.0.1:3000/thumbnails/$raw"),
      );
}

class CategoriesState extends State<Categories> {
  List<Category> categories = [];
  Future<List<Category>>? _fut;

  Future<List<Category>> _getResults() async {
    http.Response res = await client.get(
        Uri(scheme: "http", host: "127.0.0.1", port: 3000, path: "/listings"));
    if (res.statusCode != 200) throw "netfail: ${res.statusCode}";
    return jsonDecode(res.body)
        .cast<String>()
        .map(Category.fromJson)
        .toList()
        .cast<Category>();
  }

  @override
  void initState() {
    super.initState();
    _fut = _getResults();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _fut,
      initialData: const <Category>[],
      builder: (BuildContext context, AsyncSnapshot<List<Category>> snapshot) {
        if (snapshot.hasData) {
          var data = snapshot.data!;
          if (data.isEmpty) return const SizedBox();
          return TriBox(
              children: data.map((category) {
            return GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                "/listings",
                arguments: category.name,
              ),
              child: Card(
                elevation: 2.0,
                clipBehavior: Clip.antiAlias,
                child: ImageContainer(
                  image: category.thumbnail,
                  child: Container(
                    alignment: AlignmentDirectional.bottomStart,
                    child: ListTile(
                      title: Text(
                        category.name.toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList());
        } else if (snapshot.hasError) {
          print(snapshot.error);
          print(snapshot.stackTrace);
          return Text(snapshot.error.toString());
        } else {
          return const Text("Loading");
        }
      },
    );
  }
}

// this is a quick and dirty method cause there's only three categories
// will make a better version if I have to
class TriBox extends StatelessWidget {
  final List<Widget> children;

  const TriBox({Key? key, required this.children}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300, 
      width: MediaQuery.of(context).size.width,
      child: Row(
        children: [
          Expanded(child: children[0]),
          Expanded(
              child: Column(
            children: [
              Expanded(child: children[1]),
              Expanded(child: children[2]),
            ],
          )),
        ],
      ),
    );
  }
}

class ImageContainer extends StatelessWidget {
  final Widget child;
  final ImageProvider<Object> image;
  const ImageContainer({Key? key, required this.child, required this.image})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: FadeInImage(
            placeholder: MemoryImage(kTransparentImage),
            image: image,
            fit: BoxFit.cover,
          ),
        ),
        child,
      ],
    );
  }
}

class Listings extends StatefulWidget {
  const Listings({Key? key}) : super(key: key);

  @override
  State<Listings> createState() => ListingsState();
}

class ListingsState extends State<Listings> {
  List<Reward> rewards = [];
  Future<List<Reward>>? _fut;
  String? _category;

  Future<List<Reward>> _getResults() async {
    if (_category == null) {
      return [];
    }
    http.Response res = await client.get(Uri(
        scheme: "http",
        host: "127.0.0.1",
        port: 3000,
        path: "/offers/$_category"));
    if (res.statusCode != 200) throw "netfail: ${res.statusCode}";
    return jsonDecode(res.body)
        .cast<Map<String, dynamic>>()
        .map(Reward.fromJson)
        .toList()
        .cast<Reward>();
  }

  @override
  void initState() {
    super.initState();
    _fut = _getResults();
  }

  @override
  Widget build(BuildContext context) {
    setState(() {
      _category = ModalRoute.of(context)!.settings.arguments as String;
      _fut = _getResults();
    });

    return FutureBuilder(
      future: _fut,
      initialData: const <Reward>[],
      builder: (BuildContext context, AsyncSnapshot<List<Reward>> snapshot) {
        Widget? res;
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasData) {
            var data = snapshot.data!;
            if (data.isNotEmpty) {
              var w = MediaQuery.of(context).size.width;
              res = Column(
                children: [
                  SizedBox(
                    width: w,
                    child: ListView.separated(
                      scrollDirection: Axis.vertical,
                      itemCount: data.length,
                      itemBuilder: (context, i) {
                        var offer = data[i];
                        return SizedBox(
                          height: 64,
                          child: ListTile(
                            title: Text(
                              offer.name,
                            ),
                            subtitle: Text(offer.description),
                            trailing: Text(int2creds(offer.value)),
                            onTap: () => Navigator.pushNamed(
                              context,
                              "/offer",
                              arguments: offer, 
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (context, i) => const Divider(),
                      shrinkWrap: true,
                    ),
                  ),
                  const Expanded(child: SizedBox()),
                ],
              );
            } else {
              res = const Center(child: Text("I got nothing."));
            }
          } else {
            print(snapshot.error);
            print(snapshot.stackTrace);
            res = Center(child: Text(snapshot.error.toString()));
          }
        } else {
          res = const Center(child: CircularProgressIndicator());
        }
        return AnimatedSwitcher(
          duration: const Duration(seconds: 1),
          child: res,
        );
      },
    );
  }
}

class OfferPage extends StatefulWidget {
  const OfferPage({Key? key}) : super(key: key);

  @override
  State<OfferPage> createState() => OfferPageState();
}

class OfferPageState extends State<OfferPage> {
  bool _descActive = false;
  int _amount = 1;
  int _creds = 0;

  static const double maxScale = .75;
  static const double observedMinScale = .55;
  static const double actualMinScale = .25;

  void _setDescActive(bool v) {
    setState(() {
      _descActive = v;
    });
  }

  void _addAmount() {
    setState(() {
      _amount = _amount+1;
    });
  }

  void _delAmount() {
    setState(() {
      _amount = _amount-1;
    });
  }

  @override
  void initState() {
    super.initState();
    _creds = creds;
  }

  @override
  Widget build(BuildContext context) {
    var q = MediaQuery.of(context);
    Reward offer = ModalRoute.of(context)!.settings.arguments as Reward;

    return Scaffold(
      appBar: null,
      body: Stack(
        children: [
          CustomScrollView(
            controller: (() {
              var controller = ScrollController();
              controller.addListener(() {
                _setDescActive(
                    controller.position.atEdge && controller.position.pixels != 0);
              });
              return controller;
            })(),
            slivers: [
              SliverAppBar(
                pinned: true,
                collapsedHeight: q.size.height * actualMinScale,
                expandedHeight: q.size.height * maxScale,
                flexibleSpace: FlexibleSpaceBar(
                  background: Image(image: offer.thumbnail, fit: BoxFit.cover),
                  title: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(32)),
                              color: Theme.of(context).primaryColor),
                          child: Text(
                            "${offer.name}\n${int2creds(offer.value)}",
                            style: const TextStyle(color: Colors.white),
                            textScaleFactor: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  titlePadding: const EdgeInsets.all(0),
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground
                  ],
                ),
                elevation: 0,
              ),
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Container(
                      width: q.size.width,
                      height: q.size.height * (1 - observedMinScale),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                      ),
                      child: SizedBox.expand(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(32)),
                            color: Theme.of(context).cardColor,
                          ),
                          child: Column(
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    children: [
                                      const Text(
                                        "INFO",
                                        style: TextStyle(color: Colors.pink),
                                      ),
                                      const Text(
                                        "●",
                                        style: TextStyle(color: Colors.pink),
                                      ),
                                      Expanded(
                                        child: Text(
                                          offer.description,
                                          style:
                                              const TextStyle(color: Colors.grey),
                                          textAlign: TextAlign.justify,
                                          overflow: TextOverflow.fade,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomLeft,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeOutQuad,
                                  height: _descActive ? 120 : 0,
                                  child: Column(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                flex: 2,
                                                child: Container(
                                                  margin: const EdgeInsets.all(2),
                                                  child: const Text("POINTS",
                                                      style: TextStyle(
                                                          color: Colors.grey)),
                                                ),
                                              ),
                                              Expanded(
                                                child: Container(
                                                  margin: const EdgeInsets.all(2),
                                                  child: LinearProgressIndicator(
                                                    color: Colors.pink,
                                                    backgroundColor: Colors.grey,
                                                    value: min(_creds / (offer.value * _amount), 1),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: AnimatedContainer(
                                          duration:
                                              const Duration(milliseconds: 500),
                                          curve: Curves.easeOutQuad,
                                          padding: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(
                                            borderRadius: BorderRadius.vertical(
                                                top: Radius.circular(32)),
                                            color: Colors.pink,
                                          ),
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove, color: Colors.white),
                                                onPressed: _amount > 1 ? _delAmount : null,

                                              ),
                                              Text(_amount.toString(), style: const TextStyle(color: Colors.white)),
                                              IconButton(
                                                icon: const Icon(Icons.add, color: Colors.white),
                                                onPressed: _addAmount,
                                              ),
                                              const Expanded(child: SizedBox()),
                                              TextButton(
                                                onPressed: _creds - (offer.value * _amount) >= 0 ? () {
                                                  creds -= _amount * offer.value;
                                                  setState(() {
                                                    _creds = creds;
                                                  });
                                                } : null,
                                                child: const Text("REDEEM", style: TextStyle(color: Colors.white)),
                                              )
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            top: 80,
            left: 20,
            child: Text(
              int2creds(creds),
              style: const TextStyle(color: Colors.white),
              textScaleFactor: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}
