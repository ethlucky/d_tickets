# 座位渲染逻辑改进

## 🎯 问题解决

之前的座位渲染使用简单的 `Wrap` 布局，没有考虑实际的座位行结构，导致每行的座位数量显示不正确。

现在已经修改为根据 `seatLayoutHash` 中的实际座位数据进行正确的按行渲染。

## ✅ 改进内容

### 1. **数据模型改进**

#### **修改了 `SeatLayoutItemModel.fromJson` 方法**：
```dart
factory SeatLayoutItemModel.fromJson(Map<String, dynamic> json) {
  // 从不同的字段中提取行号信息
  String? rowNumber;
  if (json['rowNumber'] != null) {
    rowNumber = json['rowNumber'].toString();
  } else if (json['row'] != null) {
    rowNumber = json['row'].toString();
  }

  // 从不同的字段中提取座位号信息
  String? seatNumberInRow;
  if (json['seatNumberInRow'] != null) {
    seatNumberInRow = json['seatNumberInRow'].toString();
  } else if (json['number'] != null) {
    seatNumberInRow = json['number'].toString();
  }

  // 从 metadata 中提取状态信息
  String statusString = 'available';
  if (json['metadata'] != null && json['metadata']['status'] != null) {
    statusString = json['metadata']['status'].toString();
  } else if (json['status'] != null) {
    statusString = json['status'].toString();
  }

  return SeatLayoutItemModel(
    seatNumber: json['seatNumber'] ?? '',
    coordinates: CoordinatePoint.fromJson(json['coordinates'] ?? {}),
    row: rowNumber,
    number: seatNumberInRow,
    status: SeatLayoutStatus.values.firstWhere(
      (status) => status.toString().split('.').last == statusString,
      orElse: () => SeatLayoutStatus.available,
    ),
    seatType: json['seatType'] ?? 
              (json['metadata'] != null ? json['metadata']['seatType'] : null),
    metadata: json['metadata'] ?? {},
  );
}
```

#### **支持的数据格式**：
```json
{
  "seatNumber": "VIP区-A-001",
  "rowNumber": "A",                    // 行号
  "seatNumberInRow": 1,                // 行内座位号
  "coordinates": { "x": 100, "y": 150 },
  "metadata": {
    "seatType": "normal",
    "status": "available"
  }
}
```

### 2. **渲染逻辑改进**

#### **新的按行渲染方法**：

##### **`_buildSeatsByRows()` - 按行分组座位**：
```dart
Widget _buildSeatsByRows(List<SeatLayoutItemModel> seats) {
  // 按行分组座位
  final Map<String, List<SeatLayoutItemModel>> seatsByRow = {};
  
  for (final seat in seats) {
    final rowNumber = seat.row ?? _extractRowFromSeatNumber(seat.seatNumber);
    if (rowNumber != null) {
      seatsByRow[rowNumber] ??= [];
      seatsByRow[rowNumber]!.add(seat);
    }
  }

  // 按行号排序
  final sortedRows = seatsByRow.keys.toList()..sort();

  return Column(
    children: sortedRows.map((rowNumber) {
      final rowSeats = seatsByRow[rowNumber]!;
      // 按座位号在行内排序
      rowSeats.sort((a, b) {
        final aNum = _extractSeatNumberInRow(a.seatNumber);
        final bNum = _extractSeatNumberInRow(b.seatNumber);
        return aNum.compareTo(bNum);
      });

      return _buildSeatRow(rowNumber, rowSeats);
    }).toList(),
  );
}
```

##### **`_buildSeatRow()` - 构建单行座位**：
```dart
Widget _buildSeatRow(String rowNumber, List<SeatLayoutItemModel> rowSeats) {
  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 左侧行号标签
        Container(
          width: 30,
          height: 36,
          alignment: Alignment.center,
          child: Text(rowNumber, style: ...),
        ),
        const SizedBox(width: 8),
        // 座位区域
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            alignment: WrapAlignment.center,
            children: rowSeats.map((seat) => _buildSeatWidget(seat)).toList(),
          ),
        ),
        const SizedBox(width: 8),
        // 右侧行号标签
        Container(
          width: 30,
          height: 36,
          alignment: Alignment.center,
          child: Text(rowNumber, style: ...),
        ),
      ],
    ),
  );
}
```

