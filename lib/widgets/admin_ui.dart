import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:isp_admin_app/config/app_config.dart';

void showAdminSnackBar(BuildContext context, String message, {bool isError = false}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? AdminColors.danger : AdminColors.primaryDark,
      behavior: SnackBarBehavior.floating,
    ),
  );
}

Widget adminBadge(String text, {Color color = AdminColors.primaryAccent}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 10.5,
        fontWeight: FontWeight.w800,
        color: color,
      ),
    ),
  );
}

Color statusColor(String? status) {
  switch ((status ?? '').toLowerCase()) {
    case 'active':
    case 'online':
    case 'paid':
    case 'approved':
    case 'completed':
    case 'resolved':
    case 'unused':
    case 'verified':
      return AdminColors.success;
    case 'pending':
    case 'in_progress':
    case 'open':
    case 'used':
    case 'maintenance':
      return AdminColors.warning;
    case 'isolated':
    case 'offline':
    case 'unpaid':
    case 'rejected':
    case 'cancelled':
    case 'suspended':
    case 'full':
      return AdminColors.danger;
    default:
      return AdminColors.textMuted;
  }
}

Widget adminEmptyState(String message, {IconData icon = Icons.inbox_rounded}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AdminColors.textMuted.withValues(alpha: 0.5)),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: AdminColors.textMuted,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget adminInfoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AdminColors.textMuted),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AdminColors.textHeadline,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget adminTextField(
  TextEditingController controller,
  String label, {
  String? hint,
  TextInputType keyboardType = TextInputType.text,
  int maxLines = 1,
  bool obscureText = false,
  String? Function(String?)? validator,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: AdminColors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AdminColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AdminColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AdminColors.primaryAccent, width: 1.5),
        ),
      ),
    ),
  );
}

List<Map<String, dynamic>> extractList(dynamic data) {
  if (data is List) {
    return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
  if (data is Map && data['data'] is List) {
    return (data['data'] as List).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }
  return [];
}

Future<bool> confirmAdminDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Ya, Lanjutkan',
  bool isDanger = false,
}) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: Text(
        title,
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
      ),
      content: Text(message, style: GoogleFonts.plusJakartaSans(fontSize: 13.5)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDanger ? AdminColors.danger : AdminColors.primaryAccent,
            foregroundColor: Colors.white,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return res == true;
}

