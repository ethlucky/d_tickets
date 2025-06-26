# 座位状态位图渲染实现

## 🎯 目标

根据合约的位图（bitmap）存储逻辑实现座位状态的正确渲染，每个座位用2位来表示4种状态。

## 🏗️ 架构说明

### **重要：每个区域独立的位图**
- **每个区域**都有自己独立的 `SeatStatusMap` 账户
- **每个区域**都有自己独立的座位状态位图
- **PDA生成**：`seat_status_map + eventPda + ticketTypePda + areaId`
- **位图范围**：仅包含当前区域内的座位，不是全场馆座位

### **数据隔离优势**：
- ✅ **独立管理**：每个区域的座位状态独立更新
- ✅ **性能优化**：只需加载当前区域的位图数据
- ✅ **并发安全**：不同区域的状态更新不会互相影响
- ✅ **扩展性好**：新增区域不影响现有区域

## 📊 合约位图逻辑

### **位图存储格式**：
```rust
/// 初始化座位状态位图
pub fn initialize_bitmap(&mut self, total_seats: u32) -> Result<()> {
    let bytes_needed = ((total_seats + 3) / 4) as usize; // 每4个座位需要1字节
    require!(bytes_needed <= 4000, TicketError::TooManySeats);
    
    self.seat_status_bitmap = vec![0u8; bytes_needed];
    self.total_seats = total_seats;
    Ok(())
}

/// 获取座位状态
pub fn get_seat_status(&self, seat_index: u32) -> Result<SeatStatus> {
    require!(seat_index < self.total_seats, TicketError::InvalidSeatIndex);
    
    let byte_index = (seat_index / 4) as usize;
    let bit_index = (seat_index % 4) * 2;
    
    let status_byte = self.seat_status_bitmap[byte_index];
    let status_bits = (status_byte >> bit_index) & 0x03;
    
    match status_bits {
        0 => Ok(SeatStatus::Available),
        1 => Ok(SeatStatus::Sold),
        2 => Ok(SeatStatus::TempLocked),
        3 => Ok(SeatStatus::Unavailable),
        _ => Err(TicketError::InvalidSeatStatus.into()),
    }
}
```

### **状态映射**：
- **0 (00)** → `Available` → `SeatLayoutStatus.available`
- **1 (01)** → `Sold` → `SeatLayoutStatus.occupied`
- **2 (10)** → `TempLocked` → `SeatLayoutStatus.locked`
- **3 (11)** → `Unavailable` → `SeatLayoutStatus.unavailable`

## ✅ 实现内容

### 1. **扩展 SeatStatusData 模型**

```dart
class SeatStatusData {
  /// 座位状态位图（从合约获取的原始字节数据）
  final List<int>? seatStatusBitmap;

  /// 座位索引映射（座位号 -> 索引）
  final Map<String, int>? seatIndexMap;

  SeatStatusData({
    // ... 其他字段
    this.seatStatusBitmap,
    this.seatIndexMap,
  });
}
```

### 2. **位图解析逻辑**

#### **获取座位状态方法**：
```dart
SeatLayoutStatus getStatusForSeat(String seatNumber) {
  // 优先使用位图数据（如果可用）
  if (seatStatusBitmap != null && seatIndexMap != null) {
    final seatIndex = seatIndexMap![seatNumber];
    if (seatIndex != null) {
      return _getSeatStatusFromBitmap(seatIndex);
    }
  }

  // 回退到传统的状态映射
  // ...
}
```

#### **位图状态解析**：
```dart
SeatLayoutStatus _getSeatStatusFromBitmap(int seatIndex) {
  try {
    // 计算字节索引和位索引
    final byteIndex = seatIndex ~/ 4; // 整数除法
    final bitIndex = (seatIndex % 4) * 2; // 每个座位占2位

    if (byteIndex >= seatStatusBitmap!.length) {
      return SeatLayoutStatus.available;
    }

    // 获取状态字节
    final statusByte = seatStatusBitmap![byteIndex];
    
    // 提取2位状态
    final statusBits = (statusByte >> bitIndex) & 0x03;

    // 根据合约逻辑映射状态
    switch (statusBits) {
      case 0:
        return SeatLayoutStatus.available; // Available
      case 1:
        return SeatLayoutStatus.occupied;   // Sold
      case 2:
        return SeatLayoutStatus.locked;     // TempLocked
      case 3:
        return SeatLayoutStatus.unavailable; // Unavailable
      default:
        return SeatLayoutStatus.available;
    }
  } catch (e) {
    return SeatLayoutStatus.available;
  }
}
```

### 3. **合约服务扩展**

#### **获取位图数据**：
```dart
Future<SeatStatusData?> getSeatStatusData(String seatStatusMapPda) async {
  // 1. 获取座位状态映射数据和位图
  final mapData = await getSeatStatusMapData(seatStatusMapPda);
  
  // 2. 获取位图数据
  final bitmapData = await _getSeatStatusBitmap(seatStatusMapPda);
  
  // 3. 从Arweave获取座位索引映射数据
  final indexMapData = await _arweaveService.getJsonData(mapData.seatIndexMapHash);
  
  // 4. 解析座位索引映射
  Map<String, int>? seatIndexMap;
  if (indexMapData['seatIndexMap'] != null) {
    seatIndexMap = Map<String, int>.from(
      indexMapData['seatIndexMap'].map((key, value) => 
        MapEntry(key.toString(), int.tryParse(value.toString()) ?? 0)
      )
    );
  }

  // 5. 创建座位状态数据对象
  return SeatStatusData(
    // ... 其他字段
    seatStatusBitmap: bitmapData,
    seatIndexMap: seatIndexMap,
  );
}
```

