// Ejercicio 3.3 - Consumo de API con Dio (Flutter)
//
// pubspec.yaml:
//   dependencies:
//     dio: ^5.4.0

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'token_storage.dart';

// ---------------- Modelo ----------------

class ExchangeRates {
  final String base;
  final String date;
  final Map<String, double> rates;

  const ExchangeRates({
    required this.base,
    required this.date,
    required this.rates,
  });

  factory ExchangeRates.fromJson(Map<String, dynamic> json) {
    final rawRates = json['rates'] as Map<String, dynamic>;
    return ExchangeRates(
      base: json['base'] as String,
      date: json['date'] as String,
      rates: rawRates.map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }
}

// ---------------- Errores ----------------

class ApiException implements Exception {
  final String message;
  const ApiException(this.message);
  @override
  String toString() => message;
}

// ---------------- Servicio ----------------

class ExchangeRateService {
  final Dio _dio;

  ExchangeRateService({Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: 'https://api.exchangerate-api.com/v4',
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 10),
            ));

  Future<ExchangeRates> getLatest(String base) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/latest/$base');
      return ExchangeRates.fromJson(response.data!);
    } on DioException catch (e) {
      throw ApiException(_mapError(e));
    } catch (_) {
      throw const ApiException('Respuesta inesperada del servidor.');
    }
  }

  String _mapError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Tiempo de espera agotado. Intenta de nuevo.';
      case DioExceptionType.connectionError:
        return 'Sin conexión a internet.';
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        if (code == 404) return 'Recurso no encontrado (404).';
        if (code != null && code >= 500) return 'Error del servidor ($code).';
        return 'Error HTTP $code.';
      case DioExceptionType.cancel:
        return 'Solicitud cancelada.';
      default:
        return 'Error de red desconocido.';
    }
  }
}

// ---------------- Vista ----------------

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await demo(); // prueba del token seguro (ejercicio 3.4)
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: RatesPage(),
  ));
}

class RatesPage extends StatefulWidget {
  const RatesPage({super.key});
  @override
  State<RatesPage> createState() => _RatesPageState();
}

class _RatesPageState extends State<RatesPage> {
  final _service = ExchangeRateService();
  late Future<ExchangeRates> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getLatest('MXN');
  }

  void _reload() {
    setState(() {
      _future = _service.getLatest('MXN');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tipo de cambio (MXN)'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _reload),
        ],
      ),
      body: FutureBuilder<ExchangeRates>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${snap.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _reload, child: const Text('Reintentar')),
                ],
              ),
            );
          }
          final data = snap.data!;
          final entries = data.rates.entries.toList();
          return Column(
            children: [
              ListTile(
                title: Text('Base: ${data.base}'),
                subtitle: Text('Fecha: ${data.date}'),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (_, i) => ListTile(
                    title: Text(entries[i].key),
                    trailing: Text(entries[i].value.toStringAsFixed(4)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
