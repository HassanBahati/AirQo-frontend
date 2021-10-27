import 'package:app/constants/app_constants.dart';
import 'package:app/models/measurement.dart';
import 'package:app/screens/place_view.dart';
import 'package:app/services/local_storage.dart';
import 'package:app/services/native_api.dart';
import 'package:app/utils/dialogs.dart';
import 'package:app/widgets/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'insights_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Measurement> nearbySites = [];
  List<Measurement> searchSites = [];
  List<Measurement> allSites = [];
  bool isSearching = false;
  bool hasNearbyLocations = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 40),
        color: ColorConstants.appBodyColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: backButton(context),
                ),
                Expanded(
                  child: searchField(),
                )
              ],
            ),
            const SizedBox(
              height: 32,
            ),
            if (!isSearching && hasNearbyLocations && nearbySites.isNotEmpty)
              Text(
                'Locations near me',
                textAlign: TextAlign.start,
                style: TextStyle(
                    color: ColorConstants.inactiveColor, fontSize: 12),
              ),
            if (isSearching)
              Expanded(
                child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        searchLocations(),
                      ],
                    )),
              ),
            if (!isSearching && hasNearbyLocations)
              Expanded(
                child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        if (nearbySites.isEmpty) requestLocationAccess(),
                        if (nearbySites.isNotEmpty) nearByLocations(),
                      ],
                    )),
              ),
            if (!isSearching && !hasNearbyLocations)
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    noNearbyLocations(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> getSites() async {
    await DBHelper().getLatestMeasurements().then((value) => {
          if (mounted)
            {
              setState(() {
                allSites = value;
              })
            }
        });
  }

  Future<void> getUserLocation() async {
    try {
      var location = await LocationService().getLocation();
      var latitude = location.latitude;
      var longitude = location.longitude;
      if (longitude != null && latitude != null) {
        await LocationService()
            .getNearestSites(latitude, longitude)
            .then((value) => {
                  if (mounted)
                    {
                      if (value.isEmpty)
                        {
                          setState(() {
                            nearbySites = [];
                            hasNearbyLocations = false;
                          })
                        }
                      else
                        {
                          setState(() {
                            nearbySites = value;
                            hasNearbyLocations = true;
                          })
                        }
                    }
                });
      } else {
        throw Exception('Failed to get your location');
      }
    } catch (e) {
      var error = e.toString().replaceAll('Exception :', '');
      error = error.replaceAll('Exception', '');
      error = error.replaceAll(':', '');
      await showSnackBar(context, error);
    }
  }

  @override
  void initState() {
    super.initState();
    getSites();
    getUserLocation();
  }

  Widget nearByLocations() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 8.0,
          ),
          Container(
              padding: const EdgeInsets.only(right: 8, bottom: 8, left: 8),
              decoration: BoxDecoration(
                  color: ColorConstants.appBodyColor,
                  shape: BoxShape.rectangle,
                  borderRadius: const BorderRadius.all(Radius.circular(10.0))),
              child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: ListView.builder(
                    controller: ScrollController(),
                    shrinkWrap: true,
                    itemBuilder: (context, index) => GestureDetector(
                        onTap: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) {
                            return InsightsPage(nearbySites[index].site);
                          }));
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: locationTile(nearbySites[index]),
                        )),
                    itemCount: nearbySites.length,
                    // separatorBuilder: (BuildContext context, int index) {
                    //   return Divider(
                    //     indent: 20,
                    //     endIndent: 20,
                    //     color: ColorConstants.appColor,
                    //   );
                    // }
                  ))),
        ],
      ),
    );
  }

  Widget noNearbyLocations() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(40.0),
            decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.all(Radius.circular(10.0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 84,
                ),
                Stack(
                  children: [
                    Image.asset(
                      'assets/images/world-map.png',
                      height: 130,
                      width: 130,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: ColorConstants.appColorBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Icon(
                          Icons.map_outlined,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 52,
                ),
                const Text(
                  'You don\'t have nearby air quality stations',
                  textAlign: TextAlign.start,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 40,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget requestLocationAccess() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(40.0),
            decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.all(Radius.circular(10.0))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 84,
                ),
                Stack(
                  children: [
                    Image.asset(
                      'assets/images/world-map.png',
                      height: 130,
                      width: 130,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: ColorConstants.appColorBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Icon(
                          Icons.map_outlined,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 52,
                ),
                const Text(
                  'Enable locations',
                  textAlign: TextAlign.start,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(
                  height: 8,
                ),
                const Text(
                  'Allow AirQo to show you location air '
                  'quality update near you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(
                  height: 24,
                ),
                GestureDetector(
                  onTap: () {
                    LocationService()
                        .requestLocationAccess()
                        .then((value) => {getUserLocation()});
                  },
                  child: Container(
                      constraints:
                          const BoxConstraints(minWidth: double.infinity),
                      decoration: BoxDecoration(
                          color: ColorConstants.appColorBlue,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10.0))),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 19, bottom: 19),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Allow location',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            )
                          ],
                        ),
                      )),
                ),
                const SizedBox(
                  height: 40,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  void searchChanged(String text) {
    if (text.isEmpty) {
      setState(() {
        isSearching = false;
      });
    } else {
      setState(() {
        isSearching = true;
        searchSites = LocationService().textSearchNearestSites(text, allSites);
      });
    }
  }

  Widget searchField() {
    return Container(
      height: 40,
      constraints: const BoxConstraints(minWidth: double.maxFinite),
      decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.all(Radius.circular(10.0))),
      child: Row(
        children: [
          const SizedBox(
            width: 10,
          ),
          SvgPicture.asset(
            'assets/icon/search.svg',
            height: 17,
            width: 17,
            semanticsLabel: 'Search',
          ),
          const SizedBox(
            width: 11,
          ),
          Expanded(
            child: TextFormField(
              // controller: _textEditingController,
              onChanged: searchChanged,
              cursorWidth: 1,
              cursorColor: ColorConstants.appColorBlue,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Search your village air quality',
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(
            width: 10,
          ),
        ],
      ),
    );
  }

  Widget searchLocations() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
              // decoration: const BoxDecoration(
              //     color: Colors.white,
              //     shape: BoxShape.rectangle,
              //     borderRadius: BorderRadius.all(Radius.circular(10.0))
              // ),
              child: searchSites.isEmpty
                  ? Center(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 84,
                          ),
                          Stack(
                            children: [
                              Image.asset(
                                'assets/images/world-map.png',
                                height: 130,
                                width: 130,
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: ColorConstants.appColorBlue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Icon(
                                    Icons.map_outlined,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 52,
                          ),
                          const Text(
                            'Not found',
                            textAlign: TextAlign.start,
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(
                            height: 52,
                          ),
                        ],
                      ),
                    )
                  : MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: ListView.builder(
                        controller: ScrollController(),
                        shrinkWrap: true,
                        itemBuilder: (context, index) => GestureDetector(
                            onTap: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return InsightsPage(searchSites[index].site);
                              }));
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: locationTile(searchSites[index]),
                            )),
                        itemCount: searchSites.length,
                        // separatorBuilder: (BuildContext context, int index) {
                        //   return Divider(
                        //     indent: 20,
                        //     endIndent: 20,
                        //     color: ColorConstants.appColor,
                        //   );
                        // }
                      ))),
        ],
      ),
    );
  }
}
