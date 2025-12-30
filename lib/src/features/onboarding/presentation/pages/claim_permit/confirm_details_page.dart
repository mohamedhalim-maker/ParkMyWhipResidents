import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_app_bar.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_button.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/claim_permit/claim_permit_cubit.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/claim_permit/claim_permit_state.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/widgets/general/contact_us_text.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/widgets/claim_permit/permit_plan_container.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/widgets/claim_permit/vehicle_community_container.dart';

class ConfirmDetailsPage extends StatelessWidget {
  const ConfirmDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          context.read<ClaimPermitCubit>().enableButton();
        }
      },
      child: Scaffold(
        appBar: CommonAppBar(
          onBackPress: () {
            context.read<ClaimPermitCubit>().enableButton();
            Navigator.of(context).pop();
          },
        ),
        resizeToAvoidBottomInset: false,
        body: BlocBuilder<ClaimPermitCubit, ClaimPermitState>(
          builder: (context, state) {
            final data = state.data;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  verticalSpace(16),

                  // Page title
                  Text(
                    OnboardingStrings.confirmYourDetails,
                    style: AppTextStyles.urbanistFont28Grey800SemiBold1_2,
                  ),

                  verticalSpace(8),

                  // Subtitle
                  Text(
                    OnboardingStrings.reviewAndConfirmYourDetails,
                    style: AppTextStyles.urbanistFont16Grey800Regular1_3
                        .copyWith(color: AppColor.gray30),
                  ),

                  verticalSpace(24),

                  // Container 1: Permit Plan
                  PermitPlanContainer(data: data),

                  verticalSpace(16),

                  // Container 2: Vehicle & Community Info
                  VehicleCommunityContainer(data: data),

                  verticalSpace(16),

                  // Contact us text
                  const ContactUsText(),

                  const Spacer(),

                  // Continue to Payment button
                  CommonButton(
                    text: OnboardingStrings.continueToPayment,
                    onPressed: () {
                      // TODO: Navigate to payment or complete onboarding
                    },
                    isEnabled: true,
                  ),

                  verticalSpace(24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
