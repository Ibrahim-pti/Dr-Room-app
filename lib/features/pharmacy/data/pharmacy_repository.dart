import 'dart:convert';
import '../../../core/utils/api_client.dart';
import '../models/pharmacy_model.dart';
import '../models/medication_model.dart';
import '../models/offer_model.dart';

class PharmacyRepository {
  Future<List<Pharmacy>> getPharmacies() async {
    try {
      final response = await ApiClient.get('/pharmacies');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
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

  Future<List<Medication>> getMedications(int pharmacyId) async {
    try {
      final response = await ApiClient.get('/pharmacies/$pharmacyId/medications');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
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
        if (data['success'] == true) {
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
}
