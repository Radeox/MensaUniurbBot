import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() => runApp(MensaUniurb());

class MensaUniurb extends StatelessWidget {
  // Appbar title
  final String title = "MensaUniurb";

  // Root of the application
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        // Primary colors
        primarySwatch: Colors.blue,
        accentColor: Colors.blue,

        // Dark mode
        // brightness: Brightness.dark,

        fontFamily: 'Noto',
      ),

      // Define application routes to various screens
      initialRoute: '/',
      routes: {
        '/': (context) => SearchScreen(title: title),
        '/results': (context) => ResultScreen(),
      },
    );
  }
}

class SearchScreen extends StatefulWidget {
  // Search screen arguments
  SearchScreen({Key key, this.title}) : super(key: key);

  // Title of the screen
  final String title;

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

// Widget that creates the form search and send the query to the result widget
class _SearchScreenState extends State<SearchScreen> {
  String kitchen = "duca";
  String date = DateFormat('MM-dd-yyyy').format(DateTime.now());
  String meal = "lunch";

  // Build widget function
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Top appbar with title
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(fontSize: 24),
        ),
        centerTitle: true,
        // leading: IconButton(
        //   icon: Icon(Icons.menu),
        // ),
        flexibleSpace: CustomPaint(painter: CircleAppBar()),
      ),
      // Body of the screen
      body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Column(
              children: <Widget>[
                new Row(
                  // Select kitchen
                  children: <Widget>[
                    DropdownButton(
                      value: kitchen,
                      items: [
                        DropdownMenuItem(
                          value: "duca",
                          child: Text("Duca"),
                        ),
                        DropdownMenuItem(
                          value: "tridente",
                          child: Text("Tridente"),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          kitchen = value;
                        });
                      },
                    ),
                  ],
                  mainAxisAlignment: MainAxisAlignment.center,
                ),
                new Row(
                  children: <Widget>[
                    new Container(
                      child: Text(
                        "$date",
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    new IconButton(
                      icon: new Icon(
                        Icons.date_range,
                      ),
                      onPressed: () => _showDateTimePicker(context),
                    ),
                  ],
                  mainAxisAlignment: MainAxisAlignment.center,
                ),
                new Row(
                  children: <Widget>[
                    DropdownButton(
                      value: meal,
                      items: [
                        DropdownMenuItem(
                          value: "lunch",
                          child: Text("Pranzo"),
                        ),
                        DropdownMenuItem(
                          value: "dinner",
                          child: Text("Cena"),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          meal = value;
                        });
                      },
                    ),
                  ],
                  mainAxisAlignment: MainAxisAlignment.center,
                )
              ],
            ),
          ]),

      // Button to start query
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.search),
        onPressed: () {
          // Navigate to ResultScreen when tapped.
          Navigator.pushNamed(context, '/results',
              arguments: SearchArguments(kitchen, date, meal));
        },
      ),
    );
  }

  _showDateTimePicker(BuildContext context) async {
    DateTime selected;
    DateTime today = DateTime.now();
    Duration week = Duration(days: 7);

    selected = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: today.add(week),
    );

    setState(() {
      if (selected != null) date = DateFormat('MM-dd-yyyy').format(selected);
    });
  }
}

class ResultScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Extract arguments passed from search screen
    final SearchArguments args = ModalRoute.of(context).settings.arguments;

    return Scaffold(
      appBar: AppBar(),
      body: new FutureBuilder(
        future: getList(args),
        builder: (BuildContext context, AsyncSnapshot<List> snapshot) {
          if (!snapshot.hasData) {
            // Display during loading
            return new Center(
              // Loading animation
              child: CircularProgressIndicator(),
            );
          } else {
            List content = snapshot.data;

            // If some content exists
            if (content.isNotEmpty) {
              // Create and return the list
              return new Column(children: <Widget>[
                Expanded(child: ListView(children: content)),
              ]);
            } else {
              // If the result is empty display something else
              return new Center(
                child: Text("Empty"),
              );
            }
          }
        },
      ),
    );
  }

  // Create a list from the result
  Future<List<Widget>> getList(SearchArguments args) async {
    // Result of the request to API
    Map result = {};

    // Create an empty list
    List<Widget> list = new List();

    // Make the url with the arguments from the previous screen
    var url =
        'http://51.158.173.57:9543/${args.kitchen}/${args.date}/${args.meal}';

    // Send the request
    var response = await http.get(url);

    // Try decoding results
    // If they are empty the result will not be a JSON
    try {
      result = json.decode(response.body);
    } on Exception {}

    // If no results then return the empty list
    if (result['menu']['first'].isEmpty) return list;

    // Loop through keys of the json
    for (String type in result['menu'].keys) {
      // Loop through each item and add them to list
      for (String item in result['menu'][type]) {
        // Extract last part of the string
        String infos = item.split(" ").removeLast();

        // Check if it contains allergry infos
        RegExp filter = RegExp('([1-9])');

        if (filter.hasMatch(infos)) {
          // Remove them from the original string
          // and add them as subtitle
          item = item.replaceAll(infos, '');
          infos = infos.toUpperCase();

          // Add the item to the list with subtitle
          list.add(Card(
            child: ListTile(
              title: Text('$item'),
              subtitle: Text('$infos'),
              // leading: Icon(Icons.local_dining),
            ),
          ));
        } else {
          // Otherwise add it without anything
          list.add(Card(
            child: ListTile(
              title: Text('$item'),
            ),
          ));
        }
      }

      // Put a divider after each group
      list.add(Divider(height: 25));
    }

    return list;
  }
}

// Class that incapsulates the arguments required for the search query
class SearchArguments {
  // Kitchen name
  final String kitchen;

  // Date in MM-DD-YYYY format
  final String date;

  // Meal (lunch or dinner)
  final String meal;

  SearchArguments(this.kitchen, this.date, this.meal);
}

class CircleAppBar extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    // set the color property of the paint
    paint.color = Colors.blue;

    // center of the canvas is (x,y) => (width/2, height/2)
    var shape =
        Rect.fromLTWH(-size.width / 2, -10, size.width * 2, size.width / 2);

    canvas.drawArc(shape, 0, 10, true, paint);

    paint.color = Colors.lightBlue;

    var middle = Offset(size.width / 2, size.width / 2);

    canvas.drawCircle(middle, 100.0, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
