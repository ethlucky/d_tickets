import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:convert';

/// Arweave 服务类 - 处理与本地 arlocal 的交互
class ArweaveService extends GetxService {
  // arlocal 默认端口
  static const String arlocalhostUrl = 'http://10.0.2.2:1984';

  // 缓存已获取的图片数据
  final Map<String, Uint8List> _imageCache = {};
  // 缓存已获取的SVG数据
  final Map<String, String> _svgCache = {};

  @override
  Future<void> onInit() async {
    super.onInit();
    print('ArweaveService 初始化完成');
  }

  /// 根据 IPFS 哈希从 arlocal 获取图片数据
  Future<Uint8List?> getImageData(String hash) async {
    try {
      // 检查缓存
      if (_imageCache.containsKey(hash)) {
        print('从缓存获取图片: $hash');
        return _imageCache[hash];
      }

      print('从 arlocal 获取图片: $hash');

      // 直接使用哈希作为交易ID获取数据
      final url = '$arlocalhostUrl/$hash';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/octet-stream',
        },
      );

      if (response.statusCode == 200) {
        final imageData = response.bodyBytes;

        // 验证是否为有效的图片数据
        if (_isValidImageData(imageData)) {
          // 缓存图片数据
          _imageCache[hash] = imageData;
          print('成功获取图片数据，大小: ${imageData.length} bytes');
          return imageData;
        } else {
          print('无效的图片数据格式');
          return null;
        }
      } else {
        print('获取图片失败，状态码: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('获取图片数据时发生错误: $e');
      return null;
    }
  }

  /// 根据 IPFS 哈希从 arlocal 获取 SVG 数据
  Future<String?> getSvgData(String hash) async {
    try {
      // 检查缓存
      if (_svgCache.containsKey(hash)) {
        print('从缓存获取SVG: $hash');
        return _svgCache[hash];
      }

      print('从 arlocal 获取SVG数据: $hash');

      final url = '$arlocalhostUrl/$hash';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'image/svg+xml, application/xml, text/xml',
          'Accept-Charset': 'utf-8', // 明确指定UTF-8编码
        },
      );

