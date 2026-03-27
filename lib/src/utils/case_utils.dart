/// Converts snake_case to UpperCamelCase (PascalCase).
/// Example: 'product_detail' → 'ProductDetail'
String toUpperCamelCase(String input) {
  return input
      .split('_')
      .map((String word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
      .join();
}

/// Converts snake_case to lowerCamelCase.
/// Example: 'product_detail' → 'productDetail'
String toLowerCamelCase(String input) {
  final String pascal = toUpperCamelCase(input);
  if (pascal.isEmpty) return pascal;
  return pascal[0].toLowerCase() + pascal.substring(1);
}

/// Validates that a string is valid snake_case.
bool isValidSnakeCase(String input) => RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(input);
