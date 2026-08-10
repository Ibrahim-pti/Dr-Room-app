import 'package:flutter/material.dart';
import '../data/pharmacy_repository.dart';
import '../models/pharmacy_model.dart';
import 'pharmacy_detail_screen.dart';

class PharmaciesScreen extends StatefulWidget {
  @override
  _PharmaciesScreenState createState() => _PharmaciesScreenState();
}

class _PharmaciesScreenState extends State<PharmaciesScreen> {
  final PharmacyRepository _repository = PharmacyRepository();
  List<Pharmacy> _pharmacies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPharmacies();
  }

  Future<void> _fetchPharmacies() async {
    final pharmacies = await _repository.getPharmacies();
    setState(() {
      _pharmacies = pharmacies;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('دەرمانخانەکان', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.teal))
          : _pharmacies.isEmpty
              ? Center(child: Text('هیچ دەرمانخانەیەک بوونی نییە.'))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _pharmacies.length,
                  itemBuilder: (context, index) {
                    final pharmacy = _pharmacies[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      margin: EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PharmacyDetailScreen(pharmacy: pharmacy),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.teal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  image: pharmacy.profileImage != null
                                      ? DecorationImage(
                                          image: NetworkImage(pharmacy.profileImage!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: pharmacy.profileImage == null
                                    ? Icon(Icons.local_pharmacy, size: 40, color: Colors.teal)
                                    : null,
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            pharmacy.name,
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Icon(Icons.star, color: Colors.amber, size: 18),
                                            SizedBox(width: 4),
                                            Text(pharmacy.rating.toString(), style: TextStyle(fontWeight: FontWeight.bold)),
                                          ],
                                        )
                                      ],
                                    ),
                                    SizedBox(height: 8),
                                    Text('کرێی گەیاندن: IQD \${pharmacy.deliveryFee}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                    SizedBox(height: 8),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: pharmacy.isOpen ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        pharmacy.isOpen ? 'کراوەیە' : 'داخراوە',
                                        style: TextStyle(
                                          color: pharmacy.isOpen ? Colors.green[700] : Colors.red[700],
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
