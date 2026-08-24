String fmt(double v) {
  if (v.abs() >= 1e9) return '${(v / 1e9).toStringAsFixed(2)}B';
  if (v.abs() >= 1e6) return '${(v / 1e6).toStringAsFixed(2)}M';
  if (v.abs() >= 1e3) return '${(v / 1e3).toStringAsFixed(2)}K';
  if (v.abs() >= 1) return v.toStringAsFixed(2);
  if (v.abs() >= 0.01) return v.toStringAsFixed(4);
  return v.toStringAsFixed(6);
}
