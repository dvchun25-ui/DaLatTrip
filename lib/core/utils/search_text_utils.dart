class SearchTextUtils {
  SearchTextUtils._();

  static String normalize(String value) {
    const accented =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const plain =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    var normalized = value.trim().toLowerCase();
    for (var index = 0; index < accented.length; index++) {
      normalized = normalized.replaceAll(accented[index], plain[index]);
    }
    return normalized.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }
}
