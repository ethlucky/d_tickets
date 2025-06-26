import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../services/arweave_service.dart';

/// 场馆SVG显示组件 - 带聚焦功能
class VenueSvgViewer extends StatefulWidget {
  final String? floorPlanHash; // 场馆平面图哈希
  final List<SeatAreaInfo> seatAreas; // 座位区域信息
  final double? width;
  final double? height;
  final Function(SeatAreaInfo)? onAreaTap; // 点击区域回调
  final String? focusedAreaId; // 聚焦的区域ID

  const VenueSvgViewer({
    Key? key,
    this.floorPlanHash,
    this.seatAreas = const [],
    this.width,
    this.height,
    this.onAreaTap,
    this.focusedAreaId,
  }) : super(key: key);

  @override
  State<VenueSvgViewer> createState() => _VenueSvgViewerState();
}

class _VenueSvgViewerState extends State<VenueSvgViewer>
    with TickerProviderStateMixin {
  final ArweaveService _arweaveService = Get.find<ArweaveService>();
  String? _svgData;
  bool _isLoading = true;
  bool _hasError = false;

  // 缩放和聚焦控制
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;

  // 缩放配置
  static const double _minScale = 0.5;
  static const double _maxScale = 5.0;
  static const double _focusScale = 2.5; // 聚焦时的缩放比例

  // 追踪上次聚焦的区域
  String? _lastFocusedAreaId;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _loadSvgData();
  }

  @override
  void didUpdateWidget(VenueSvgViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.floorPlanHash != widget.floorPlanHash) {
      _loadSvgData();
    }

    // 检查聚焦区域是否变化
    if (widget.focusedAreaId != _lastFocusedAreaId) {
      print(
          '🔄 focusedAreaId变化: ${_lastFocusedAreaId} -> ${widget.focusedAreaId}');
      _lastFocusedAreaId = widget.focusedAreaId;

      if (widget.focusedAreaId != null && widget.focusedAreaId!.isNotEmpty) {
        print('📍 准备聚焦到区域: ${widget.focusedAreaId}');
        // 延迟执行聚焦，确保布局完成
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _focusOnArea(widget.focusedAreaId!);
          }
        });
      } else {
        print('🔄 清除聚焦，重置视图');
        // 如果focusedAreaId为空，重置视图
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _resetTransform();
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  /// 加载SVG数据
  Future<void> _loadSvgData() async {
    if (widget.floorPlanHash == null || widget.floorPlanHash!.isEmpty) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _svgData = null;
      });
    }

    try {
      print('🔄 VenueSvgViewer开始加载SVG: ${widget.floorPlanHash}');

      // 使用增强版的SVG获取方法，自动尝试多种编码修复
      final svgData =
          await _arweaveService.getSvgDataEnhanced(widget.floorPlanHash!);

      if (mounted) {
        setState(() {
          _svgData = svgData;
          _isLoading = false;
          _hasError = svgData == null;
        });

        if (svgData != null) {
          print('✅ VenueSvgViewer SVG加载成功，数据长度: ${svgData.length}');
        } else {
          print('❌ VenueSvgViewer SVG加载失败');
        }
      }
    } catch (e) {
      print('❌ VenueSvgViewer加载场馆SVG失败: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  /// 聚焦到指定区域
  void _focusOnArea(String areaId) {
    final area = widget.seatAreas.firstWhereOrNull((a) => a.areaId == areaId);
    if (area == null || !mounted) {
      print('❌ 聚焦失败: 未找到区域 $areaId 或组件已卸载');
      return;
    }

    print('🎯 聚焦到区域: ${area.areaId}');
    print('   区域坐标: (${area.x}, ${area.y})');

    // 计算聚焦变换矩阵
    final containerWidth = widget.width ?? 400;
    final containerHeight = widget.height ?? 300;

    print('   容器大小: $containerWidth x $containerHeight');

    // 计算区域中心点（现在区域是24x24的固定尺寸）
    final areaCenterX = area.x + 12; // 24/2 = 12
    final areaCenterY = area.y + 12; // 24/2 = 12

    print('   区域中心: ($areaCenterX, $areaCenterY)');

    // 使用适中的缩放比例
    final focusScale = 3.0; // 提高缩放比例，让小区域更明显

    // 计算平移偏移，使区域居中
    final translateX = (containerWidth / 2) - (areaCenterX * focusScale);
    final translateY = (containerHeight / 2) - (areaCenterY * focusScale);

    print('   缩放比例: $focusScale');
    print('   平移偏移: ($translateX, $translateY)');

    // 创建变换矩阵
    final targetMatrix = Matrix4.identity()
      ..translate(translateX, translateY)
      ..scale(focusScale);

    // 动画到目标位置
    _animateToMatrix(targetMatrix);
  }

  /// 动画到指定变换矩阵
  void _animateToMatrix(Matrix4 targetMatrix) {
    if (!mounted) return;

    // 停止当前动画
    _animationController.stop();
    _animation?.removeListener(_updateTransform);

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: targetMatrix,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animation!.addListener(_updateTransform);
    _animationController.forward(from: 0);
  }

  /// 更新变换
  void _updateTransform() {
    if (mounted && _animation != null) {
      _transformationController.value = _animation!.value;
    }
  }

  /// 重置缩放和位置
  void _resetTransform() {
    _animateToMatrix(Matrix4.identity());
  }

  /// 构建加载状态
  Widget _buildLoadingWidget() {
    return Container(
      width: widget.width,
      height: widget.height ?? 300,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 8),
            Text(
              '加载场馆平面图...',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建错误状态
  Widget _buildErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height ?? 300,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.grey,
              size: 32,
            ),
            const SizedBox(height: 8),
            const Text(
              '平面图加载失败',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadSvgData,
              child: const Text(
                '重试',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建SVG显示
  Widget _buildSvgViewer() {
    return Container(
      width: widget.width,
      height: widget.height ?? 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            // 可缩放的SVG容器
            InteractiveViewer(
              transformationController: _transformationController,
              minScale: _minScale,
              maxScale: _maxScale,
              boundaryMargin: const EdgeInsets.all(20),
              child: SizedBox(
                width: widget.width ?? 400,
                height: widget.height ?? 300,
                child: Stack(
                  clipBehavior: Clip.none, // 允许区域超出边界显示
                  children: [
                    // SVG背景
                    Positioned.fill(
                      child: SvgPicture.string(
                        _svgData!,
                        fit: BoxFit.contain,
                        placeholderBuilder: (context) => Container(
                          color: Colors.grey[100],
                          child: const Center(
                            child: Icon(Icons.image, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),

                    // 叠加区域信息
                    ...widget.seatAreas.map((area) => _buildAreaOverlay(area)),
                  ],
                ),
              ),
            ),

            // 控制按钮
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }

  /// 构建控制按钮
  Widget _buildControlButtons() {
    return Positioned(
      top: 8,
      right: 8,
      child: Column(
        children: [
          // 重置按钮
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.center_focus_strong, size: 20),
              onPressed: _resetTransform,
              tooltip: '重置视图',
            ),
          ),

          const SizedBox(height: 8),

          // 缩放指示器
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedBuilder(
              animation: _transformationController,
              builder: (context, child) {
                final scale =
                    _transformationController.value.getMaxScaleOnAxis();
                return Text(
                  '${(scale * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 构建区域叠加层
  Widget _buildAreaOverlay(SeatAreaInfo area) {
    final isFocused = widget.focusedAreaId == area.areaId;

    return Positioned(
      left: area.x,
      top: area.y,
      child: GestureDetector(
        onTap: () {
          print('点击区域: ${area.areaId}');
          widget.onAreaTap?.call(area);
        },
        child: Container(
          width: 24, // 更小的尺寸
          height: 24, // 更小的尺寸
          decoration: BoxDecoration(
            color: Colors.transparent, // 透明背景
            border: Border.all(
              color: _getAreaColor(area),
              width: isFocused ? 3 : 2,
            ),
            borderRadius: BorderRadius.circular(2), // 更小的圆角
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: _getAreaColor(area).withOpacity(0.3),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          // 移除所有子组件，只保留纯边框
        ),
      ),
    );
  }

  /// 获取区域颜色
  Color _getAreaColor(SeatAreaInfo area) {
    // 根据区域ID或票种类型分配不同颜色
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];

    final index = area.areaId.hashCode % colors.length;
    return colors[index.abs()];
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingWidget();
    }

    if (_hasError || _svgData == null) {
      return _buildErrorWidget();
    }

    return _buildSvgViewer();
  }
}

/// 座位区域信息
class SeatAreaInfo {
  final String areaId; // 区域ID
  final String ticketTypeName; // 票种名称
  final double x; // X坐标
  final double y; // Y坐标
  final double width; // 宽度
  final double height; // 高度
  final int totalSeats; // 总座位数
  final int availableSeats; // 可用座位数

  const SeatAreaInfo({
    required this.areaId,
    required this.ticketTypeName,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.totalSeats,
    required this.availableSeats,
  });

  /// 是否售罄
  bool get isSoldOut => availableSeats == 0;

  /// 售出比例 (0.0 - 1.0)
  double get soldRatio =>
      totalSeats > 0 ? (totalSeats - availableSeats) / totalSeats : 0.0;
}
