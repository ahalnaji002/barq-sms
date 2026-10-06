part of '../home_screen.dart';

class AnimatedEntrance extends StatelessWidget {
  final AnimationController controller;
  final double begin;
  final double end;
  final Offset offset;
  final Widget child;

  const AnimatedEntrance({
    super.key,
    required this.controller,
    required this.begin,
    required this.end,
    required this.offset,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final curvedAnimation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        begin,
        end,
        curve: Curves.easeOutCubic,
      ),
    );

    final slideAnimation = Tween<Offset>(
      begin: offset,
      end: Offset.zero,
    ).animate(curvedAnimation);

    return FadeTransition(
      opacity: curvedAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: child,
      ),
    );
  }
}

class AnimatedBoltIcon extends StatefulWidget {
  const AnimatedBoltIcon({super.key});

  @override
  State<AnimatedBoltIcon> createState() => _AnimatedBoltIconState();
}

class _AnimatedBoltIconState extends State<AnimatedBoltIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1500,
      ),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 1.10,
        ).chain(
          CurveTween(
            curve: Curves.easeOut,
          ),
        ),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.10,
          end: 1,
        ).chain(
          CurveTween(
            curve: Curves.easeIn,
          ),
        ),
        weight: 50,
      ),
    ]).animate(_controller);

    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0,
          end: -0.035,
        ),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: -0.035,
          end: 0.035,
        ),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 0.035,
          end: 0,
        ),
        weight: 25,
      ),
    ]).animate(_controller);

    _controller.repeat(
      reverse: false,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
        );
      },
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.28),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.45),
          ),
        ),
        child: Icon(
          Icons.bolt_rounded,
          size: 47,
          color: AppColors.card(context),
        ),
      ),
    );
  }
}

class DashboardStatCard extends StatefulWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  final Color iconBackground;
  final bool animateNumber;

  const DashboardStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
    required this.iconBackground,
    this.animateNumber = false,
  });

  @override
  State<DashboardStatCard> createState() => _DashboardStatCardState();
}

class _DashboardStatCardState extends State<DashboardStatCard> {
  double _previousValue = 0.0;

  double get _currentValue {
    return double.tryParse(widget.value) ?? 0.0;
  }

  @override
  void didUpdateWidget(covariant DashboardStatCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.animateNumber) {
      _previousValue = double.tryParse(oldWidget.value) ?? _previousValue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 155,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
            color: AppColors.border(context),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow(context),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: widget.iconBackground,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                widget.icon,
                color: widget.iconColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.animateNumber)
              TweenAnimationBuilder<double>(
                tween: Tween<double>(
                  begin: _previousValue,
                  end: _currentValue,
                ),
                duration: const Duration(milliseconds: 850),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Text(
                    value.round().toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text(context),
                    ),
                  );
                },
              )
            else
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: Tween<double>(
                        begin: 0.82,
                        end: 1.0,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  widget.value,
                  key: ValueKey(widget.value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text(context),
                  ),
                ),
              ),
            const SizedBox(height: 3),
            Text(
              widget.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.25,
                color: AppColors.subtitle(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedNumber extends StatelessWidget {
  final int value;
  final TextStyle? style;

  const AnimatedNumber({
    super.key,
    required this.value,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 0.0,
        end: value.toDouble(),
      ),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Text(
          animatedValue.round().toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style ??
              TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.text(context),
              ),
        );
      },
    );
  }
}

class HomeActionCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool isLoading;

  const HomeActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  State<HomeActionCard> createState() => _HomeActionCardState();
}

class _HomeActionCardState extends State<HomeActionCard> {
  static const Color primaryColor = Color(0xFFFFB300);

  bool _isPressed = false;

  void _changePressedState(bool value) {
    if (!mounted) return;

    setState(() {
      _isPressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.975 : 1,
      duration: const Duration(
        milliseconds: 120,
      ),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 180,
        ),
        margin: const EdgeInsets.only(
          bottom: 13,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow(context).withValues(
                alpha: _isPressed ? 0.05 : 0.10,
              ),
              blurRadius: _isPressed ? 6 : 12,
              offset: Offset(
                0,
                _isPressed ? 2 : 4,
              ),
            ),
          ],
        ),
        child: Material(
          color: AppColors.card(context),
          borderRadius: BorderRadius.circular(19),
          child: InkWell(
            borderRadius: BorderRadius.circular(19),
            onTap: widget.isLoading ? null : widget.onTap,
            onTapDown: widget.isLoading
                ? null
                : (_) {
                    _changePressedState(true);
                  },
            onTapUp: widget.isLoading
                ? null
                : (_) {
                    _changePressedState(false);
                  },
            onTapCancel: widget.isLoading
                ? null
                : () {
                    _changePressedState(false);
                  },
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(19),
                border: Border.all(
                  color: AppColors.border(context),
                ),
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 250,
                    ),
                    width: 57,
                    height: 57,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(
                        milliseconds: 280,
                      ),
                      transitionBuilder: (
                        child,
                        animation,
                      ) {
                        return FadeTransition(
                          opacity: animation,
                          child: ScaleTransition(
                            scale: animation,
                            child: child,
                          ),
                        );
                      },
                      child: widget.isLoading
                          ? const Padding(
                              key: ValueKey(
                                'loading',
                              ),
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.7,
                                color: primaryColor,
                              ),
                            )
                          : Icon(
                              widget.icon,
                              key: ValueKey(
                                widget.icon,
                              ),
                              color: primaryColor,
                              size: 29,
                            ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.text(context),
                          ),
                        ),
                        const SizedBox(height: 5),
                        AnimatedSwitcher(
                          duration: const Duration(
                            milliseconds: 280,
                          ),
                          child: Text(
                            widget.subtitle,
                            key: ValueKey(
                              widget.subtitle,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.35,
                              color: AppColors.subtitle(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedContainer(
                    duration: const Duration(
                      milliseconds: 180,
                    ),
                    width: 34,
                    height: 34,
                    transform: Matrix4.translationValues(
                      _isPressed ? -2 : 0,
                      0,
                      0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.card(context),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: AppColors.subtitle(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
