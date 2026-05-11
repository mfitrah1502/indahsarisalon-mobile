import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/service_model.dart';
import '../models/promo_model.dart';

class ServiceController {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> fetchServicesAndCategories() async {
    final catData = await _supabase
        .from('categories')
        .select('id, name')
        .order('name');

    List<dynamic> svcData;
    try {
      svcData = await _supabase
          .from('treatment_details')
          .select('id, name, duration, price, treatment_id, image_url, treatments(id, name, category_id, is_promo, is_active, image, categories(id, name))')
          .order('id');
    } catch (e) {
      debugPrint("Error fetching services: $e");
      svcData = [];
    }

    // Fetch promos safely
    List<dynamic> promosData;
    try {
      promosData = await _supabase.from('promos').select('id, title, is_active, start_at, end_at, image_url');
    } catch (e) {
      try {
        promosData = await _supabase.from('promos').select('id, title, is_active, start_at, end_at');
      } catch (e2) {
        promosData = [];
      }
    }
    final Map<String, dynamic> promoMap = {for (var p in promosData) p['title']: p};

    final cats = ['All', ...List<Map<String, dynamic>>.from(catData).map((c) => c['name'] as String)];

    final services = List<Map<String, dynamic>>.from(svcData).map<ServiceModel>((td) {
      final treatment = td['treatments'] as Map<String, dynamic>?;
      final category = treatment?['categories'] as Map<String, dynamic>?;
      final treatmentName = treatment?['name'] ?? '';
      final detailName = td['name'] ?? '';
      final isPromo = treatment?['is_promo'] == true;
      final displayName = (treatmentName == detailName || detailName.isEmpty)
          ? treatmentName
          : "$treatmentName - $detailName";
      
      final promoInfo = isPromo ? promoMap[treatmentName] : null;
      
      bool activeStatus = treatment?['is_active'] ?? true;
      if (isPromo) {
        activeStatus = promoInfo?['is_active'] ?? true;
      }

      return ServiceModel(
        tdId: td['id'],
        treatmentId: td['treatment_id'],
        treatmentName: treatmentName,
        detailName: detailName,
        displayName: displayName,
        category: category?['name'] ?? '',
        duration: (td['duration'] as num?)?.toInt() ?? 0,
        price: (td['price'] as num?)?.toInt() ?? 0,
        imageUrl: td['image_url'] ?? treatment?['image'], // Prefer detail image, fallback to parent
        isPromo: isPromo,
        promoId: promoInfo?['id'],
        isActive: activeStatus,
      );
    }).toList();

    return {
      'categories': cats,
      'services': services,
    };
  }

  Future<String?> uploadImage(Uint8List bytes, String fileName, String folder) async {
    try {
      final path = '$folder/$fileName';
      debugPrint("Uploading to storage: treatments/$path");
      await _supabase.storage.from('treatments').uploadBinary(
        path, 
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );
      final String publicUrl = _supabase.storage.from('treatments').getPublicUrl(path);
      debugPrint("Upload success: $publicUrl");
      return publicUrl;
    } catch (e) {
      debugPrint("Error uploading image to Supabase Storage: $e");
      // If error is 'Bucket not found', we inform through the exception
      return Future.error("Upload failed: $e");
    }
  }

  Future<Map<String, dynamic>?> fetchPromoDetails(int promoId) async {
    final data = await _supabase.from('promos').select().eq('id', promoId).maybeSingle();
    return data;
  }

  Future<void> updatePromoStatus({
    required int promoId,
    required bool isActive,
    required DateTime startAt,
    required DateTime endAt,
    String? imageUrl,
  }) async {
    final Map<String, dynamic> data = {
      'is_active': isActive,
      'start_at': startAt.toIso8601String(),
      'end_at': endAt.toIso8601String(),
    };
    if (imageUrl != null) data['image_url'] = imageUrl;
    
    await _supabase.from('promos').update(data).eq('id', promoId);
  }

  Future<void> savePromo(PromoModel promo) async {
    final data = {
      'title': promo.title,
      'description': promo.description,
      'price': promo.price,
      'image_url': promo.imageUrl,
      'start_at': promo.startAt.toIso8601String(),
      'end_at': promo.endAt.toIso8601String(),
      'is_active': promo.isActive,
    };
    
    if (promo.id != null) {
      await _supabase.from('promos').update(data).eq('id', promo.id!);
    } else {
      await _supabase.from('promos').insert(data);
    }
  }

  Future<void> deleteService(int tdId) async {
    // ... soft delete logic ...
    try {
      await _supabase
          .from('treatment_details')
          .update({'is_active': false})
          .eq('id', tdId);
    } catch (e) {
      debugPrint("Soft delete failed, attempting hard delete: $e");
      await _supabase
          .from('treatment_details')
          .delete()
          .eq('id', tdId);
    }
  }

  Future<void> saveService({
    required bool isEdit,
    ServiceModel? existingService,
    required String treatmentName,
    required String detailName,
    required String category,
    required int price,
    required int duration,
    String? imageUrl,
  }) async {
    // Get or create category
    final catResult = await _supabase.from('categories').select('id').eq('name', category).maybeSingle();
    int catId;
    if (catResult != null) {
      catId = catResult['id'];
    } else {
      final newCat = await _supabase.from('categories').insert({'name': category}).select('id').single();
      catId = newCat['id'];
    }

    if (isEdit && existingService != null) {
      // Update treatment detail
      final Map<String, dynamic> updateData = {
        'name': detailName.isEmpty ? treatmentName : detailName,
        'price': price,
        'duration': duration,
      };
      if (imageUrl != null) updateData['image_url'] = imageUrl;
      
      await _supabase.from('treatment_details').update(updateData).eq('id', existingService.tdId);

      // Update treatment name if changed
      await _supabase.from('treatments').update({
        'name': treatmentName,
        'category_id': catId,
      }).eq('id', existingService.treatmentId);
    } else {
      // Get or create treatment
      final treatmentResult = await _supabase.from('treatments')
          .select('id').eq('name', treatmentName).eq('category_id', catId).maybeSingle();
      int treatmentId;
      if (treatmentResult != null) {
        treatmentId = treatmentResult['id'];
      } else {
        final Map<String, dynamic> treatData = {
          'name': treatmentName,
          'category_id': catId,
        };
        try {
          if (imageUrl != null) treatData['image'] = imageUrl; // Some schemas use 'image'
          final newTreatment = await _supabase.from('treatments').insert(treatData).select('id').single();
          treatmentId = newTreatment['id'];
        } catch (e) {
          treatData.remove('image');
          final newTreatment = await _supabase.from('treatments').insert(treatData).select('id').single();
          treatmentId = newTreatment['id'];
        }
      }

      // Create new treatment detail
      final Map<String, dynamic> detailData = {
        'treatment_id': treatmentId,
        'name': detailName.isEmpty ? treatmentName : detailName,
        'price': price,
        'duration': duration,
      };
      if (imageUrl != null) detailData['image_url'] = imageUrl;
      
      await _supabase.from('treatment_details').insert(detailData);
    }
  }
}
