import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_model.dart';

class ServiceController {
  final _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>> fetchServicesAndCategories() async {
    final catData = await _supabase
        .from('categories')
        .select('id, name')
        .order('name');

    final svcData = await _supabase
        .from('treatment_details')
        .select('id, name, duration, price, treatment_id, treatments(id, name, category_id, categories(id, name))')
        .order('id');

    final cats = ['All', ...List<Map<String, dynamic>>.from(catData).map((c) => c['name'] as String)];

    final services = List<Map<String, dynamic>>.from(svcData).map<ServiceModel>((td) {
      final treatment = td['treatments'] as Map<String, dynamic>?;
      final category = treatment?['categories'] as Map<String, dynamic>?;
      final treatmentName = treatment?['name'] ?? '';
      final detailName = td['name'] ?? '';
      final displayName = (treatmentName == detailName || detailName.isEmpty)
          ? treatmentName
          : "$treatmentName - $detailName";
          
      return ServiceModel(
        tdId: td['id'],
        treatmentId: td['treatment_id'],
        treatmentName: treatmentName,
        detailName: detailName,
        displayName: displayName,
        category: category?['name'] ?? '',
        duration: (td['duration'] as num?)?.toInt() ?? 0,
        price: (td['price'] as num?)?.toInt() ?? 0,
      );
    }).toList();

    return {
      'categories': cats,
      'services': services,
    };
  }

  Future<void> deleteService(int tdId) async {
    await _supabase
        .from('treatment_details')
        .delete()
        .eq('id', tdId);
  }

  Future<void> saveService({
    required bool isEdit,
    ServiceModel? existingService,
    required String treatmentName,
    required String detailName,
    required String category,
    required int price,
    required int duration,
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
      await _supabase.from('treatment_details').update({
        'name': detailName.isEmpty ? treatmentName : detailName,
        'price': price,
        'duration': duration,
      }).eq('id', existingService.tdId);

      // Also update the treatment name if changed
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
        final newTreatment = await _supabase.from('treatments').insert({
          'name': treatmentName,
          'category_id': catId,
        }).select('id').single();
        treatmentId = newTreatment['id'];
      }

      // Create new treatment detail
      await _supabase.from('treatment_details').insert({
        'treatment_id': treatmentId,
        'name': detailName.isEmpty ? treatmentName : detailName,
        'price': price,
        'duration': duration,
      });
    }
  }
}
