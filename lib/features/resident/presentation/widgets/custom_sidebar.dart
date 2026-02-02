import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fcm_app/core/data/repair_repository.dart';
import 'package:fcm_app/core/data/auth_repository.dart';
// import '../screens/create_repair_screen.dart'; // REMOVED

class CustomSidebar extends StatelessWidget {
  final String username;
  final VoidCallback? onMenuPressed; // Callback for menu button
  final Function(bool)? onDialogVisibilityChanged; // NEW: Notify parent of dialog state
  final VoidCallback? onNewRepairPressed; // NEW: Callback for new repair button

  const CustomSidebar({
    super.key, 
    required this.username, 
    this.onMenuPressed,
    this.onDialogVisibilityChanged,
    this.onNewRepairPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container( // Changed Drawer to Container
      color: const Color(0xFF121212), // Deeper dark background
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Section (Icons + Profile)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Icons Row
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu, color: Color(0xFFC5A059), size: 30),
                      onPressed: onMenuPressed ?? () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    const Icon(Icons.notifications_none, color: Color(0xFFC5A059), size: 26),
                    const SizedBox(width: 14),
                    const Icon(Icons.search, color: Color(0xFFC5A059), size: 26),
                    const SizedBox(width: 8),
                  ],
                ),
                const SizedBox(height: 28),
                
