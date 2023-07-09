import 'package:flutter/material.dart';
import 'package:flutter_pcd/main_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MainPage(),
    );
  }
}

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   // This widget is the home page of your application. It is stateful, meaning
//   // that it has a State object (defined below) that contains fields that affect
//   // how it looks.

//   // This class is the configuration for the state. It holds the values (in this
//   // case the title) provided by the parent (in this case the App widget) and
//   // used by the build method of the State. Fields in a Widget subclass are
//   // always marked "final".

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;

//   void _incrementCounter() {
//     setState(() {
//       // This call to setState tells the Flutter framework that something has
//       // changed in this State, which causes it to rerun the build method below
//       // so that the display can reflect the updated values. If we changed
//       // _counter without calling setState(), then the build method would not be
//       // called again, and so nothing would appear to happen.
//       _counter++;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     // This method is rerun every time setState is called, for instance as done
//     // by the _incrementCounter method above.
//     //
//     // The Flutter framework has been optimized to make rerunning build methods
//     // fast, so that you can just rebuild anything that needs updating rather
//     // than having to individually change instances of widgets.
//     return Scaffold(
//       appBar: AppBar(
//         // TRY THIS: Try changing the color here to a specific color (to
//         // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
//         // change color while the other colors stay the same.
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         // Here we take the value from the MyHomePage object that was created by
//         // the App.build method, and use it to set our appbar title.
//         title: Text(widget.title),
//       ),
//       body: const PcdViewer(),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
// }

// class PcdViewer extends StatefulWidget {
//   const PcdViewer({super.key});

//   @override
//   State<PcdViewer> createState() => _PcdViewerState();
// }

// class _PcdViewerState extends State<PcdViewer> {
//   double rotateYDegrees = 0;
//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [
//         Positioned.fill(
//           child: CustomPaint(
//             painter: PcdPainter(
//               PointCloud.colorCube(500, 51, Point.fromXYZ(0, 0, 0)),
//               Matrix4.identity()
//               ..rotateX(10 * math.pi / 180)
//               ..rotateY(rotateYDegrees * math.pi / 180)
//             ),
//           ),
//         ),
//         Positioned(
//           bottom: 0,
//           left: 0,
//           right: 0,
//           child: Slider(
//             value: rotateYDegrees,
//             min: -180,
//             max: 180,
//             onChanged: (value) {
//               setState(() {
//                 rotateYDegrees = value;
//               });
//             },
//           ),
//         ),
//       ],
//     );
//   }
// }

// class PcdPainter extends CustomPainter {
//   final PointCloud pointCloud;
//   final Matrix4 transform;
//   const PcdPainter(this.pointCloud, this.transform);
//   @override
//   void paint(Canvas canvas, Size size) {
//     final stopWatch = Stopwatch()..start();
//     var lastElapsed = 0;
//     final tOriginCenter = Matrix4.identity()
//       ..translate(size.width / 2, size.height / 2);
//     canvas.save();
//     canvas.transform(tOriginCenter.storage);

//     print("A: ${stopWatch.elapsedMicroseconds - lastElapsed} us");
//     lastElapsed = stopWatch.elapsedMicroseconds;

//     final out = Float32x4List(pointCloud.points.length);
//     final matrix = Float32x4List.fromList([
//       Float32x4(transform.storage[0], transform.storage[1], transform.storage[2], transform.storage[3]),
//       Float32x4(transform.storage[4], transform.storage[5], transform.storage[6], transform.storage[7]),
//       Float32x4(transform.storage[8], transform.storage[9], transform.storage[10], transform.storage[11]),
//       Float32x4(transform.storage[12], transform.storage[13], transform.storage[14], transform.storage[15]),
//     ]);

//     for (var i = 0; i < pointCloud.points.length; i++) {
//       Matrix44SIMDOperations.transform4(out, i, matrix, 0, pointCloud.points, i);
//     }
    

//     print("B: ${stopWatch.elapsedMicroseconds - lastElapsed} us");
//     lastElapsed = stopWatch.elapsedMicroseconds;

//     final paint = Paint()
//       ..color = Colors.black
//       ..strokeWidth = 5
//       ..style = PaintingStyle.stroke;

//     final points = Float32List(out.length * 2);
//     for (var i = 0; i < out.length; i++) {
//       points[i * 2] = out[i].x;
//       points[i * 2 + 1] = out[i].y;
//     }
    
    
//     canvas.drawRawPoints(PointMode.points, points, paint);

//     // canvas.drawPoints(PointMode.points, out.map((e) => Offset(e.x, e.y)).toList(), paint);

//     // for (var i = 0; i < out.length; i++) {
//     //   final point = out[i];
//     //   final paint = Paint()
//     //     ..color = pointCloud.colors[i]
//     //     ..strokeWidth = 5
//     //     ..style = PaintingStyle.stroke;

//     //   canvas.drawPoints(PointMode.points, [Offset(point.x, point.y)], paint);
//     // }

    
//     print("C: ${stopWatch.elapsedMicroseconds - lastElapsed} us");
//     lastElapsed = stopWatch.elapsedMicroseconds;
//     canvas.restore();
//     print("D: ${stopWatch.elapsedMicroseconds - lastElapsed} us");
//     lastElapsed = stopWatch.elapsedMicroseconds;
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) {
//     return false;
//   }
// }

// class PointCloud {
//   final Float32x4List points;
//   final List<Color> colors;

//   PointCloud(this.points, this.colors);

//   static PointCloud colorCube(int sideLength, int pointsPerSide, Point center) {
//     Float32x4List resultPoints = Float32x4List(pointsPerSide * pointsPerSide * pointsPerSide);
//     List<Color> resultColors = [];
//     Point origin = Point.fromXYZ(
//       center.x - sideLength / 2, 
//       center.y - sideLength / 2, 
//       center.z - sideLength / 2
//     );
//     double step = sideLength / (pointsPerSide - 1);
//     for (int x = 0; x < pointsPerSide; x++) {
//       for (int y = 0; y < pointsPerSide; y++) {
//         for (int z = 0; z < pointsPerSide; z++) {
//           resultPoints[x * pointsPerSide * pointsPerSide + y * pointsPerSide + z] = Float32x4(
//             x * step + origin.x, 
//             y * step + origin.y,
//             z * step + origin.z,
//             1.0
//           );
//           resultColors.add(Color.fromARGB(255, 
//             (x / pointsPerSide * 255).toInt(),
//             (y / pointsPerSide * 255).toInt(),
//             (z / pointsPerSide * 255).toInt(),
//           ));
//         }
//       }
//     }
//     return PointCloud(resultPoints, resultColors);
//   }
// }

// class Point {
//   final Vector3 vector;
//   final Color? color;

//   Point(this.vector, {this.color});

//   Point.fromXYZ(double x, double y, double z, {this.color}) : vector = Vector3(x, y, z);

//   double get x => vector.x;
//   double get y => vector.y;
//   double get z => vector.z;
// }