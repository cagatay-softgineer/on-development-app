import 'package:flutter/material.dart';
import 'package:ssdk_rsrc/models/button_params.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final ButtonParams buttonParams;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.buttonParams,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: buttonParams.buttonWidth, // Dynamic width
      height: buttonParams.buttonHeight, // Dynamic height
      decoration: BoxDecoration(
        // Use gradient if enabled
        gradient:
            buttonParams.useGradient
                ? LinearGradient(
                  colors: [
                    buttonParams.gradientStartColor,
                    buttonParams.gradientEndColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                : null,
        color:
            !buttonParams.useGradient
                ? buttonParams.backgroundColor
                : null, // Default color if gradient is not used
        borderRadius:
            buttonParams.shape == BoxShape.rectangle
                ? BorderRadius.circular(buttonParams.borderRadius)
                : null,
        boxShadow: [
          BoxShadow(
            color: buttonParams.shadowColor,
            offset: buttonParams.shadowOffset,
            spreadRadius: 1,
            blurStyle: BlurStyle.normal,
            blurRadius: buttonParams.elevation,
          ),
        ],
        shape: buttonParams.shape,
      ),
      child: ElevatedButton(
        onPressed: buttonParams.isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          elevation: 0, // Avoid double shadows when using BoxShadow
          padding: buttonParams.padding,
          shape:
              buttonParams.shape == BoxShape.circle
                  ? const CircleBorder()
                  : RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      buttonParams.borderRadius,
                    ),
                  ),
          side: BorderSide(
            color: buttonParams.borderColor,
            width: buttonParams.letterSpacing,
          ),
          backgroundColor: Colors.transparent, // Make background transparent
        ),
        child:
            buttonParams.isLoading
                ? SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: buttonParams.textColor,
                    strokeWidth: 2.0,
                  ),
                )
                : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (buttonParams.leadingIcon != null)
                      Icon(
                        buttonParams.leadingIcon,
                        color: buttonParams.textColor,
                        size: buttonParams.iconSize,
                      ),
                    if (buttonParams.leadingIcon != null)
                      SizedBox(width: buttonParams.letterSpacing),
                    Text(
                      text,
                      textAlign: buttonParams.textAlign,
                      style: buttonParams.textStyle.copyWith(
                        color: buttonParams.textColor,
                        fontFamily: buttonParams.fontFamily,
                      ),
                    ),
                    if (buttonParams.trailingIcon != null)
                      SizedBox(width: buttonParams.letterSpacing),
                    if (buttonParams.trailingIcon != null)
                      Icon(
                        buttonParams.trailingIcon,
                        color: buttonParams.textColor,
                        size: buttonParams.iconSize,
                      ),
                  ],
                ),
      ),
    );
  }
}
