import 'dart:async';

import 'package:app/config/languages/CustomLocalizations.dart';
import 'package:app/constants/app_constants.dart';
import 'package:app/models/device.dart';
import 'package:app/models/measurement.dart';
import 'package:app/models/place.dart';
import 'package:app/models/suggestion.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'package:path/path.dart';

class DBHelper {
  var _database;
  var constants = DbConstants();

  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await initDB();
    return _database;
  }

  Future<Database> initDB() async {
    return await openDatabase(
      join(await getDatabasesPath(), constants.dbName),
      version: 1,
      onCreate: (db, version) {
        createDefaultTables(db);
      },
      // onUpgrade: (db, oldVersion, newVersion){
      //
      // },
    );
  }

  Future<void> createDefaultTables(Database db) async {

    print('creating databases');

    await db.execute(Measurement.latestMeasurementsTableDropStmt());
    await db.execute(Measurement.latestMeasurementsTableCreateStmt());

    // await db.execute(Device.devicesTableDropStmt());
    // await db.execute(Device.createTableStmt());

    // historical measurements table
    // await db.execute(Measurement.historicalMeasurementsTableStmt());

    // forecast data table
    // await db.execute(Measurement.forecastDataTableStmt());

  }

  Future<void> insertSearchHistory(Suggestion suggestion) async {
    try {
      print('Inserting search term into local db');

      final db = await database;

      var jsonData = suggestion.toJson();

      try {
        await db.insert(
          '${constants.searchTableHistory}',
          jsonData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } on Error catch (e) {
        print(e);
      }

      print('Search term insertion into local db complete');
    } catch (e) {
      print(e);
    }
  }

  Future<void> deleteSearchHistory(Suggestion suggestion) async {
    try {
      print('Inserting search term into local db');

      final db = await database;

      try {
        await db.delete('${constants.searchTableHistory}',
            where: '${constants.place_id} = ?',
            whereArgs: [suggestion.placeId]);
      } on Error catch (e) {
        print(e);
      }

      print('Search term deletion from local db complete');
    } catch (e) {
      print(e);
    }
  }

  Future<List<Suggestion>> getSearchHistory() async {
    try {
      print('Getting search history from local db');

      final db = await database;

      var res = await db.query(constants.searchTableHistory);

      print('Got ${res.length} places from local db');

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

  Future<void> insertLatestMeasurements(List<Measurement> measurements) async {

      final db = await database;

      if (measurements.isNotEmpty) {
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

  }

  Future<bool> updateFavouritePlaces(Device device) async {
    var prefs = await SharedPreferences.getInstance();
    var favouritePlaces = prefs
        .getStringList(PrefConstants().favouritePlaces) ?? [];

    var name = device.name.trim().toLowerCase();
    if(favouritePlaces.contains(name)){

      var updatedList = <String>[];

      for (var fav in favouritePlaces) {
        if(name != fav.trim().toLowerCase()) {
          updatedList.add(fav.trim().toLowerCase());
        }
      }
      favouritePlaces = updatedList;
    }
    else{
      favouritePlaces.add(name);
    }

    await prefs.setStringList(PrefConstants().favouritePlaces, favouritePlaces);
    return favouritePlaces.contains(name);

  }

  Future<Device> renameFavouritePlace(Device device, String name) async {
    print('Renaming favourite place in local db');

    try {
      final db = await database;

      var res = await db.query('${constants.locationsTable}',
          where: '${constants.name} = ?', whereArgs: [device.name]);

      if (res.isEmpty) {
        var locationMap = Device.toDbMap(device);
        locationMap['${constants.favourite}'] = 1;
        locationMap['${constants.nickName}'] = name;

        await db.insert('${constants.locationsTable}', locationMap);
      } else {
        var updateMap = <String, Object?>{'${constants.nickName}': name};

        var num = await db.update(
          '${constants.locationsTable}',
          updateMap,
          where: '${constants.name} = ?',
          whereArgs: [device.name],
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        print('updated rows : $num');
      }
      return getDevice(device.name);
    } on Error catch (e) {
      print(e);
      return device;
    }
  }

  Future<Measurement?> getMeasurement(String name) async {
    try {
      print('Getting measurements locally');

      final db = await database;

      var res = await db.query(Measurement.latestMeasurementsDb(),
          where: '${Measurement.dbDeviceName()} = ?', whereArgs: [name]);

      if (res.isEmpty) {
        return null;
      }

      print('Got measurement locally');
      return Measurement.fromJson(Measurement.mapFromDb(res.first));

    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<List<Measurement>> getLatestMeasurements() async {
    try {
      print('Getting measurements from local db');

      final db = await database;

      var res = await db.query(Measurement.latestMeasurementsDb());


      print('Got ${res.length} measurements from local db');

      return res.isNotEmpty
          ? List.generate(res.length, (i) {
              return Measurement.fromJson(Measurement.mapFromDb(res[i]));
            })
          : <Measurement>[];
    } catch (e) {
      print(e);
      return <Measurement>[];
    }
  }

  Future<List<Device>> getDevices() async {
    try {
      print('Getting devices from local db');

      final db = await database;
      var res = await db.query(Device.dbName());

      print('Got ${res.length} places from local db');

      var devices = res.isNotEmpty
          ? List.generate(res.length, (i) {
              return Device.fromJson(Device.fromDbMap(res[i]));
            })
          : <Device>[];

      return devices;
    } catch (e) {
      print(e);
      return <Device>[];
    }
  }

  Future<Device> getDevice(String name) async {
    try {
      print('Getting device from local db');

      final db = await database;
      var res = await db.query(constants.locationsTable,
          where: '${constants.name} = ?', whereArgs: [name]);

      var device = Device.fromJson(Device.fromDbMap(res.first));

      return device;
    } catch (e) {
      print(e);
      throw Exception('Device doesn\'t exist');
    }
  }

  Future<List<Measurement>> getFavouritePlaces() async {
    try {
      final db = await database;

      var prefs = await SharedPreferences.getInstance();
      var favouritePlaces = prefs
          .getStringList(PrefConstants().favouritePlaces) ?? [];

      if(favouritePlaces.isEmpty){
        return [];
      }

      var placesRes = <Map<String, Object?>>[];
      for(var fav in favouritePlaces){

        var res = await db.query('${Measurement.latestMeasurementsDb()}',
            where: '${'${Measurement.dbDeviceName()} = ?'}',
            whereArgs: [fav]);
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
      print(e);

      return <Measurement>[];
    }
  }

}