                // Profile Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFC5A059).withOpacity(0.6), width: 1.2),
                        ),
                        child: const Icon(Icons.person_outline, color: Color(0xFFC5A059), size: 30),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username.isEmpty || username == 'Resident' ? 'อนาคิน สกายวอล์คเกอร์' : username,
                            style: GoogleFonts.kanit(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'โปรไฟล์',
                            style: GoogleFonts.kanit(
                              color: Colors.white24,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 2. New Repair Button (FE-03)
          const Divider(color: Colors.white10, height: 1),
          InkWell(
            onTap: () {
              onNewRepairPressed?.call();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    child: const Icon(Icons.assignment, color: Color(0xFFC5A059), size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'การแจ้งซ่อมใหม่',
                          style: GoogleFonts.kanit(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          'คลิกที่นี่เพื่อสร้างการแจ้งซ่อมใหม่',
                          style: GoogleFonts.kanit(
                            color: Colors.white24,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<RepairRequest>>(
              valueListenable: RepairRepository.instance.repairsNotifier,
              builder: (context, repairs, child) {
                if (repairs.isEmpty) {
                  return Center(
                    child: Text(
                      'ยังไม่มีรายการแจ้งซ่อม',
                      style: GoogleFonts.kanit(color: Colors.grey),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24, top: 0),
                  itemCount: repairs.length,
                  itemBuilder: (context, index) {
                    final item = repairs[index];
                    return _buildRepairItem(context, item);
                  },
                );
              },
            ),
          ),
          
          // 4. Logout Button (New)
          const Divider(color: Colors.white10, height: 1),
          InkWell(
            onTap: () async {
              await AuthRepository.instance.logout();
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  const Icon(Icons.logout, color: Colors.redAccent, size: 24),
                  const SizedBox(width: 16),
                  Text(
                    'ออกจากระบบ',
                    style: GoogleFonts.kanit(
                      color: Colors.redAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRepairItem(BuildContext context, RepairRequest item) {
    return InkWell(
      onTap: () {
        if (item.status == 'เสร็จสิ้น') {
          _showCompletionDialog(context, item);
        } else if (item.status == 'ปฏิเสธ') {
          _showRejectionDialog(context, item);
        } else {
          _showRepairOptions(context, item);
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: GoogleFonts.kanit(
                    color: const Color(0xFFC5A059),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  item.date,
                  style: GoogleFonts.kanit(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: item.status == 'เสร็จสิ้น' ? const Color(0xFF2E4D2E) :
                       item.status == 'ดำเนินการ' ? const Color(0xFF8B7348) :
                       item.status == 'รอ' ? const Color(0xFF4A4A4A) :
                       item.status == 'ปฏิเสธ' ? const Color(0xFF8B0000) :
                       Colors.grey.shade900,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                item.status,
                style: GoogleFonts.kanit(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FE-06: Satisfaction Assessment
  void _showCompletionDialog(BuildContext context, RepairRequest item) {
    onDialogVisibilityChanged?.call(true); // Notify open
    showDialog(
      context: context,
      barrierDismissible: true, // Allow click outside to close
      builder: (context) {
        int _rating = 0; // Local state for dialog
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF151515),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: const BorderSide(color: Colors.green),
              ),
              title: Text('ประเมินความพึงพอใจ', style: GoogleFonts.kanit(color: Colors.green)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('งาน "${item.title}" เสร็จสิ้นแล้ว', style: GoogleFonts.kanit(color: Colors.white70)),
                  const SizedBox(height: 16),
                  
                  // Interactive Star Rating
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (index) {
                        return IconButton(
                          onPressed: () {
                            setStateDialog(() {
                              _rating = index + 1;
                            });
                          },
                          icon: Icon(
                            index < _rating ? Icons.star : Icons.star_border,
                            color: Colors.amber,
                            size: 32,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 16),
                  TextField(
                    style: GoogleFonts.kanit(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'ข้อเสนอแนะเพิ่มเติม...',
                      hintStyle: GoogleFonts.kanit(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.black,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('ข้าม', style: GoogleFonts.kanit(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Logic: Submit Rating to Backend (implied)
                    
                    // Archive/Delete request from view as requested
                    RepairRepository.instance.deleteRequest(item.id);
                    
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('ขอบคุณสำหรับการประเมินครับ! 🙏 รายการถูกย้ายไปที่ประวัติแล้ว', style: GoogleFonts.kanit()), backgroundColor: Colors.green),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  child: Text('ส่งประเมิน', style: GoogleFonts.kanit()),
                ),
              ],
            );
          },
        );
      },
    ).then((_) => onDialogVisibilityChanged?.call(false));
  }

  // Rejection Handling
  void _showRejectionDialog(BuildContext context, RepairRequest item) {
    onDialogVisibilityChanged?.call(true); // Notify open
    showDialog(
      context: context,
      barrierDismissible: true, // Allow click outside to close
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151515),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.red),
          ),
          title: Text('รายการถูกปฏิเสธ', style: GoogleFonts.kanit(color: Colors.red)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('เหตุผลจากนิติบุคคล:', style: GoogleFonts.kanit(color: Colors.white70, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  item.rejectionReason ?? 'ไม่มีเหตุผลระบุ',
                  style: GoogleFonts.kanit(color: Colors.white),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Delete
                RepairRepository.instance.deleteRequest(item.id);
                Navigator.pop(context);
              },
              child: Text('ลบรายการ', style: GoogleFonts.kanit(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                // Resubmit -> Go to Edit
                Navigator.pop(context);

                _showEditDialog(context, item);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
              child: Text('แก้ไขแล้วส่งใหม่', style: GoogleFonts.kanit()),
            ),
          ],
        );
      },
    ).then((_) => onDialogVisibilityChanged?.call(false)); // Notify close
  }

  void _showRepairOptions(BuildContext context, RepairRequest item) {
    onDialogVisibilityChanged?.call(true); // Notify open
    bool _transitioningToEdit = false; // Track if going to edit dialog
    
    showDialog(
      context: context,
      barrierDismissible: true, // Allow click outside to close
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151515),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFC5A059)),
          ),
          title: Text('จัดการรายการ: ${item.title}', style: GoogleFonts.kanit(color: const Color(0xFFC5A059))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               ListTile(
                 leading: const Icon(Icons.edit, color: Colors.blue),
                 title: Text('แก้ไขรายละเอียด', style: GoogleFonts.kanit(color: Colors.white)),
                 onTap: () {
                   _transitioningToEdit = true; // Mark as transitioning
                   Navigator.pop(context); // Close options dialog
                   _showEditDialog(context, item); // Open Edit Dialog (will call onDialogVisibilityChanged(true))
                 },
               ),
               ListTile(
                 leading: const Icon(Icons.delete, color: Colors.red),
                 title: Text('ยกเลิกรายการนี้', style: GoogleFonts.kanit(color: Colors.white)),
                 onTap: () {
                    RepairRepository.instance.deleteRequest(item.id);
                    Navigator.pop(context);
                 },
               ),
            ],
          ),
        );
      },
    ).then((_) {
      // Only reset if NOT transitioning to edit dialog
      if (!_transitioningToEdit) {
        onDialogVisibilityChanged?.call(false);
      }
    });
  }

  void _showEditDialog(BuildContext context, RepairRequest item) {
    onDialogVisibilityChanged?.call(true);
    
    // Local controllers for editing
    TextEditingController _editDescController = TextEditingController(text: item.title);
    // Parse date string (d/m/year_thai) to DateTime
    List<String> parts = item.date.split('/');
    DateTime _editDate = DateTime.now();
    if (parts.length == 3) {
      int d = int.parse(parts[0]);
      int m = int.parse(parts[1]);
      int y = int.parse(parts[2]) - 543;
      _editDate = DateTime(y, m, d);
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF151515),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFFC5A059), width: 1),
              ),
              title: Text('แก้ไขรายการ', style: GoogleFonts.kanit(color: const Color(0xFFC5A059))),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _editDescController,
                      style: GoogleFonts.kanit(color: Colors.white),
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'รายละเอียดปัญหา',
                        labelStyle: GoogleFonts.kanit(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.black,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFC5A059))),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Date Picker
                    InkWell(
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: _editDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2101),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.dark(
                                  primary: Color(0xFFC5A059),
                                  onPrimary: Colors.black,
                                  surface: Color(0xFF151515),
                                  onSurface: Colors.white,
                                ),
                                dialogBackgroundColor: const Color(0xFF151515),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            _editDate = picked;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_month, color: Color(0xFFC5A059), size: 24),
                            const SizedBox(width: 12),
                            Text(
                              "${_editDate.day}/${_editDate.month}/${_editDate.year + 543}",
                              style: GoogleFonts.kanit(color: Colors.white, fontSize: 14),
                            ),
                            const Spacer(),
                            const Icon(Icons.edit, color: Colors.grey, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('ยกเลิก', style: GoogleFonts.kanit(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Update Logic
                    final updated = RepairRequest(
                        id: item.id,
                        title: _editDescController.text,
                        date: "${_editDate.day}/${_editDate.month}/${_editDate.year + 543}",
                        status: item.status,
                        statusColor: item.statusColor,
                        imagePath: item.imagePath,
                    );
                    RepairRepository.instance.updateRequest(updated);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('บันทึกการแก้ไขเรียบร้อย', style: GoogleFonts.kanit()), backgroundColor: const Color(0xFFC5A059)),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC5A059), foregroundColor: Colors.black),
                  child: Text('บันทึก', style: GoogleFonts.kanit(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
        );
      }
    ).then((_) => onDialogVisibilityChanged?.call(false));
  }
}
