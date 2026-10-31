List<Filters> filters = [
  Filters([], 'Normal'),
  Filters([
    1.0,
    0.2,
    0,
    0,
    0,
    0.2,
    1.0,
    0.2,
    0,
    0,
    0,
    0.2,
    1.0,
    0,
    0,
    0,
    0,
    0,
    1,
    0
  ], 'Vintage'),
  Filters([
    1.2,
    0.1,
    0,
    0,
    0,
    0.1,
    1.1,
    0.1,
    0,
    0,
    0,
    0.1,
    1.0,
    0,
    0,
    0,
    0,
    0,
    1,
    0
  ], 'Warm'),
  Filters(
      [0.8, 0, 0, 0, 0, 0, 0.8, 0.1, 0, 0, 0.1, 0.1, 1.2, 0, 0, 0, 0, 0, 1, 0],
      'Blue'),
  // Filters([0.5, 0.5, 1.0, 0, 0, 0.5, 0.5, 1.0, 0, 0, 0.5, 0.5, 1.0, 0, 0, 0, 0, 0, 1, 0], 'Blue'),
  Filters([
    0.33,
    0.33,
    0.33,
    0,
    0,
    0.33,
    0.33,
    0.33,
    0,
    0,
    0.33,
    0.33,
    0.33,
    0,
    0,
    0,
    0,
    0,
    1,
    0
  ], 'Grayscale'),
  // High Saturation
  // Filters([1.5, 0.5, 0.5, 0, 0, 0.5, 1.5, 0.5, 0, 0, 0.5, 0.5, 1.5, 0, 0, 0, 0, 0, 1, 0], 'High Saturation'),
  // Low Saturation
  Filters([
    0.5,
    0.25,
    0.25,
    0,
    0,
    0.25,
    0.5,
    0.25,
    0,
    0,
    0.25,
    0.25,
    0.5,
    0,
    0,
    0,
    0,
    0,
    1,
    0
  ], 'Low Saturation'),
  // Night Vision
  Filters([
    0.1,
    0.4,
    0,
    0,
    0,
    0.3,
    1.0,
    0.3,
    0,
    0,
    0,
    0.4,
    0.1,
    0,
    0,
    0,
    0,
    0,
    1,
    0
  ], 'Night Vision'),
  // Vintage Purple
  // Filters([0.6, 0.2, 0.8, 0, 0, 0.3, 0.3, 0.5, 0, 0, 0.3, 0.1, 0.6, 0, 0, 0, 0, 0, 1, 0], 'Vintage Purple'),
  // Cool Tone
  Filters([
    0.9,
    0.1,
    0,
    0,
    0,
    0.1,
    0.9,
    0.1,
    0,
    0,
    0,
    0.1,
    1.1,
    0,
    0,
    0,
    0,
    0,
    1,
    0
  ], 'Cool Tone'),
  // Warm Tone
  Filters([
    1.2,
    0.2,
    0.1,
    0,
    0,
    0.2,
    1.1,
    0.1,
    0,
    0,
    0.1,
    0.1,
    0.9,
    0,
    0,
    0,
    0,
    0,
    1,
    0
  ], 'Warm Tone'),

  // Green Boost
  Filters([
    1.0,
    0.1,
    0,
    0,
    0,
    0.1,
    1.5,
    0.1,
    0,
    0,
    0,
    0.1,
    1.0,
    0,
    0,
    0,
    0,
    0,
    1,
    0
  ], 'Green Boost'),

  // Sepia Tone
  // Filters([0.39, 0.77, 0.19, 0, 0, 0.35, 0.69, 0.17, 0, 0, 0.27, 0.53, 0.13, 0, 0, 0, 0, 0, 1, 0], 'Sepia'),

  // High Contrast
  Filters([
    1.5,
    -0.5,
    -0.5,
    0,
    0,
    -0.5,
    1.5,
    -0.5,
    0,
    0,
    -0.5,
    -0.5,
    1.5,
    0,
    0,
    0,
    0,
    0,
    1,
    0
  ], 'High Contrast'),

  // Red Boost
  Filters([
    1.5,
    0.2,
    0.2,
    0,
    0,
    0.1,
    1.0,
    0.1,
    0,
    0,
    0.1,
    0.1,
    1.0,
    0,
    0,
    0,
    0,
    0,
    1,
    0
  ], 'Red Boost'),

  // Dusky Purple
  // Filters([0.7, 0.1, 1.2, 0, 0, 0.2, 0.7, 0.1, 0, 0, 0.3, 0.2, 0.8, 0, 0, 0, 0, 0, 1, 0], 'Dusky Purple'),

  // Sepia (Brownish Vintage Look)
  // Filters([0.393, 0.769, 0.189, 0, 0, 0.349, 0.686, 0.168, 0, 0, 0.272, 0.534, 0.131, 0, 0, 0, 0, 0, 1, 0], 'Sepia'),

  // Dark Sepia (Stronger Vintage Look)
  // Filters([0.5, 0.7, 0.3, 0, -30, 0.4, 0.6, 0.2, 0, -30, 0.3, 0.5, 0.2, 0, -30, 0, 0, 0, 1, 0], 'Dark Sepia'),

  // Midnight Purple (Deep Purple with Darker Shadows)
  // Filters([0.8, 0.2, 1.0, 0, -20, 0.3, 0.3, 0.7, 0, -20, 0.4, 0.2, 0.8, 0, -20, 0, 0, 0, 1, 0], 'Midnight Purple'),

  // Shadow Boost (Strong Shadow Enhancement)
  Filters(
      [1.0, 0, 0, 0, -60, 0, 1.0, 0, 0, -60, 0, 0, 1.0, 0, -60, 0, 0, 0, 1, 0],
      'Shadow Boost'),

  // Deep Red Wine (Dark Reddish Effect)
  Filters([
    1.3,
    0.1,
    0.2,
    0,
    -30,
    0.1,
    0.9,
    0.1,
    0,
    -30,
    0.2,
    0.2,
    0.8,
    0,
    -30,
    0,
    0,
    0,
    1,
    0
  ], 'Deep Red Wine'),

  // Espresso (Dark Coffee-Like Tone)
  Filters([
    1.2,
    0.4,
    0.2,
    0,
    -40,
    0.3,
    1.0,
    0.3,
    0,
    -40,
    0.2,
    0.2,
    0.7,
    0,
    -40,
    0,
    0,
    0,
    1,
    0
  ], 'Espresso'),
];

class Filters {
  List<double> colorFilter;
  String filterName;

  Filters(this.colorFilter, this.filterName);
}
