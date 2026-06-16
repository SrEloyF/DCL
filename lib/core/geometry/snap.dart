double snapToGrid(double value, double step) {
  if (step <= 0) return value;
  return (value / step).roundToDouble() * step;
}
