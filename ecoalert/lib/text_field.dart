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
      height: 30,
      width: MediaQuery.of(context).size.width * 0.72,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword ? !(isVisible ?? false) : false,
        style: const TextStyle(color: Colors.black ,fontSize: 10, fontWeight: FontWeight.w500),
        cursorColor: cursorColor,
        validator: validator,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,// 👈 this centers text vertically
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 14, // 👈 control icon width
            minHeight: 0,
          ),
          filled: true,
          fillColor: Colors.white,
          // background color
          hintText: hint,
          hintStyle: TextStyle(
            color: Color(0xFF9E9E9E), // explicit grey hex
            fontSize: 10,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Icon(icon, size: 14),
          ),
          errorStyle: TextStyle(
            color: Colors.black, // 👈 validation error color
            fontSize: 10,
          ),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    isVisible == true ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 14,
                  ),
                  onPressed: onToggle,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.grey, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(
                color: Color(0xFF7ECBA9),
                width: 2.5,
              ),
          ),
        ),
      ),
    );
  }
}
