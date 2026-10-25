import 'package:flutter/material.dart';

/// Badge visual untuk menampilkan status dokumen atau barang
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'completed':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        label = 'Completed';
        icon = Icons.check_circle_outline;
        break;
      case 'confirmed':
        bg = Colors.teal.shade50;
        fg = Colors.teal.shade800;
        label = 'Confirmed';
        icon = Icons.verified_outlined;
        break;
      case 'draft':
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        label = 'Draft';
        icon = Icons.edit_note_outlined;
        break;
      case 'cancelled':
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        label = 'Cancelled';
        icon = Icons.cancel_outlined;
        break;
      case 'active':
      case 'aktif':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        label = 'Aktif';
        icon = Icons.check_circle_outline;
        break;
      case 'inactive':
      case 'nonaktif':
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        label = 'Nonaktif';
        icon = Icons.pause_circle_outline;
        break;
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade800;
        label = status;
        icon = Icons.info_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
