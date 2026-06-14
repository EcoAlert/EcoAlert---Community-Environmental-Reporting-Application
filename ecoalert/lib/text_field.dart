import 'package:flutter/material.dart';

class InputField extends StatelessWidget {
  final controller, keyboardType, hint, icon, validator, cursorColor;
  final bool isPassword;
  final bool? isVisible;
  final VoidCallback? onToggle;

  const InputField({
    super.key,
    required this.controller,
    required this.keyboardType,
    required this.hint,
    required this.validator,
    this.icon,
    this.isPassword = false,
    this.isVisible,
    this.onToggle,
    this.cursorColor = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.72,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword ? !(isVisible ?? false) : false,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        cursorColor: cursorColor,
        validator: validator,
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal:
                8, // all fields have same internal spacing
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 14,
            minHeight: 0,
          ),
          // limits the suffix icon size so password field stays same height as email
          suffixIconConstraints: const BoxConstraints(
            minWidth: 30,
            minHeight: 0,
            maxHeight:
                30, // clamps the eye icon height to match other fields
          ),
          filled: true,
          fillColor: Colors.white,
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 10),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Icon(icon, size: 14),
          ),
          errorStyle: const TextStyle(color: Colors.red, fontSize: 10),
          suffixIcon: isPassword
              ? IconButton(
                  padding:
                      EdgeInsets.zero, // removes default IconButton padding
                  constraints:
                      const BoxConstraints(), // removes minimum size constraint
                  icon: Icon(
                    isVisible == true
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 14,
                    color: Color(0xFF9E9E9E),
                  ),
                  onPressed: onToggle,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFF7ECBA9), width: 2.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFF7ECBA9), width: 2.5),
          ),
        ),
      ),
    );
  }
}
