/// Lokasi rilis APK di GitHub Releases.
///
/// Isi dengan akun dan nama repo GitHub tempat APK di-upload, mis.
/// repo https://github.com/budi/expense_tracker -> owner 'budi',
/// repo 'expense_tracker'. Repo harus public agar bisa dicek tanpa login.
///
/// Setiap rilis wajib:
/// - tag sesuai versi di pubspec.yaml, mis. `v1.0.1+2`
/// - melampirkan satu file `.apk`
const kUpdateRepoOwner = 'hamdosan';
const kUpdateRepoName = 'pencatatan_apk';

bool get isUpdateConfigured =>
    kUpdateRepoOwner.isNotEmpty && kUpdateRepoName.isNotEmpty;
