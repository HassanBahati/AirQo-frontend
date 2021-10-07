import 'dart:async';

import 'package:app/constants/app_constants.dart';
import 'package:app/models/alert.dart';
import 'package:app/models/historicalMeasurement.dart';
import 'package:app/models/measurement.dart';
import 'package:app/models/predict.dart';
import 'package:app/models/site.dart';
import 'package:app/models/story.dart';
import 'package:app/models/suggestion.dart';
import 'package:app/utils/distance.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'fb_notifications.dart';
import 'native_api.dart';

class DBHelper {
  var _database;

  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await initDB();
    await createDefaultTables(_database);
    return _database;
  }

  Future<bool> addAlert(Alert alert) async {
    try {
      final db = await database;

      try {
        await NotificationService().requestPermission();
        var jsonData = alert.toJson();
        await db.insert(
          '${Alert.alertDbName()}',
          jsonData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return true;
      } catch (e) {
        print(e);
      }
    } catch (e) {
      print(e);
    }

    return false;
  }

  Future<bool> addFavouritePlaces(Site site) async {
    var prefs = await SharedPreferences.getInstance();
    var favouritePlaces =
        prefs.getStringList(PrefConstant.favouritePlaces) ?? [];

    var name = site.id.trim().toLowerCase();
    if (!favouritePlaces.contains(name)) {
      favouritePlaces.add(name);
    }

    await prefs.setStringList(PrefConstant.favouritePlaces, favouritePlaces);
    return favouritePlaces.contains(name);
  }

  Future<void> createDefaultTables(Database db) async {
    var prefs = await SharedPreferences.getInstance();
    var initialLoading = prefs.getBool(PrefConstant.reLoadDb) ?? true;

    if (initialLoading) {
      await db.execute(Measurement.dropTableStmt());
      await db.execute(Suggestion.dropTableStmt());
      await db.execute(HistoricalMeasurement.dropTableStmt());
      await db.execute(Predict.dropTableStmt());
      await db.execute(Site.dropTableStmt());
      await db.execute(Story.dropTableStmt());
      await db.execute(Alert.dropTableStmt());
      await prefs.setBool(PrefConstant.reLoadDb, false);
    }

    await db.execute(Measurement.createTableStmt());
    await db.execute(Suggestion.createTableStmt());
    await db.execute(HistoricalMeasurement.createTableStmt());
    await db.execute(Predict.createTableStmt());
    await db.execute(Site.createTableStmt());
    await db.execute(Story.createTableStmt());
    await db.execute(Alert.createTableStmt());
  }

  Future<bool> deleteAlert(Alert alert) async {
    try {
      final db = await database;

      try {
        await db.delete('${Alert.alertDbName()}',
            where: '${Alert.dbSiteId()} = ?', whereArgs: [alert.siteId]);
        return true;
      } catch (e) {
        print(e);
        print('Inserting alert into db');
      }
    } catch (e) {
      print(e);
    }

    return false;
  }

  Future<void> deleteSearchHistory(Suggestion suggestion) async {
    try {
      final db = await database;

      try {
        await db.delete('${Suggestion.dbName()}',
            where: '${Suggestion.dbPlaceId()} = ?',
            whereArgs: [suggestion.placeId]);
      } on Error catch (e) {
        print(e);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<List<Alert>> getAlerts() async {
    try {
      final db = await database;

      var res = await db.query(Alert.alertDbName());

      return res.isNotEmpty
          ? List.generate(res.length, (i) {
              return Alert.fromJson(res[i]);
            })
          : <Alert>[];
    } catch (e) {
      print(e);
      return <Alert>[];
    }
  }

  Future<List<Measurement>> getFavouritePlaces() async {
    try {
      final db = await database;

      var prefs = await SharedPreferences.getInstance();
      var favouritePlaces =
          prefs.getStringList(PrefConstant.favouritePlaces) ?? [];

      if (favouritePlaces.isEmpty) {
        return [];
      }

      var placesRes = <Map<String, Object?>>[];

      for (var fav in favouritePlaces) {
        var res = await db.query('${Measurement.latestMeasurementsDb()}',
            where: '${'${Site.dbId()} = ?'}', whereArgs: [fav]);

        placesRes.addAll(res);
      }
      if (placesRes.isEmpty) {
        return [];
      }

      return placesRes.isNotEmpty
          ? List.generate(placesRes.length, (i) {
              return Measurement.fromJson(Measurement.mapFromDb(placesRes[i]));
            })
          : <Measurement>[];
    } catch (e) {
      print('am here');
      print(e);

      return <Measurement>[];
    }
  }

  Future<List<Predict>> getForecastMeasurements(String siteId) async {
    try {
      final db = await database;

      var res = await db.query(Predict.forecastDb(),
          where: '${Site.dbId()} = ?', whereArgs: [siteId]);

      return res.isNotEmpty
          ? List.generate(res.length, (i) {
              return Predict.fromJson(Predict.mapFromDb(res[i]));
            })
          : <Predict>[];
    } catch (e) {
      print(e);
      return <Predict>[];
    }
  }

  Future<List<HistoricalMeasurement>> getHistoricalMeasurements(
      String siteId) async {
    try {
      final db = await database;

      var res = await db.query(HistoricalMeasurement.historicalMeasurementsDb(),
          where: '${Site.dbId()} = ?', whereArgs: [siteId]);

      return res.isNotEmpty
          ? List.generate(res.length, (i) {
              return HistoricalMeasurement.fromJson(
                  HistoricalMeasurement.mapFromDb(res[i]));
            })
          : <HistoricalMeasurement>[];
    } catch (e) {
      print(e);
      return <HistoricalMeasurement>[];
    }
  }

  Future<List<Measurement>> getLatestMeasurements() async {
    try {
      final db = await database;

      var res = await db.query(Measurement.latestMeasurementsDb());

      return res.isNotEmpty
          ? List.generate(res.length, (i) {
              return Measurement.fromJson(Measurement.mapFromDb(res[i]));
            })
          : <Measurement>[]
        ..sort((siteA, siteB) => siteA.site
            .getName()
            .toLowerCase()
            .compareTo(siteB.site.getName().toLowerCase()));
    } catch (e) {
      print(e);
      return <Measurement>[];
    }
  }

  Future<Measurement?> getLocationMeasurement() async {
    try {
      var nearestMeasurement;
      var nearestMeasurements = <Measurement>[];

      double distanceInMeters;

      var location = await LocationApi().getLocation();
      if (location.longitude != null && location.latitude != null) {
        var latitude = location.latitude;
        var longitude = location.longitude;
        var addresses =
            await LocationApi().getAddressGoogle(latitude!, longitude!);
        var userAddress = addresses.first;

        await getLatestMeasurements().then((measurements) => {
              for (var measurement in measurements)
                {
                  distanceInMeters = metersToKmDouble(
                      Geolocator.distanceBetween(
                          measurement.site.latitude,
                          measurement.site.longitude,
                          location.latitude!,
                          location.longitude!)),
                  if (distanceInMeters < AppConfig.maxSearchRadius.toDouble())
                    {
                      // print('$distanceInMeters : '
                      //     '${AppConfig.maxSearchRadius.toDouble()} : '
                      //     '${measurement.site.getName()}'),
                      measurement.site.distance = distanceInMeters,
                      measurement.site.userLocation = userAddress.thoroughfare,
                      nearestMeasurements.add(measurement)
                    }
                },
              if (nearestMeasurements.isNotEmpty)
                {
                  nearestMeasurement = nearestMeasurements.first,
                  for (var m in nearestMeasurements)
                    {
                      if (nearestMeasurement.site.distance > m.site.distance)
                        {nearestMeasurement = m}
                    }
                }
            });

        await LocationApi().getLocation().then((value) => {
              getLatestMeasurements().then((measurements) => {
                    if (location.longitude != null && location.latitude != null)
                      {
                        for (var measurement in measurements)
                          {
                            distanceInMeters = metersToKmDouble(
                                Geolocator.distanceBetween(
                                    measurement.site.latitude,
                                    measurement.site.longitude,
                                    location.latitude!,
                                    location.longitude!)),
                            if (distanceInMeters <
                                AppConfig.maxSearchRadius.toDouble())
                              {
                                // print('$distanceInMeters : '
                                //     '${AppConfig
                                //     .maxSearchRadius.toDouble()} : '
                                //     '${measurement.site.getName()}'),
                                measurement.site.distance = distanceInMeters,
                                nearestMeasurements.add(measurement)
                              }
                          },
                        if (nearestMeasurements.isNotEmpty)
                          {
                            nearestMeasurement = nearestMeasurements.first,
                            for (var m in nearestMeasurements)
                              {
                                if (nearestMeasurement.site.distance >
                                    m.site.distance)
                                  {nearestMeasurement = m}
                              }
                          }
                      }
                  })
            });
      }

      return nearestMeasurement;
    } catch (e) {
      print('error $e');
      return null;
    }
  }

  Future<Measurement?> getMeasurement(String siteId) async {
    try {
      final db = await database;

      var res = await db.query(Measurement.latestMeasurementsDb(),
          where: '${Site.dbId()} = ?', whereArgs: [siteId]);

      if (res.isEmpty) {
        return null;
      }
      return Measurement.fromJson(Measurement.mapFromDb(res.first));
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<Measurement?> getNearestMeasurement(
      double latitude, double longitude) async {
    try {
      var nearestMeasurement;
      var nearestMeasurements = <Measurement>[];

      double distanceInMeters;

      await getLatestMeasurements().then((measurements) => {
            for (var measurement in measurements)
              {
                distanceInMeters = metersToKmDouble(Geolocator.distanceBetween(
                    measurement.site.latitude,
                    measurement.site.longitude,
                    latitude,
                    longitude)),
                if (distanceInMeters < AppConfig.maxSearchRadius.toDouble())
                  {
                    // print('$distanceInMeters : '
                    //     '${AppConfig.maxSearchRadius.toDouble()} : '
                    //     '${measurement.site.getName()}'),
                    measurement.site.distance = distanceInMeters,
                    nearestMeasurements.add(measurement)
                  }
              },
            if (nearestMeasurements.isNotEmpty)
              {
                nearestMeasurement = nearestMeasurements.first,
                for (var m in nearestMeasurements)
                  {
                    if (nearestMeasurement.site.distance > m.site.distance)
                      {nearestMeasurement = m}
                  },
              }
          });

      return nearestMeasurement;
    } catch (e) {
      print('error $e');
      return null;
    }
  }

  Future<List<Suggestion>> getSearchHistory() async {
    try {
      final db = await database;

      var res = await db.query(Suggestion.dbName());

      var history = res.isNotEmpty
          ? List.generate(res.length, (i) {
              return Suggestion.fromJson(res[i]);
            })
          : <Suggestion>[];

      return history;
    } catch (e) {
      print(e);
      return <Suggestion>[];
    }
  }

  Future<Site?> getSite(String siteId) async {
    try {
      final db = await database;
      var res = await db.query(Site.sitesDbName(),
          where: '${Site.dbId()} = ?', whereArgs: [siteId]);

      return Site.fromJson(Site.fromDbMap(res.first));
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<List<Site>> getSites() async {
    try {
      final db = await database;
      var res = await db.query(Site.sitesDbName());

      var sites = res.isNotEmpty
          ? List.generate(res.length, (i) {
              return Site.fromJson(Site.fromDbMap(res[i]));
            })
          : <Site>[]
        ..sort((siteA, siteB) => siteA
            .getName()
            .toLowerCase()
            .compareTo(siteB.getName().toLowerCase()));

      return sites;
    } catch (e) {
      print(e);
      return <Site>[];
    }
  }

  Future<List<Story>> getStories() async {
    try {
      final db = await database;

      var res = await db.query(Story.storyDbName());

      return res.isNotEmpty
          ? List.generate(res.length, (i) {
              return Story.fromJson(res[i]);
            })
          : <Story>[];
    } catch (e) {
      print(e);
      return <Story>[];
    }
  }

  Future<Database> initDB() async {
    return await openDatabase(
      join(await getDatabasesPath(), AppConfig.dbName),
      version: 1,
      onCreate: (db, version) {
        createDefaultTables(db);
      },
      // onUpgrade: (db, oldVersion, newVersion){
      //   createDefaultTables(db);
      // },
    );
  }

  Future<void> insertForecastMeasurements(
      List<Predict> measurements, String siteId) async {
    try {
      final db = await database;

      if (measurements.isNotEmpty) {
        await db.delete(Predict.forecastDb(),
            where: '${Site.dbId()} = ?', whereArgs: [siteId]);

        for (var measurement in measurements) {
          try {
            var jsonData = Predict.mapToDb(measurement, siteId);
            await db.insert(
              '${Predict.forecastDb()}',
              jsonData,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          } catch (e) {
            print('Inserting predicted measurements into db');
            print(e);
          }
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> insertHistoricalMeasurements(
      List<HistoricalMeasurement> measurements) async {
    try {
      final db = await database;

      if (measurements.isNotEmpty) {
        await db.delete(HistoricalMeasurement.historicalMeasurementsDb());

        for (var measurement in measurements) {
          try {
            var jsonData = HistoricalMeasurement.mapToDb(measurement);
            await db.insert(
              '${HistoricalMeasurement.historicalMeasurementsDb()}',
              jsonData,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          } catch (e) {
            print('Inserting historical measurements into db');
            print(e);
          }
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> insertLatestMeasurements(List<Measurement> measurements) async {
    try {
      final db = await database;

      if (measurements.isNotEmpty) {
        // await db.delete(Measurement.latestMeasurementsDb());

        for (var measurement in measurements) {
          try {
            var jsonData = Measurement.mapToDb(measurement);
            await db.insert(
              '${Measurement.latestMeasurementsDb()}',
              jsonData,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          } catch (e) {
            print('Inserting latest measurements into db');
            print(e);
          }
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> insertLatestStories(List<Story> stories) async {
    try {
      final db = await database;

      if (stories.isNotEmpty) {
        // await db.delete(Story.storyDbName());

        for (var story in stories) {
          try {
            var jsonData = story.toJson();
            await db.insert(
              '${Story.storyDbName()}',
              jsonData,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          } catch (e) {
            await db.execute(Story.dropTableStmt());
            await db.execute(Story.createTableStmt());
            print('Inserting latest stories into db');
            print(e);
          }
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> insertSearchHistory(Suggestion suggestion) async {
    try {
      final db = await database;

      var jsonData = suggestion.toJson();

      try {
        await db.insert(
          '${Suggestion.dbName()}',
          jsonData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } on Error catch (e) {
        print(e);
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> insertSiteHistoricalMeasurements(
      List<HistoricalMeasurement> measurements, String siteId) async {
    try {
      final db = await database;

      if (measurements.isNotEmpty) {
        await db.delete(HistoricalMeasurement.historicalMeasurementsDb(),
            where: '${Site.dbId()} = ?', whereArgs: [siteId]);

        for (var measurement in measurements) {
          try {
            var jsonData = HistoricalMeasurement.mapToDb(measurement);
            await db.insert(
              '${HistoricalMeasurement.historicalMeasurementsDb()}',
              jsonData,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          } catch (e) {
            print('Inserting site historical measurements into db');
            print(e);
          }
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> insertSites(List<Site> sites) async {
    try {
      final db = await database;

      if (sites.isNotEmpty) {
        await db.delete(Site.sitesDbName());
        for (var site in sites) {
          try {
            var jsonData = Site.toDbMap(site);
            await db.insert(
              '${Site.sitesDbName()}',
              jsonData,
              conflictAlgorithm: ConflictAlgorithm.replace,
            );
          } catch (e) {
            print('Inserting sites into db');
            print(e);
          }
        }
      }
    } catch (e) {
      print(e);
    }
  }

  Future<bool> updateFavouritePlaces(Site site) async {
    var prefs = await SharedPreferences.getInstance();
    var favouritePlaces =
        prefs.getStringList(PrefConstant.favouritePlaces) ?? [];

    var name = site.id.trim().toLowerCase();
    if (favouritePlaces.contains(name)) {
      var updatedList = <String>[];

      for (var fav in favouritePlaces) {
        if (name != fav.trim().toLowerCase()) {
          updatedList.add(fav.trim().toLowerCase());
        }
      }
      favouritePlaces = updatedList;
    } else {
      favouritePlaces.add(name);
    }

    await prefs.setStringList(PrefConstant.favouritePlaces, favouritePlaces);
    return favouritePlaces.contains(name);
  }

  Future<bool> updateSiteAlerts(
      Site site, PollutantLevel pollutantLevel) async {
    var prefs = await SharedPreferences.getInstance();
    var preferredAlerts = prefs.getStringList(PrefConstant.siteAlerts) ?? [];

    var topicName = site.getTopic(pollutantLevel);

    if (preferredAlerts.contains(topicName)) {
      await NotificationService().requestPermission();
      await NotificationService().unSubscribeFromSite(site, pollutantLevel);
      while (preferredAlerts.contains(topicName)) {
        preferredAlerts.remove(topicName.trim().toLowerCase());
      }
    } else {
      await NotificationService().subscribeToSite(site, pollutantLevel);
      preferredAlerts.add(topicName.trim().toLowerCase());
    }

    await prefs.setStringList(PrefConstant.siteAlerts, preferredAlerts);

    return preferredAlerts.contains(topicName);
  }
}
