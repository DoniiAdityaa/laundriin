import 'package:awesome_dio_interceptor/awesome_dio_interceptor.dart';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:laundriin/config/user_preference.dart';
import 'package:laundriin/data/socket/socket_service.dart';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/api/api_service.dart';
import 'constant.dart';
import 'env/env.dart';

/// Global [GetIt.instance].
final GetIt serviceLocator = GetIt.instance;

/// Set up [GetIt] locator.
Future<void> setUpLocator() async {
  final prefs = await SharedPreferences.getInstance();
  serviceLocator.registerSingleton<UserPreference>(UserPreference(prefs));

  serviceLocator.registerFactory<Dio>(() {
    final dio = Dio();

    kDebugMode ? dio.interceptors.add(AwesomeDioInterceptor()) : null;
    dio.options = BaseOptions(
      connectTimeout: const Duration(seconds: timeOutDuration),
      receiveTimeout: const Duration(seconds: timeOutDuration),
      persistentConnection: false,
      contentType: 'application/json',
      responseType: ResponseType.json,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        // "apikey": Env.apiKey,
        'Authorization':
            'Bearer ${serviceLocator.get<UserPreference>().getToken()}'
      },
    );

    return dio;
  });

  serviceLocator.registerFactory<ApiService>(
    () => ApiService(
      serviceLocator.get<Dio>(),
      baseUrl: baseApi,
    ),
  );

  // register
  // serviceLocator.registerFactory<AuthRepository>(
  //   () => AuthRepository(
  //     serviceLocator.get<ApiService>(),
  //   ),
  // );

  // serviceLocator.registerFactory<RegisterCubit>(
  //   () => RegisterCubit(),
  // );

  // // login
  // serviceLocator.registerFactory<LoginCubit>(
  //   () => LoginCubit(),
  // );

  // // user session
  // serviceLocator.registerFactory<UserSessionCubit>(
  //   () => UserSessionCubit(),
  // );

  // // product list
  // // serviceLocator.registerFactory<ProductListCubit>(
  // //   () => ProductListCubit(
  // //     serviceLocator.get<ProductRepository>(),
  // //   ),
  // // );
  // serviceLocator.registerFactory<ProductRepository>(
  //   () => ProductRepository(
  //     serviceLocator.get<ApiService>(),
  //   ),
  // );
  // // product list
  // serviceLocator.registerFactory<ProductListCubit>(
  //   () => ProductListCubit(),
  // );
  // // detail product
  // serviceLocator.registerFactory<DetailProductCubit>(
  //   () => DetailProductCubit(),
  // );
  // // favorite product
  // serviceLocator.registerFactory<FavoriteCubit>(
  //   () => FavoriteCubit(),
  // );

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  SocketService socketService = SocketService();
  serviceLocator.registerSingleton<PackageInfo>(packageInfo);
  serviceLocator.registerSingleton<SocketService>(socketService);
}
