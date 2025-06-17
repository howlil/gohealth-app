import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class ModernSearchField extends StatefulWidget {
  final TextEditingController controller;
  final Function(String)? onChanged;
  final String hintText;
  final bool showFilterButton;
  final VoidCallback? onFilterTap;

  const ModernSearchField({
    super.key,
    required this.controller,
    this.onChanged,
    this.hintText = 'Cari...',
    this.showFilterButton = false,
    this.onFilterTap,
  });

  @override
  State<ModernSearchField> createState() => _ModernSearchFieldState();
}

class _ModernSearchFieldState extends State<ModernSearchField> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isFocused ? AppColors.primary : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isFocused ? 0.08 : 0.03),
            blurRadius: _isFocused ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: widget.controller,
              onChanged: widget.onChanged,
              onTap: () => setState(() => _isFocused = true),
              onFieldSubmitted: (_) => setState(() => _isFocused = false),
              onEditingComplete: () => setState(() => _isFocused = false),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
                prefixIcon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.search_rounded,
                    color:
                        _isFocused ? AppColors.primary : Colors.grey.shade400,
                    size: 24,
                  ),
                ),
                suffixIcon: widget.controller.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: Colors.grey.shade400,
                          size: 20,
                        ),
                        onPressed: () {
                          widget.controller.clear();
                          widget.onChanged?.call('');
                          setState(() {});
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),
          ),
          if (widget.showFilterButton) ...[
            Container(
              height: 24,
              width: 1,
              color: Colors.grey.shade300,
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onFilterTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.tune_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
