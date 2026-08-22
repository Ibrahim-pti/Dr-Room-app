import 'dart:convert';
import '../../../core/utils/api_client.dart';
import '../models/pharmacy_model.dart';
import '../models/medication_model.dart';
import '../models/offer_model.dart';

class PharmacyRepository {
  Future<List<Pharmacy>> getPharmacies({String? city, String? search, bool? isOpen}) async {
    try {
      String queryParams = '';
      final params = <String>[];
      if (city != null && city.isNotEmpty && city != 'هەمووی') {
        params.add('city=${Uri.encodeComponent(city)}');
      }
      if (search != null && search.isNotEmpty) {
        params.add('search=${Uri.encodeComponent(search)}');
      }
      if (isOpen != null) {
        params.add('is_open=${isOpen ? "1" : "0"}');
      }
      if (params.isNotEmpty) {
        queryParams = '?${params.join('&')}';
      }

      final response = await ApiClient.get('/pharmacies$queryParams');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((json) => Pharmacy.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching pharmacies: $e');
      return [];
    }
  }

  Future<Pharmacy?> getPharmacyDetail(int pharmacyId) async {
    try {
      final response = await ApiClient.get('/pharmacies/$pharmacyId');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return Pharmacy.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching pharmacy detail: $e');
      return null;
    }
  }

  Future<List<Medication>> getMedications(int pharmacyId, {String? category, String? search}) async {
    try {
      String queryParams = '';
      final params = <String>[];
      if (category != null && category.isNotEmpty && category != 'هەمووی') {
        params.add('category=${Uri.encodeComponent(category)}');
      }
      if (search != null && search.isNotEmpty) {
        params.add('search=${Uri.encodeComponent(search)}');
      }
      if (params.isNotEmpty) {
        queryParams = '?${params.join('&')}';
      }

      final response = await ApiClient.get('/pharmacies/$pharmacyId/medications$queryParams');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((json) => Medication.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching medications: $e');
      return [];
    }
  }

  Future<List<PharmacyOffer>> getOffers(int pharmacyId) async {
    try {
      final response = await ApiClient.get('/pharmacies/$pharmacyId/offers');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List)
              .map((json) => PharmacyOffer.fromJson(json))
              .toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching offers: $e');
      return [];
    }
  }

  Future<List<dynamic>> getReviews(int pharmacyId) async {
    try {
      final response = await ApiClient.get('/pharmacies/$pharmacyId/reviews');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'] as List;
        }
      }
      return [];
    } catch (e) {
      print('Error fetching pharmacy reviews: $e');
      return [];
    }
  }

  Future<bool> addReview(int pharmacyId, {required double rating, String? comment}) async {
    try {
      final response = await ApiClient.post(
        '/pharmacies/$pharmacyId/reviews',
        body: {
          'rating': rating,
          'comment': comment ?? '',
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<List<Map<String, String>>> getCategories() async {
    try {
      final response = await ApiClient.get('/pharmacies/categories');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return (data['data'] as List).map<Map<String, String>>((item) {
            return {
              'name': item['name']?.toString() ?? '',
              'icon': item['icon']?.toString() ?? '💊',
            };
          }).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}