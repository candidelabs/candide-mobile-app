extension BigIntExtensions on BigInt {
  BigInt scale(double scale) {
    if (!scale.isFinite) throw ArgumentError.value(scale, "scale", "Must be a finite value");
    var value = this;
    if (scale.isNegative) {
      scale = -scale;
      value = -value;
    }
    var exponent = 0;
    while (scale < 0x10000000000000 /*2^52*/) {
      // Potential fractional part.
      scale *= 0x100000000;
      exponent += 32;
    }
    return (value * BigInt.from(scale)) >> exponent;
  }
}