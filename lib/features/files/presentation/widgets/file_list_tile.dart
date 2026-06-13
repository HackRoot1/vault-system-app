import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../data/models/vault_file_model.dart';

class FileListTile extends StatelessWidget {
  const FileListTile({
    required this.file,
    required this.onDownload,
    required this.onShare,
    required this.onDelete,
    this.onLongPress,
    super.key,
  });

  final VaultFileModel file;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: onLongPress,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: const Color(0xFF112240),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: const Color(0x12FFFFFF)),
        ),
        child: Row(
          children: [
            Container(
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                color: _iconBgColor(file.extension),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Icon(
                  _fileIcon(file.extension),
                  size: 26.sp,
                  color: _iconColor(file.extension),
                ),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _fileMeta(file),
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: const Color(0xFF8899AA),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ActionIcon(Icons.download_outlined, onDownload),
                SizedBox(width: 2.w),
                _ActionIcon(Icons.share_outlined, onShare),
                SizedBox(width: 2.w),
                _ActionIcon(
                  Icons.delete_outline,
                  onDelete,
                  color: const Color(0xFFCC3333),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _fileMeta(VaultFileModel file) {
  final dt = DateTime.tryParse(file.createdAt);
  if (dt == null) return '';
  return '${_monthName(dt.month)} ${dt.day}, ${dt.year}';
}

String _monthName(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[month - 1];
}

Color _iconBgColor(String ext) {
  switch (ext) {
    case 'pdf':
      return const Color(0xFF4A1515);
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
    case 'webp':
      return const Color(0xFF1A2F4A);
    case 'doc':
    case 'docx':
      return const Color(0xFF1A3A4A);
    case 'xls':
    case 'xlsx':
      return const Color(0xFF1A3A2A);
    case 'zip':
    case 'rar':
    case 'tar':
      return const Color(0xFF3A2F1A);
    case 'html':
    case 'htm':
      return const Color(0xFF2A1A3A);
    default:
      return const Color(0xFF1E2A3A);
  }
}

Color _iconColor(String ext) {
  switch (ext) {
    case 'pdf':
      return const Color(0xFFFF6B6B);
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
    case 'webp':
      return const Color(0xFF4488FF);
    case 'doc':
    case 'docx':
      return const Color(0xFF44AAFF);
    case 'xls':
    case 'xlsx':
      return const Color(0xFF44CC77);
    case 'zip':
    case 'rar':
    case 'tar':
      return const Color(0xFFFFAA44);
    case 'html':
    case 'htm':
      return const Color(0xFFAA66FF);
    default:
      return const Color(0xFF8899AA);
  }
}

IconData _fileIcon(String ext) {
  switch (ext) {
    case 'pdf':
      return Icons.picture_as_pdf_outlined;
    case 'jpg':
    case 'jpeg':
    case 'png':
    case 'gif':
    case 'webp':
      return Icons.image_outlined;
    case 'doc':
    case 'docx':
      return Icons.description_outlined;
    case 'xls':
    case 'xlsx':
      return Icons.table_chart_outlined;
    case 'zip':
    case 'rar':
    case 'tar':
      return Icons.folder_zip_outlined;
    case 'html':
    case 'htm':
      return Icons.code_outlined;
    default:
      return Icons.insert_drive_file_outlined;
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon(this.icon, this.onTap, {this.color});

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Icon(
          icon,
          size: 20.sp,
          color: color ?? const Color(0xFF8899AA),
        ),
      ),
    );
  }
}
