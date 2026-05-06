import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../app/l10n/app_localization.dart';
import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../core/widgets/pressable.dart';
import 'data/support_billing_service.dart';
import 'domain/entities/support_plan.dart';

class HelpProjectScreen extends StatefulWidget {
  const HelpProjectScreen({super.key});

  @override
  State<HelpProjectScreen> createState() => _HelpProjectScreenState();
}

class _HelpProjectScreenState extends State<HelpProjectScreen> {
  int _selectedIndex = 0;
  final SupportBillingService _billing = SupportBillingService();
  late final StreamSubscription<List<PurchaseDetails>> _purchaseSubscription;
  Map<String, SupportProduct> _productsById = {};
  bool _purchasePending = false;

  final List<SupportPlan> _plans = const [
    SupportPlan(
      months: 12,
      discountLabel: '-24%',
      priceLabel: '1 750 ₽',
      productId: 'support_12_months',
    ),
    SupportPlan(
      months: 3,
      discountLabel: '-18%',
      priceLabel: '490 ₽',
      productId: 'support_3_months',
    ),
    SupportPlan(
      months: 1,
      discountLabel: null,
      priceLabel: '199 ₽',
      productId: 'support_1_month',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _purchaseSubscription = _billing.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _purchaseSubscription.cancel(),
      onError: (_) {
        if (!mounted) return;
        setState(() => _purchasePending = false);
        _showMessage(_purchaseUnavailableMessage);
      },
    );
    unawaited(_loadProducts());
  }

  @override
  void dispose() {
    _purchaseSubscription.cancel();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final products = await _billing.loadProducts(_plans);
    if (!mounted) return;
    setState(() => _productsById = products);
  }

  Future<void> _buySelectedPlan() async {
    if (_purchasePending) return;
    final selected = _plans[_selectedIndex];
    final product = _productsById[selected.productId];
    if (product == null) {
      _showMessage(_purchaseUnavailableMessage);
      return;
    }

    setState(() => _purchasePending = true);
    try {
      final started = await _billing.buy(product);
      if (!started) {
        if (!mounted) return;
        setState(() => _purchasePending = false);
        _showMessage(_purchaseUnavailableMessage);
      }
    } catch (e) {
      debugPrint('[HelpProjectScreen] _onPurchaseTap failed: $e');
      if (!mounted) return;
      setState(() => _purchasePending = false);
      _showMessage(_purchaseUnavailableMessage);
    }
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.pending) {
        if (mounted) setState(() => _purchasePending = true);
        continue;
      }

      if (purchase.pendingCompletePurchase) {
        await _billing.completePurchase(purchase);
      }

