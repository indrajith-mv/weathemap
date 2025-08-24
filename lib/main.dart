import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:latlong2/latlong.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(),
      
    );
  }
}

class MyHomePage extends StatefulWidget {
  

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(10.9034382, 76.4343615), // Center the map over London
        initialZoom: 20,
      ),
      children: [
        TileLayer(
  urlTemplate: "https://api.maptiler.com/maps/streets/{z}/{x}/{y}.png?key=VGFtXlKOP6b5nHC6OTA8",
  userAgentPackageName: 'com.yourcompany.yourapp',
),
        RichAttributionWidget( // Include a stylish prebuilt attribution widget that meets all requirments
          attributions: [
            TextSourceAttribution(
              'OpenStreetMap contributors',
              onTap: () => launchUrl(Uri.parse('https://openstreetmap.org/copyright')), // (external)
            ),
            // Also add images...
          ],
        ),
      ],
    );
  }

  

  // @override
  // Widget build(BuildContext context) {
    
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: Text('WHEATHER',style: TextStyle(color: Colors.amber[400]),),
  //       actions: [
        
  //      IconButton(onPressed: (){
  //       SearchBar();
        
  //      }, 
  //      icon: Icon(Icons.search))
  //      ],
        

       
  //     ),
  //     body: Center(
       
  //       child: Column(
          
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //         ],
  //       ),
  //     ),
     
       
  //   );
}
