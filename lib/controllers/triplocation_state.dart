import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:retkipaikka_flutter/controllers/filtering_state.dart';
import 'package:retkipaikka_flutter/helpers/api/base_api.dart';
import 'package:retkipaikka_flutter/helpers/shared_preferences_helper.dart';
import 'package:retkipaikka_flutter/models/abstract_filter_model.dart';

import 'package:retkipaikka_flutter/models/triplocation_model.dart';
import 'package:retkipaikka_flutter/screens/main/components/map/location_map.dart';
import 'package:collection/collection.dart';

class TripLocationState extends ChangeNotifier {
  List<TripLocation> allTripLocations = [];
  List<TripLocation> filteredTriplocations = [];
  List<TripLocation> newLocations = [];
  TripLocation? selectedLocation;
  MapController? mapController;
  PopupController popupController = PopupController();
  List<CustomMarker> mapMarkers = [];
  CustomMarker? selectedMarker;
  bool drawerOpen = false;
  bool adminLocationsInitialLoad = false;

  List<String> parseLocationImages(List<dynamic> images, String locationId) {
    List<String> imgs = [];

    for (var image in images) {
      imgs.add(
          BaseApi.baseUrl + "/Images/" + locationId + "/download/" + image);
    }

    return imgs;
  }

  void setMapMarkers(List<CustomMarker> markers) {
    mapMarkers = markers;
  }

  void onMarkerClick(CustomMarker marker) {
    selectedMarker = marker;
    notifyListeners();
  }

  void openDrawer() {
    drawerOpen = true;
    notifyListeners();
  }

  void closeDrawer() {
    drawerOpen = false;
    notifyListeners();
  }

  void drawerButtonClick() {
    drawerOpen = !drawerOpen;
    notifyListeners();
  }

  void setLocations(List<TripLocation> locList) async {
    List<dynamic>? favouriteIds =
        await SharedPreferencesHelper.getUserFavourites();
    if (favouriteIds != null) {
      for (TripLocation loc in locList) {
        if (favouriteIds.contains(loc.id)) {
          loc.isFavourite = true;
        }
      }
    }
    allTripLocations = locList;
    filteredTriplocations = locList;
    notifyListeners();
  }

  void setNewAndAccepted(
    List<TripLocation> acceptedLocs,
    List<TripLocation> newLocs,
  ) {
    allTripLocations = acceptedLocs;
    filteredTriplocations = acceptedLocs;
    newLocations = newLocs;
    notifyListeners();
  }

  void setNewLocations(List<TripLocation> locList) {
    newLocations = locList;
    notifyListeners();
  }

  void setSelectedLocation(TripLocation location) {
    selectedLocation = location;
    openDrawer();
    notifyListeners();
  }

  void centerMapToLocation(TripLocation location) {
    mapController?.move(location.getCoordinates(), 12);
    CustomMarker? marker = mapMarkers
        .firstWhereOrNull((element) => element.locationId == location.id);
    if (marker != null) {
      popupController.showPopupsOnlyFor([marker]);
    }
  }

  void resetSelectedLocation() {
    selectedLocation = null;
    notifyListeners();
  }

  void setFilteredLocations(List<TripLocation> locList) {
    filteredTriplocations = locList;
    notifyListeners();
  }

  void handleFiltering(FilteringState filterState) {
    List<AbstractFilter> tempList = filterState.locationFiltering;

    List<AbstractFilter> municipalities =
        tempList.where((element) => element.parentId != null).toList();
    List<AbstractFilter> regions =
        tempList.where((element) => element.parentId == null).toList();
    List<AbstractFilter> categories = filterState.categoryFiltering;
    List<AbstractFilter> commons = filterState.commonFiltering;

    List<TripLocation> tripLocs = List.from(allTripLocations);

    // Filter regions
    if (regions.isNotEmpty) {
      tripLocs = tripLocs
          .where((loc) =>
              regions.indexWhere((element) => element.name == loc.region) != -1)
          .toList();
    }

    // Filter municipalities
    if (municipalities.isNotEmpty) {
      tripLocs = tripLocs
          .where((loc) =>
              municipalities
                  .indexWhere((element) => element.name == loc.municipality) !=
              -1)
          .toList();
    }

    // Filter categories
    if (categories.isNotEmpty) {
      tripLocs = tripLocs
          .where((loc) =>
              categories.indexWhere((element) => element.id == loc.category) !=
              -1)
          .toList();
    }

    // Filter commons
    if (commons.isNotEmpty) {
      tripLocs = tripLocs.where((loc) {
        bool retVal = true;
        for (var element in commons) {
          if (!loc.filters.contains(element.id)) {
            return false;
          }
        }
        return retVal;
      }).toList();
    }
    // tripLocs = tripLocs.toList();
    // if (tripLocs.length != allTripLocations.length ) {
    setFilteredLocations(tripLocs.toList());
    //}
  }

  void toggleFavourite(TripLocation location) async {
    await location.toggleFavourite();
    notifyListeners();
  }
}