### 3. **数据提取方法**

#### **行号提取**：
```dart
String? _extractRowFromSeatNumber(String seatNumber) {
  try {
    // 座位号格式: "VIP区-A-001"
    final parts = seatNumber.split('-');
    if (parts.length >= 3) {
      return parts[1]; // 返回行号部分 "A"
    }
  } catch (e) {
    print('提取行号失败: $seatNumber, 错误: $e');
  }
  return null;
}
```

#### **行内座位号提取**：
```dart
int _extractSeatNumberInRow(String seatNumber) {
  try {
    // 座位号格式: "VIP区-A-001"
    final parts = seatNumber.split('-');
    if (parts.length >= 3) {
      return int.parse(parts[2]); // 返回座位号部分 001 -> 1
    }
  } catch (e) {
    print('提取座位号失败: $seatNumber, 错误: $e');
  }
  return 0;
}
```

#### **显示号码生成**：
```dart
String _getSeatDisplayNumber(String seatNumber) {
  try {
    // 座位号格式: "VIP区-A-001"
    final parts = seatNumber.split('-');
    if (parts.length >= 3) {
      final rowNumber = parts[1];
      final seatNum = int.parse(parts[2]);
      return '$rowNumber$seatNum'; // 返回 "A1"
    }
  } catch (e) {
    print('获取显示号码失败: $seatNumber, 错误: $e');
  }
  return seatNumber;
}
```

## 🎨 **视觉改进**

### **新的布局结构**：
```
        STAGE
    ┌─────────────────┐
A   │ A1 A2 A3 ... A20 │   A
B   │ B1 B2 B3 ... B20 │   B  
C   │ C1 C2 C3 ... C20 │   C
D   │ D1 D2 D3 ... D20 │   D
E   │ E1 E2 E3 ... E20 │   E
    └─────────────────┘
```

### **特点**：
- ✅ **舞台指示器**：顶部显示舞台位置
- ✅ **行号标签**：左右两侧显示行号
- ✅ **按行排列**：每行座位数量根据实际数据
- ✅ **居中对齐**：座位在行内居中显示
- ✅ **正确排序**：行按字母顺序，座位按数字顺序

## 🔄 **数据流程**

### **1. 数据加载**：
```
seatLayoutHash (Arweave) 
    ↓
SeatLayoutModel.fromJson() 
    ↓
提取 rowNumber 和 seatNumberInRow
    ↓
创建 SeatLayoutItemModel 对象
```

### **2. 渲染处理**：
```
List<SeatLayoutItemModel> 
    ↓
按 row 字段分组
    ↓
每组内按 seatNumberInRow 排序
    ↓
按行渲染座位
```

### **3. 显示逻辑**：
```
每行 = 行号标签 + 座位列表 + 行号标签
座位显示 = 行号 + 座位号 (如 "A1", "B15")
```

## 🎯 **支持的座位号格式**

### **标准格式**：
- `"VIP区-A-001"` → 行号: "A", 座位: 1, 显示: "A1"
- `"普通区-B-015"` → 行号: "B", 座位: 15, 显示: "B15"

### **数据字段映射**：
- `rowNumber` → `row` 字段
- `seatNumberInRow` → `number` 字段  
- `metadata.status` → `status` 字段
- `metadata.seatType` → `seatType` 字段

## 🚀 **效果**

现在座位渲染完全基于 `seatLayoutHash` 中的实际数据结构：

- ✅ **正确的行结构**：每行显示实际的座位数量
- ✅ **准确的座位排序**：按行号和座位号正确排序
- ✅ **清晰的视觉布局**：行号标签和座位对齐
- ✅ **灵活的数据支持**：支持不同的座位号格式

座位现在按照真实的剧院/体育馆布局进行渲染，每行的座位数量完全基于实际的座位配置数据！🎭