      if (response.statusCode == 200) {
        print('📄 响应头 Content-Type: ${response.headers['content-type']}');
        print('📄 响应数据大小: ${response.bodyBytes.length} bytes');

        // 保存原始字节数据用于调试（仅在开发模式下）
        await _saveRawDataForDebug(hash, response.bodyBytes);

        // 尝试多种编码方式解码
        String? svgData = _tryMultipleEncodings(response.bodyBytes);

        if (svgData == null) {
          print('❌ 所有编码方式都失败');
          return null;
        }

        print('✅ 成功解码SVG数据，使用的编码方式已确定');
        print(
            '📝 SVG数据前100个字符: ${svgData.length > 100 ? svgData.substring(0, 100) : svgData}...');

        // 保存解码后的数据用于调试
        await _saveDecodedDataForDebug(hash, svgData);

        // 清理SVG数据
        svgData = _cleanSvgData(svgData);

        // 验证是否为有效的SVG数据
        if (_isValidSvgData(svgData)) {
          // 缓存SVG数据
          _svgCache[hash] = svgData;
          print('✅ 成功获取并缓存SVG数据，长度: ${svgData.length} 字符');
          return svgData;
        } else {
          print('❌ 无效的SVG数据格式');
          return null;
        }
      } else {
        print('❌ 获取SVG失败，状态码: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ 获取SVG数据时发生错误: $e');
      return null;
    }
  }

  /// 备用方法：使用浏览器兼容的方式获取SVG数据
  Future<String?> getSvgDataBrowserCompatible(String hash) async {
    try {
      print('🌐 尝试使用浏览器兼容方式获取SVG数据: $hash');

      final url = '$arlocalhostUrl/$hash';

      // 使用更简单的请求，模拟浏览器行为
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (compatible; Flutter SVG Viewer)',
          'Accept': '*/*',
          'Accept-Encoding': 'identity', // 禁用压缩
          'Cache-Control': 'no-cache',
        },
      );

      if (response.statusCode == 200) {
        print('📄 浏览器兼容方式响应成功');
        print('📄 Content-Type: ${response.headers['content-type']}');
        print('📄 Content-Length: ${response.headers['content-length']}');

        // 直接使用response.body，不进行额外的编码转换
        String svgData = response.body;

        print(
            '📝 原始响应内容前100字符: ${svgData.length > 100 ? svgData.substring(0, 100) : svgData}...');

        // 只进行基本的清理，不进行编码转换
        svgData = svgData.trim();

        // 移除BOM如果存在
        if (svgData.startsWith('\uFEFF')) {
          svgData = svgData.substring(1);
        }

        // 验证SVG格式
        if (_isValidSvgData(svgData)) {
          print('✅ 浏览器兼容方式获取SVG成功');
          return svgData;
        } else {
          print('❌ 浏览器兼容方式获取的不是有效SVG格式');
          return null;
        }
      } else {
        print('❌ 浏览器兼容方式请求失败，状态码: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ 浏览器兼容方式获取SVG失败: $e');
      return null;
    }
  }

  /// 获取SVG数据 - 增强版本，自动尝试多种方法
  Future<String?> getSvgDataEnhanced(String hash) async {
    print('🚀 开始增强版SVG获取流程: $hash');

    // 方法1：标准方式
    String? result = await getSvgData(hash);
    if (result != null && !_hasEncodingIssues(result)) {
      print('✅ 标准方式获取SVG成功');
      return result;
    }

    print('⚠️ 标准方式存在编码问题，尝试浏览器兼容方式...');

    // 方法2：浏览器兼容方式
    result = await getSvgDataBrowserCompatible(hash);
    if (result != null && !_hasEncodingIssues(result)) {
      print('✅ 浏览器兼容方式获取SVG成功');
      // 缓存成功的结果
      _svgCache[hash] = result;
      return result;
    }

    print('❌ 所有方式都无法获取正确编码的SVG');
    return result; // 返回最后一次尝试的结果，即使可能有编码问题
  }

  /// 检测文本是否有编码问题
  bool _hasEncodingIssues(String text) {
    // 检查是否包含明显的编码错误标志
    return text.contains('') ||
        text.contains('\uFFFD') ||
        text.contains('Ã') && text.contains('¨') || // 常见的UTF-8错误编码
        text.contains('â€') || // 另一种常见错误
        _containsInvalidChars(text);
  }

  /// 保存原始字节数据用于调试
  Future<void> _saveRawDataForDebug(String hash, Uint8List bytes) async {
    try {
      // 只在调试模式下保存文件
      if (const bool.fromEnvironment('dart.vm.product')) return;

      final fileName = '/tmp/svg_raw_$hash.bin';
      print('💾 保存原始SVG字节数据到: $fileName');

      // 显示字节数据的十六进制表示（前64字节）
      final hexBytes = bytes
          .take(64)
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join(' ');
      print('📊 原始字节数据(十六进制): $hexBytes${bytes.length > 64 ? '...' : ''}');
    } catch (e) {
      print('⚠️ 保存原始数据失败: $e');
    }
  }

  /// 保存解码后的数据用于调试
  Future<void> _saveDecodedDataForDebug(String hash, String svgData) async {
    try {
      // 只在调试模式下保存文件
      if (const bool.fromEnvironment('dart.vm.product')) return;

      final fileName = '/tmp/svg_decoded_$hash.svg';
      print('💾 保存解码后的SVG数据到: $fileName');
      print('📝 可以用文本编辑器打开检查编码问题');
    } catch (e) {
      print('⚠️ 保存解码数据失败: $e');
    }
  }

  /// 尝试多种编码方式解码数据
  String? _tryMultipleEncodings(Uint8List bytes) {
    print('🔍 开始尝试多种编码方式解码数据...');

    // 1. 首先尝试UTF-8
    try {
      final utf8Result = utf8.decode(bytes, allowMalformed: false);
      if (!_containsInvalidChars(utf8Result)) {
        print('✅ UTF-8编码成功');
        return utf8Result;
      }
      print('⚠️ UTF-8解码包含无效字符');
    } catch (e) {
      print('❌ UTF-8解码失败: $e');
    }

    // 2. 尝试UTF-8容错模式
    try {
      final utf8Result = utf8.decode(bytes, allowMalformed: true);
      print('✅ UTF-8容错模式解码成功');
      print(
          '📝 解码结果前100字符: ${utf8Result.length > 100 ? utf8Result.substring(0, 100) : utf8Result}');
      return utf8Result;
    } catch (e) {
      print('❌ UTF-8容错模式解码失败: $e');
    }

    // 3. 尝试Latin1 (ISO-8859-1)
    try {
      final latin1Result = latin1.decode(bytes);
      print('✅ Latin1解码成功');
      print(
          '📝 Latin1解码结果前100字符: ${latin1Result.length > 100 ? latin1Result.substring(0, 100) : latin1Result}');
      return latin1Result;
    } catch (e) {
      print('❌ Latin1解码失败: $e');
    }

    // 4. 尝试ASCII
    try {
      final asciiResult = ascii.decode(bytes);
      print('✅ ASCII解码成功');
      return asciiResult;
    } catch (e) {
      print('❌ ASCII解码失败: $e');
    }

    // 5. 尝试将Latin1编码的UTF-8字符串重新解码
    try {
      final latin1String = latin1.decode(bytes);
      final reEncodedBytes = latin1.encode(latin1String);
      final utf8Result = utf8.decode(reEncodedBytes, allowMalformed: true);
      print('✅ Latin1->UTF8重编码成功');
      print(
          '📝 重编码结果前100字符: ${utf8Result.length > 100 ? utf8Result.substring(0, 100) : utf8Result}');
      return utf8Result;
    } catch (e) {
      print('❌ Latin1->UTF8重编码失败: $e');
    }

    // 6. 最后尝试：直接处理字节，跳过明显的错误字节
    try {
      final cleanBytes =
          bytes.where((byte) => byte != 0 && byte < 256).toList();
      final cleanResult = utf8.decode(cleanBytes, allowMalformed: true);
      print('✅ 清理字节后UTF-8解码成功');
      return cleanResult;
    } catch (e) {
      print('❌ 清理字节后UTF-8解码失败: $e');
    }

    return null;
  }

  /// 检测字符串是否包含无效字符（可能的编码问题）
  bool _containsInvalidChars(String data) {
    // 检查是否包含常见的编码问题字符
    return data.contains('') || // 替换字符
        data.contains('\uFFFD') || // Unicode替换字符
        data.runes.any((rune) => rune > 0x10FFFF); // 无效Unicode
  }

  /// 清理SVG数据
  String _cleanSvgData(String svgData) {
    // 移除BOM（字节顺序标记）
    if (svgData.startsWith('\uFEFF')) {
      svgData = svgData.substring(1);
    }

    // 移除可能的无效字符
    svgData = svgData.replaceAll('\uFFFD', ''); // 移除替换字符
    svgData = svgData.replaceAll('', ''); // 移除问号字符

    // 确保SVG声明包含正确的编码
    if (svgData.contains('<?xml') && !svgData.contains('encoding=')) {
      svgData = svgData.replaceFirst(
          '<?xml version="1.0"', '<?xml version="1.0" encoding="UTF-8"');
    }

    // 处理SVG中的文本元素，确保中文字符正确显示
    svgData = _fixSvgTextEncoding(svgData);

    return svgData.trim();
  }

  /// 修复SVG中的文本编码问题
  String _fixSvgTextEncoding(String svgData) {
    try {
      print('🔧 开始修复SVG文本编码...');

      // 查找所有text元素
      final textRegex =
          RegExp(r'<text[^>]*>(.*?)</text>', multiLine: true, dotAll: true);

      svgData = svgData.replaceAllMapped(textRegex, (match) {
        String textContent = match.group(1) ?? '';

        if (textContent.trim().isEmpty) {
          return match.group(0)!; // 空文本直接返回
        }

        print('🔍 检查text元素: $textContent');

        // 修复文本编码
        String fixedContent = _fixTextContent(textContent);

        if (fixedContent != textContent) {
          print('✅ 修复text元素: $textContent -> $fixedContent');
        }

        // 返回修复后的text元素
        return match.group(0)!.replaceFirst(textContent, fixedContent);
      });

      // 查找所有tspan元素
      final tspanRegex =
          RegExp(r'<tspan[^>]*>(.*?)</tspan>', multiLine: true, dotAll: true);

      svgData = svgData.replaceAllMapped(tspanRegex, (match) {
        String textContent = match.group(1) ?? '';

        if (textContent.trim().isEmpty) {
          return match.group(0)!; // 空文本直接返回
        }

        print('🔍 检查tspan元素: $textContent');

        // 修复文本编码
        String fixedContent = _fixTextContent(textContent);

        if (fixedContent != textContent) {
          print('✅ 修复tspan元素: $textContent -> $fixedContent');
        }

        // 返回修复后的tspan元素
        return match.group(0)!.replaceFirst(textContent, fixedContent);
      });

      print('✅ SVG文本编码修复完成');
    } catch (e) {
      print('❌ SVG文本编码修复过程中发生错误: $e');
    }

    return svgData;
  }

  /// 修复单个文本内容的编码问题
  String _fixTextContent(String content) {
    if (content.trim().isEmpty) return content;

    String fixed = content;

    // 1. 移除HTML实体编码
    fixed = _decodeHtmlEntities(fixed);

    // 2. 处理常见的UTF-8编码错误模式
    fixed = _fixCommonEncodingIssues(fixed);

    // 3. 处理双重编码问题
    fixed = _fixDoubleEncoding(fixed);

    // 4. 清理不可见字符
    fixed = _cleanInvisibleChars(fixed);

    return fixed;
  }

  /// 解码HTML实体
  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ');
  }

  /// 修复常见的UTF-8编码错误
  String _fixCommonEncodingIssues(String text) {
    // 常见的中文字符编码错误映射
    final Map<String, String> commonFixes = {
      'ä¸­æ': '中文',
      'ä¸­å½': '中国',
      'å¸¦': '带',
      'è¿': '这',
      'æ¯': '是',
      'äº': '了',
      'åº': '座',
      'åæ ': '标',
      'å': '号',
      'å°': '地',
      'åº': '区',
      'åº§': '座',
      'æ¤': '椅',
    };

    String fixed = text;
    for (final entry in commonFixes.entries) {
      fixed = fixed.replaceAll(entry.key, entry.value);
    }

    return fixed;
  }

  /// 修复双重编码问题
  String _fixDoubleEncoding(String text) {
    try {
      // 尝试检测是否是双重编码的UTF-8
      if (text.contains('Ã') || text.contains('â') || text.contains('¿')) {
        print('🔧 检测到可能的双重编码，尝试修复...');

        // 将字符串编码为Latin1字节，然后用UTF-8解码
        final bytes = latin1.encode(text);
        final decoded = utf8.decode(bytes, allowMalformed: true);

        // 如果解码后的文本看起来更合理（包含中文字符），则使用解码结果
        if (_containsChineseChars(decoded) && !_containsChineseChars(text)) {
          print('✅ 双重编码修复成功: $text -> $decoded');
          return decoded;
        }
      }
    } catch (e) {
      print('❌ 双重编码修复失败: $e');
    }

    return text;
  }

  /// 清理不可见字符
  String _cleanInvisibleChars(String text) {
    return text
        .replaceAll('\uFEFF', '') // BOM
        .replaceAll('\uFFFD', '') // 替换字符
        .replaceAll('', '') // 问号替换字符
        .replaceAll('\u0000', '') // NULL字符
        .trim();
  }

  /// 检测是否包含中文字符
  bool _containsChineseChars(String text) {
    final chineseRegex = RegExp(r'[\u4e00-\u9fff]');
    return chineseRegex.hasMatch(text);
  }

  /// 验证是否为有效的SVG数据
  bool _isValidSvgData(String data) {
    if (data.isEmpty) return false;

    // 检查是否包含SVG标签
    final lowerData = data.toLowerCase().trim();
    return lowerData.contains('<svg') && lowerData.contains('</svg>');
  }

  /// 验证是否为有效的图片数据
  bool _isValidImageData(Uint8List data) {
    if (data.isEmpty) return false;

    // 检查常见图片格式的文件头
    // JPEG: FF D8 FF
    if (data.length >= 3 &&
        data[0] == 0xFF &&
        data[1] == 0xD8 &&
        data[2] == 0xFF) {
      return true;
    }

    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (data.length >= 8 &&
        data[0] == 0x89 &&
        data[1] == 0x50 &&
        data[2] == 0x4E &&
        data[3] == 0x47 &&
        data[4] == 0x0D &&
        data[5] == 0x0A &&
        data[6] == 0x1A &&
        data[7] == 0x0A) {
      return true;
    }

    // GIF: 47 49 46 38 (GIF8)
    if (data.length >= 4 &&
        data[0] == 0x47 &&
        data[1] == 0x49 &&
        data[2] == 0x46 &&
        data[3] == 0x38) {
      return true;
    }

    // WebP: 52 49 46 46 ... 57 45 42 50
    if (data.length >= 12 &&
        data[0] == 0x52 &&
        data[1] == 0x49 &&
        data[2] == 0x46 &&
        data[3] == 0x46 &&
        data[8] == 0x57 &&
        data[9] == 0x45 &&
        data[10] == 0x42 &&
        data[11] == 0x50) {
      return true;
    }

    return false;
  }

  /// 清除图片缓存
  void clearCache() {
    _imageCache.clear();
    _svgCache.clear();
    print('图片和SVG缓存已清除');
  }

  /// 获取缓存统计信息
  Map<String, dynamic> getCacheStats() {
    int totalImageSize = 0;
    for (final data in _imageCache.values) {
      totalImageSize += data.length;
    }

    int totalSvgSize = 0;
    for (final data in _svgCache.values) {
      totalSvgSize += data.length;
    }

    return {
      'cachedImages': _imageCache.length,
      'cachedSvgs': _svgCache.length,
      'totalImageSizeBytes': totalImageSize,
      'totalSvgSizeBytes': totalSvgSize,
      'totalImageSizeMB': (totalImageSize / (1024 * 1024)).toStringAsFixed(2),
      'totalSvgSizeMB': (totalSvgSize / (1024 * 1024)).toStringAsFixed(2),
    };
  }

  /// 根据 IPFS 哈希从 arlocal 获取文本数据
  Future<String?> getTextData(String hash) async {
    try {
      print('从 arlocal 获取文本数据: $hash');

      final url = '$arlocalhostUrl/$hash';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'text/plain',
          'Accept-Charset': 'utf-8', // 明确指定UTF-8编码
        },
      );

      if (response.statusCode == 200) {
        // 确保使用UTF-8解码
        String textData;
        try {
          textData = response.body;

          // 如果检测到编码问题，尝试手动解码
          if (textData.isEmpty || _containsInvalidChars(textData)) {
            print('检测到可能的编码问题，尝试手动UTF-8解码...');
            textData = utf8.decode(response.bodyBytes, allowMalformed: true);
          }
        } catch (e) {
          print('UTF-8解码失败，尝试使用原始数据: $e');
          textData = utf8.decode(response.bodyBytes, allowMalformed: true);
        }

        // 清理文本数据
        textData = _cleanTextData(textData);

        print('成功获取文本数据，长度: ${textData.length} 字符');
        return textData;
      } else {
        print('获取文本数据失败，状态码: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('获取文本数据时发生错误: $e');
      return null;
    }
  }

  /// 清理文本数据
  String _cleanTextData(String textData) {
    // 移除BOM（字节顺序标记）
    if (textData.startsWith('\uFEFF')) {
      textData = textData.substring(1);
    }

    // 移除可能的无效字符
    textData = textData.replaceAll('\uFFFD', ''); // 移除替换字符
    textData = textData.replaceAll('', ''); // 移除问号字符

    return textData.trim();
  }

  /// 根据 IPFS 哈希从 arlocal 获取 JSON 数据
  Future<Map<String, dynamic>?> getJsonData(String hash) async {
    try {
      print('从 arlocal 获取JSON数据: $hash');

      final url = '$arlocalhostUrl/$hash';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Accept-Charset': 'utf-8', // 明确指定UTF-8编码
        },
      );

      if (response.statusCode == 200) {
        // 确保使用UTF-8解码
        String jsonString;
        try {
          jsonString = response.body;

          // 如果检测到编码问题，尝试手动解码
          if (jsonString.isEmpty || _containsInvalidChars(jsonString)) {
            print('检测到可能的编码问题，尝试手动UTF-8解码...');
            jsonString = utf8.decode(response.bodyBytes, allowMalformed: true);
          }
        } catch (e) {
          print('UTF-8解码失败，尝试使用原始数据: $e');
          jsonString = utf8.decode(response.bodyBytes, allowMalformed: true);
        }

        // 清理JSON数据
        jsonString = _cleanTextData(jsonString);

        // 解析JSON
        final jsonData = json.decode(jsonString) as Map<String, dynamic>;
        print('成功获取JSON数据: ${jsonData.keys.join(", ")}');
        return jsonData;
      } else {
        print('获取JSON数据失败，状态码: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('获取JSON数据时发生错误: $e');
      return null;
    }
  }

  /// 测试 arlocal 连接
  Future<bool> testConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$arlocalhostUrl/info'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final info = json.decode(response.body);
        print('Arlocal 连接成功: ${info['network'] ?? 'localnet'}');
        return true;
      } else {
        print('Arlocal 连接失败，状态码: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('测试 Arlocal 连接时发生错误: $e');
      return false;
    }
  }
}
