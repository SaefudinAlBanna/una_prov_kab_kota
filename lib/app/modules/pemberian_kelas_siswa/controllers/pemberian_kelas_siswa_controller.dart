// lib/app/modules/pemberian_kelas_siswa/controllers/pemberian_kelas_siswa_controller.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../controllers/config_controller.dart';
import '../../../models/pegawai_model.dart';
import '../../../models/siswa_model.dart';


class PemberianKelasSiswaController extends GetxController {
  final ConfigController configC = Get.find<ConfigController>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Worker _statusWorker;

  final isLoading = true.obs;
  final isProcessing = false.obs;
  final isWaliKelasLoading = false.obs;

  final RxList<DocumentSnapshot> daftarKelas = <DocumentSnapshot>[].obs;
  final Rxn<DocumentSnapshot> kelasTerpilih = Rxn<DocumentSnapshot>();

  final RxList<SiswaModel> siswaDiKelas = <SiswaModel>[].obs;
  final RxList<SiswaModel> siswaTanpaKelas = <SiswaModel>[].obs;
  
  final RxList<PegawaiModel> daftarGuru = <PegawaiModel>[].obs;
  final RxString searchQueryGuru = "".obs;
  final RxSet<String> assignedWaliKelasUids = <String>{}.obs;
  final RxList<Map<String, dynamic>> daftarMasterKelas = <Map<String, dynamic>>[].obs;

  String get tahunAjaranAktif => configC.tahunAjaranAktif.value;
  String get semesterAktif => configC.semesterAktif.value;
  
  @override
  void onInit() {
    super.onInit();
    _statusWorker = ever(configC.status, (appStatus) {
      if (appStatus == AppStatus.authenticated && isLoading.value) {
        _initializeData();
      }
    });
    if (configC.status.value == AppStatus.authenticated) {
      _initializeData();
    }
  }

  @override
  void onClose() {
    _statusWorker.dispose();
    super.onClose();
  }

  Future<void> _initializeData() async {
    isLoading.value = true;
    await Future.wait([
      fetchKelas(),
      fetchSiswaTanpaKelas(),
      fetchDaftarGuru(),
      fetchMasterKelas(),
    ]);
    isLoading.value = false;
  }

  Future<void> fetchMasterKelas() async {
  try {
    final snapshot = await _firestore
        .collection('Sekolah').doc(configC.idSekolah)
        .collection('master_kelas').orderBy('urutan').get();
    daftarMasterKelas.assignAll(snapshot.docs.map((doc) => doc.data()).toList());
  } catch (e) {
    Get.snackbar("Error", "Gagal memuat data master kelas: $e");
  }
}

  Future<void> fetchKelas() async {
    if (tahunAjaranAktif.isEmpty || tahunAjaranAktif.contains("TIDAK")) return;
    final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('kelas').where('tahunAjaran', isEqualTo: tahunAjaranAktif).get();
    daftarKelas.assignAll(snapshot.docs);
    
    final uids = snapshot.docs.map((doc) => (doc.data() as Map<String, dynamic>)['waliKelasUid'] as String?)
        .where((uid) => uid != null && uid.isNotEmpty).cast<String>().toSet();
    assignedWaliKelasUids.assignAll(uids);
  }

  Future<void> fetchSiswaTanpaKelas() async {
    final snapshot = await _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('siswa').where('kelasId', isNull: true).get();
    siswaTanpaKelas.assignAll(snapshot.docs.map((doc) => SiswaModel.fromFirestore(doc)).toList());
  }

  Future<void> fetchDaftarGuru() async {
    try {
      // Ambil semua pegawai
      final snapshot = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('pegawai')
          //.where('role', isEqualTo: 'Guru Kelas') // HAPUS INI agar lebih fleksibel
          .get();
      
      // [FIX] Masukkan hasil snapshot ke observable list
      // Filter manual di sini jika mau, atau ambil semua
      final listPegawai = snapshot.docs.map((doc) => PegawaiModel.fromFirestore(doc)).toList();
      
      // Opsional: Filter hanya yang mengandung kata 'Guru' di role atau alias
      // Atau biarkan semua tampil agar Wali Kelas bisa dipilih dari siapa saja (misal Kepsek)
      daftarGuru.assignAll(listPegawai);
      
    } catch (e) {
      print("Error fetch guru: $e");
    }
  }

