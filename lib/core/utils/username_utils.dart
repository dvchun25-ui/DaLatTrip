/// Class hỗ trợ normalize, validate và tạo username mặc định
class UsernameUtils {
  /// Danh sách các từ khóa hệ thống không được dùng làm username
  static const Set<String> reservedKeywords = {
    'admin',
    'administrator',
    'support',
    'dalattrip',
    'system',
    'root',
    'official',
    'help',
    'moderator',
    'dalat',
  };

  /// Biến đổi tiếng Việt có dấu thành không dấu
  static String removeVietnameseDiacritics(String text) {
    var str = text;
    final vietnameseSigns = [
      'aàáảãạâầấẩẫậăằắẳẵặ',
      'AÀÁẢÃẠÂẦẤẨẪẬĂẰẮẲẴẶ',
      'eèéẻẽẹêềếểễệ',
      'EÈÉẺẼẸÊỀẾỂỄỆ',
      'iìíỉĩị',
      'IÌÍỈĨỊ',
      'oòóỏõọôồốổỗộơờớởỡợ',
      'OÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢ',
      'uùúủũụưừứửữự',
      'UÙÚỦŨỤƯỪỨỬỮỰ',
      'yỳýỷỹỵ',
      'YỲÝỶỸỴ',
      'dđ',
      'DĐ',
    ];

    final replacements = ['a', 'A', 'e', 'E', 'i', 'I', 'o', 'O', 'u', 'U', 'y', 'Y', 'd', 'D'];

    for (int i = 0; i < vietnameseSigns.length; i++) {
      for (int j = 0; j < vietnameseSigns[i].length; j++) {
        str = str.replaceAll(vietnameseSigns[i][j], replacements[i]);
      }
    }
    return str;
  }

  /// Normalize username: lowercase, không khoảng trắng, lọc ký tự hợp lệ
  static String normalizeUsername(String input) {
    if (input.isEmpty) return '';

    // Bỏ dấu tiếng Việt
    var normalized = removeVietnameseDiacritics(input.trim());

    // Lowercase
    normalized = normalized.toLowerCase();

    // Chỉ giữ lại: a-z, 0-9, _, .
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9_.]'), '');

    // Bỏ dấu . thừa ở đầu và cuối
    while (normalized.startsWith('.')) {
      normalized = normalized.substring(1);
    }
    while (normalized.endsWith('.')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    return normalized;
  }

  /// Validation username
  /// Trả về message lỗi nếu không hợp lệ, hoặc null nếu hợp lệ
  static String? validateUsername(String rawInput) {
    final username = normalizeUsername(rawInput);

    if (username.isEmpty) {
      return 'Vui lòng nhập tên người dùng';
    }

    if (username.length < 4) {
      return 'Tên người dùng phải từ 4 ký tự trở lên';
    }

    if (username.length > 20) {
      return 'Tên người dùng không được vượt quá 20 ký tự';
    }

    // Kiểm tra ký tự không hợp lệ
    final validPattern = RegExp(r'^[a-z0-9_.]+$');
    if (!validPattern.hasMatch(username)) {
      return 'Chỉ được dùng chữ cái (a-z), số (0-9), dấu gạch dưới (_) và dấu chấm (.)';
    }

    // Không được chứa khoảng trắng
    if (rawInput.contains(' ')) {
      return 'Tên người dùng không được chứa khoảng trắng';
    }

    // Không được bắt đầu hoặc kết thúc bằng dấu chấm
    if (rawInput.trim().startsWith('.') || rawInput.trim().endsWith('.')) {
      return 'Không được bắt đầu hoặc kết thúc bằng dấu chấm';
    }

    // Từ khóa hệ thống
    if (reservedKeywords.contains(username)) {
      return 'Tên người dùng này dành cho hệ thống, vui lòng chọn tên khác';
    }

    return null;
  }

  /// Tạo username mặc định từ email
  /// Ví dụ: vanchung211@gmail.com -> vanchung211
  static String generateDefaultUsername(String email) {
    if (email.isEmpty || !email.contains('@')) {
      final randSuffix = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
      return 'user_$randSuffix';
    }

    final prefix = email.split('@').first;
    var baseUsername = normalizeUsername(prefix);

    if (baseUsername.length < 4) {
      baseUsername = '${baseUsername}_user';
    }

    if (baseUsername.length > 20) {
      baseUsername = baseUsername.substring(0, 20);
    }

    return baseUsername;
  }
}
