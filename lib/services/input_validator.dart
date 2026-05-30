import 'dart:typed_data';

/// Centralized input validation and sanitization for all user-facing inputs.
/// Prevents injection attacks, enforces length/format constraints, and
/// sanitizes text before it reaches the database or AI prompts.
class InputValidator {
  InputValidator._();

  // ── Length limits ──

  static const int maxNameLength = 50;
  static const int maxMessageLength = 2000;
  static const int maxSurpriseTextLength = 5000;
  static const int maxDareResponseLength = 500;
  static const int maxJudgeNameLength = 60;
  static const int maxRoomNameLength = 50;
  static const int maxQuestTitleLength = 100;
  static const int maxQuestDescLength = 500;
  static const int maxSearchQueryLength = 100;
  static const int maxInviteCodeLength = 12;

  // ── File limits ──

  static const int maxImageBytes = 5 * 1024 * 1024; // 5 MB
  static const int maxAudioBytes = 10 * 1024 * 1024; // 10 MB
  static const Set<String> allowedImageExtensions = {'.jpg', '.jpeg', '.png', '.webp'};
  static const Set<String> allowedAudioExtensions = {'.m4a', '.aac', '.mp3', '.wav'};

  // ── Text sanitization ──

  /// Sanitizes user text: trims, enforces max length, strips control characters.
  static String sanitizeText(String input, {int maxLength = maxMessageLength}) {
    var text = input.trim();
    if (text.length > maxLength) {
      text = text.substring(0, maxLength);
    }
    text = _stripControlChars(text);
    return text;
  }

  /// Sanitizes text specifically before embedding in AI prompts.
  /// Strips patterns that could manipulate prompt structure.
  static String sanitizeForPrompt(String input, {int maxLength = maxMessageLength}) {
    var text = sanitizeText(input, maxLength: maxLength);
    text = text.replaceAll(RegExp(r'```'), '');
    text = text.replaceAll(RegExp(r'<\/?[a-zA-Z][^>]*>'), '');
    text = text.replaceAll(RegExp(r"""\{["']?\w+["']?\s*:"""), '{');
    return text;
  }

  /// Strips ASCII control characters (except newline and tab).
  static String _stripControlChars(String input) {
    return input.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
  }

  // ── Specific validators ──

  /// Validates a display name. Returns error message or null if valid.
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your name';
    final name = value.trim();
    if (name.length > maxNameLength) return 'Name must be $maxNameLength characters or fewer';
    if (RegExp(r'[<>{}\\\/]').hasMatch(name)) return 'Name contains invalid characters';
    return null;
  }

  /// Validates age. Returns error message or null if valid.
  static String? validateAge(String? value) {
    final age = int.tryParse((value ?? '').trim());
    if (age == null) return 'Enter a valid age';
    if (age < 13 || age > 120) return 'Age must be between 13 and 120';
    return null;
  }

  /// Validates gender is one of the allowed values.
  static bool isValidGender(String value) {
    return const {'male', 'female', 'na'}.contains(value);
  }

  /// Validates an invite code: alphanumeric only, reasonable length.
  static String? validateInviteCode(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter your friend\'s code';
    final code = value.trim().toUpperCase();
    if (code.length > maxInviteCodeLength) return 'Code is too long';
    if (!RegExp(r'^[A-Z0-9]+$').hasMatch(code)) return 'Code must be letters and numbers only';
    return null;
  }

  /// Validates a battle/chat message.
  static String? validateMessage(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter a message';
    if (value.trim().length > maxMessageLength) return 'Message is too long (max $maxMessageLength characters)';
    return null;
  }

  /// Validates surprise text content.
  static String? validateSurpriseContent(String? value) {
    if (value == null || value.trim().isEmpty) return 'Write something for your surprise';
    if (value.trim().length > maxSurpriseTextLength) {
      return 'Content is too long (max $maxSurpriseTextLength characters)';
    }
    return null;
  }

  /// Validates custom judge personality name.
  static String? validateJudgeName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter a personality name';
    if (value.trim().length > maxJudgeNameLength) {
      return 'Name must be $maxJudgeNameLength characters or fewer';
    }
    return null;
  }

  /// Validates a search query.
  static String sanitizeSearchQuery(String query) {
    return sanitizeText(query, maxLength: maxSearchQueryLength);
  }

  // ── File validators ──

  /// Validates image file before upload. Returns error message or null.
  static String? validateImageUpload(Uint8List bytes, String fileName) {
    if (bytes.length > maxImageBytes) {
      return 'Image is too large (max ${maxImageBytes ~/ (1024 * 1024)} MB)';
    }
    final ext = _fileExtension(fileName);
    if (!allowedImageExtensions.contains(ext)) {
      return 'Unsupported image format. Use JPG, PNG, or WebP';
    }
    if (!_hasValidImageHeader(bytes)) {
      return 'File does not appear to be a valid image';
    }
    return null;
  }

  /// Validates audio file before upload. Returns error message or null.
  static String? validateAudioUpload(Uint8List bytes, String fileName) {
    if (bytes.length > maxAudioBytes) {
      return 'Audio is too large (max ${maxAudioBytes ~/ (1024 * 1024)} MB)';
    }
    final ext = _fileExtension(fileName);
    if (!allowedAudioExtensions.contains(ext)) {
      return 'Unsupported audio format. Use M4A, AAC, MP3, or WAV';
    }
    return null;
  }

  static String _fileExtension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot == -1) return '';
    return fileName.substring(dot).toLowerCase();
  }

  /// Checks magic bytes for common image formats.
  static bool _hasValidImageHeader(Uint8List bytes) {
    if (bytes.length < 4) return false;
    // JPEG: FF D8 FF
    if (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true;
    // PNG: 89 50 4E 47
    if (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) return true;
    // WebP: RIFF....WEBP
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
        bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50) return true;
    return false;
  }
}
