import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';
import 'package:retkipaikka_flutter/controllers/app_state.dart';
import 'package:provider/provider.dart';
import 'package:retkipaikka_flutter/controllers/triplocation_state.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:retkipaikka_flutter/models/triplocation_model.dart';
import 'package:collection/collection.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class LocationMap extends HookWidget {
   LocationMap({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TripLocationState tState = context.watch<TripLocationState>();
    var markerState = useState<CustomMarker?>(null);
    useEffect(() {
      List<CustomMarker> dataList = [];
      for (var item in tState.filteredTriplocations) {
        dataList.add(CustomMarker(
          locationId: item.id,
          width: 40.0,
          height: 50.0,
          point: item.getCoordinates(),
          builder: (ctx) => MouseRegion(
            cursor: SystemMouseCursors.click,
            child: SvgPicture.asset(
              "assets/icons/map_marker.svg",
            ),
          ),
        ));
      }

      if (tState.selectedMarker != null) {
        dataList.add(tState.selectedMarker!);
      }
      tState.setMapMarkers(dataList);
    }, [tState.filteredTriplocations, tState.selectedMarker]);

    return FlutterMap(
      options: MapOptions(
        onMapCreated: (c){
          tState.mapController = c;
        },
        onTap: ((tapPosition, point) {
          if (tState.popupController.selectedMarkers.isNotEmpty) {
            tState.popupController.hideAllPopups();
          } else {
            tState.onMarkerClick(CustomMarker(
                locationId: "-1",
                width: 50.0,
                height: 80.0,
                point: point,
                builder: (ctx) => const Icon(Icons.outlined_flag_outlined)));
          }
        }),
        interactiveFlags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        plugins: [MarkerClusterPlugin()],
        center: LatLng(61.29, 23.45),
        zoom: 8,
      ),
      layers: [
        TileLayerOptions(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: ['a', 'b', 'c'],
          attributionBuilder: (_) {
            return Text("© OpenStreetMap contributors");
          },
        ),
        MarkerClusterLayerOptions(
            centerMarkerOnClick: false,
            disableClusteringAtZoom: 11,
            builder: ((context, markers) {
              return Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0),
                    color: Theme.of(context).primaryColor),
                child: Center(
                  child: Text(
                    markers.length.toString(),
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            }),
            // onMarkerTap: (item){
            //   ValueKey<String> key = item.key as ValueKey<String>;
            //   print(key);

            // },
            popupOptions: PopupOptions(
                popupController: tState.popupController,
                popupBuilder: (context, marker) {
                  CustomMarker cMarker = marker as CustomMarker;
                  TripLocation? loc = tState.filteredTriplocations
                      .firstWhereOrNull(
                          (elem) => elem.id == cMarker.locationId);

                  if (loc != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FittedBox(
                        child: Container(
                          color: Colors.white,
                          child: Row(children: [
                            IconButton(
                              icon: loc.isFavourite
                                  ? const Icon(Icons.star)
                                  : const Icon(Icons.star_border),
                              onPressed: () {
                                tState.toggleFavourite(loc);
                              },
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 5, right: 10),
                                  child: Text(
                                    loc.name,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Text(
                                  loc.region,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w300),
                                ),
                                loc.municipality != null
                                    ? Text(
                                        loc.municipality!,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w300),
                                      )
                                    : const SizedBox(),
                                TextButton(
                                  onPressed: () {
                                    tState.setSelectedLocation(loc);
                                  },
                                  child: const Text("Lisätiedot"),
                                  style: ButtonStyle(
                                      padding: MaterialStateProperty.all(
                                          EdgeInsets.zero)),
                                )
                              ],
                            )
                          ]),
                        ),
                      ),
                    );
                  }
                  return SizedBox();
                }),
            markers: tState.mapMarkers,
            maxClusterRadius: 120,
            size: Size(40, 40)),
      ],
    );
  }
}

class CustomMarker extends Marker {
  String locationId;
  CustomMarker(
      {required this.locationId,
      required LatLng point,
      required WidgetBuilder builder,
      double width = 30,
      double height = 30})
      : super(point: point, builder: builder, width: width, height: height);
}