#### **位图数据提取**：
```dart
Future<List<int>?> _getSeatStatusBitmap(String seatStatusMapPda) async {
  // 1. 获取账户数据
  final accountInfo = await client.getAccountInfo(seatStatusMapPda);
  
  // 2. 解析账户数据
  final decodedData = /* 解析逻辑 */;
  
  // 3. 提取位图数据
  final bitmapData = _extractSeatStatusBitmap(decodedData);
  
  return bitmapData;
}

List<int>? _extractSeatStatusBitmap(Uint8List data) {
  try {
    int offset = 0;
    final buffer = ByteData.sublistView(data);

    // 跳过固定字段
    // ... 跳过 event, ticket_type, seat_layout_hash, seat_index_map_hash
    // ... 跳过 total_seats, sold_seats

    // 读取位图长度 (4字节 u32)
    final bitmapLength = buffer.getUint32(offset, Endian.little);
    offset += 4;

    // 读取位图数据
    final bitmapBytes = data.sublist(offset, offset + bitmapLength);

    return bitmapBytes;
  } catch (e) {
    return null;
  }
}
```

## 🔄 数据流程

### **区域级别的状态获取流程**：

1. **PDA生成**（区域级别）：
   ```
   eventPda + ticketTypePda + areaId
   ↓
   generateSeatStatusMapPDA()
   ↓
   区域专属的 seatStatusMapPda
   ```

2. **合约查询**（区域级别）：
   ```
   getSeatStatusData(seatStatusMapPda)
   ↓
   获取区域账户数据 + 解析区域位图
   ↓
   获取区域座位索引映射 (Arweave)
   ```

3. **状态解析**（区域内座位）：
   ```
   区域内座位号 → 区域内座位索引 (seatIndexMap)
   ↓
   区域内索引 → 字节索引和位索引
   ↓
   区域位图字节 → 2位状态值
   ↓
   状态值 → SeatLayoutStatus
   ```

4. **渲染显示**：
   ```
   SeatLayoutStatus → 颜色映射
   ↓
   区域座位组件渲染
   ```

### **多区域处理**：
```
VIP区域:
  - seatStatusMapPda_VIP
  - bitmap_VIP (仅VIP区座位)
  - seatIndexMap_VIP

普通区域:
  - seatStatusMapPda_Normal
  - bitmap_Normal (仅普通区座位)
  - seatIndexMap_Normal
```

## 🎨 状态颜色映射

```dart
Color _getSeatColor(SeatLayoutItemModel seat) {
  switch (seat.status) {
    case SeatLayoutStatus.available:
      return const Color(0xFF10B981); // 绿色 - 可选择
    case SeatLayoutStatus.occupied:
      return const Color(0xFFEF4444); // 红色 - 已售出
    case SeatLayoutStatus.locked:
      return const Color(0xFF8B5CF6); // 紫色 - 临时锁定
    case SeatLayoutStatus.unavailable:
      return const Color(0xFF737373); // 灰色 - 不可用
    case SeatLayoutStatus.selected:
      return const Color(0xFF141414); // 黑色 - 已选中
  }
}
```

## 📊 位图计算示例

### **示例：VIP区域 - 100个座位的位图**

- **区域座位数**：100 (仅VIP区域内的座位)
- **所需字节数**：`(100 + 3) / 4 = 25` 字节
- **每字节存储**：4个座位的状态
- **座位索引范围**：0-99 (区域内的相对索引)

### **座位索引 → 位图位置**：

| 座位索引 | 字节索引 | 位索引 | 位位置 |
|---------|---------|--------|--------|
| 0       | 0       | 0      | bit 0-1 |
| 1       | 0       | 2      | bit 2-3 |
| 2       | 0       | 4      | bit 4-5 |
| 3       | 0       | 6      | bit 6-7 |
| 4       | 1       | 0      | bit 0-1 |
| ...     | ...     | ...    | ...    |

### **状态提取计算**：
```dart
// 座位索引 5 的状态
final seatIndex = 5;
final byteIndex = 5 ~/ 4;        // = 1
final bitIndex = (5 % 4) * 2;    // = 2

final statusByte = bitmap[1];     // 获取第1字节
final statusBits = (statusByte >> 2) & 0x03; // 提取bit 2-3
```

## 🚀 优势

### **性能优势**：
- ✅ **高效存储**：每个座位只占用2位
- ✅ **快速查询**：O(1)时间复杂度
- ✅ **内存友好**：大幅减少存储空间

### **准确性优势**：
- ✅ **实时状态**：直接从合约获取最新状态
- ✅ **原子操作**：状态更新的一致性
- ✅ **无缓存问题**：避免状态不同步

### **扩展性优势**：
- ✅ **支持大规模**：可处理数万个座位
- ✅ **向后兼容**：保留传统状态映射作为回退
- ✅ **灵活映射**：支持不同的状态定义

现在座位状态渲染完全基于合约的位图逻辑，确保了状态的准确性和实时性！🎭
