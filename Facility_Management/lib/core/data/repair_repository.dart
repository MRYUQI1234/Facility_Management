import 'package:flutter/material.dart';

class RepairRequest {
  final String id;
  final String title;
  final String date;
  final String status;
  final Color statusColor;
  final String? imagePath;
  final String? rejectionReason;

  RepairRequest({
    required this.id,
    required this.title,
    required this.date,
    required this.status,
    required this.statusColor,
    this.imagePath,
    this.rejectionReason,
  });
}

class RepairRepository {
  static final RepairRepository instance = RepairRepository._internal();
  RepairRepository._internal();

  // Initialize with some dummy data if needed, or empty
  final ValueNotifier<List<RepairRequest>> repairsNotifier = ValueNotifier([
     RepairRequest(
      id: '1',
      title: 'แอร์เสีย',
      date: '5/1/2569',
      status: 'กำลังดำเนินการ',
      statusColor: Colors.blue,
    ),
    RepairRequest(
      id: '2',
      title: 'ท่อน้ำรั่ว',
      date: '2/1/2569',
      status: 'รอดำเนินการ',
      statusColor: Colors.orange,
    ),
    RepairRequest(
      id: '3',
      title: 'ไฟดับ',
      date: '1/1/2569',
      status: 'เสร็จสิ้น',
      statusColor: Colors.green,
    ),
  ]);

  void addRequest(String title, String? imagePath) {
    final now = DateTime.now();
    final dateStr = "${now.day}/${now.month}/${now.year + 543}";
    
    final newRequest = RepairRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      date: dateStr,
      status: 'รอดำเนินการ',
      statusColor: Colors.orange,
      imagePath: imagePath,
    );

    repairsNotifier.value = [newRequest, ...repairsNotifier.value];
  }

  void deleteRequest(String id) {
    repairsNotifier.value = repairsNotifier.value.where((item) => item.id != id).toList();
  }

  void updateRequest(RepairRequest updatedItem) {
     final index = repairsNotifier.value.indexWhere((item) => item.id == updatedItem.id);
     if (index != -1) {
       final List<RepairRequest> newList = List.from(repairsNotifier.value);
       newList[index] = updatedItem;
       repairsNotifier.value = newList;
     }
  }
}
