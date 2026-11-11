/// 密度三档（TOKENS.md §2.1）。
///
/// 机制：只换这一组变量，正文列宽 / 时间轴宽度 / 栏宽**不动**。
/// 禁止在 widget 里逐处写死像素 —— 一律读本枚举。
enum DensityProfile {
  /// 紧凑档。
  compact(
    bodySize: 14,
    lineHeight: 1.5,
    labelSize: 12,
    h2Size: 17,
    padH: 11,
    padV: 9,
    gapSec: 16,
  ),

  /// 舒适档（默认）。
  comfortable(
    bodySize: 15,
    lineHeight: 1.66,
    labelSize: 12.5,
    h2Size: 19,
    padH: 14,
    padV: 12,
    gapSec: 22,
  ),

  /// 宽松档。
  roomy(
    bodySize: 16.5,
    lineHeight: 1.84,
    labelSize: 13.5,
    h2Size: 21,
    padH: 18,
    padV: 16,
    gapSec: 28,
  );

  /// 构造密度档位；各字段含义见下方同名成员。
  const DensityProfile({
    required this.bodySize,
    required this.lineHeight,
    required this.labelSize,
    required this.h2Size,
    required this.padH,
    required this.padV,
    required this.gapSec,
  });

  /// 正文字号。
  final double bodySize;

  /// 正文行高。
  final double lineHeight;

  /// 标签字号。
  final double labelSize;

  /// 段标题字号。
  final double h2Size;

  /// 卡片内边距横向。
  final double padH;

  /// 卡片内边距纵向。
  final double padV;

  /// 段间距。
  final double gapSec;
}
