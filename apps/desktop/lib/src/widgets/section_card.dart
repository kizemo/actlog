import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/density_profile.dart';

/// 今日页各区块共用的卡片外壳。
///
/// 视觉口径（`v2-ledger.html:193-199`）：4px 圆角 + `--hair-soft` 1px 边 +
/// `--card` 底；hover **只把边换成 `--hair-strong`**（不加阴影、不位移）；
/// 段头行**不带 Material 图标**，下沿一条 1px `--hair` 线；
/// 内距读密度档 [DensityProfile] 的 `padH` / `padV`（`--pad-card`）。
class SectionCard extends StatefulWidget {
  /// 创建区块卡片。
  const SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.accent,
    super.key,
  });

  /// 区块图标。
  ///
  /// **仅为兼容既有调用方保留**：B 版段头已按 `.sec-h` 去掉前置图标
  /// （D-11），本参数不再参与渲染。
  final IconData icon;

  /// 区块标题。
  final String title;

  /// 标题下的一行说明（可为空）。
  final String? subtitle;

  /// 标题行右侧动作（可为空）。
  final Widget? trailing;

  /// 强调色。
  ///
  /// **仅为兼容既有调用方保留**：图标移除后无消费点；段头的缺口语义
  /// 由 `SectionHeader` 的赭石描边承担，不在卡片壳上着色。
  final Color? accent;

  /// 区块内容。
  final Widget child;

  @override
  State<SectionCard> createState() => _SectionCardState();
}

class _SectionCardState extends State<SectionCard> {
  bool _hovered = false;

  /// 从主题反查密度档。
  ///
  /// [DensityProfile] 目前只经 `AppTheme` 落成 `TextTheme` 字号，没有独立的
  /// provider / ThemeExtension 读取入口（`app_theme.dart` 不在本单元写集内）。
  /// 主题里唯一能区分三档的痕迹就是正文字号，故按字号反查，避免在控件里
  /// 再写死一份 `12 / 14 / 18`；查不到时回退舒适档。
  static DensityProfile _densityOf(ThemeData theme) {
    final size = theme.textTheme.bodyLarge?.fontSize;
    for (final density in DensityProfile.values) {
      if (density.bodySize == size) {
        return density;
      }
    }
    return DensityProfile.comfortable;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final density = _densityOf(theme);
    final hasSubtitle =
        widget.subtitle != null && widget.subtitle!.isNotEmpty;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.symmetric(vertical: AppTokens.gapCard / 2),
        padding: EdgeInsets.symmetric(
          horizontal: density.padH,
          vertical: density.padV,
        ),
        decoration: BoxDecoration(
          color: AppTokens.card,
          borderRadius: BorderRadius.circular(AppTokens.radius),
          border: Border.all(
            color: _hovered ? AppTokens.hairStrong : AppTokens.hairSoft,
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 8),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppTokens.hair, width: 1),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  // 标题 + 说明占满「trailing 之外」的整条宽度并由内层 Row 分配：
                  // 外层若用 `Spacer()` 把 trailing 顶到右边，`Spacer` 会和标题
                  // / 说明抢同一份 flex 剩余空间（不能既 `Spacer` 又 `Flexible`），
                  // 所以改为 `Expanded` 包住标题块，trailing 自然贴右。
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            widget.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppTokens.ink,
                            ),
                          ),
                        ),
                        if (hasSubtitle) ...[
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              widget.subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppTokens.faint,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (widget.trailing != null) ...[
                    const SizedBox(width: 12),
                    KeyedSubtree(
                      key: const ValueKey<String>('section-card-trailing'),
                      child: widget.trailing!,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            widget.child,
          ],
        ),
      ),
    );
  }
}