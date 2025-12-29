import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:park_my_whip_residents/src/core/constants/app_icons.dart';
import 'package:park_my_whip_residents/src/core/constants/colors.dart';
import 'package:park_my_whip_residents/src/core/constants/strings.dart';
import 'package:park_my_whip_residents/src/core/constants/text_style.dart';
import 'package:park_my_whip_residents/src/core/helpers/spacing.dart';
import 'package:park_my_whip_residents/src/core/widgets/common_button.dart';
import 'package:park_my_whip_residents/src/core/widgets/search_text_field.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/resident/resident_onboarding_cubit.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/cubit/resident/resident_onboarding_state.dart';
import 'package:park_my_whip_residents/src/features/onboarding/presentation/widgets/resident/community_selection_item.dart';

/// Shows a bottom sheet for community selection
void showCommunitySelectionBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColor.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (sheetContext) => BlocProvider.value(
      value: context.read<ResidentOnboardingCubit>(),
      child: const _CommunitySelectionBottomSheet(),
    ),
  );
}

class _CommunitySelectionBottomSheet extends StatefulWidget {
  const _CommunitySelectionBottomSheet();

  @override
  State<_CommunitySelectionBottomSheet> createState() =>
      _CommunitySelectionBottomSheetState();
}

class _CommunitySelectionBottomSheetState
    extends State<_CommunitySelectionBottomSheet> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ResidentOnboardingCubit, ResidentOnboardingState>(
      builder: (context, state) {
        final cubit = context.read<ResidentOnboardingCubit>();
        final filteredCommunities = state.filteredCommunities;
        
        return Container(
          height: 747.h,
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              verticalSpace(24),
              
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 15.w,
                  ),
                  Text(
                    OnboardingStrings.chooseYourCommunity,
                    style: AppTextStyles.urbanistFont18Grey800SemiBold1_25,
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      AppIcons.close,
                      size: 15.w,
                      color: AppColor.black,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              
              verticalSpace(16),
              
              // Search field
              SearchTextField(
                hintText: OnboardingStrings.searchForYourCommunity,
                controller: _searchController,
                onChanged: (query) => cubit.onCommunitySearchChanged(query),
                searchActiveHint: OnboardingStrings.searchForYourCommunity,
              ),
              
              verticalSpace(8),
              
              // Communities list
              Expanded(
                child: filteredCommunities.isEmpty
                    ? Center(
                        child: Text(
                          OnboardingStrings.noCommunityFound,
                          style: AppTextStyles.urbanistFont14Grey700Regular1_4,
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredCommunities.length,
                        itemBuilder: (context, index) {
                          final community = filteredCommunities[index];
                          final isSelected = state.tempSelectedCommunity == community;
                          
                          return CommunitySelectionItem(
                            communityName: community,
                            isSelected: isSelected,
                            onTap: () => cubit.onTempCommunitySelected(community),
                          );
                        },
                      ),
              ),
              
              verticalSpace(24),
              
              // Save button
              CommonButton(
                text: OnboardingStrings.save,
                onPressed: () {
                  cubit.onCommunitySaved();
                  Navigator.pop(context);
                },
                isEnabled: state.tempSelectedCommunity != null,
              ),
              
              verticalSpace(24),
            ],
          ),
        );
      },
    );
  }
}
