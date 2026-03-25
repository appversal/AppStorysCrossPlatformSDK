package com.appversal.appstorys.utils

import com.appversal.appstorys.core.engine.TriggerEventMatcher
import com.appversal.appstorys.core.model.Campaign
import com.appversal.appstorys.core.model.TriggerEvent

/**
 * Centralized campaign filtering and eligibility logic for the AppStorys SDK.
 *
 * This utility class consolidates all campaign selection and visibility determination,
 * eliminating duplication across composables and ensuring consistent application of
 * display rules throughout the SDK.
 *
 * ## Key Responsibilities
 *
 * ### Campaign Filtering
 * Filters campaigns by multiple dimensions in a single unified operation:
 * - **Campaign Type** (e.g., "STR" for Stories, "BAN" for Banners, "WID" for Widgets)
 * - **Trigger Eligibility** (via [TriggerEventMatcher.shouldShowCampaign])
 * - **Disabled Status** (checks if campaign is on the disabled list)
 * - **Valid ID** (ensures campaign has a non-null ID)
 *
 * ### Back-Press Campaign Detection
 * Determines if a campaign is eligible to display on back-button press, applying special
 * logic for back-press specific event conditions (see [isBackPressCampaignReady]).
 *
 * ## Design Pattern
 *
 * The engine is **stateless**—each method is a pure function that takes all relevant
 * state as parameters. This makes it easy to test and reason about without side effects.
 *
 * ## Usage Example
 *
 * ```kotlin
 * val engine = CampaignEngine()
 *
 * // Filter for visible Stories campaigns
 * val storiesCampaigns = engine.filterCampaigns(
 *     campaigns = campaignList,
 *     campaignType = "STR",
 *     trackedEvents = userTrackedEvents,
 *     disabledCampaignIds = disabledList
 * )
 *
 * // Check if back-press campaign is ready to show
 * val readyForBackPress = engine.isBackPressCampaignReady(
 *     campaigns = campaignList,
 *     disabledIds = disabledList,
 *     currentEvents = userTrackedEvents,
 *     backPressCampaignConsumed = wasBackPressAlreadyHandled
 * )
 * ```
 *
 * ## Integration
 *
 * Every `@Composable` in the SDK that renders campaigns now delegates filtering to
 * this engine rather than inline filtering logic, ensuring:
 * - Consistency across all campaign types
 * - Easier testing and maintenance
 * - Single source of truth for eligibility rules
 *
 * @see com.appversal.appstorys.AppStorys for SDK integration points
 * @see TriggerEventMatcher for the underlying trigger matching logic
 */
internal class CampaignEngine {
    /**
     * Filters campaigns by type, trigger eligibility, and disabled status.
     *
     * This is the primary filtering method used by all composables. It applies a consistent
     * set of rules to determine which campaigns should be considered for display:
     *
     * 1. **Type Match**: Campaign type must equal the requested [campaignType]
     * 2. **Valid ID**: Campaign must have a non-null ID
     * 3. **Not Disabled**: Campaign ID must not be in [disabledCampaignIds]
     * 4. **Trigger Eligible**: Campaign must pass [TriggerEventMatcher.shouldShowCampaign]
     *    based on current [trackedEvents]
     *
     * ## Parameters
     *
     * @param campaigns Full list of campaigns to filter (typically `AppStorys.campaigns.value`)
     * @param campaignType The campaign type code to match (e.g., "STR", "BAN", "WID", "PIP", "CSAT")
     * @param trackedEvents Set of user-tracked events (used for trigger matching)
     * @param disabledCampaignIds List of campaign IDs that should be hidden/excluded (default: empty)
     *
     * @return List of eligible campaigns matching all criteria, in original order
     *
     * ## Example
     *
     * ```kotlin
     * val bannerCampaigns = engine.filterCampaigns(
     *     campaigns = allCampaigns,
     *     campaignType = "BAN",
     *     trackedEvents = trackedEventNames.value,
     *     disabledCampaignIds = disabledCampaigns.value
     * )
     * val banner = bannerCampaigns.firstOrNull { it.details is BannerDetails }
     * ```
     *
     * @see TriggerEventMatcher.shouldShowCampaign for trigger evaluation logic
     */
    fun filterCampaigns(
        campaigns: List<Campaign>,
        campaignType: String,
        trackedEvents: Set<TriggerEventMatcher.TrackedEventData>,
        disabledCampaignIds: List<String> = emptyList()
    ): List<Campaign> {
        return campaigns.filter { campaign ->
            campaign.campaignType == campaignType &&
            campaign.id != null &&
            !disabledCampaignIds.contains(campaign.id) &&
            TriggerEventMatcher.shouldShowCampaign(
                triggerEvent = campaign.triggerEvent,
                campaignId = campaign.id,
                trackedEvents = trackedEvents
            )
        }
    }

    /**
     * Determines if a back-press triggered campaign is eligible to display.
     *
     * Back-press campaigns have special trigger logic: they activate when the user presses
     * the back button, but only if:
     * 1. The campaign hasn't already consumed this back-press event
     * 2. The campaign hasn't been explicitly disabled
     * 3. The campaign has a back-press trigger configured
     * 4. (Optional) Any additional event conditions on the back-press are satisfied
     *
     * ## Parameters
     *
     * @param campaigns Full list of campaigns to search
     * @param disabledIds List of disabled campaign IDs
     * @param currentEvents Set of currently tracked events (for condition matching)
     * @param backPressCampaignConsumed Flag indicating if back-press has already been handled
     *                                 (prevents duplicate triggers)
     *
     * @return `true` if a campaign is ready to display on back-press; `false` otherwise
     *
     * ## Back-Press Trigger Logic
     *
     * A campaign is back-press ready if:
     * - `backPressCampaignConsumed` is `false` (first back-press in current session)
     * - It has a [TriggerEvent.ObjectTrigger] with `backPress == true`
     * - Either:
     *   - No additional conditions (show immediately on back-press)
     *   - OR conditions exist and are satisfied by prior [currentEvents]
     *
     * @see com.appversal.appstorys.AppStorys.handleBackPress for SDK integration
     */
    fun isBackPressCampaignReady(
        campaigns: List<Campaign>,
        disabledIds: List<String>,
        currentEvents: Set<TriggerEventMatcher.TrackedEventData>,
        backPressCampaignConsumed: Boolean
    ): Boolean {
        if (backPressCampaignConsumed) return false
        return campaigns.any { campaign ->
            !disabledIds.contains(campaign.id) &&
            when (val trigger = campaign.triggerEvent) {
                is TriggerEvent.ObjectTrigger -> {
                    val isBackPress = trigger.eventConfig.any { it.backPress == true }
                    if (!isBackPress) return@any false
                    val realConditions = trigger.eventConfig.filter { it.backPress == null }
                    if (realConditions.isEmpty()) true
                    else {
                        val matchingEvents = currentEvents.filter { it.eventName == trigger.event }
                        matchingEvents.any { tracked ->
                            TriggerEventMatcher.matchesAllConditions(
                                realConditions,
                                tracked.metadata
                            )
                        }
                    }
                }
                else -> false
            }
        }
    }
}