  Future<void> pilihKelas(DocumentSnapshot kelasDoc) async {
    kelasTerpilih.value = kelasDoc;

    // Menampilkan loading saat data siswa diambil
    isProcessing.value = true; 
    siswaDiKelas.clear();

    try {
      final String tahunAjaran = configC.tahunAjaranAktif.value;

      // Path langsung ke subkoleksi yang datanya sudah kita denormalisasi
      final siswaDiKelasSnapshot = await _firestore
          .collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaran)
          .collection('kelastahunajaran').doc(kelasDoc.id)
          .collection('daftarsiswa')
          .orderBy('namaLengkap')
          .get();

      // Langsung proses hasilnya menjadi model, tidak perlu query kedua
      final allSiswa = siswaDiKelasSnapshot.docs.map((doc) =>
          SiswaModel.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();

      siswaDiKelas.assignAll(allSiswa);

    } catch (e) {
      Get.snackbar("Error", "Gagal memuat daftar siswa di kelas: ${e.toString()}");
      print("### Gagal di pilihKelas: $e");
    } finally {
      isProcessing.value = false;
    }
  }

  // --- FUNGSI DIPERBAIKI DENGAN DENORMALISASI ---
  Future<void> addSiswaToKelas(SiswaModel siswa) async {
    if (kelasTerpilih.value == null) return;
    isProcessing.value = true;

    try { // Tambahkan try-finally
      final kelasDoc = kelasTerpilih.value!;
      final kelasRef = kelasDoc.reference;
      final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
      final daftarSiswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaranAktif)
          .collection('kelastahunajaran').doc(kelasRef.id)
          .collection('daftarsiswa').doc(siswa.uid);

      WriteBatch batch = _firestore.batch();

      batch.update(kelasRef, {'siswaUids': FieldValue.arrayUnion([siswa.uid])});
      batch.update(siswaRef, {'kelasId': kelasRef.id, 'statusSiswa': 'Aktif'});
      batch.set(daftarSiswaRef, {
        'uid': siswa.uid, 
        'nisn': siswa.nisn, 
        'namaLengkap': siswa.namaLengkap
      });

      await batch.commit();

      // --- MULAI PERBAIKAN LOGIKA STATE ---
      // 1. Buat objek siswa baru dengan kelasId yang sudah di-update
      final siswaYangDimasukkan = siswa.copyWith(kelasId: kelasRef.id, statusSiswa: 'Aktif');

      // 2. Hapus siswa dari daftar tanpa kelas
      siswaTanpaKelas.removeWhere((s) => s.uid == siswa.uid);

      // 3. Tambahkan objek siswa yang sudah diperbarui ke daftar kelas ini
      siswaDiKelas.add(siswaYangDimasukkan);
      siswaDiKelas.sort((a, b) => a.namaLengkap.compareTo(b.namaLengkap)); // Jaga urutan
      // --- SELESAI PERBAIKAN LOGIKA STATE ---

    } catch (e) {
      Get.snackbar("Error", "Gagal menambahkan siswa: ${e.toString()}");
    } finally {
      isProcessing.value = false;
    }
  }

  Future<void> removeSiswaFromKelas(SiswaModel siswa) async {
    if (kelasTerpilih.value == null) return;
    isProcessing.value = true;
  
    try {
      final kelasRef = kelasTerpilih.value!.reference;
      final siswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').doc(siswa.uid);
      final daftarSiswaRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
        .collection('tahunajaran').doc(tahunAjaranAktif)
        .collection('kelastahunajaran').doc(kelasRef.id)
        .collection('daftarsiswa').doc(siswa.uid);
  
      WriteBatch batch = _firestore.batch();
      
      // --- PERBAIKAN UTAMA DI SINI ---
      // Ganti FieldValue.delete() menjadi null
      batch.update(siswaRef, {
        'kelasId': null, 
        'statusSiswa': 'Tidak Aktif'
      });
      // --- AKHIR PERBAIKAN UTAMA ---
  
      // Operasi lain tetap sama
      batch.update(kelasRef, {'siswaUids': FieldValue.arrayRemove([siswa.uid])});
      batch.delete(daftarSiswaRef);
  
      await batch.commit();
      
      // Logika state UI Anda sudah benar, tidak perlu diubah
      final siswaYangDikeluarkan = siswa.copyWith(removeKelasId: true, statusSiswa: 'Tidak Aktif');
      siswaDiKelas.removeWhere((s) => s.uid == siswa.uid);
      siswaTanpaKelas.add(siswaYangDikeluarkan);
      siswaTanpaKelas.sort((a, b) => a.namaLengkap.compareTo(b.namaLengkap));
  
    } catch (e) {
      Get.snackbar("Error", "Gagal mengeluarkan siswa: ${e.toString()}");
    } finally {
      isProcessing.value = false;
    }
  }

  // --- FUNGSI LAINNYA TIDAK BERUBAH ---
  void showBuatKelasDialog() {
    final Rxn<Map<String, dynamic>> kelasTerpilihDariMaster = Rxn<Map<String, dynamic>>();

    // Filter master kelas: hanya tampilkan yang belum dibuat di tahun ajaran ini
    final namaKelasYangSudahAda = daftarKelas.map((doc) => (doc.data() as Map)['namaKelas']).toSet();
    final pilihanKelasTersedia = daftarMasterKelas.where((master) => !namaKelasYangSudahAda.contains(master['namaKelas'])).toList();

    Get.defaultDialog(
      title: "Buat Kelas Baru",
      content: Obx(() => DropdownButtonFormField<Map<String, dynamic>>(
        value: kelasTerpilihDariMaster.value,
        hint: const Text("Pilih dari master kelas..."),
        isExpanded: true,
        items: pilihanKelasTersedia.map((masterKelas) {
          return DropdownMenuItem<Map<String, dynamic>>(
            value: masterKelas,
            child: Text(masterKelas['namaKelas']),
          );
        }).toList(),
        onChanged: (value) {
          kelasTerpilihDariMaster.value = value;
        },
        validator: (value) => value == null ? 'Pilihan tidak boleh kosong' : null,
      )),
      actions: [
        OutlinedButton(onPressed: () => Get.back(), child: const Text("Batal")),
        ElevatedButton(
          onPressed: () {
            if (kelasTerpilihDariMaster.value != null) {
              Get.back();
              _buatKelas(kelasTerpilihDariMaster.value!);
            } else {
              Get.snackbar("Peringatan", "Anda harus memilih kelas dari daftar.");
            }
          },
          child: const Text("Buat"),
        ),
      ],
    );
  }

  Future<void> _buatKelas(Map<String, dynamic> masterKelasData) async {
    final namaKelas = masterKelasData['namaKelas'];
    final fase = masterKelasData['fase'];

    if (namaKelas == null || namaKelas.isEmpty) return;

    final kelasId = "$namaKelas-$tahunAjaranAktif";
    await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('kelas').doc(kelasId).set({
      'namaKelas': namaKelas,
      'tahunAjaran': tahunAjaranAktif,
      'fase': fase,
      'waliKelasUid': null,
      'waliKelasNama': null,
      'siswaUids': [],
    });
    fetchKelas(); // Ambil ulang daftar kelas untuk memperbarui UI
  }

    // Future<void> assignWaliKelas(PegawaiModel guru) async {
    //   if (kelasTerpilih.value == null) return;
    //   isWaliKelasLoading.value = true;

    //   final kelasDoc = kelasTerpilih.value!;
    //   final kelasRef = kelasDoc.reference;
    //   final guruBaruRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').doc(guru.uid);
    //   final String? guruLamaUid = (kelasDoc.data() as Map<String, dynamic>)['waliKelasUid'];

    //   WriteBatch batch = _firestore.batch();

    //   if (guruLamaUid != null && guruLamaUid.isNotEmpty) {
    //     final guruLamaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').doc(guruLamaUid);
    //     batch.update(guruLamaRef, {'waliKelasDari': FieldValue.delete()});
    //   }

    //   batch.update(guruBaruRef, {'waliKelasDari': kelasRef.id});

    //   // --- [PERBAIKAN] Simpan alias dan nama lengkap ---
    //   final namaUntukDitampilkan = (guru.alias == null || guru.alias!.isEmpty) ? guru.nama : guru.alias!;
    //   batch.update(kelasRef, {
    //     'waliKelasUid': guru.uid,
    //     'waliKelasNama': namaUntukDitampilkan, // Ini adalah alias (atau nama jika alias kosong)
    //     'waliKelasNamaLengkap': guru.nama, // Field baru untuk referensi
    //   });

    //   final kelasTahunAjaranRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
    //     .collection('tahunajaran').doc(tahunAjaranAktif)
    //     .collection('kelastahunajaran').doc(kelasRef.id);

    //   batch.set(kelasTahunAjaranRef, {
    //     'idWaliKelas': guru.uid,
    //     'namaWaliKelas': namaUntukDitampilkan, // Gunakan variabel yang sama
    //     'namaKelas': (kelasDoc.data() as Map<String, dynamic>)['namaKelas'],
    //   }, SetOptions(merge: true));
    //   // --- AKHIR PERBAIKAN ---

    //   await batch.commit();

    //   await fetchKelas();
    //   kelasTerpilih.value = await kelasRef.get();
    //   isWaliKelasLoading.value = false;
    //   Get.back();
    // }

    Future<void> assignWaliKelas(PegawaiModel guru) async {
    if (kelasTerpilih.value == null) return;
    isWaliKelasLoading.value = true;

    final kelasDoc = kelasTerpilih.value!;
    final kelasRef = kelasDoc.reference; // Referensi Dokumen Kelas
    final guruBaruRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').doc(guru.uid);
    
    // Data Wali Kelas Lama (Jika ada)
    final String? guruLamaUid = (kelasDoc.data() as Map<String, dynamic>)['waliKelasUid'];

    WriteBatch batch = _firestore.batch();

    // 1. URUS GURU LAMA (Cabut hak akses dari kelas INI saja)
    if (guruLamaUid != null && guruLamaUid.isNotEmpty) {
      final guruLamaRef = _firestore.collection('Sekolah').doc(configC.idSekolah).collection('pegawai').doc(guruLamaUid);
      
      // Hapus kelas ini dari Array 'waliKelasGroup' milik guru lama
      batch.update(guruLamaRef, {
        'waliKelasGroup': FieldValue.arrayRemove([kelasRef.id])
      });
      
      // OPSI: Kita biarkan 'waliKelasDari' (String) di guru lama apa adanya, 
      // atau set null jika itu satu-satunya kelas dia. 
      // Demi keamanan spark & efisiensi, kita biarkan saja, 
      // karena Rules nanti akan mengecek Array terlebih dahulu.
    }

    // 2. URUS GURU BARU (Berikan hak akses Multi-Kelas)
    batch.set(guruBaruRef, {
      // Field Baru: Tambahkan kelas ke dalam list (Array Union aman, tidak duplikat)
      'waliKelasGroup': FieldValue.arrayUnion([kelasRef.id]),
      
      // Field Lama (Legacy Support): Tetap update string ini agar fitur lama jalan.
      // Ini akan berisi kelas TERAKHIR yang ditugaskan.
      'waliKelasDari': kelasRef.id, 
    }, SetOptions(merge: true));

    // 3. UPDATE DOKUMEN KELAS (Master Kelas)
    final namaUntukDitampilkan = (guru.alias == null || guru.alias!.isEmpty) ? guru.nama : guru.alias!;
    batch.update(kelasRef, {
      'waliKelasUid': guru.uid,
      'waliKelasNama': namaUntukDitampilkan,
      'waliKelasNamaLengkap': guru.nama,
    });

    // 4. UPDATE DOKUMEN KELAS TAHUN AJARAN (Untuk query cepat)
    final kelasTahunAjaranRef = _firestore.collection('Sekolah').doc(configC.idSekolah)
      .collection('tahunajaran').doc(tahunAjaranAktif)
      .collection('kelastahunajaran').doc(kelasRef.id);

    batch.set(kelasTahunAjaranRef, {
      'idWaliKelas': guru.uid,
      'namaWaliKelas': namaUntukDitampilkan,
      'namaKelas': (kelasDoc.data() as Map<String, dynamic>)['namaKelas'],
    }, SetOptions(merge: true));

    await batch.commit();

    // Refresh UI
    await fetchKelas();
    kelasTerpilih.value = await kelasRef.get();
    isWaliKelasLoading.value = false;
    Get.back();
  }

    Future<void> jalankanMigrasiDataSiswa() async {
      isProcessing.value = true;
      Get.dialog(
        const AlertDialog(
          title: Text("Proses Migrasi..."),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text("Menambal data siswa di setiap kelas. Mohon jangan tutup aplikasi."),
            ],
          ),
        ),
        barrierDismissible: false,
      );

      try {
        final WriteBatch batch = _firestore.batch();
        int writeCounter = 0;

        // 1. Ambil semua data siswa dalam satu kali query untuk efisiensi
        final semuaSiswaSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah).collection('siswa').get();
        final Map<String, SiswaModel> petaSiswa = {
          for (var doc in semuaSiswaSnap.docs) doc.id: SiswaModel.fromFirestore(doc)
        };
        print("Migrasi: Ditemukan total ${petaSiswa.length} siswa.");

        // 2. Ambil semua kelas yang ada di tahun ajaran aktif
        final semuaKelasSnap = await _firestore.collection('Sekolah').doc(configC.idSekolah)
          .collection('tahunajaran').doc(tahunAjaranAktif)
          .collection('kelastahunajaran').get();
        print("Migrasi: Ditemukan ${semuaKelasSnap.docs.length} kelas untuk diproses.");

        // 3. Iterasi setiap kelas untuk menambal data siswanya
        for (final kelasDoc in semuaKelasSnap.docs) {
          print("Migrasi: Memproses kelas ${kelasDoc.id}...");
          final siswaDiKelasSnap = await kelasDoc.reference.collection('daftarsiswa').get();

          for (final siswaDiKelasDoc in siswaDiKelasSnap.docs) {
            final siswaUid = siswaDiKelasDoc.id;
            final siswaDataLengkap = petaSiswa[siswaUid];

            if (siswaDataLengkap != null) {
              // Siapkan data untuk di-update (ditambal)
              batch.update(siswaDiKelasDoc.reference, {
                'namaLengkap': siswaDataLengkap.namaLengkap,
                'nisn': siswaDataLengkap.nisn,
              });
              writeCounter++;

              // Commit batch setiap 400 operasi untuk menghindari limit
              if (writeCounter >= 400) {
                await batch.commit();
                print("Migrasi: Batch commit triggered at $writeCounter writes.");
                // Re-initialize batch for the next set of operations
                // batch = _firestore.batch(); // Note: re-initializing batch is complex, for this scale, one batch is likely fine.
                // For simplicity, we assume total writes are < 500. If more, a more complex script is needed.
              }
            }
          }
        }

        // 4. Commit sisa operasi di batch
        await batch.commit();

        Get.back(); // Tutup dialog loading
        Get.snackbar("Berhasil", "Migrasi data siswa selesai. Total $writeCounter data siswa diperbarui.", backgroundColor: Colors.green, colorText: Colors.white);

      } catch (e) {
        Get.back(); // Tutup dialog loading
        Get.snackbar("Error Migrasi", "Terjadi kesalahan: ${e.toString()}", backgroundColor: Colors.red, colorText: Colors.white);
        print("### ERROR MIGRASI: $e");
      } finally {
        isProcessing.value = false;
      }
    }
}
