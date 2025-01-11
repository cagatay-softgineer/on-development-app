import 'package:flutter/material.dart';
import 'models/button_params.dart';

class ButtonCustomizer extends StatefulWidget {
  final ButtonParams initialParams;
  final ValueChanged<ButtonParams> onParamsChanged;

  ButtonCustomizer({required this.initialParams, required this.onParamsChanged});

  @override
  _ButtonCustomizerState createState() => _ButtonCustomizerState();
}

class _ButtonCustomizerState extends State<ButtonCustomizer> {
  late ButtonParams _currentParams;
  late Color _selectedColor; // Ensure this gets updated dynamically

  @override
  void initState() {
    super.initState();
    _currentParams = widget.initialParams;
    _selectedColor = _currentParams.backgroundColor;
  }

  void _updateParams() {
    widget.onParamsChanged(_currentParams);
  }

  // Helper to update the alpha channel of a color
  Color _withAlpha(Color color, double alpha) {
    return color.withAlpha((alpha * 255).toInt());
  }
  

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text('Background Color:'),
            SizedBox(width: 10),
            DropdownButton<Color>(
              value: _selectedColor, // Use _selectedColor for dropdown value
              items: [
                DropdownMenuItem(value: Colors.blue, child: Text('Blue')),
                DropdownMenuItem(value: Colors.red, child: Text('Red')),
                DropdownMenuItem(value: Colors.green, child: Text('Green')),
                DropdownMenuItem(value: Colors.orange, child: Text('Orange')),
                DropdownMenuItem(value: Colors.purple, child: Text('Purple')),
                DropdownMenuItem(value: Colors.yellow, child: Text('Yellow')),
                DropdownMenuItem(value: Colors.cyan, child: Text('Cyan')),
                DropdownMenuItem(value: Colors.pink, child: Text('Pink')),
                DropdownMenuItem(value: Colors.brown, child: Text('Brown')),
                DropdownMenuItem(value: Colors.grey, child: Text('Grey')),
                DropdownMenuItem(value: Colors.black, child: Text('Black')),
                DropdownMenuItem(value: Colors.white, child: Text('White')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedColor = value!; // Update selected color
                  _currentParams.backgroundColor = _withAlpha(
                    _selectedColor,
                    _currentParams.backgroundAlpha,
                  ); // Apply alpha to selected color
                  _updateParams();
                });
              },
            ),
          ],
        ),

        // Alpha Slider for Background Color
        Row(
          children: [
            Text('Background Opacity:'),
            SizedBox(width: 10),
            Expanded(
              child: Slider(
                value: _currentParams.backgroundAlpha,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: (_currentParams.backgroundAlpha * 100).round().toString() + '%',
                onChanged: (value) {
                  setState(() {
                    _currentParams.backgroundAlpha = value; // Update alpha
                    _currentParams.backgroundColor = _withAlpha(
                      _selectedColor,
                      _currentParams.backgroundAlpha,
                    ); // Apply alpha to selected color
                    _updateParams();
                  });
                },
              ),
            ),
          ],
        ),
        Row(
          children: [
            Text('Text Color:'),
            SizedBox(width: 10),
            DropdownButton<Color>(
              value: _currentParams.textColor,
              items: [
                DropdownMenuItem(value: Colors.white, child: Text('White')),
                DropdownMenuItem(value: Colors.black, child: Text('Black')),
                DropdownMenuItem(value: Colors.red, child: Text('Red')),
                DropdownMenuItem(value: Colors.blue, child: Text('Blue')),
                DropdownMenuItem(value: Colors.green, child: Text('Green')),
                DropdownMenuItem(value: Colors.orange, child: Text('Orange')),
                DropdownMenuItem(value: Colors.purple, child: Text('Purple')),
                DropdownMenuItem(value: Colors.yellow, child: Text('Yellow')),
                DropdownMenuItem(value: Colors.cyan, child: Text('Cyan')),
                DropdownMenuItem(value: Colors.pink, child: Text('Pink')),
                DropdownMenuItem(value: Colors.brown, child: Text('Brown')),
                DropdownMenuItem(value: Colors.grey, child: Text('Grey')),
              ],
              onChanged: (value) {
                setState(() {
                  _currentParams.textColor = value!;
                  _updateParams();
                });
              },
            ),
          ],
        ),
        Row(
          children: [
            Text('Border Radius:'),
            SizedBox(width: 10),
            Slider(
              value: _currentParams.borderRadius,
              min: 0,
              max: 32,
              divisions: 8,
              label: '${_currentParams.borderRadius.round()}',
              onChanged: (value) {
                setState(() {
                  _currentParams.borderRadius = value;
                  _updateParams();
                });
              },
            ),
          ],
        ),
        Row(
          children: [
            Text('Elevation:'),
            SizedBox(width: 10),
            Slider(
              value: _currentParams.elevation,
              min: 0,
              max: 16,
              divisions: 8,
              label: '${_currentParams.elevation.round()}',
              onChanged: (value) {
                setState(() {
                  _currentParams.elevation = value;
                  _updateParams();
                });
              },
            ),
          ],
        ),
        Row(
          children: [
            Text('Button Width:'),
            SizedBox(width: 10),
            Slider(
              value: _currentParams.buttonWidth,
              min: 100,
              max: 300,
              divisions: 8,
              label: '${_currentParams.buttonWidth.round()}',
              onChanged: (value) {
                setState(() {
                  _currentParams.buttonWidth = value;
                  _updateParams();
                });
              },
            ),
          ],
        ),
        Row(
          children: [
            Text('Button Height:'),
            SizedBox(width: 10),
            Slider(
              value: _currentParams.buttonHeight,
              min: 40,
              max: 100,
              divisions: 8,
              label: '${_currentParams.buttonHeight.round()}',
              onChanged: (value) {
                setState(() {
                  _currentParams.buttonHeight = value;
                  _updateParams();
                });
              },
            ),
          ],
        ),
        Row(
          children: [
            Text('Border Width:'),
            SizedBox(width: 10),
            Slider(
              value: _currentParams.borderWidth,
              min: 0,
              max: 5,
              divisions: 5,
              label: '${_currentParams.borderWidth.toStringAsFixed(1)}',
              onChanged: (value) {
                setState(() {
                  _currentParams.borderWidth = value;
                  _updateParams();
                });
              },
            ),
          ],
        ),
        Row(
          children: [
            Text('Blur Effect:'),
            SizedBox(width: 10),
            Slider(
              value: _currentParams.blurAmount,
              min: 0,
              max: 20,
              divisions: 10,
              label: '${_currentParams.blurAmount.toStringAsFixed(1)}',
              onChanged: (value) {
                setState(() {
                  _currentParams.blurAmount = value;
                  _updateParams();
                });
              },
            ),
          ],
        ),
        // Gradient Toggle
          Row(
            children: [
              Text('Use Gradient:'),
              Switch(
                value: _currentParams.useGradient,
                onChanged: (value) {
                  setState(() {
                    _currentParams.useGradient = value;
                    _updateParams();
                  });
                },
              ),
            ],
          ),
          if (_currentParams.useGradient)
            Column(
              children: [
                Row(
                  children: [
                    Text('Gradient Start Color:'),
                    SizedBox(width: 10),
                    DropdownButton<Color>(
                      value: _currentParams.gradientStartColor,
                      items: [
                DropdownMenuItem(value: Colors.blue, child: Text('Blue')),
                DropdownMenuItem(value: Colors.red, child: Text('Red')),
                DropdownMenuItem(value: Colors.green, child: Text('Green')),
                DropdownMenuItem(value: Colors.orange, child: Text('Orange')),
                DropdownMenuItem(value: Colors.purple, child: Text('Purple')),
                DropdownMenuItem(value: Colors.yellow, child: Text('Yellow')),
                DropdownMenuItem(value: Colors.cyan, child: Text('Cyan')),
                DropdownMenuItem(value: Colors.pink, child: Text('Pink')),
                DropdownMenuItem(value: Colors.brown, child: Text('Brown')),
                DropdownMenuItem(value: Colors.grey, child: Text('Grey')),
                DropdownMenuItem(value: Colors.black, child: Text('Black')),
                DropdownMenuItem(value: Colors.white, child: Text('White')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          // Update the selected gradient start color
                          _currentParams.gradientStartColor = value!;
                          _updateParams();
                        });
                      },
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text('Gradient End Color:'),
                    SizedBox(width: 10),
                    DropdownButton<Color>(
                      value: _currentParams.gradientEndColor,
                      items: [
                DropdownMenuItem(value: Colors.blue, child: Text('Blue')),
                DropdownMenuItem(value: Colors.red, child: Text('Red')),
                DropdownMenuItem(value: Colors.green, child: Text('Green')),
                DropdownMenuItem(value: Colors.orange, child: Text('Orange')),
                DropdownMenuItem(value: Colors.purple, child: Text('Purple')),
                DropdownMenuItem(value: Colors.yellow, child: Text('Yellow')),
                DropdownMenuItem(value: Colors.cyan, child: Text('Cyan')),
                DropdownMenuItem(value: Colors.pink, child: Text('Pink')),
                DropdownMenuItem(value: Colors.brown, child: Text('Brown')),
                DropdownMenuItem(value: Colors.grey, child: Text('Grey')),
                DropdownMenuItem(value: Colors.black, child: Text('Black')),
                DropdownMenuItem(value: Colors.white, child: Text('White')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          // Update only the dropdown value
                          _currentParams.gradientEndColor = value!;
                          _updateParams();
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          // Font Family
          Row(
            children: [
              Text('Font Family:'),
              SizedBox(width: 10),
              DropdownButton<String>(
                value: _currentParams.fontFamily,
                items: [
                  DropdownMenuItem(value: 'Roboto', child: Text('Roboto')),
                  DropdownMenuItem(value: 'Lobster', child: Text('Lobster')),
                  DropdownMenuItem(value: 'OpenSans', child: Text('OpenSans')),
                ],
                onChanged: (value) {
                  setState(() {
                    _currentParams.fontFamily = value!;
                    _updateParams();
                  });
                },
              ),
            ],
          ),
          // Shadow
          Row(
            children: [
              Text('Shadow Color:'),
              SizedBox(width: 10),
              DropdownButton<Color>(
                value: _currentParams.shadowColor,
                items: [
                  DropdownMenuItem(value: Colors.black26, child: Text('Black26')),
                  DropdownMenuItem(value: Colors.black45, child: Text('Black45')),
                  DropdownMenuItem(value: Colors.grey, child: Text('Grey')),
                ],
                onChanged: (value) {
                  setState(() {
                    _currentParams.shadowColor = value!;
                    _updateParams();
                  });
                },
              ),
            ],
          ),
          Row(
            children: [
              Text('Show Loading:'),
              Switch(
                value: _currentParams.isLoading,
                onChanged: (value) {
                  setState(() {
                    _currentParams.isLoading = value;
                    _updateParams();
                  });
                },
              ),
            ],
          ),
          // Button Shape
          Row(
            children: [
              Text('Button Shape:'),
              SizedBox(width: 10),
              DropdownButton<BoxShape>(
                value: _currentParams.shape,
                items: [
                  DropdownMenuItem(value: BoxShape.rectangle, child: Text('Rectangle')),
                  DropdownMenuItem(value: BoxShape.circle, child: Text('Circle')),
                ],
                onChanged: (value) {
                  setState(() {
                    _currentParams.shape = value!;
                    _updateParams();
                  });
                },
              ),
            ],
          ),

          // Leading Icon
          Row(
            children: [
              Text('Leading Icon:'),
              SizedBox(width: 10),
              DropdownButton<IconData>(
                value: _currentParams.leadingIcon,
                items: [
                  DropdownMenuItem(value: Icons.star, child: Text('Star')),
                  DropdownMenuItem(value: Icons.home, child: Text('Home')),
                  DropdownMenuItem(value: Icons.favorite, child: Text('Favorite')),
                ],
                onChanged: (value) {
                  setState(() {
                    _currentParams.leadingIcon = value;
                    _updateParams();
                  });
                },
              ),
            ],
          ),

          // Trailing Icon
          Row(
            children: [
              Text('Trailing Icon:'),
              SizedBox(width: 10),
              DropdownButton<IconData>(
                value: _currentParams.trailingIcon,
                items: [
                  DropdownMenuItem(value: Icons.arrow_forward, child: Text('Arrow Forward')),
                  DropdownMenuItem(value: Icons.check, child: Text('Check')),
                  DropdownMenuItem(value: Icons.share, child: Text('Share')),
                ],
                onChanged: (value) {
                  setState(() {
                    _currentParams.trailingIcon = value;
                    _updateParams();
                  });
                },
              ),
            ],
          ),

          // Font Family
          Row(
            children: [
              Text('Font Family:'),
              SizedBox(width: 10),
              DropdownButton<String>(
                value: _currentParams.fontFamily,
                items: [
                  DropdownMenuItem(value: 'Roboto', child: Text('Roboto')),
                  DropdownMenuItem(value: 'Lobster', child: Text('Lobster')),
                  DropdownMenuItem(value: 'OpenSans', child: Text('Open Sans')),
                ],
                onChanged: (value) {
                  setState(() {
                    _currentParams.fontFamily = value!;
                    _updateParams();
                  });
                },
              ),
            ],
          ),

          // Enable/Disable Button
          Row(
            children: [
              Text('Enable Button:'),
              Switch(
                value: _currentParams.isEnabled,
                onChanged: (value) {
                  setState(() {
                    _currentParams.isEnabled = value;
                    _updateParams();
                  });
                },
              ),
            ],
          ),
      ],
    );
  }
  
}
