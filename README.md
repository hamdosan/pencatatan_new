# Catatan Keuangan

Aplikasi pencatatan keuangan pribadi berbasis Flutter dengan arsitektur **MVC**,
tampilan Material 3 (mode terang & gelap), dan tata letak responsif untuk
ponsel, tablet, hingga desktop.

## Fitur

- Catat pemasukan & pengeluaran (jumlah, judul, kategori, tanggal, catatan)
- Beranda: total saldo, ringkasan bulan berjalan, rasio tabungan, transaksi terakhir
- Riwayat: pencarian, filter jenis, dikelompokkan per hari, geser untuk hapus (+ undo)
- Statistik: pilih bulan, grafik donat per kategori, rincian persentase, tren 6 bulan
- Data tersimpan lokal (SharedPreferences), mode gelap, format Rupiah & tanggal Indonesia
- Data contoh sekali klik untuk mencoba aplikasi

## Arsitektur MVC

```
lib/
├── main.dart                 # bootstrap: inisialisasi & load data
├── app.dart                  # MaterialApp, tema, lokalisasi, scope controller
├── models/                   # MODEL — data & akses penyimpanan
│   ├── transaction_model.dart
│   ├── category_model.dart
│   ├── transaction_type.dart
│   ├── summary_models.dart
│   ├── transaction_repository.dart
│   └── settings_repository.dart
├── controllers/              # CONTROLLER — logika bisnis & state
│   ├── transaction_controller.dart
│   ├── settings_controller.dart
│   └── controller_scope.dart # InheritedNotifier: menyambungkan controller ke view
├── views/                    # VIEW — UI murni
│   ├── screens/              # main_shell, dashboard, transactions, statistics, form
│   └── widgets/              # komponen UI yang dapat dipakai ulang
├── theme/app_theme.dart
└── utils/                    # formatter Rupiah/tanggal, breakpoint responsif
```

Alurnya: **View** memanggil method di **Controller** (mis. `add`, `setFilter`),
Controller mengubah **Model** dan menyimpannya lewat repository, lalu
`notifyListeners()` membuat View yang bergantung otomatis rebuild.

## Responsif

| Lebar layar | Navigasi                       | Tata letak                              |
|-------------|--------------------------------|-----------------------------------------|
| < 600       | NavigationBar bawah + FAB      | satu kolom, form layar penuh            |
| 600 – 1023  | NavigationRail ringkas         | konten dibatasi lebar, form dalam dialog |
| ≥ 1024      | NavigationRail diperluas       | dua kolom di Beranda & Statistik        |

## Menjalankan

Butuh Flutter SDK 3.27 atau lebih baru.

```powershell
cd D:\Flutter\catatan_keuangan
flutter create --project-name catatan_keuangan --platforms android,ios .
flutter pub get
flutter test
flutter run
```

`flutter create .` hanya menambahkan folder platform (android/ios) dan tidak
menimpa file di `lib/` maupun `test/` yang sudah ada.
