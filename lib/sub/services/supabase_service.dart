// lib/services/supabase_service.dart

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _mediaBucket = 'news-media'; 
  
  // دالة رفع ملفات XFile إلى Supabase Storage وإرجاع قائمة الروابط العامة
  Future<List<String>> uploadFiles(List<XFile> files, Function(double) onProgress) async {
    List<String> downloadUrls = [];
    final int totalFiles = files.length;
    
    for (int i = 0; i < totalFiles; i++) {
        final file = files[i];
        final fileExtension = file.name.split('.').last;
        final fileName = 'news_media/${DateTime.now().millisecondsSinceEpoch}_$i.${fileExtension}';

        try {
            // 1. تنفيذ عملية الرفع (بدون onUploadProgress)
            await _supabase.storage.from(_mediaBucket).upload(
                fileName,
                File(file.path),
                fileOptions: const FileOptions(
                    cacheControl: '3600', 
                    upsert: false,
                ),
            );
            
            // 2. الحصول على رابط الـ URL العام
            final url = _supabase.storage.from(_mediaBucket).getPublicUrl(fileName);
            downloadUrls.add(url);
            
            // 3. تحديث شريط التقدم الكلي بناءً على الملفات المكتملة
            final overallProgress = (i + 1) / totalFiles;
            onProgress(overallProgress); // تحديث التقدم بعد اكتمال رفع ملف واحد

        } on StorageException catch (e) {
            throw Exception('فشل الرفع إلى Supabase: ${e.message}');
        } catch (e) {
            rethrow; 
        }
    }
    return downloadUrls;
  }
}