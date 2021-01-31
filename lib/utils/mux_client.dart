import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_stream/model/asset_data.dart';
import 'package:flutter_stream/model/video_data.dart';
import 'package:flutter_stream/res/string.dart';

import '../res/string.dart';

class MUXClient {
  Dio _dio = Dio();

  /// Method for configuring Dio, and passing the proper token
  /// for authorization
  initializeDio() {
    // authToken format: {MUX_TOKEN_ID}:{MUX_TOKEN_SECRET}
    String basicAuth = 'Basic ' + base64Encode(utf8.encode('$authToken'));

    BaseOptions options = BaseOptions(
      baseUrl: muxBaseUrl, // https://api.mux.com
      connectTimeout: 8000,
      receiveTimeout: 5000,
      headers: {
        "Content-Type": contentType, // application/json
        "authorization": basicAuth,
      },
    );
    _dio = Dio(options);
  }

  /// Method for storing a video to MUX, by passing the [videoUrl].
  ///
  /// Returns the `VideoData`.
  storeVideo({String videoUrl}) async {
    Response response;

    try {
      response = await _dio.post(
        "/video/v1/assets",
        data: {
          "input": videoUrl,
          "playback_policy": playbackPolicy,
        },
      );
    } catch (e) {
      print('Error starting build: $e');
    }

    if (response.statusCode == 201) {
      VideoData videoData = VideoData.fromJson(response.data);

      String status = videoData.data.status;

      print(status);

      while (status == 'preparing') {
        print('check');
        await Future.delayed(Duration(seconds: 1));
        videoData = await checkPostStatus(videoId: videoData.data.id);
        status = videoData.data.status;
      }

      // print('Video READY, id: ${videoData.data.id}');

      return videoData;
    }

    return null;
  }

  /// Method for tracking the status of video storage on MUX.
  ///
  /// Returns the `VideoData`.
  Future<VideoData> checkPostStatus({String videoId}) async {
    try {
      Response response = await _dio.get(
        "/video/v1/assets/$videoId",
      );

      print(response.data);

      if (response.statusCode == 200) {
        VideoData videoData = VideoData.fromJson(response.data);

        return videoData;
      }
    } catch (e) {
      print('Error starting build: $e');
    }

    return null;
  }

  /// Method for retrieving the entire asset list.
  ///
  /// Returns the `AssetData`.
  Future<AssetData> getAssetList() async {
    try {
      Response response = await _dio.get(
        "/video/v1/assets",
      );

      print(response.data);

      if (response.statusCode == 200) {
        AssetData assetData = AssetData.fromJson(response.data);

        return assetData;
      }
    } catch (e) {
      print('Error starting build: $e');
    }

    return null;
  }
}
