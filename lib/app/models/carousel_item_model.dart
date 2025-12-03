import 'package:flutter/material.dart';

// Enum Sesuai Refrensi Kapten + Tambahan 'Info' & 'Prioritas' untuk pengumuman umum
enum CarouselContentType { 
  SedangBerlangsung, 
  Berikutnya, 
  RekapAbsensi, 
  PesanDefault, 
  Info, // Tambahan untuk pengumuman kalender
  Prioritas // Tambahan untuk pesan pimpinan
}

class CarouselItemModel {
  final String namaKelas;
  final CarouselContentType tipeKonten; // Rename dari 'tipe' ke 'tipeKonten' sesuai refrensi
  final String judul;
  final String isi;
  final String? subJudul;
  
  // Properti Visual (Tetap kita butuhkan agar View tidak error)
  final IconData ikon;
  final Color warna;

  CarouselItemModel({
    required this.namaKelas,
    required this.tipeKonten,
    required this.judul,
    required this.isi,
    this.subJudul,
    required this.ikon,
    required this.warna,
  });
}