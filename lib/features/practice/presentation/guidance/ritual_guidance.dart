class RitualGuidance {
  const RitualGuidance({
    required this.id,
    required this.title,
    required this.body,
    required this.steps,
    this.ritualLabel,
    this.ritualText,
  });

  final String id;
  final String title;
  final String body;
  final List<String> steps;
  final String? ritualLabel;
  final String? ritualText;
}

class RitualGuidanceCatalog {
  static const miqatNiyyah = RitualGuidance(
    id: 'miqat_niyyah',
    title: 'Miqat & Niyyah',
    body:
        'Anda sudah hampir dengan kawasan Miqat. Fokuskan niat Umrah sebelum meneruskan perjalanan.',
    ritualLabel: 'Contoh lafaz niat',
    ritualText:
        'Sahaja aku mengerjakan Umrah dan aku berihram dengannya kerana Allah Taala.',
    steps: [
      'Pastikan pakaian ihram dan niat sudah bersedia.',
      'Selepas berniat, teruskan talbiyah dan jaga larangan ihram.',
      'Teruskan ke Tawaf apabila sampai ke kawasan Kaabah.',
    ],
  );

  static const tawafStart = RitualGuidance(
    id: 'tawaf_start',
    title: 'Mula Tawaf',
    body:
        'Anda berada dalam zon Tawaf. Mulakan pusingan dengan tenang dan kekalkan arah pergerakan.',
    ritualLabel: 'Bacaan ringkas ketika mula',
    ritualText:
        'Mulakan dengan Bismillah, Allahu Akbar, kemudian berdoa mengikut kemampuan sepanjang Tawaf.',
    steps: [
      'Mulakan kiraan dari pusingan pertama.',
      'Pastikan berada dalam lingkungan kawasan Tawaf.',
      'Tekan Next dalam simulasi selepas satu pusingan lengkap.',
    ],
  );

  static const tawafRound = RitualGuidance(
    id: 'tawaf_round',
    title: 'Pusingan Tawaf Direkod',
    body:
        'Pusingan anda telah direkod. Teruskan sehingga lengkap tujuh pusingan.',
    ritualLabel: 'Doa semasa Tawaf',
    ritualText:
        'Teruskan zikir, istighfar, selawat, dan doa peribadi. Fokus kepada adab dan ketenangan ibadah.',
    steps: [
      'Semak kiraan pusingan pada panel Tawaf Rounds.',
      'Jika keluar zon, aplikasi akan simpan progress untuk disambung semula.',
      'Selesaikan tujuh pusingan sebelum bergerak ke Sai.',
    ],
  );

  static const tawafComplete = RitualGuidance(
    id: 'tawaf_complete',
    title: 'Tawaf Lengkap',
    body:
        'Alhamdulillah, tujuh pusingan Tawaf telah lengkap dalam simulasi ini.',
    ritualLabel: 'Selepas Tawaf',
    ritualText:
        'Baca doa kesyukuran dan mohon agar ibadah diterima sebelum bergerak ke Sai.',
    steps: [
      'Semak semula status pusingan sebelum keluar.',
      'Langkah seterusnya ialah Sai antara Safa dan Marwa.',
      'Gunakan dashboard untuk bergerak ke modul Sai.',
    ],
  );

  static const saiMarwa = RitualGuidance(
    id: 'sai_marwa',
    title: 'Tiba di Marwa',
    body:
        'Anda telah sampai ke Marwa dalam simulasi Sai. Aplikasi akan menukar sasaran seterusnya.',
    ritualLabel: 'Doa di Marwa',
    ritualText:
        'Berdoa dengan hajat yang baik, perbanyakkan zikir, dan teruskan perjalanan ke Safa.',
    steps: [
      'Semak kiraan lap pada panel Sai Laps.',
      'Sasaran seterusnya ialah Safa.',
      'Teruskan ulang-alik sehingga tujuh lap lengkap.',
    ],
  );

  static const saiSafa = RitualGuidance(
    id: 'sai_safa',
    title: 'Tiba di Safa',
    body:
        'Anda telah sampai ke Safa dalam simulasi Sai. Teruskan perjalanan ke sasaran seterusnya.',
    ritualLabel: 'Doa di Safa',
    ritualText:
        'Berdoa dengan khusyuk, perbanyakkan zikir, dan teruskan perjalanan ke Marwa.',
    steps: [
      'Pastikan sasaran pada banner telah bertukar.',
      'Elakkan menekan Reach berulang kali untuk pusingan yang sama.',
      'Teruskan ke Marwa untuk lap berikutnya.',
    ],
  );

  static const saiComplete = RitualGuidance(
    id: 'sai_complete',
    title: 'Sai Lengkap',
    body: 'Alhamdulillah, tujuh lap Sai telah lengkap dalam simulasi ini.',
    ritualLabel: 'Selepas Sai',
    ritualText:
        'Baca doa kesyukuran dan semak semula langkah akhir Umrah mengikut panduan pembimbing.',
    steps: [
      'Semak kiraan akhir pada panel Sai Laps.',
      'Pastikan semua langkah utama Umrah telah diselesaikan.',
      'Gunakan keputusan ini sebagai rekod progress latihan.',
    ],
  );
}
