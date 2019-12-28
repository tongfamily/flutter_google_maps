import 'dart:async';

import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'api_key.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // title: 'Ice Creams FTW',
      title: 'Shot Detection Demo',
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: Colors.pink[50],
      ),
      // home: const HomePage(title: 'Ice Cream Stores in SF'),
      home: const HomePage(title: 'Shot Detection'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key key, @required this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Stream<QuerySnapshot> _detections;
  final Completer<GoogleMapController> _mapController = Completer();

  @override
  void initState() {
    super.initState();

    // to handle dates correctly as date objects are changing

    _detections = Firestore.instance
        // .collection('ice_cream_stores'
        .collection('detection')
        // .orderBy('name')
        // https://stackoverflow.com/questions/58154176/how-to-order-data-from-firestore-in-flutter-orderby-not-ordering-correct
        .orderBy('time', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _detections,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData) {
            return Center(child: const Text('Loading...'));
          }

          return Stack(
            children: <Widget>[
              StoreMap(
                documents: snapshot.data.documents,
                // San Francisco
                // initialPosition: const LatLng(37.7786, -122.4375),
                // Marjory Stoneman Douglas High School via latlong.net
                initialPosition: const LatLng(26.304510, -80.269460),
                mapController: _mapController,
              ),
              StoreCarousel(
                documents: snapshot.data.documents,
                mapController: _mapController,
              ),
            ],
          );
        },
      ),
    );
  }
}

class StoreCarousel extends StatelessWidget {
  const StoreCarousel({
    Key key,
    @required this.documents,
    @required this.mapController,
  }) : super(key: key);

  final List<DocumentSnapshot> documents;
  final Completer<GoogleMapController> mapController;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: documents.length,
            itemBuilder: (builder, index) {
              return SizedBox(
                width: 340,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Card(
                    child: Center(
                      child: StoreListTile(
                        document: documents[index],
                        mapController: mapController,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class StoreListTile extends StatefulWidget {
  const StoreListTile({
    Key key,
    @required this.document,
    @required this.mapController,
  }) : super(key: key);

  final DocumentSnapshot document;
  final Completer<GoogleMapController> mapController;

  @override
  State<StatefulWidget> createState() {
    return _StoreListTileState();
  }
}

final _placesApiClient = GoogleMapsPlaces(apiKey: googleMapsApiKey);

class _StoreListTileState extends State<StoreListTile> {
  String _placePhotoUrl = '';
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _retrievePlacesDetails();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _retrievePlacesDetails() async {
    final details =
        await _placesApiClient.getDetailsByPlaceId(widget.document['placeId']);
    if (!_disposed) {
      setState(() {
        if (details.result != null) {
          _placePhotoUrl = _placesApiClient.buildPhotoUrl(
            photoReference: details.result.photos[0].photoReference,
            maxHeight: 300,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.document['name']),
      subtitle: Text(widget.document['address']),
      leading: Container(
        child: _placePhotoUrl.isNotEmpty
            // ? CircleAvatar(backgroundImage: NetworkImage(_placePhotoUrl))
            ? ClipRRect(
                child: Image.network(_placePhotoUrl, fit: BoxFit.cover),
                borderRadius: const BorderRadius.all(Radius.circular(2)),
              )
            : CircleAvatar(
                child: Icon(
                  Icons.android,
                  color: Colors.white,
                ),
                backgroundColor: Colors.pink,
              ),
        width: 100,
        height: 60,
      ),
      onTap: () async {
        final controller = await widget.mapController.future;
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(
                widget.document['location'].latitude,
                widget.document['location'].longitude,
              ),
              zoom: 16,
            ),
          ),
        );
      },
    );
  }
}

// Do not need this constant anymore
// Can access colors from 0-360 via
// the structure call BitmapDescriptor.hueYellow
// const _pinkHue = 350.0;
// List al; the types found in the database and the required color
// TODO Doesn't handle new types properly yet
const _locationTypeToMarketColor = {
  'shot' : BitmapDescriptor.hueRed,
  'building' : BitmapDescriptor.hueViolet,
  'campus' : BitmapDescriptor.hueGreen,
};

class StoreMap extends StatelessWidget {
  const StoreMap({
    Key key,
    @required this.documents,
    @required this.initialPosition,
    @required this.mapController,
  }) : super(key: key);



  final List<DocumentSnapshot> documents;
  final LatLng initialPosition;
  final Completer<GoogleMapController> mapController;


  @override
  Widget build(BuildContext context) {
    // print('hello $_locationTypeToMarketColor');
    // https://pub.dev/documentation/google_maps_flutter/latest/google_maps_flutter/GoogleMap-class.html
    return GoogleMap(
      buildingsEnabled: true,
      indoorViewEnabled: true,
      mapType: MapType.satellite,
      rotateGesturesEnabled: true,
      scrollGesturesEnabled: true,
      trafficEnabled: true,
      zoomGesturesEnabled: true,
      initialCameraPosition: CameraPosition(
        target: initialPosition,
        zoom: 12,
      ),
      markers: documents
          //           .map((document) => Marker(
          .map((document) => Marker(
                markerId: MarkerId(document['placeId']),
                // icon: BitmapDescriptor.defaultMarkerWithHue(_pinkHue),
                // https://pub.dev/documentation/google_maps_flutter/latest/google_maps_flutter/BitmapDescriptor-class.html
                // use built in like this
                // icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                icon: BitmapDescriptor.defaultMarkerWithHue(_locationTypeToMarketColor[document['type']]),
                position: LatLng(
                  document['location'].latitude,
                  document['location'].longitude,
                ),
                infoWindow: InfoWindow(
                  title: document['name'],
                  snippet: document['address'],
                ),
              // ))
              ))
          .toSet(),
      onMapCreated: (mapController) {
        this.mapController.complete(mapController);
      },
    );
  }
}
