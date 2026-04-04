import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/l10n/app_localization.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/ui_kit/app_button.dart';
import '../../../core/widgets/pressable.dart';
import '../../settings/gender/data/gender_repository_memory.dart';
import '../../settings/gender/domain/entities/app_gender.dart';
import '../../settings/gender/domain/usecases/get_available_genders.dart';
import '../../settings/gender/domain/usecases/get_selected_gender.dart';
import '../../settings/gender/domain/usecases/set_selected_gender.dart';
import '../../settings/gender/presentation/gender_controller.dart';
import '../../settings/language/data/language_repository_memory.dart';
import '../../settings/language/domain/entities/app_language.dart';
import '../../settings/language/domain/usecases/get_available_languages.dart';
import '../../settings/language/domain/usecases/get_selected_language.dart';
import '../../settings/language/domain/usecases/set_selected_language.dart';
import '../../settings/language/presentation/language_bottom_sheet.dart';
import '../../settings/language/presentation/language_controller.dart';

class OnboardingStartScreen extends StatefulWidget {
  const OnboardingStartScreen({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  State<OnboardingStartScreen> createState() => _OnboardingStartScreenState();
}

class _OnboardingStartScreenState extends State<OnboardingStartScreen> {
  late final GenderController _genderController;
  late final LanguageController _languageController;

  @override
  void initState() {
    super.initState();
    final genderRepo = GenderRepositoryMemory.instance;
    _genderController = GenderController(
      getAvailableGenders: GetAvailableGenders(genderRepo),
      getSelectedGender: GetSelectedGender(genderRepo),
      setSelectedGender: SetSelectedGender(genderRepo),
    );

    final languageRepo = LanguageRepositoryMemory.instance;
    _languageController = LanguageController(
      getAvailableLanguages: GetAvailableLanguages(languageRepo),
      getSelectedLanguage: GetSelectedLanguage(languageRepo),
      setSelectedLanguage: SetSelectedLanguage(languageRepo),
    );
  }

  @override
  void dispose() {
    _genderController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 40.h, 16.w, 12.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 7),
              Text(
                context.t('onboarding.start.title'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24.sp,
                  height: 1.0,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: 40.h),
              Text(
                context.t('onboarding.start.gender'),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),
              AnimatedBuilder(
                animation: _genderController,
                builder: (context, _) {
                  return _GenderSegmented(
                    selectedId: _genderController.selected.id,
                    onSelect: (gender) => _genderController.select(gender),
                  );
                },
              ),
              SizedBox(height: 24.h),
              Text(
                context.t('onboarding.start.language'),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              SizedBox(height: 12.h),
              AnimatedBuilder(
                animation: _languageController,
                builder: (context, _) {
                  return _LanguageField(
                    language: _languageController.selected,
                    onTap: _openLanguageSheet,
                  );
                },
              ),
              const Spacer(flex: 8),
              AppButton(
                label: context.t('common.next'),
                onPressed: widget.onNext,
                variant: AppButtonVariant.primary,
                size: AppButtonSize.medium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openLanguageSheet() async {
    final selected = await showLanguageBottomSheet(context);
    if (!mounted || selected == null) return;
    _languageController.select(selected);
    await context.setLocale(Locale(selected.id));
    if (!mounted) return;
    setState(() {});
  }
}

class _GenderSegmented extends StatelessWidget {
  const _GenderSegmented({required this.selectedId, required this.onSelect});

  final String selectedId;
  final ValueChanged<AppGender> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(AppRadii.pill.r);
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: isDark ? colors.soft : colors.card,
        borderRadius: radius,
      ),
      child: Row(
        children: [
          Expanded(
            child: _GenderOption(
              label: context.t('gender.male'),
              selected: selectedId == 'male',
              onTap: () => onSelect(const AppGender(id: 'male', label: 'Male')),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _GenderOption(
              label: context.t('gender.female'),
              selected: selectedId == 'female',
              onTap: () =>
                  onSelect(const AppGender(id: 'female', label: 'Female')),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderOption extends StatelessWidget {
  const _GenderOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = selected ? colors.primary : Colors.transparent;
    final fg = selected
        ? Colors.white
        : (isDark ? colors.textSecondary : colors.textMuted);
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.pill.r),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 41.h,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadii.pill.r),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageField extends StatelessWidget {
  const _LanguageField({required this.language, required this.onTap});

  final AppLanguage language;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.inner.r),
      child: Container(
        height: 56.h,
        padding: EdgeInsets.symmetric(horizontal: 22.w),
        decoration: BoxDecoration(
          color: isDark ? colors.soft : colors.card,
          borderRadius: BorderRadius.circular(AppRadii.inner.r),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                localizedLanguageLabel(context, language.id),
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: colors.textPrimary,
                ),
              ),
            ),
            SvgPicture.asset(
              'assets/icons/arrow-bottom.svg',
              width: 15.r,
              colorFilter: ColorFilter.mode(
                colors.textPrimary,
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