      if (!mounted) continue;
      setState(() => _purchasePending = false);
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        _showMessage(_purchaseSuccessMessage);
      } else if (purchase.status == PurchaseStatus.error) {
        _showMessage(_purchaseUnavailableMessage);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String get _purchaseUnavailableMessage => context.locale.languageCode == 'ru'
      ? 'Покупка пока недоступна'
      : 'Purchase is currently unavailable';

  String get _purchaseSuccessMessage => context.locale.languageCode == 'ru'
      ? 'Спасибо за поддержку'
      : 'Thank you for your support';

  @override
  Widget build(BuildContext context) {
    final isRussian = context.locale.languageCode == 'ru';
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: Stack(
          children: [
            const _Background(),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
                    child: Row(
                      children: [
                        _CircleBackButton(
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 18.h),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          context.t('support.thankYouTitle'),
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          context.t('support.description'),
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w400,
                            height: 1,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 33.h),
                        for (var i = 0; i < _plans.length; i++) ...[
                          _PlanTile(
                            plan: _plans[i],
                            product: _productsById[_plans[i].productId],
                            selected: i == _selectedIndex,
                            onTap: () => setState(() => _selectedIndex = i),
                          ),
                          if (i != _plans.length - 1) SizedBox(height: 14.h),
                        ],
                        SizedBox(height: 33.h),
                        _SupportLinks(
                          isColumn: isRussian,
                          privacyLabel: context.t('support.privacyPolicy'),
                          termsLabel: context.t('support.termsOfService'),
                          onPrivacyTap: () {},
                          onTermsTap: () {},
                        ),
                        SizedBox(height: isRussian ? 16.h : 12.h),
                        _SubscribeButton(
                          onTap: _purchasePending
                              ? null
                              : () => unawaited(_buySelectedPlan()),
                          loading: _purchasePending,
                        ),
                        SizedBox(height: 12.h),
                        Text(
                          context.t('support.disclaimer'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w400,
                            height: 1.1,
                            color: Colors.white.withAlpha(190),
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.plan,
    required this.product,
    required this.selected,
    required this.onTap,
  });

  final SupportPlan plan;
  final SupportProduct? product;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? Colors.white.withAlpha(52)
        : Colors.white.withValues(alpha: 0.12);
    final border = selected ? Colors.white : null;

    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.inner.r),
      child: Container(
        height: 56.h,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadii.inner.r),
          border: border == null ? null : Border.all(color: border, width: 1),
        ),
        child: Row(
          children: [
            _CheckBox(selected: selected),
            SizedBox(width: 16.w),
            Expanded(
              child: Row(
                children: [
                  Text(
                    _monthPlanLabel(context, plan.months),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.36,
                      letterSpacing: 0.1,
                    ),
                  ),
                  if (plan.discountLabel != null) ...[
                    SizedBox(width: 16.w),
                    _DiscountBadge(text: plan.discountLabel!),
                  ],
                ],
              ),
            ),
            Text(
              product?.price ?? plan.priceLabel,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.36,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _monthPlanLabel(BuildContext context, int months) {
  if (context.locale.languageCode != 'ru') {
    return months == 1 ? '$months month' : '$months months';
  }

  final mod10 = months % 10;
  final mod100 = months % 100;
  final suffix = mod10 == 1 && mod100 != 11
      ? 'месяц'
      : mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)
      ? 'месяца'
      : 'месяцев';
  return '$months $suffix';
}

class _DiscountBadge extends StatelessWidget {
  const _DiscountBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(AppRadii.chip.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  const _CheckBox({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final borderColor = Colors.white.withAlpha(180);
    return Container(
      width: 20.r,
      height: 20.r,
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(6.r),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: selected
          ? Icon(
              Icons.check_rounded,
              size: 12.r,
              color: const Color(0xFF0A1B4D),
            )
          : null,
    );
  }
}

class _LinkText extends StatelessWidget {
  const _LinkText({
    required this.label,
    required this.onTap,
    required this.textAlign,
  });

  final String label;
  final TextAlign textAlign;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRussian = context.locale.languageCode == 'ru';
    return Pressable(
      onTap: onTap,
      child: Text(
        label,
        textAlign: textAlign,
        style: TextStyle(
          fontSize: isRussian ? 10.sp : 14.sp,
          fontWeight: FontWeight.w400,
          color: Colors.white,
          height: 1,
        ),
      ),
    );
  }
}

class _SupportLinks extends StatelessWidget {
  const _SupportLinks({
    required this.isColumn,
    required this.privacyLabel,
    required this.termsLabel,
    required this.onPrivacyTap,
    required this.onTermsTap,
  });

  final bool isColumn;
  final String privacyLabel;
  final String termsLabel;
  final VoidCallback onPrivacyTap;
  final VoidCallback onTermsTap;

  @override
  Widget build(BuildContext context) {
    final links = [
      _LinkText(
        label: privacyLabel,
        onTap: onPrivacyTap,
        textAlign: TextAlign.start,
      ),
      _LinkText(label: termsLabel, onTap: onTermsTap, textAlign: TextAlign.end),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Align(alignment: Alignment.centerLeft, child: links[0]),
        ),
        SizedBox(width: 16.w),
        Flexible(
          child: Align(alignment: Alignment.centerRight, child: links[1]),
        ),
      ],
    );
  }
}

class _SubscribeButton extends StatelessWidget {
  const _SubscribeButton({required this.onTap, required this.loading});

  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.inner.r),
      child: Container(
        height: 52.h,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadii.inner.r),
        ),
        child: Center(
          child: loading
              ? SizedBox(
                  width: 18.r,
                  height: 18.r,
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF24398B),
                  ),
                )
              : Text(
                  context.t('support.subscribe'),
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF24398B),
                    height: 1.2,
                  ),
                ),
        ),
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  const _CircleBackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final radius = 22.r;
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(color: colors.card, shape: BoxShape.circle),
        child: SvgPicture.asset(
          'assets/icons/back.svg',
          width: 7.r,
          height: 15.r,
          fit: BoxFit.none,
          colorFilter: ColorFilter.mode(colors.textPrimary, BlendMode.srcIn),
        ),
      ),
    );
  }
}

class _Background extends StatelessWidget {
  const _Background();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withAlpha(26),
              Colors.black.withAlpha(110),
              Colors.black.withAlpha(190),
            ],
            stops: const [0.0, 0.55, 0.78, 1.0],
          ),
        ),
      ),
    );
  }
}
