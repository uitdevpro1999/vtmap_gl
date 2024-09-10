part of vtmap_gl_platform_interface;

class LayerOptions {
  final String? iconImage;
  final double? iconSize;
  final bool? symbolIconAllowOverlap;
  final String? fillColor;
  final String? fillOutLineColor;
  final double? fillOpacity;

  LayerOptions(
      {this.iconImage,
      this.iconSize,
      this.symbolIconAllowOverlap = false,
      this.fillOpacity,
      this.fillColor,
      this.fillOutLineColor});

  Map<String, dynamic> toMap() {
    final Map<String, dynamic> optionsMap = new Map<String, dynamic>();
    void addIfNonNull(String fieldName, dynamic value) {
      if (value != null) {
        optionsMap[fieldName] = value;
      }
    }

    addIfNonNull("iconImage", iconImage);
    addIfNonNull("iconSize", iconSize);
    addIfNonNull('symbolIconAllowOverlap', symbolIconAllowOverlap);
    addIfNonNull("fillOpacity", fillOpacity);
    addIfNonNull("fillColor", fillColor);
    addIfNonNull("fillOutLineColor", fillOutLineColor);
    return optionsMap;
  }
}

enum LayerType { symbol, fill }
