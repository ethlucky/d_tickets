# 区域级别座位状态位图说明

## 🎯 重要澄清

**每个区域都有自己独立的座位状态位图，不是所有区域共享一个大位图！**

## 🏗️ 架构设计

### **区域独立性**

#### **每个区域的独立组件**：
```
VIP区域:
├── seatStatusMapPda_VIP (基于 eventPda + ticketTypePda + "VIP区")
├── seatStatusBitmap_VIP (仅包含VIP区的座位状态)
├── seatIndexMap_VIP (VIP区座位号 → VIP区内索引)
└── totalSeats_VIP (VIP区总座位数)

普通区域:
├── seatStatusMapPda_Normal (基于 eventPda + ticketTypePda + "普通区")  
├── seatStatusBitmap_Normal (仅包含普通区的座位状态)
├── seatIndexMap_Normal (普通区座位号 → 普通区内索引)
└── totalSeats_Normal (普通区总座位数)
```

#### **PDA生成逻辑**：
```dart
// 每个区域都有自己的PDA
final seatStatusMapPDA = await _contractService.generateSeatStatusMapPDA(
  eventPda,           // 活动PDA
  ticketTypePDA,      // 票种PDA  
  areaId,            // 区域ID (如 "VIP区", "普通区")
);
```

## 📊 位图数据结构

### **区域级别的位图**

#### **VIP区示例**（假设100个座位）：
```
VIP区座位: VIP区-A-001 到 VIP区-E-020 (100个座位)
位图大小: (100 + 3) / 4 = 25 字节
座位索引: 0-99 (区域内相对索引)

座位映射:
VIP区-A-001 → 索引 0
VIP区-A-002 → 索引 1
VIP区-A-003 → 索引 2
...
VIP区-E-020 → 索引 99
```

#### **普通区示例**（假设400个座位）：
```
普通区座位: 普通区-F-001 到 普通区-T-020 (400个座位)
位图大小: (400 + 3) / 4 = 100 字节  
座位索引: 0-399 (区域内相对索引)

座位映射:
普通区-F-001 → 索引 0
普通区-F-002 → 索引 1
普通区-F-003 → 索引 2
...
普通区-T-020 → 索引 399
```

## 🔄 数据处理流程

### **区域选择和数据加载**：

1. **用户选择区域**：
   ```
   用户点击 "VIP区" 
   ↓
   areaId = "VIP区"
   ```

2. **生成区域PDA**：
   ```
   generateSeatStatusMapPDA(eventPda, ticketTypePda, "VIP区")
   ↓
   seatStatusMapPda_VIP
   ```

3. **获取区域数据**：
   ```
   getSeatStatusData(seatStatusMapPda_VIP)
   ↓
   - VIP区的位图数据 (25字节)
   - VIP区的座位索引映射
   - VIP区的座位布局数据
   ```

4. **渲染VIP区座位**：
   ```
   VIP区座位号 → VIP区内索引 → 位图状态 → 颜色渲染
   ```

### **状态查询逻辑**：

```dart
// 查询 VIP区-A-001 的状态
String seatNumber = "VIP区-A-001";

// 1. 从VIP区的索引映射中获取区域内索引
int seatIndex = seatIndexMap_VIP[seatNumber]; // 例如: 0

// 2. 从VIP区的位图中获取状态
SeatLayoutStatus status = _getSeatStatusFromBitmap(seatIndex);
// 使用的是VIP区的位图，不是全场馆的位图

// 3. 计算位图位置
int byteIndex = seatIndex ~/ 4;        // 0 ~/ 4 = 0
int bitIndex = (seatIndex % 4) * 2;    // (0 % 4) * 2 = 0

// 4. 从VIP区位图的第0字节的第0-1位获取状态
int statusBits = (vipBitmap[0] >> 0) & 0x03;
```

## 🎯 优势分析

### **性能优势**：
- ✅ **数据局部性**：只加载当前区域的数据
- ✅ **内存效率**：避免加载不需要的区域数据
- ✅ **查询速度**：区域内索引范围小，计算快速

### **管理优势**：
- ✅ **独立更新**：不同区域的状态更新互不影响
- ✅ **并发安全**：多个区域可以同时进行状态更新
- ✅ **故障隔离**：一个区域的问题不影响其他区域

### **扩展优势**：
- ✅ **动态区域**：可以随时添加新区域
- ✅ **灵活配置**：每个区域可以有不同的座位数量
- ✅ **独立权限**：可以为不同区域设置不同的访问权限

## 🔧 实现细节

### **控制器中的区域处理**：

```dart
// 当前实现已经是区域级别的
void _loadAreaSeatStatus() async {
  // 1. 生成当前区域的PDA
  final seatStatusMapPDA = await _contractService.generateSeatStatusMapPDA(
    eventPda!,
    ticketTypePDA,
    areaId!,  // 当前选择的区域ID
  );

  // 2. 获取当前区域的状态数据
  final seatStatusData = await _contractService.getSeatStatusData(seatStatusMapPDA);
  
  // 3. 更新当前区域的座位状态
  // 这里的位图和索引映射都是区域级别的
}
```

### **数据模型中的区域处理**：

```dart
class SeatStatusData {
  // 这些字段都是区域级别的，不是全场馆级别的
  final List<int>? seatStatusBitmap;      // 当前区域的位图
  final Map<String, int>? seatIndexMap;  // 当前区域的索引映射
  final int totalSeats;                  // 当前区域的总座位数
  final int soldSeats;                   // 当前区域的已售座位数
}
```

## 🚀 总结

现在的实现已经是正确的区域级别处理：

- ✅ **每个区域独立的PDA**：基于 `eventPda + ticketTypePda + areaId`
- ✅ **每个区域独立的位图**：仅包含区域内座位的状态
- ✅ **每个区域独立的索引映射**：座位号到区域内索引的映射
- ✅ **区域级别的状态查询**：在区域位图中查找座位状态

这种设计确保了：
1. **数据隔离**：不同区域的数据完全独立
2. **性能优化**：只处理当前区域的数据
3. **扩展性好**：可以轻松添加新区域
4. **管理简单**：每个区域可以独立管理和更新

用户在查看某个区域的座位时，系统只会加载和处理该区域的位图数据，不会涉及其他区域的数据！🎭
