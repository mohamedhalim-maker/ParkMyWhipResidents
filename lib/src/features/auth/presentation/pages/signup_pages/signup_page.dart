import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/config/injection.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_app_bar.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_button.dart';
import 'package:park_my_whip_residents/src/core/widgets/custom_text_field.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/signup/signup_cubit.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/cubit/signup/signup_state.dart';
import 'package:park_my_whip_residents/src/features/auth/presentation/widgets/already_have_account_text.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        onBackPress: () =>
            getIt<SignupCubit>().navigateBackToLogin(context: context),
      ),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: BlocBuilder<SignupCubit, SignupState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  verticalSpace(10),
                  Text(
                    AuthStrings.letsGetStarted,
                    style: AppTextStyles.urbanistFont34Grey800SemiBold1_2,
                  ),
                  verticalSpace(8),
                  Text(
                    AuthStrings.signupSubtitle,
                    style: AppTextStyles.urbanistFont15LightGrayRegular1_33,
                  ),
                  verticalSpace(24),
                  CustomTextField(
                    title: AuthStrings.emailLabelShort,
                    hintText: AuthStrings.emailHintExample,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    controller: getIt<SignupCubit>().emailController,
                    validator: (_) => state.emailError,
                    onChanged: (_) =>
                        getIt<SignupCubit>().onEmailFieldChanged(),
                  ),
                  verticalSpace(20),
                  const AlreadyHaveAccountText(),
                  const Spacer(),
                  CommonButton(
                    text: AuthStrings.continueText,
                    onPressed: () => getIt<SignupCubit>()
                        .validateEmailForm(context: context),
                    isEnabled: state.isEmailButtonEnabled,
                  ),
                  verticalSpace(16),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
