import 'package:flutter/material.dart';
// Add import for the TicTacToe game (to be created)
import 'games/tic_tac_toe.dart';
import 'games/brick_breaker.dart';
import 'games/tetris.dart';
import 'games/snake.dart';
import 'games/game_2048.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Games',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF18122B),
        fontFamily: 'Orbitron',
        colorScheme:
            ColorScheme.fromSeed(
              seedColor: const Color(0xFF00FFF7),
              brightness: Brightness.dark,
            ).copyWith(
              primary: const Color(0xFF00FFF7),
              secondary: const Color(0xFFFF00FF),
            ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Orbitron',
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color(0xFF00FFF7),
            letterSpacing: 2,
          ),
        ),
        listTileTheme: const ListTileThemeData(
          iconColor: Color(0xFF00FFF7),
          textColor: Color(0xFF00FFF7),
        ),
      ),
      home: const GameSelectionScreen(),
    );
  }
}

class GameSelectionScreen extends StatelessWidget {
  const GameSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Select a Game'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _neonGameTile(
                context,
                title: 'Tic-Tac-Toe',
                icon: Icons.grid_3x3,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TicTacToeGame(),
                    ),
                  );
                },
                color: const Color(0xFF00FFF7),
              ),
              const SizedBox(height: 32),
              _neonGameTile(
                context,
                title: 'Brick Breaker',
                icon: Icons.sports_tennis,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BrickBreakerGame(),
                    ),
                  );
                },
                color: const Color(0xFFFFA500),
              ),
              const SizedBox(height: 32),
              _neonGameTile(
                context,
                title: 'Tetris',
                icon: Icons.view_column,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TetrisGame()),
                  );
                },
                color: const Color(0xFFFF00FF),
              ),
              const SizedBox(height: 32),
              _neonGameTile(
                context,
                title: 'Snake',
                icon: Icons.show_chart,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SnakeGame()),
                  );
                },
                color: const Color(0xFF39FF14),
              ),
              const SizedBox(height: 32),
              _neonGameTile(
                context,
                title: '2048',
                icon: Icons.grid_4x4,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const Game2048()),
                  );
                },
                color: const Color(0xFFFFA500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _neonGameTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color, width: 3),
            color: Colors.white.withOpacity(0.05),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 40),
              const SizedBox(width: 24),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                  color: color,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(color: color.withOpacity(0.5), blurRadius: 8),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
