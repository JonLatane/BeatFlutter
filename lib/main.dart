import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() => runApp(MyApp());

const Map<int, Color> swatch = {
  50: Color.fromRGBO(0xF9, 0x37, 0x30, .1),
  100: Color.fromRGBO(0xF9, 0x37, 0x30, .2),
  200: Color.fromRGBO(0xF9, 0x37, 0x30, .3),
  300: Color.fromRGBO(0xF9, 0x37, 0x30, .4),
  400: Color.fromRGBO(0xF9, 0x37, 0x30, .5),
  500: Color.fromRGBO(0xF9, 0x37, 0x30, .6),
  600: Color.fromRGBO(0xF9, 0x37, 0x30, .7),
  700: Color.fromRGBO(0xF9, 0x37, 0x30, .8),
  800: Color.fromRGBO(0xF9, 0x37, 0x30, .9),
  900: Color.fromRGBO(0xF9, 0x37, 0x30, 1),
};

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeatFlutter',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: MaterialColor(0xFFF93730, swatch),
      ),
      home: MyHomePage(title: 'BeatFlutter'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

Duration animationDuration = const Duration(milliseconds: 300);

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  int _counter = 0;
  InteractionMode _interactionMode = InteractionMode.view;
  bool _showViewOptions = false;
  bool _showKeyboard = false;
  bool _showColorboard = false;

  _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  _doNothing() {}

  _viewMode() {
    setState(() {
      _interactionMode = InteractionMode.view;
    });
  }

  _editMode() {
    setState(() {
      _interactionMode = InteractionMode.edit;
      _showViewOptions = false;
    });
  }

  _toggleViewOptions() {
    setState(() {
      _showViewOptions = !_showViewOptions;
    });
  }

  _toggleKeyboard() {
    setState(() {
      _showKeyboard = !_showKeyboard;
    });
  }

  _toggleColorboard() {
    setState(() {
      _showColorboard = !_showColorboard;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF424242),
      appBar: PreferredSize(
          preferredSize: Size.fromHeight(0.0), // here the desired height
          child: AppBar(
              // Here we take the value from the MyHomePage object that was created by
              // the App.build method, and use it to set our appbar title.
              //title: Row(Text(widget.title)])
              )),
      body: Stack(children: [
        Column(children: [
          Container(
              height: 48,
              child: Row(children: [
                Expanded(
                    child: FlatButton(
                        onPressed: _doNothing,
                        padding: EdgeInsets.only(bottom: 10.0),
                        child: SvgPicture.asset('assets/logo.svg'))),
                Expanded(
                    child: FlatButton(
                        onPressed: _doNothing,
                        padding: EdgeInsets.all(0.0),
                        child: Icon(
                            (_interactionMode == InteractionMode.view)
                                ? Icons.play_arrow
                                : Icons.menu,
                            color: Colors.white))),
                Expanded(
                    child: (_interactionMode == InteractionMode.view)
                        ? RaisedButton(
                            onPressed: _toggleViewOptions,
                            padding: EdgeInsets.all(0.0),
                            child:
                                Icon(Icons.remove_red_eye, color: Colors.black))
                        : FlatButton(
                            onPressed: _viewMode,
                            padding: EdgeInsets.all(0.0),
                            child: Icon(Icons.remove_red_eye,
                                color: Colors.white))),
                Expanded(
                    child: (_interactionMode == InteractionMode.edit)
                        ? RaisedButton(
                            onPressed: _editMode,
                            padding: EdgeInsets.all(0.0),
                            child: Icon(Icons.edit, color: Colors.black))
                        : FlatButton(
                            onPressed: _editMode,
                            padding: EdgeInsets.all(0.0),
                            child: Icon(Icons.edit, color: Colors.white)))
              ])),
          AnimatedContainer(
              duration: animationDuration,
              height: (_interactionMode == InteractionMode.edit) ? 36 : 0,
              child: Row(children: [
                Expanded(
                    child: RaisedButton(
                  child: Image.asset('assets/play.png'),
                  onPressed: _doNothing,
                )),
                Expanded(
                    child: RaisedButton(
                  child: Image.asset('assets/stop.png'),
                  onPressed: _doNothing,
                )),
                Expanded(
                    child: RaisedButton(
                  padding: EdgeInsets.only(top: 7, bottom: 5),
                  child: SvgPicture.asset('assets/metronome.svg'),
                  onPressed: _doNothing,
                )),
                Expanded(
                    child: RaisedButton(
                  child: Image.asset('assets/piano.png'),
                  onPressed: _toggleKeyboard,
                  color: (_showKeyboard) ? Colors.white : Colors.grey,
                )),
                Expanded(
                    child: RaisedButton(
                  child: Image.asset('assets/colorboard.png'),
                  onPressed: _toggleColorboard,
                  color: (_showColorboard) ? Colors.white : Colors.grey,
                ))
              ])),
          AnimatedContainer(
              duration: animationDuration,
              height: (_showViewOptions) ? 36 : 0,
              child: Row(children: [
                Expanded(
                    child: RaisedButton(
                        onPressed: _doNothing,
                        padding: EdgeInsets.all(0.0),
                        child: SvgPicture.asset('assets/notehead_filled.svg',
                            fit: BoxFit.none))),
                Expanded(
                    child: RaisedButton(
                        onPressed: _toggleKeyboard,
                        padding: EdgeInsets.all(0.0),
                        color: (_showKeyboard) ? Colors.white : Colors.grey,
                        child: Image.asset('assets/piano.png'))),
                Expanded(
                    child: RaisedButton(
                        onPressed: _toggleColorboard,
                        padding: EdgeInsets.all(0.0),
                        color: (_showColorboard) ? Colors.white : Colors.grey,
                        child: Image.asset('assets/colorboard.png')))
              ])),
          AnimatedContainer(
              duration: animationDuration,
              height: (_interactionMode == InteractionMode.edit) ? 36 : 0,
              child: Row(children: [
                Expanded(
                    child: Text('Section List',
                        style: TextStyle(color: Colors.white))),
                RaisedButton(
                  child: Text('+'),
                  onPressed: _doNothing,
                )
              ])),
          Expanded(
              child: Stack(children: [
            GridView.builder(
              gridDelegate: new SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 16),
              itemCount: _counter * 17,
              itemBuilder: (BuildContext context, int index) {
                return GridTile(
                    child: SvgPicture.asset('assets/notehead_half.svg'));
              },
              padding: const EdgeInsets.all(4.0),
            ),
            Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'You have pushed the button this many times:',
                ),
                Text(
                  '$_counter',
                  style: Theme.of(context).textTheme.display1,
                ),
              ],
            ))
          ])),
          AnimatedContainer(
              duration: animationDuration,
              height: (_showColorboard) ? 150 : 0,
              width: MediaQuery.of(context).size.width,
              color: Colors.white,
              child: Text('Colorboard')),
          AnimatedContainer(
              duration: animationDuration,
              height: (_showKeyboard) ? 150 : 0,
              width: MediaQuery.of(context).size.width,
              color: Colors.white,
              child: Text('Keyboard')),
        ]),
        // The keyboards
//        Column(children: [
//          Expanded(child:Text('')),
//          Align(
//          alignment: Alignment.bottomCenter,
//          child: Column(
//          children: [
//            Container(height:150, width: MediaQuery.of(context).size.width,color: Colors.white, child: Text('Colorboard')),
//            Container(height:150, width: MediaQuery.of(context).size.width, color: Colors.white, child: Text('Keyboard')),
//          ]
//        )
//        )
//    ])
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

enum InteractionMode { view, edit }
