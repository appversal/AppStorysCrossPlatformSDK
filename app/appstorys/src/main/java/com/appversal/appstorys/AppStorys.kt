package com.appversal.appstorys

import android.app.Activity
import android.app.Application
import android.content.Context
import android.content.Intent
import android.graphics.drawable.Drawable
import android.os.Build
import android.util.Log
import android.util.Patterns
import android.view.View
import androidx.activity.compose.BackHandler
import androidx.annotation.OptIn
import androidx.annotation.RequiresApi
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.layout.LayoutCoordinates
import androidx.compose.ui.layout.boundsInWindow
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import androidx.core.net.toUri
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.ProcessLifecycleOwner
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.media3.common.util.UnstableApi
import com.appversal.appstorys.core.AppStorysCore
import com.appversal.appstorys.core.api.ApiClient
import com.appversal.appstorys.core.platform.PlatformStorage
import com.appversal.appstorys.ui.AutoSlidingCarousel
import com.appversal.appstorys.ui.BottomSheetComponent
import com.appversal.appstorys.ui.CardScratch
import com.appversal.appstorys.ui.CarousalImage
import com.appversal.appstorys.ui.CsatDialog
import com.appversal.appstorys.ui.DoubleWidgets
import com.appversal.appstorys.ui.reels.FullScreenVideoScreen
import com.appversal.appstorys.ui.ImageCard
import com.appversal.appstorys.ui.MilestoneBanner
import com.appversal.appstorys.ui.MilestoneModal
import com.appversal.appstorys.ui.MilestoneWidgets
import com.appversal.appstorys.ui.OverlayContainer
import com.appversal.appstorys.ui.floater.OverlayFloater
import com.appversal.appstorys.ui.pipvideo.PipVideo
import com.appversal.appstorys.ui.modals.PopupModal
import com.appversal.appstorys.ui.reels.ReelsRow
import com.appversal.appstorys.ui.stories.StoryAppMain
import com.appversal.appstorys.ui.SurveyBottomSheet
import com.appversal.appstorys.ui.common_components.createCrossButtonConfig
import com.appversal.appstorys.ui.reels.getLikedReels
import com.appversal.appstorys.ui.getScratchedCampaigns
import com.appversal.appstorys.ui.common_components.createExpandButtonConfig
import com.appversal.appstorys.ui.common_components.createSoundToggleButtonConfig
import com.appversal.appstorys.ui.reels.saveLikedReels
import com.appversal.appstorys.ui.saveScratchedCampaigns
import com.appversal.appstorys.ui.spinwheel.getSpinCount
import com.appversal.appstorys.ui.spinwheel.saveSpinCount
import com.appversal.appstorys.core.model.BannerDetails
import com.appversal.appstorys.core.model.BottomSheetDetails
import com.appversal.appstorys.core.model.CSATDetails
import com.appversal.appstorys.core.model.CsatFeedbackPostRequest
import com.appversal.appstorys.core.model.FloaterDetails
import com.appversal.appstorys.core.model.MilestoneDetails
import com.appversal.appstorys.core.model.ModalDetails
import com.appversal.appstorys.core.model.PipDetails
import com.appversal.appstorys.core.model.ReelStatusRequest
import com.appversal.appstorys.core.model.ReelsDetails
import com.appversal.appstorys.core.model.ScratchCardDetails
import com.appversal.appstorys.core.model.SpinTheWheelDetails
import com.appversal.appstorys.core.model.StoriesDetails
import com.appversal.appstorys.core.model.SurveyDetails
import com.appversal.appstorys.core.model.Tooltip
import com.appversal.appstorys.core.model.TooltipsDetails
import com.appversal.appstorys.core.model.WidgetDetails
import com.appversal.appstorys.core.model.WidgetImage
import com.appversal.appstorys.utils.ViewTreeAnalyzer
import com.appversal.appstorys.utils.getDeviceInfo
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.json.JSONObject
import kotlin.collections.plus
import kotlin.toString

object AppStorys {
    private lateinit var context: Application

    internal lateinit var navigateToScreen: (String) -> Unit

    internal lateinit var apiClient: ApiClient

    private lateinit var core: AppStorysCore

    private val campaigns get() = core.campaigns
    private val disabledCampaigns get() = core.disabledCampaigns
    private val trackedEventNames get() = core.trackedEvents

    private val impressions = MutableStateFlow<List<String>>(emptyList())

    private val viewsCoordinates = MutableStateFlow<Map<String, LayoutCoordinates>>(emptyMap())

    val tooltipTargetView = MutableStateFlow<Tooltip?>(null)

    private val tooltipViewed = MutableStateFlow<List<String>>(emptyList())

    private val showcaseVisible = MutableStateFlow(false)
    private val selectedReelIndex = MutableStateFlow(0)

    private val reelFullScreenVisible = MutableStateFlow(false)

    private val scratchedCampaigns = MutableStateFlow<List<String>>(emptyList())

     // In-memory spin count per campaign — keyed by campaign ID, value = remaining spins
     private val spinCountByCampaign = mutableStateMapOf<String, Int>()

    private var isScreenCaptureEnabled by mutableStateOf(false)

    private var showCsat by mutableStateOf(false)

    private var showModal by mutableStateOf(true)

    private var showBottomSheet by mutableStateOf(true)

    private var backPressCampaignConsumed = false

    private val coroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    private var widgetPositionList = listOf<String>()

    private val viewedTooltips = MutableStateFlow<Set<String>>(emptySet())

    /**
     * Tells the SDK whether the sdk components are visible to the user,
     * this is very important for features like pip where the sdk needs to know
     * whether the user can see the pip or not to pause/resume the pip video
     */
    var isVisible by mutableStateOf(true)

    private val currentMilestoneIndex = MutableStateFlow(0)
    private var showMilestone by mutableStateOf(true)

     private fun isBackPressCampaignReady(): Boolean {
         return core.isBackPressCampaignReady(backPressCampaignConsumed)
     }

    fun initialize(
        context: Application,
        appId: String,
        accountId: String,
        userId: String = "",
        navigateToScreen: (String) -> Unit
    ) {
        if (::context.isInitialized) {
            Log.w("AppStorys", "SDK is already initialized")
            return
        }

        this.context = context
        this.navigateToScreen = navigateToScreen
        this.apiClient = ApiClient()

        // Create and initialize shared core facade.
        // Business logic/state/networking live in core.
        core = AppStorysCore(PlatformStorage())
        core.initialize(appId = appId, accountId = accountId, userId = userId)

        // Android-specific: lifecycle observer stays in wrapper.
        ProcessLifecycleOwner.get().lifecycle.addObserver(
            object : DefaultLifecycleObserver {
                override fun onResume(owner: LifecycleOwner) {
                    super.onResume(owner)
                    core.onAppResumed()
                }

                override fun onStop(owner: LifecycleOwner) {
                    core.onAppStopped()
                    showModal = true
                    showCsat = false
                    showBottomSheet = true
                    backPressCampaignConsumed = false
                }
            }
        )

        // Android-specific: restore persisted UI/game state after init.
        coroutineScope.launch {
            while (core.sdkState == AppStorysCore.SdkState.Initializing) {
                delay(100)
            }

            if (core.sdkState == AppStorysCore.SdkState.Initialized) {
                val savedScratchedCampaigns = getScratchedCampaigns(
                    context.getSharedPreferences("AppStory", Context.MODE_PRIVATE)
                )
                scratchedCampaigns.emit(savedScratchedCampaigns)

                val spinPrefs =
                    context.getSharedPreferences("appstorys_spin_counts", Context.MODE_PRIVATE)
                spinPrefs.all.forEach { (key, value) ->
                    if (value is Int) spinCountByCampaign[key] = value
                }
            }

            showCaseInformation()
        }
    }

    fun getScreenCampaigns(
        screenName: String,
        positionList: List<String> = emptyList()
    ) {
        // Android-specific UI/session resets; campaign loading is delegated to core.
        widgetPositionList = positionList
        impressions.update { emptyList() }
        backPressCampaignConsumed = false
        core.getScreenCampaigns(screenName, positionList)
        isScreenCaptureEnabled = core.isTestUser
    }

    fun getPersonalizationData(): Map<String, String> {
        return core.getPersonalizationData()
    }

    fun trackEvents(
        campaign_id: String? = null,
        event: String,
        metadata: Map<String, Any>? = null
    ) {
        // Android-specific: merge device info for non-system events.
        // Core handles variant lookup + API call.
        val mergedMetadata = if (
            event !in setOf(
                "viewed",
                "clicked",
                "csat captured",
                "survey captured",
                "shared",
                "SurveySubmitted",
                "SurveyDismissed",
                "ThankYouCTAClicked"
            )
        ) {
            (metadata ?: emptyMap()) + getDeviceInfo(context)
        } else {
            metadata
        }
        core.trackEvent(campaign_id, event, mergedMetadata)
    }

    fun viaAppStorys(
        event: String,
    ) {
        core.viaAppStorys(event)
    }

    fun setUserProperties(attributes: Map<String, Any>) {
        // Android-specific: merge device info before forwarding to core.
        val mergedAttributes = attributes + getDeviceInfo(context)
        core.setUserProperties(mergedAttributes)
    }

    fun setUserId(newUserId: String) {
        core.setUserId(newUserId)
    }

    fun handleBackPress(onNavigate: () -> Unit) {
        if (isBackPressCampaignReady()) {
            backPressCampaignConsumed = true
            // Inject back-press sentinel in core tracked events.
            core.injectBackPressSentinel()
            // Don't call onNavigate — stay on screen, campaign will show
        } else {
            onNavigate()
        }
    }

    @Composable
    fun overlayElements(
        bottomPadding: Dp = 0.dp,
        topPadding: Dp = 0.dp,
        activity: Activity? = null,
        bannerBottomPadding: Dp = 0.dp,
        floaterBottomPadding: Dp = 0.dp,
        pipTopPadding: Dp = 0.dp,
        pipBottomPadding: Dp = 0.dp,
        csatBottomPadding: Dp = 0.dp,
    ) {

        BackHandler(enabled = true) {
            if (isBackPressCampaignReady()) {
                backPressCampaignConsumed = true
                // Same back-press sentinel path for composable back handling.
                core.injectBackPressSentinel()
            } else {
                (activity as? androidx.activity.ComponentActivity)
                    ?.onBackPressedDispatcher
                    ?.onBackPressed()
            }
        }

        OverlayContainer.Content(
            bottomPadding = bottomPadding,
            topPadding = topPadding,
            activity = activity,
            bannerBottomPadding = bannerBottomPadding,
            floaterBottomPadding = floaterBottomPadding,
            pipTopPadding = pipTopPadding,
            pipBottomPadding = pipBottomPadding,
            csatBottomPadding = csatBottomPadding
        )
    }

    suspend fun analyzeViewRoot(
        root: View, screenName: String, activity: Activity
    ) = runCatching {
        val TAG = "AnalyzeViewRoot"
        Log.i(TAG, "Calling ViewTreeAnalyzer.analyzeViewRoot()")

        ViewTreeAnalyzer.analyzeViewRoot(
            root = root,
            screenName = screenName,
            user_id = core.userId,
            accessToken = core.accessToken,
            activity = activity,
            context = context
        ).also {
            Log.i(TAG, "ViewTreeAnalyzer.analyzeViewRoot() completed successfully")
        }
    }.onFailure { error ->
        Log.i("AnalyzeViewRoot", "Error analyzing view root", error)
    }.onSuccess {
        Log.i("AnalyzeViewRoot", "analyzeViewRoot() finished with success result: $it")
    }

    @Composable
     fun CSAT(
         bottomPadding: Dp = 0.dp
     ) {
         if (!showCsat) {
             val campaignsData = campaigns.collectAsStateWithLifecycle()
             val trackedEventsData = trackedEventNames.collectAsStateWithLifecycle()
             val disabledData = disabledCampaigns.collectAsStateWithLifecycle()

             val filtered = remember(campaignsData.value, trackedEventsData.value, disabledData.value) {
                 core.getFilteredCampaigns("CSAT", disabledData.value)
             }

             val campaign = filtered.firstOrNull()
             val csatDetails = when (val details = campaign?.details) {
                 is CSATDetails -> details
                 else -> null
             }

             if (csatDetails != null && campaign != null) {
                val style = csatDetails.styling
                var isVisibleState by remember { mutableStateOf(false) }
                val delaySeconds = remember(style) {
                    style?.appearance?.displayDelay?.let { element ->
                        if (element is kotlinx.serialization.json.JsonPrimitive) {
                            element.content.toIntOrNull() ?: 0
                        } else {
                            0
                        }
                    } ?: 0
                }

                 LaunchedEffect(Unit) {
                     campaign.id?.let {
                         trackEvents(it, "viewed")
                     }
                     delay(delaySeconds * 1000L)
                    isVisibleState = true
                }

                val bottomPaddingValue =
                    (style?.appearance?.margin?.bottom?.dp?.plus(bottomPadding)) ?: bottomPadding

                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(
                            bottom = bottomPaddingValue
                        ),
                    contentAlignment = Alignment.BottomCenter
                ) {
                    AnimatedVisibility(
                        modifier = Modifier,
                        visible = isVisibleState,
                        enter = slideInVertically() { it },
                        exit = slideOutVertically { it }
                    ) {
                        CsatDialog(
                            onDismiss = {
                                isVisibleState = false
                                coroutineScope.launch {
                                    delay(500L)
                                    showCsat = true
                                }
                            },
                            onSubmitFeedback = { feedback ->
                                coroutineScope.launch {
                                    apiClient.sendCSATResponse(
                                        core.accessToken,
                                        CsatFeedbackPostRequest(
                                            user_id = core.userId,
                                            csat = csatDetails.id,
                                            rating = feedback.rating,
                                            additional_comments = feedback.additionalComments,
                                            feedback_option = feedback.feedbackOption
                                        )
                                    )
                                    trackEvents(
                                        campaign_id = campaign?.id,
                                        event = "csat captured",
                                        metadata = mapOf(
                                            "starCount" to feedback.rating,
                                            "selectedOption" to (feedback.feedbackOption
                                                ?: "") as Any,
                                            "additionalComments" to feedback.additionalComments
                                        )
                                    )
                                }
                            },
                            csatDetails = csatDetails
                        )
                    }
                }
            }
        }
    }

     @Composable
     fun Floater(
         modifier: Modifier = Modifier,
         bottomPadding: Dp = 0.dp
     ) {
         val campaignsData = campaigns.collectAsStateWithLifecycle()
         val trackedEventsData = trackedEventNames.collectAsStateWithLifecycle()
         val disabledData = disabledCampaigns.collectAsStateWithLifecycle()

         val filtered = remember(campaignsData.value, trackedEventsData.value, disabledData.value) {
             core.getFilteredCampaigns("FLT", disabledData.value)
         }

         val campaign = filtered.firstOrNull { it.details is FloaterDetails }

         val floaterDetails = when (val details = campaign?.details) {
             is FloaterDetails -> details
             else -> null
         }


         if (floaterDetails != null && (!floaterDetails.image.isNullOrEmpty() || !floaterDetails.lottie_data.isNullOrEmpty()) && campaign != null) {
             LaunchedEffect(Unit) {
                 campaign.id?.let {
                     trackEvents(it, "viewed")
                 }
             }

            val styling = floaterDetails.styling

            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(
                        bottom = styling?.floaterBottomPadding?.toFloatOrNull()?.dp
                            ?: bottomPadding,
                        start = styling?.floaterLeftPadding?.toFloatOrNull()?.dp ?: 0.dp,
                        end = styling?.floaterRightPadding?.toFloatOrNull()?.dp ?: 0.dp,
                    ),
                content = {
                    OverlayFloater(
                        modifier = modifier.align(
                            when (floaterDetails.position) {
                                "right" -> Alignment.BottomEnd
                                "left" -> Alignment.BottomStart
                                else -> Alignment.BottomStart
                            }
                        ),
                        onClick = {
                            campaign?.id?.let { campaignId ->
                                if (!floaterDetails.link.isNullOrEmpty()) {
                                    clickEvent(link = floaterDetails.link, campaignId = campaignId)
                                    trackEvents(campaignId, "clicked")
                                }
                            }
                        },
                        image = floaterDetails.image ?: "",
                        lottieUrl = floaterDetails.lottie_data ?: "",
                        height = floaterDetails.height?.dp ?: 60.dp,
                        width = floaterDetails.width?.dp ?: 60.dp,
                        borderRadiusValues = RoundedCornerShape(
                            topStart = (styling?.topLeftRadius?.toFloatOrNull() ?: 0f).dp,
                            topEnd = (styling?.topRightRadius?.toFloatOrNull() ?: 0f).dp,
                            bottomStart = (styling?.bottomLeftRadius?.toFloatOrNull() ?: 0f).dp,
                            bottomEnd = (styling?.bottomRightRadius?.toFloatOrNull() ?: 0f).dp
                        )
                    )
                }
            )
        }
    }


     @Composable
     fun Pip(
         modifier: Modifier = Modifier,
         bottomPadding: Dp = 0.dp,
         topPadding: Dp = 0.dp,
     ) {
         val campaignsData = campaigns.collectAsStateWithLifecycle()
         val trackedEventsData = trackedEventNames.collectAsStateWithLifecycle()
         val disabledData = disabledCampaigns.collectAsStateWithLifecycle()

         val filtered = remember(campaignsData.value, trackedEventsData.value, disabledData.value) {
             core.getFilteredCampaigns("PIP", disabledData.value)
         }

         val campaign = filtered.firstOrNull { it.details is PipDetails }

         val pipDetails = when (val details = campaign?.details) {
             is PipDetails -> details
             else -> null
         }

         if (pipDetails != null && !pipDetails.small_video.isNullOrEmpty() && campaign != null) {
            key(
                campaign?.id, campaign?.triggerEvent
            ) {
                val smallVideo = pipDetails.small_video

                var showPip by remember { mutableStateOf(true) }
                LaunchedEffect(Unit) {
                    campaign.id?.let {
                        trackEvents(it, "viewed")
                    }
                }

                Box(modifier = modifier?.fillMaxWidth() ?: Modifier.fillMaxWidth()) {
                    if (showPip) {
                        // Use appearance dimensions if available, otherwise fall back to root-level dimensions
                        val pipHeight = pipDetails.styling?.appearance?.pipHeight?.toIntOrNull()?.dp
                            ?: pipDetails.height?.dp ?: 200.dp
                        val pipWidth = pipDetails.styling?.appearance?.pipWidth?.toIntOrNull()?.dp
                            ?: pipDetails.width?.dp ?: 113.dp

                        PipVideo(
                            videoUri = smallVideo ?: "",
                            fullScreenVideoUri = if (!pipDetails.large_video.isNullOrEmpty()) {
                                pipDetails.large_video
                            } else {
                                null
                            },
                            onClose = {
                                showPip = false
                                // Clear trigger event in core so dismissed item does not re-qualify.
                                core.clearTrackedEventForTrigger(campaign?.triggerEvent)
                            },
                            height = pipHeight,
                            width = pipWidth,
                            button_text = pipDetails.button_text.toString(),
                            link = pipDetails.link.toString(),
                            position = pipDetails.position.toString(),
                            bottomPadding = bottomPadding,
                            topPadding = topPadding,
                            isMovable = pipDetails.styling?.isMovable ?: false,
                            pipStyling = pipDetails.styling,

                            crossButtonConfig = run {
                                // Support new backend format with "color" (singular) instead of "colors"
                                val pipCrossButton = pipDetails.styling?.crossButton
                                val pipCrossColors = pipCrossButton?.color ?: pipCrossButton?.colors
                                val pipCrossImageUrl = pipCrossButton?.image
                                val pipCrossMargin = pipCrossButton?.margin

                                createCrossButtonConfig(
                                    fillColorString = pipCrossColors?.fill,
                                    crossColorString = pipCrossColors?.cross,
                                    strokeColorString = pipCrossColors?.stroke,
                                    marginTop = pipCrossButton?.margin?.top,
                                    marginEnd = pipCrossButton?.margin?.right,
                                    size = pipCrossButton?.size,
                                    imageUrl = pipCrossImageUrl
                                )
                            },

                            maximiseButtonConfig = run {
                                val expandControls = pipDetails.styling?.expandControls
                                val maximise = expandControls?.maximise
                                // Check color (singular) first, then fall back to colors (plural) for legacy support
                                val maximiseColors = maximise?.color ?: maximise?.colors
                                val maximiseMargin = maximise?.margin

                                createExpandButtonConfig(
                                    fillColorString = maximiseColors?.fill,
                                    iconColorString = maximiseColors?.cross,
                                    strokeColorString = maximiseColors?.stroke,
                                    marginTop = maximiseMargin?.top,
                                    marginEnd = maximiseMargin?.right,
                                    marginBottom = maximiseMargin?.bottom,
                                    marginStart = maximiseMargin?.left,
                                    size = maximise?.size,
                                    imageUrl = maximise?.image ?: pipDetails.maximiseImage
                                )
                            },

                            minimiseButtonConfig = run {
                                val expandControls = pipDetails.styling?.expandControls
                                val minimise = expandControls?.minimise
                                // Check color (singular) first, then fall back to colors (plural) for legacy support
                                val minimiseColors = minimise?.color ?: minimise?.colors
                                val minimiseMargin = minimise?.margin

                                createExpandButtonConfig(
                                    fillColorString = minimiseColors?.fill,
                                    iconColorString = minimiseColors?.cross,
                                    strokeColorString = minimiseColors?.stroke,
                                    marginTop = minimiseMargin?.top,
                                    marginEnd = minimiseMargin?.right,
                                    marginBottom = minimiseMargin?.bottom,
                                    marginStart = minimiseMargin?.left,
                                    size = minimise?.size,
                                    imageUrl = minimise?.image ?: pipDetails.minimiseImage
                                )
                            },

                            muteButtonConfig = run {
                                val soundToggle = pipDetails.styling?.soundToggle
                                val mute = soundToggle?.mute
                                // Check color (singular) first, then fall back to colors (plural) for legacy support
                                val muteColors = mute?.color ?: mute?.colors
                                val muteMargin = mute?.margin

                                createSoundToggleButtonConfig(
                                    fillColorString = muteColors?.fill,
                                    iconColorString = muteColors?.cross,
                                    strokeColorString = muteColors?.stroke,
                                    marginTop = muteMargin?.top,
                                    marginEnd = muteMargin?.right,
                                    marginBottom = muteMargin?.bottom,
                                    marginStart = muteMargin?.left,
                                    size = mute?.size,
                                    imageUrl = mute?.image ?: pipDetails.muteImage
                                )
                            },

                            unmuteButtonConfig = run {
                                val soundToggle = pipDetails.styling?.soundToggle
                                val unmute = soundToggle?.unmute
                                // Check color (singular) first, then fall back to colors (plural) for legacy support
                                val unmuteColors = unmute?.color ?: unmute?.colors
                                val unmuteMargin = unmute?.margin

                                createSoundToggleButtonConfig(
                                    fillColorString = unmuteColors?.fill,
                                    iconColorString = unmuteColors?.cross,
                                    strokeColorString = unmuteColors?.stroke,
                                    marginTop = unmuteMargin?.top,
                                    marginEnd = unmuteMargin?.right,
                                    marginBottom = unmuteMargin?.bottom,
                                    marginStart = unmuteMargin?.left,
                                    size = unmute?.size,
                                    imageUrl = unmute?.image ?: pipDetails.unmuteImage
                                )
                            },


                            onButtonClick = {
                                campaign?.id?.let { campaignId ->
                                    trackEvents(campaignId, "clicked")
                                }
                            },
                            onExpandClick = {
                                campaign?.id?.let { campaignId ->
                                    trackEvents(campaignId, "viewed")
                                }
                            }
                        )
                    }
                }
            }
        }
    }

    private fun showCaseInformation() {
        coroutineScope.launch {
            combine(
                campaigns,
                viewsCoordinates
            ) { campaignList, coordinates -> campaignList to coordinates }.collectLatest { (campaignList, coordinates) ->
                val campaign =
                    campaignList.firstOrNull { it.campaignType == "TTP" && it.details is TooltipsDetails }
                val tooltipsDetails = campaign?.details as? TooltipsDetails
                if (tooltipsDetails != null) {
                    for (tooltip in tooltipsDetails.tooltips?.sortedBy { it.order }
                        ?: emptyList()) {
                        val target = tooltip.target
                        if (target != null && !tooltipViewed.value.contains(target)) {
                            while (tooltipTargetView.value != null) {
                                delay(500L)
                            }
                            tooltipTargetView.emit(tooltip)
                            showcaseVisible.emit(true)
                            tooltipViewed.update {
                                it + target
                            }
                        }
                    }
                }
            }
        }
    }

     @OptIn(UnstableApi::class)
     @Composable
     fun Stories() {
         val campaignsData = campaigns.collectAsStateWithLifecycle()
         val trackedEventsData = trackedEventNames.collectAsStateWithLifecycle()
         val disabledData = disabledCampaigns.collectAsStateWithLifecycle()

         val filtered = remember(campaignsData.value, trackedEventsData.value, disabledData.value) {
             core.getFilteredCampaigns("STR", disabledData.value)
         }

         val campaign = filtered.firstOrNull()
         val storiesDetails = campaign?.details as? StoriesDetails

        if (storiesDetails != null && !storiesDetails.groups.isNullOrEmpty() && campaign != null) {
            StoryAppMain(
                apiStoriesDetails = storiesDetails,
                sendEvent = {
                    coroutineScope.launch {
                        trackEvents(campaign.id, "viewed", mapOf("story_slide" to it.first.id!!))
                    }
                },
                sendClickEvent = {
                    trackEvents(campaign.id, it.second, mapOf("story_slide" to it.first.id!!))
                },
                campaignId = campaign.id ?: ""
            )
        }
    }

     @Composable
     fun Reels(modifier: Modifier = Modifier) {
         val campaignsData = campaigns.collectAsStateWithLifecycle()
         val trackedEventsData = trackedEventNames.collectAsStateWithLifecycle()
         val disabledData = disabledCampaigns.collectAsStateWithLifecycle()

         val filtered = remember(campaignsData.value, trackedEventsData.value, disabledData.value) {
             core.getFilteredCampaigns("REL", disabledData.value)
         }

         val campaign = filtered.firstOrNull()
         val reelsDetails = campaign?.details as? ReelsDetails
         val selectedReelIndex by selectedReelIndex.collectAsStateWithLifecycle()
         val visibility by reelFullScreenVisible.collectAsStateWithLifecycle()
         val reels = reelsDetails?.reels

         if (!reels.isNullOrEmpty() && campaign != null) {
            Box(modifier = Modifier.fillMaxSize()) {

                ReelsRow(
                    modifier = modifier,
                    reels = reels,
                    onReelClick = { index ->
                        coroutineScope.launch {
                            this@AppStorys.selectedReelIndex.emit(index)
                            reelFullScreenVisible.emit(true)
                        }
                    },
                    height = reelsDetails.styling?.thumbnailHeight?.toIntOrNull()?.dp ?: 180.dp,
                    width = reelsDetails.styling?.thumbnailWidth?.toIntOrNull()?.dp ?: 120.dp,
                    cornerRadius = reelsDetails.styling?.cornerRadius?.toIntOrNull()?.dp ?: 12.dp
                )

                if (visibility) {
                    ReelFullScreen(
                        campaignId = campaign.id,
                        reelsDetails = reelsDetails,
                        selectedReelIndex = selectedReelIndex
                    ) {
                        coroutineScope.launch {
                            this@AppStorys.selectedReelIndex.emit(0)
                            reelFullScreenVisible.emit(false)
                        }
                    }
                }
            }
        }
    }

    @Composable
    private fun ReelFullScreen(
        campaignId: String?,
        reelsDetails: ReelsDetails,
        selectedReelIndex: Int,
        onDismiss: () -> Unit
    ) {
        if (!reelsDetails.reels.isNullOrEmpty()) {

            var likedReels by remember {
                mutableStateOf(
                    getLikedReels(
                        context.getSharedPreferences(
                            "AppStory",
                            Context.MODE_PRIVATE
                        )
                    )
                )
            }

            Dialog(
                onDismissRequest = onDismiss,
                properties = DialogProperties(
                    dismissOnBackPress = true,
                    dismissOnClickOutside = false,
                    usePlatformDefaultWidth = false
                )
            ) {

                BackHandler {
                    coroutineScope.launch {
                        this@AppStorys.selectedReelIndex.emit(0)
                        reelFullScreenVisible.emit(false)
                    }
                }

                FullScreenVideoScreen(
                    reelsDetails = reelsDetails,
                    reels = reelsDetails.reels ?: emptyList(),
                    likedReels = likedReels,
                    startIndex = selectedReelIndex,
                    sendLikesStatus = {
                        coroutineScope.launch {
                            if (it.second == "like") {
                                val list = ArrayList(likedReels)
                                list.add(it.first.id)
                                likedReels = list.distinct()
                                saveLikedReels(
                                    idList = list.distinct(),
                                    sharedPreferences = context.getSharedPreferences(
                                        "AppStory",
                                        Context.MODE_PRIVATE
                                    )
                                )
                            } else {
                                val list = ArrayList(likedReels)
                                list.remove(it.first.id)
                                likedReels = list.distinct()
                                saveLikedReels(
                                    idList = list.distinct(),
                                    sharedPreferences = context.getSharedPreferences(
                                        "AppStory",
                                        Context.MODE_PRIVATE
                                    )
                                )
                            }

                            apiClient.sendReelLikeStatus(
                                accessToken = core.accessToken,
                                request = ReelStatusRequest(
                                    user_id = core.userId,
                                    action = it.second,
                                    reel = it.first.id
                                )
                            )
                        }
                    },
                    sendEvents = {
                        if (it.second == "IMP") {
                            if (!impressions.value.contains(it.first.id)) {
                                coroutineScope.launch {
                                    val impressions = ArrayList(impressions.value)
                                    impressions.add(it.first.id)
                                    this@AppStorys.impressions.emit(impressions)
                                    trackEvents(
                                        campaignId,
                                        "viewed",
                                        mapOf("reel_id" to it.first.id!!)
                                    )
                                }
                            }
                        } else {
                            coroutineScope.launch {
                                trackEvents(
                                    campaignId,
                                    "clicked",
                                    mapOf("reel_id" to it.first.id!!)
                                )
                            }
                        }

                    },
                    onBack = {
                        coroutineScope.launch {
                            this@AppStorys.selectedReelIndex.emit(0)
                            reelFullScreenVisible.emit(false)
                        }
                    }
                )
            }
        }
    }

    @Composable
    fun getBannerHeight(): Dp {
        val campaignsData = campaigns.collectAsStateWithLifecycle()
        val defaultHeight = 100.dp

        val campaign =
            campaignsData.value.firstOrNull { it.campaignType == "BAN" && it.details is BannerDetails }
        val bannerDetails = campaign?.details as? BannerDetails

        return bannerDetails?.height?.dp ?: defaultHeight
    }

    @Composable
    fun getUserId(): String {
        return core.userId
    }

     @Composable
     fun PinnedBanner(
         modifier: Modifier = Modifier,
         placeholder: Drawable? = null,
         placeholderContent: (@Composable () -> Unit)? = null,
         bottomPadding: Dp = 0.dp,
     ) {
         val campaignsData = campaigns.collectAsStateWithLifecycle()
         val trackedEventsData = trackedEventNames.collectAsStateWithLifecycle()
         val disabledCampaignsFlow = disabledCampaigns.collectAsStateWithLifecycle()

         val filtered = remember(campaignsData.value, trackedEventsData.value, disabledCampaignsFlow.value) {
             core.getFilteredCampaigns("BAN", disabledCampaignsFlow.value)
         }

         val campaign = filtered.firstOrNull { it.details is BannerDetails }
         val bannerDetails = campaign?.details as? BannerDetails

         if (bannerDetails != null && campaign != null) {
            val style = bannerDetails.styling
            val bannerUrl = bannerDetails.image

            val aspectRatio: Float? = remember(bannerDetails) {
                val w = bannerDetails.width
                val h = bannerDetails.height
                if (w != null && h != null && w > 0 && h > 0) {
                    h.toFloat() / w.toFloat()
                } else null
            }

            val forcedHeight: Dp? = remember(bannerDetails) {
                val bannerHeight = bannerDetails.height
                if (bannerDetails.width == null && bannerHeight != null) {
                    bannerHeight.dp
                } else null
            }

//
//            val calculatedHeight =
//                if (bannerDetails.width != null && bannerDetails.height != null) {
//                    val aspectRatio = bannerDetails.height.toFloat() / bannerDetails.width.toFloat()
//
//                    val marginLeft = style?.marginLeft?.dp ?: 0.dp
//                    val marginRight = style?.marginRight?.dp ?: 0.dp
//
//                    val actualWidth = screenWidth - marginLeft - marginRight
//
//                    (actualWidth.value * aspectRatio).dp
//                } else {
//                    bannerDetails.height?.dp
//                }

            LaunchedEffect(Unit) {
                campaign.id?.let {
                    trackEvents(it, "viewed")
                }
            }

            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(bottom = bottomPadding)
            ) {
                com.appversal.appstorys.ui.PinnedBanner(
                    modifier = modifier
                        .align(Alignment.BottomCenter)
                        .fillMaxWidth(),
                    imageUrl = bannerUrl ?: "",
                    lottieUrl = bannerDetails.lottie_data,
                    //width = bannerDetails.width?.dp ?: screenWidth,
                    exitIcon = (style?.crossButton?.enabled ?: style?.enableCloseButton) != false,
                    exitUnit = {
                        campaign.id?.let { core.disableCampaign(it) }
                    },
                    shape = RoundedCornerShape(
                        topStart = style?.topLeftRadius?.toIntOrNull()?.dp ?: 0.dp,
                        topEnd = style?.topRightRadius?.toIntOrNull()?.dp ?: 0.dp,
                        bottomEnd = style?.bottomRightRadius?.toIntOrNull()?.dp ?: 0.dp,
                        bottomStart = style?.bottomLeftRadius?.toIntOrNull()?.dp ?: 0.dp
                    ),
                    bottomMargin = style?.marginBottom?.dp ?: 0.dp,
                    leftMargin = style?.marginLeft?.dp ?: 0.dp,
                    rightMargin = style?.marginRight?.dp ?: 0.dp,
                    contentScale = ContentScale.FillWidth,
                    //height = null,
                    aspectRatio = aspectRatio,
                    forcedHeight = forcedHeight,
                    placeHolder = placeholder,
                    placeholderContent = placeholderContent,
                    crossButtonConfig = run {
                        // Support new backend format with "color" (singular) instead of "colors"
                        val crossColors = style?.crossButton?.color ?: style?.crossButton?.colors
                        val crossImageUrl =
                            style?.crossButton?.image ?: bannerDetails.crossButtonImage
                        createCrossButtonConfig(
                            fillColorString = crossColors?.fill,
                            crossColorString = crossColors?.cross,
                            strokeColorString = crossColors?.stroke,
                            marginTop = style?.crossButton?.margin?.top,
                            marginEnd = style?.crossButton?.margin?.right,
                            size = style?.crossButton?.size,
                            imageUrl = crossImageUrl
                        )
                    },
                    onClick = {
                        if (bannerDetails.link.toString().trim().removeSurrounding("\"")
                                .isNotEmpty()
                        ) {
                            campaign.id?.let {
                                clickEvent(
                                    link = bannerDetails.link.toString().trim()
                                        .removeSurrounding("\""), campaignId = it
                                )
                                trackEvents(it, "clicked")
                            }
                        }
                    }
                )
            }
        }
    }

    @Composable
     fun Widget(
         modifier: Modifier = Modifier,
         placeholder: Drawable? = null,
         position: String? = null
     ) {
         val campaignsData = campaigns.collectAsStateWithLifecycle()
         val trackedEventsData = trackedEventNames.collectAsStateWithLifecycle()
         val disabledData = disabledCampaigns.collectAsStateWithLifecycle()

         val filtered = remember(campaignsData.value, trackedEventsData.value, disabledData.value) {
             core.getFilteredCampaigns("WID", disabledData.value)
         }

         val campaign = filtered.firstOrNull {
             if (position == null) {
                 it.position == null
             } else {
                 it.position == position
             }
         }
         val widgetDetails = campaign?.details as? WidgetDetails

         if (widgetDetails != null && campaign != null) {

            if (widgetDetails.type == "full") {

                FullWidget(
                    modifier = modifier,
                    staticWidth = LocalConfiguration.current.screenWidthDp.dp,
                    placeHolder = placeholder,
                    contentScale = ContentScale.FillWidth,
                    position = position,
                )

            } else if (widgetDetails.type == "half") {
                DoubleWidget(
                    modifier = modifier,
                    staticWidth = LocalConfiguration.current.screenWidthDp.dp,
                    position = position,
                    placeHolder = placeholder,
                )
            }
        }
    }


    @Composable
    private fun FullWidget(
        modifier: Modifier = Modifier,
        contentScale: ContentScale = ContentScale.FillWidth,
        staticWidth: Dp? = null,
        placeHolder: Drawable?,
        placeholderContent: (@Composable () -> Unit)? = null,
        position: String?
    ) {
        val campaignsData = campaigns.collectAsStateWithLifecycle()
        val disabledCampaigns = disabledCampaigns.collectAsStateWithLifecycle()
        val campaign = campaignsData.value
            .filter { it.campaignType == "WID" && it.details is WidgetDetails && it.position == position }
            .firstOrNull { (it.details as WidgetDetails).type == "full" }

        val widgetDetails = (campaign?.details as? WidgetDetails)

        var isVisible by remember { mutableStateOf(false) }
        val configuration = LocalConfiguration.current
        val screenWidth = configuration.screenWidthDp.dp


        val widgetImages = widgetDetails?.widgetImages
        val campaignId = campaign?.id

        if (widgetDetails != null && !widgetImages.isNullOrEmpty() && campaignId != null &&
            !disabledCampaigns.value.contains(campaignId) && widgetDetails.type == "full"
        ) {
            val sortedWidgetImages = widgetImages.sortedBy { it.order }
            val pagerState = rememberPagerState(pageCount = {
                sortedWidgetImages.count()
            })
            val widthInDp: Dp? = widgetDetails.width?.dp

            val calculatedHeight =
                if (widgetDetails.width != null && widgetDetails.height != null) {
                    val widgetWidth = widgetDetails.width
                    val widgetHeight = widgetDetails.height
                    val aspectRatio = widgetHeight!!.toFloat() / widgetWidth!!.toFloat()

                    val marginLeft = (widgetDetails.styling?.leftMargin ?: 0).dp
                    val marginRight = (widgetDetails.styling?.rightMargin ?: 0).dp

                    val actualWidth = (staticWidth ?: screenWidth) - marginLeft - marginRight
                    (actualWidth.value.minus(
                        0
//                        32
                        // for the new widget
//                            +26
                    ) * aspectRatio).dp
                } else {
                    widgetDetails.height?.dp
                }

            LaunchedEffect(pagerState.currentPage, isVisible) {
                if (isVisible) {
                    campaign?.id?.let {
                        val currentWidgetId = sortedWidgetImages[pagerState.currentPage].id

                        if (currentWidgetId != null && !impressions.value.contains(currentWidgetId)) {
                            val impressions = ArrayList(impressions.value)
                            impressions.add(currentWidgetId)
                            this@AppStorys.impressions.emit(impressions)
                            trackEvents(
                                it,
                                "viewed",
                                mapOf("widget_image" to currentWidgetId)
                            )
                        }
                    }
                }
            }

            AutoSlidingCarousel(
                modifier = modifier
                    .padding(
                        top = (widgetDetails.styling?.topMargin ?: 0).dp,
                        bottom = (widgetDetails.styling?.bottomMargin ?: 0).dp,
                        start = (widgetDetails.styling?.leftMargin ?: 0).dp,
                        end = (widgetDetails.styling?.rightMargin ?: 0).dp,
                    )
                    .onGloballyPositioned { layoutCoordinates ->
                        val visibilityRect = layoutCoordinates.boundsInWindow()
                        val parentHeight =
                            layoutCoordinates.parentLayoutCoordinates?.size?.height ?: 0
                        val widgetHeight = layoutCoordinates.size.height
                        val isAtLeastHalfVisible = visibilityRect.top < parentHeight &&
                                visibilityRect.bottom > 0 &&
                                (visibilityRect.height >= widgetHeight * 0.5f)

                        isVisible = isAtLeastHalfVisible
                    },
                widgetDetails = widgetDetails,
                pagerState = pagerState,
                itemsCount = sortedWidgetImages.count(),
                width = staticWidth,
                itemContent = { index ->

                    sortedWidgetImages[index].takeIf {
                        it.image != null || it.lottie_data != null
                    }?.let {

                        CarousalImage(
                            modifier = modifier.clickable(
                                interactionSource = remember { MutableInteractionSource() },
                                indication = null,
                            ) {
                                if (sortedWidgetImages[index].link.toString().trim()
                                        .removeSurrounding("\"").isNotEmpty()
                                ) {
                                    campaign.id?.let { campaignId ->
                                        clickEvent(
                                            link = sortedWidgetImages[index].link.toString().trim()
                                                .removeSurrounding("\""),
                                            campaignId = campaignId,
                                            widgetImageId = sortedWidgetImages[index].id
                                        )

                                        trackEvents(
                                            campaignId,
                                            "clicked",
                                            mapOf("widget_image" to sortedWidgetImages[index].id!!)
                                        )
                                    }
                                }
                            },
                            contentScale = contentScale,
                            imageUrl = sortedWidgetImages[index].image ?: "",
                            lottieUrl = sortedWidgetImages[index].lottie_data ?: "",
                            placeHolder = placeHolder,
                            height = calculatedHeight,
                            width = widthInDp ?: staticWidth,
                            placeholderContent = placeholderContent
                        )
                    }
                }
            )

        }
    }


    @Composable
    private fun DoubleWidget(
        modifier: Modifier = Modifier,
        staticWidth: Dp? = null,
        position: String?,
        placeHolder: Drawable?,
        placeholderContent: (@Composable () -> Unit)? = null,
    ) {
        val campaignsData = campaigns.collectAsStateWithLifecycle()
        val disabledCampaigns = disabledCampaigns.collectAsStateWithLifecycle()

        val campaign = campaignsData.value
            .filter { it.campaignType == "WID" && it.details is WidgetDetails && it.position == position }
            .firstOrNull { (it.details as WidgetDetails).type == "half" }

        val widgetDetails = (campaign?.details as? WidgetDetails)

        var isVisible by remember { mutableStateOf(false) }
        val configuration = LocalConfiguration.current
        val screenWidth = configuration.screenWidthDp.dp

        val widgetImages = widgetDetails?.widgetImages
        val campaignId = campaign?.id

        if (widgetDetails != null && campaignId != null &&
            !disabledCampaigns.value.contains(campaignId) && !widgetImages.isNullOrEmpty() && widgetDetails.type == "half"
        ) {
            val widthInDp: Dp? = widgetDetails.width?.dp

            val calculatedHeight =
                if (widgetDetails.width != null && widgetDetails.height != null) {
                    val widgetWidth = widgetDetails.width
                    val widgetHeight = widgetDetails.height
                    val aspectRatio = widgetHeight!!.toFloat() / widgetWidth!!.toFloat()

                    val marginLeft = (widgetDetails.styling?.leftMargin ?: 0).dp
                    val marginRight = (widgetDetails.styling?.rightMargin ?: 0).dp

                    val horizontalMargin = marginLeft + marginRight

                    val actualWidth = (staticWidth ?: screenWidth) - horizontalMargin
                    ((actualWidth.value.minus(12) * aspectRatio).div(2)).dp
                } else {
                    (widgetDetails.height?.minus(12))?.div(2)?.dp
                }

            val widgetImagesPairs = widgetImages.turnToPair()
            val pagerState = rememberPagerState(pageCount = {
                widgetImagesPairs.count()
            })

            LaunchedEffect(pagerState.currentPage, isVisible) {
                if (isVisible) {
                    campaign?.id?.let {

                        if (widgetImagesPairs[pagerState.currentPage].first.id != null && !impressions.value.contains(
                                widgetImagesPairs[pagerState.currentPage].first.id
                            )
                        ) {
                            val impressions = ArrayList(impressions.value)
                            impressions.add(widgetImagesPairs[pagerState.currentPage].first.id)
                            this@AppStorys.impressions.emit(impressions)
                            trackEvents(
                                it,
                                "viewed",
                                mapOf("widget_image" to widgetImagesPairs[pagerState.currentPage].first.id!!)
                            )

                        }

                        if (widgetImagesPairs[pagerState.currentPage].second.id != null && !impressions.value.contains(
                                widgetImagesPairs[pagerState.currentPage].second.id
                            )
                        ) {
                            val impressions = ArrayList(impressions.value)
                            impressions.add(widgetImagesPairs[pagerState.currentPage].second.id)
                            this@AppStorys.impressions.emit(impressions)
                            trackEvents(
                                it,
                                "viewed",
                                mapOf("widget_image" to widgetImagesPairs[pagerState.currentPage].second.id!!)
                            )

                        }
                    }
                }
            }

            DoubleWidgets(
                modifier = modifier
                    .padding(
                        top = (widgetDetails.styling?.topMargin ?: 0).dp,
                        bottom = (widgetDetails.styling?.bottomMargin ?: 0).dp,
                        start = (widgetDetails.styling?.leftMargin ?: 0).dp,
                        end = (widgetDetails.styling?.rightMargin ?: 0).dp,
                    )
                    .onGloballyPositioned { layoutCoordinates ->
                        val visibilityRect = layoutCoordinates.boundsInWindow()
                        val parentHeight =
                            layoutCoordinates.parentLayoutCoordinates?.size?.height ?: 0
                        val widgetHeight = layoutCoordinates.size.height
                        val isAtLeastHalfVisible = visibilityRect.top < parentHeight &&
                                visibilityRect.bottom > 0 &&
                                (visibilityRect.height >= widgetHeight * 0.5f)

                        isVisible = isAtLeastHalfVisible
                    },
                pagerState = pagerState,
                itemsCount = widgetImagesPairs.count(),
                width = widthInDp ?: staticWidth,
                itemContent = { index ->
                    val (leftImage, rightImage) = widgetImagesPairs[index]
                    Row(
                        modifier = Modifier
                            .fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        if (leftImage.image != null || leftImage.lottie_data != null) {
                            ImageCard(
                                modifier = Modifier
                                    .weight(1f)
                                    .clickable(
                                        interactionSource = remember { MutableInteractionSource() },
                                        indication = null,
                                    ) {
                                        if (leftImage.link.toString().trim()
                                                .removeSurrounding("\"").isNotEmpty()
                                        ) {
                                            campaign.id?.let { campaignId ->
                                                clickEvent(
                                                    link = leftImage.link.toString().trim()
                                                        .removeSurrounding("\""),
                                                    campaignId = campaignId,
                                                    widgetImageId = leftImage.id
                                                )

                                                trackEvents(
                                                    campaignId,
                                                    "clicked",
                                                    mapOf("widget_image" to leftImage.id!!)
                                                )
                                            }
                                        }

                                    },
                                imageUrl = leftImage.image ?: "",
                                lottieUrl = leftImage.lottie_data ?: "",
                                widgetDetails = widgetDetails,
                                height = calculatedHeight,
                                placeHolder = placeHolder,
                                placeholderContent = placeholderContent
                            )
                        }
                        if (rightImage.image != null || rightImage.lottie_data != null) {
                            ImageCard(
                                modifier = Modifier
                                    .weight(1f)
                                    .clickable(
                                        interactionSource = remember { MutableInteractionSource() },
                                        indication = null,
                                    ) {
                                        if (rightImage.link.toString().trim()
                                                .removeSurrounding("\"").isNotEmpty()
                                        ) {
                                            campaign.id?.let { campaignId ->
                                                clickEvent(
                                                    link = rightImage.link.toString().trim()
                                                        .removeSurrounding("\""),
                                                    campaignId = campaignId,
                                                    widgetImageId = rightImage.id
                                                )

                                                trackEvents(
                                                    campaignId,
                                                    "clicked",
                                                    mapOf("widget_image" to rightImage.id!!)
                                                )
                                            }
                                        }
                                    },
                                imageUrl = rightImage.image ?: "",
                                lottieUrl = rightImage.lottie_data ?: "",
                                widgetDetails = widgetDetails,
                                height = calculatedHeight,
                                placeHolder = placeHolder,
                                placeholderContent = placeholderContent
                            )
                        }
                    }
                }
            )
        }
    }

    @Composable
     fun BottomSheet() {

         val campaignsData = campaigns.collectAsStateWithLifecycle()
         val trackedEventsData = trackedEventNames.collectAsStateWithLifecycle()
         val disabledData = disabledCampaigns.collectAsStateWithLifecycle()

         val filtered = remember(campaignsData.value, trackedEventsData.value, disabledData.value) {
             core.getFilteredCampaigns("BTS", disabledData.value)
         }

         val campaign = filtered.firstOrNull { it.details is BottomSheetDetails }

         val bottomSheetDetails = when (val details = campaign?.details) {
             is BottomSheetDetails -> details
             else -> null
         }

         if (bottomSheetDetails != null && showBottomSheet && campaign != null) {

             LaunchedEffect(Unit) {
                 campaign.id?.let {
                     trackEvents(it, "viewed")
                 }
             }

            BottomSheetComponent(
                onDismissRequest = {
                    showBottomSheet = false
                    // Clear trigger event in core so dismissed item does not re-qualify.
                    core.clearTrackedEventForTrigger(campaign?.triggerEvent)
                },
                bottomSheetDetails = bottomSheetDetails,
                onClick = { ctaLink ->
                    if (!ctaLink.isNullOrEmpty()) {
                        campaign?.id?.let { campaignId ->
                            clickEvent(link = ctaLink, campaignId = campaignId)
                            trackEvents(campaignId, "clicked")
                        }
                    }
                },
            )
        }
    }

     @Composable
     fun Survey() {
         var showSurvey by remember { mutableStateOf(true) }

         val campaignsData = campaigns.collectAsStateWithLifecycle()
         val trackedEventsData = trackedEventNames.collectAsStateWithLifecycle()
         val disabledData = disabledCampaigns.collectAsStateWithLifecycle()

         val filtered = remember(campaignsData.value, trackedEventsData.value, disabledData.value) {
             core.getFilteredCampaigns("SUR", disabledData.value)
         }

         val campaign = filtered.firstOrNull { it.details is SurveyDetails }

         val surveyDetails = when (val details = campaign?.details) {
             is SurveyDetails -> details
             else -> null
         }

         if (surveyDetails != null && showSurvey && campaign != null) {
            SurveyBottomSheet(
                onDismissRequest = {
                    showSurvey = false
                },
                surveyDetails = surveyDetails,
                campaignId = campaign?.id,
                onTrackEvent = { campId, event, metadata ->
                    trackEvents(
                        campaign_id = campId,
                        event = event,
                        metadata = metadata
                    )
                }
            )
        }
    }

     @Composable
     fun Modals() {
         val campaignsData = campaigns.collectAsStateWithLifecycle()
         val trackedEventsData = trackedEventNames.collectAsStateWithLifecycle()
         val disabledData = disabledCampaigns.collectAsStateWithLifecycle()

         val filtered = remember(campaignsData.value, trackedEventsData.value, disabledData.value) {
             core.getFilteredCampaigns("MOD", disabledData.value)
         }

         val campaign = filtered.firstOrNull { it.details is ModalDetails }

         val modalDetails = when (val details = campaign?.details) {
             is ModalDetails -> details
             else -> null
         }

         if (modalDetails != null && showModal && campaign != null) {

             LaunchedEffect(Unit) {
                 campaign.id?.let {
                     trackEvents(it, "viewed")
                 }
             }

            PopupModal(
                onCloseClick = {
                    showModal = false
                },
                modalDetails = modalDetails,
                onModalClick = {
                    val modal = modalDetails.modals?.getOrNull(0)

                    val link =
                        modal?.content?.primaryCtaRedirection?.url
                            ?: modal?.content?.primaryCtaRedirection?.value
                            ?: modal?.redirection?.url
                            ?: modal?.redirection?.value

                    campaign?.id?.let { campaignId ->
                        trackEvents(campaignId, "clicked")
                        clickEvent(link = link, campaignId = campaignId)
                    }
                },


                onPrimaryCta = { link ->
                    // primary CTA receives resolved URL string
                    campaign?.id?.let { campaignId ->
                        trackEvents(campaignId, "clicked")
                        clickEvent(link = link, campaignId = campaignId)
                    }
                },
                onSecondaryCta = { link ->
                    campaign?.id?.let { campaignId ->
                        trackEvents(campaignId, "clicked")
                        clickEvent(link = link, campaignId = campaignId)
                        showModal = false
                    }
                },
            )
        }
    }

    @RequiresApi(Build.VERSION_CODES.M)
    @Composable
     fun ScratchCard() {

         var confettiTrigger by remember { mutableStateOf(0) }
          val campaignsData = campaigns.collectAsStateWithLifecycle()
          val trackedEventsData = trackedEventNames.collectAsStateWithLifecycle()
         val disabledData = disabledCampaigns.collectAsStateWithLifecycle()

         val filtered = remember(campaignsData.value, trackedEventsData.value, disabledData.value) {
             core.getFilteredCampaigns("SCRT", disabledData.value)
         }

         val campaign = filtered.firstOrNull { it.details is ScratchCardDetails }

         val scratchCardDetails = when (val details = campaign?.details) {
             is ScratchCardDetails -> details
             else -> null
         }

         val scratchedCampaignsData = scratchedCampaigns.collectAsStateWithLifecycle()

         val isAlreadyScratched = campaign?.id?.let {
             scratchedCampaignsData.value.contains(it)
         } ?: false

         var wasFullyScratched by remember(campaign?.id, isAlreadyScratched) {
             mutableStateOf(isAlreadyScratched)
         }

         var isPresented by remember(campaign?.id) { mutableStateOf(true) }

         if (scratchCardDetails != null && campaign != null && isPresented) {

             LaunchedEffect(Unit) {
                 campaign.id?.let {
                     trackEvents(it, "viewed")
                 }
            }

            LaunchedEffect(wasFullyScratched) {
                if (wasFullyScratched && campaign?.id != null && !isAlreadyScratched) {
                    trackEvents(campaign.id, "scratched")

                    val currentScratchedCampaigns = ArrayList(scratchedCampaigns.value)
                    currentScratchedCampaigns.add(campaign.id)
                    scratchedCampaigns.emit(currentScratchedCampaigns.distinct())

                    saveScratchedCampaigns(
                        campaignIds = currentScratchedCampaigns.distinct(),
                        sharedPreferences = context.getSharedPreferences(
                            "AppStory",
                            Context.MODE_PRIVATE
                        )
                    )
                }
            }

            val ctaUrl = scratchCardDetails.link ?: ""

            CardScratch(
                isPresented = isPresented,
                onDismiss = {
                    isPresented = false
                    // Clear trigger event in core so dismissed item does not re-qualify.
                    core.clearTrackedEventForTrigger(campaign?.triggerEvent)
                },
                onConfettiTrigger = {
                    confettiTrigger++
                },
                wasFullyScratched = wasFullyScratched,
                onWasFullyScratched = { wasFullyScratched = it },

                crossButtonConfig = run {

                    val crossObj = scratchCardDetails.content
                        ?.get("crossButton")
                        ?.takeIf { it !is kotlinx.serialization.json.JsonNull }
                        ?.jsonObject

                    val colors = crossObj
                        ?.get("color")
                        ?.takeIf { it !is kotlinx.serialization.json.JsonNull }
                        ?.jsonObject

                    val margin = crossObj
                        ?.get("margin")
                        ?.takeIf { it !is kotlinx.serialization.json.JsonNull }
                        ?.jsonObject

                    createCrossButtonConfig(
                        fillColorString = colors?.get("fill")?.jsonPrimitive?.contentOrNull,
                        crossColorString = colors?.get("cross")?.jsonPrimitive?.contentOrNull,
                        strokeColorString = colors?.get("stroke")?.jsonPrimitive?.contentOrNull,
                        marginTop = margin?.get("top")?.jsonPrimitive?.intOrNull,
                        marginEnd = margin?.get("right")?.jsonPrimitive?.intOrNull,
                        size = crossObj?.get("size")?.jsonPrimitive?.intOrNull,
                        imageUrl = crossObj?.get("image")?.jsonPrimitive?.contentOrNull
                    )
                },
                crossButtonMarginBottom = run {
                    val crossObj = scratchCardDetails.content
                        ?.get("crossButton")
                        ?.takeIf { it !is kotlinx.serialization.json.JsonNull }
                        ?.jsonObject
                    val margin = crossObj
                        ?.get("margin")
                        ?.takeIf { it !is kotlinx.serialization.json.JsonNull }
                        ?.jsonObject
                    margin?.get("bottom")?.jsonPrimitive?.intOrNull?.dp ?: 0.dp
                },
                crossButtonAlignment = run {
                    val crossObj = scratchCardDetails.content
                        ?.get("crossButton")
                        ?.takeIf { it !is kotlinx.serialization.json.JsonNull }
                        ?.jsonObject
                    crossObj?.get("alignment")?.jsonPrimitive?.contentOrNull ?: "center"
                },
                scratchCardDetails = scratchCardDetails,
                onCtaClick = {
                    campaign?.id?.let {
                        clickEvent(link = ctaUrl, campaignId = it)
                        trackEvents(it, "clicked")
                    }
                }
            )
        }
    }

     @RequiresApi(Build.VERSION_CODES.M)
     @Composable
     fun SpinTheWheel() {
          val campaignsData = campaigns.collectAsStateWithLifecycle()
          val trackedEventsData = trackedEventNames.collectAsStateWithLifecycle()
         val disabledData = disabledCampaigns.collectAsStateWithLifecycle()

         val filtered = remember(campaignsData.value, trackedEventsData.value, disabledData.value) {
             core.getFilteredCampaigns("STW", disabledData.value)
         }

         val campaign = filtered.firstOrNull { it.details is SpinTheWheelDetails }

         val spinTheWheelDetails = when (val details = campaign?.details) {
             is SpinTheWheelDetails -> details
             else -> null
         }

         var isPresented by remember(campaign?.id) { mutableStateOf(true) }

         // Spin count: hoist here so it survives recomposition and screen navigation
         val campaignId = campaign?.id
         if (spinTheWheelDetails != null && campaignId != null && campaign != null) {
             val initialSpins = spinTheWheelDetails.availableSpins
                 ?: spinTheWheelDetails.content?.userInteraction?.numberSpin
                 ?: 3

             // Seed in-memory map on first encounter (also covers post-restart restore)
             if (!spinCountByCampaign.containsKey(campaignId)) {
                 val persisted = getSpinCount(
                     campaignId = campaignId,
                     sharedPreferences = context.getSharedPreferences(
                         "appstorys_spin_counts",
                         Context.MODE_PRIVATE
                     )
                 )
                 spinCountByCampaign[campaignId] = persisted ?: initialSpins
             }

             val spinsLeft = spinCountByCampaign[campaignId] ?: initialSpins

             if (isPresented) {

                 LaunchedEffect(Unit) {
                     trackEvents(campaignId, "viewed")
                 }

                val redirectUrl = spinTheWheelDetails.link ?: ""

                com.appversal.appstorys.ui.spinwheel.SpinTheWheel(
                    isPresented = isPresented,
                    onDismiss = {
                        isPresented = false
                        // Clear trigger event in core so dismissed item does not re-qualify.
                        core.clearTrackedEventForTrigger(campaign?.triggerEvent)
                    },
                    spinTheWheelDetails = spinTheWheelDetails,
                    spinsLeft = spinsLeft,
                    onSpinUsed = {
                        val updated = (spinCountByCampaign[campaignId] ?: initialSpins) - 1
                        val clamped = updated.coerceAtLeast(0)
                        spinCountByCampaign[campaignId] = clamped
                        saveSpinCount(
                            campaignId = campaignId,
                            count = clamped,
                            sharedPreferences = context.getSharedPreferences(
                                "appstorys_spin_counts",
                                Context.MODE_PRIVATE
                            )
                        )
                    },
                    onCtaClick = { link ->
                        val targetLink = link?.takeIf { it.isNotEmpty() } ?: redirectUrl
                        if (targetLink.isNotEmpty()) {
                            clickEvent(link = targetLink, campaignId = campaignId)
                            trackEvents(campaignId, "clicked")
                        }
                    },
                    onSpinComplete = { prizeLabel, couponCode ->
                        trackEvents(
                            campaignId, "spin_completed", mapOf(
                                "prize_label" to (prizeLabel ?: ""),
                                "coupon_code" to (couponCode ?: "")
                            )
                        )
                    }
                )
            }
        }
    }

     @Composable
     fun Milestone(
         topPadding: Dp = 0.dp,
         bottomPadding: Dp = 0.dp,
         isWidgets: Boolean = true
     ) {
         val campaignsData = campaigns.collectAsStateWithLifecycle()
         val trackedEventsData = trackedEventNames.collectAsStateWithLifecycle()
         val disabledCampaignsFlow = disabledCampaigns.collectAsStateWithLifecycle()

         val filtered = remember(campaignsData.value, trackedEventsData.value, disabledCampaignsFlow.value) {
             core.getFilteredCampaigns("MIL", disabledCampaignsFlow.value)
         }

         val campaign = filtered.firstOrNull { it.details is MilestoneDetails }

         val milestoneDetails = campaign?.details as? MilestoneDetails

         val currentIndex by currentMilestoneIndex.collectAsStateWithLifecycle()

         // Track events and update milestone index
         LaunchedEffect(trackedEventsData.value.size, milestoneDetails) {
             milestoneDetails?.milestoneItems?.let { items ->
                 val sortedItems = items.sortedBy { it.order }

                 for ((index, item) in sortedItems.withIndex()) {
                     item.triggerEvents?.forEach { trigger ->
                         trigger.eventName?.let { eventName ->
                             if (trackedEventsData.value.any { it.eventName == eventName } && index > currentIndex) {
                                 currentMilestoneIndex.emit(index)
                                 return@LaunchedEffect
                             }
                         }
                     }
                 }
             }
         }

         if (milestoneDetails != null &&
             campaign?.id != null &&
             !disabledCampaignsFlow.value.contains(campaign.id) &&
             campaign != null &&
             showMilestone
         ) {
            val sortedItems = milestoneDetails.milestoneItems?.sortedBy { it.order } ?: return

            if (currentIndex >= sortedItems.size) return

            val currentItem = sortedItems[currentIndex]
            val showAs = milestoneDetails.content?.showStreaksAs ?: "banner"

//            LaunchedEffect(currentIndex) {
//                campaign.id?.let {
//                    trackEvents(it, "viewed", mapOf("milestone_item" to currentItem.id!!))
//                }
//            }

            if ((showAs == "banner" || showAs == "modals") && !isWidgets) {
                when (showAs) {
                    "banner" -> MilestoneBanner(
                        milestoneItem = currentItem,
                        styling = milestoneDetails.styling,
                        bottomPadding = bottomPadding,
                        onClose = {
                            showMilestone = false
                            campaign.id?.let { core.disableCampaign(it) }
                        },
                        onClick = {
//                        campaign.id?.let { campaignId ->
//                            trackEvents(campaignId, "clicked", mapOf("milestone_item" to currentItem.id!!))
//                        }
                        }
                    )

                    "modals" -> MilestoneModal(
                        milestoneItem = currentItem,
                        styling = milestoneDetails.styling,
                        bottomPadding = bottomPadding,
                        onClose = {
                            showMilestone = false
                            campaign.id?.let { core.disableCampaign(it) }
                        },
                        onClick = {
//                        campaign.id?.let { campaignId ->
//                            trackEvents(campaignId, "clicked", mapOf("milestone_item" to currentItem.id!!))
//                        }
                        }
                    )
                }
            } else if (showAs == "widgets" && isWidgets) {
                // MileStone Widgets
                MilestoneWidgets(
                    milestoneItem = currentItem,
                    styling = milestoneDetails.styling,
                    onClick = {
//                        campaign.id?.let { campaignId ->
//                            trackEvents(campaignId, "clicked", mapOf("milestone_item" to currentItem.id!!))
//                        }
                    }
                )
            }
        }
    }

    @Composable
    fun TestUserButton(
        modifier: Modifier = Modifier,
        screenName: String? = null,
        activity: Activity? = null
    ) {
        val TAG = "TestUserButton"

        val activityRef = activity ?: LocalContext.current as? Activity

        var shouldAnalyze by remember { mutableStateOf(false) }
        var isCapturing by remember { mutableStateOf(false) }

        val snackbarHostState = remember { SnackbarHostState() }
        val coroutineScope = rememberCoroutineScope()

        LaunchedEffect(shouldAnalyze) {
            Log.i(TAG, "LaunchedEffect triggered. shouldAnalyze = $shouldAnalyze")

            if (shouldAnalyze) {
                Log.i(TAG, "Starting screen capture flow")
                isCapturing = true
                Log.i(TAG, "isCapturing = true")
                delay(500)
                val activity = activityRef
                Log.i(TAG, "Activity reference: $activity")
                val rootView = activity?.window?.decorView?.rootView
                Log.i(TAG, "Root view acquired: $rootView")
                rootView?.let {
                    val screenToAnalyze = screenName ?: core.currentScreen
                    Log.i(TAG, "Screen to analyze: $screenToAnalyze")

                    Log.i(TAG, "Calling analyzeViewRoot()")
                    analyzeViewRoot(it, screenToAnalyze, activity)
                    Log.i(TAG, "analyzeViewRoot() completed")

                    coroutineScope.launch {
                        Log.i(TAG, "Showing snackbar")
                        snackbarHostState.showSnackbar("Screen captured successfully!")
                    }
                }
                shouldAnalyze = false
                isCapturing = false
                if (widgetPositionList.isNotEmpty() && widgetPositionList[0].isNotEmpty()) {
                    Log.i(TAG, "widgetPositionList is valid")
                    coroutineScope.launch {
                        Log.i(TAG, "Calling apiClient.identifyPositions()")
                        apiClient.identifyPositions(
                            accessToken = core.accessToken,
                            positionList = widgetPositionList,
                            screenName = core.currentScreen
                        )
                    }
                }
            }
        }

        if (
            isScreenCaptureEnabled &&
            !isCapturing
        ) {
            Box(
                modifier = Modifier.fillMaxSize()
            ) {
                FloatingActionButton(
                    onClick = {
                        Log.i(TAG, "Capture button clicked")
                        shouldAnalyze = true

                        Log.i(TAG, "shouldAnalyze = true")
                    },
                    modifier = modifier
                        .padding(bottom = 86.dp, end = 16.dp)
                        .align(Alignment.BottomEnd),
                    containerColor = Color.White
                ) {
                    Text(
                        modifier = Modifier.padding(horizontal = 12.dp),
                        text = "Capture Screen"
                    )
                }

                SnackbarHost(
                    hostState = snackbarHostState,
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .padding(bottom = 80.dp)
                )
            }
        }
    }


    internal fun handleTooltipAction(tooltip: Tooltip, isClick: Boolean = false) {
        coroutineScope.launch {
            val campaign = campaigns.value.firstOrNull { campaign ->
                campaign.campaignType == "TTP" &&
                    (campaign.details as? TooltipsDetails)
                        ?.tooltips
                        ?.any { it.id == tooltip.id } != null
            } ?: campaigns.value.firstOrNull { campaign ->
                campaign.campaignType == "TTP" && campaign.details is TooltipsDetails
            }

            val tooltipId = tooltip.id ?: return@launch

            if (!viewedTooltips.value.contains(tooltipId)) {
                trackEvents(
                    campaign?.id,
                    "viewed",
                    mapOf("tooltip_id" to tooltipId)
                )
                viewedTooltips.update { it + tooltipId }
            }

            if (isClick) {
                val tooltipLink = tooltip.link
                if (!tooltipLink.isNullOrEmpty()) {
                    trackEvents(
                        campaign?.id,
                        "clicked",
                        mapOf("tooltip_id" to tooltipId)
                    )

                    if (tooltipLink.isNotEmpty()) {
                        if (!isValidUrl(tooltipLink)) {
                            navigateToScreen(tooltipLink)
                        } else {
                            openUrl(tooltipLink)
                        }
                    } else {
                        dismissTooltip()
                    }
                } else {
                    dismissTooltip()
                }
            }
        }
    }

    internal fun dismissTooltip() {
        coroutineScope.launch {
            tooltipTargetView.emit(null)
            showcaseVisible.emit(false)
        }
    }

    private fun clickEvent(link: Any?, campaignId: String, widgetImageId: String? = null) {

        viaAppStorys(event = "viaAppStorys${link}")

        if (link != null && link is String) {
            if (link.isNotEmpty()) {
                if (!isValidUrl(link)) {
                    navigateToScreen(link)
                } else {
                    openUrl(link)
                }
            }
        } else if (link is Map<*, *>) {
            val json = JSONObject(link)
            handleDeepLink(json, campaignId, widgetImageId)
        } else if (link is JSONObject) {
            handleDeepLink(link, campaignId, widgetImageId)
        }
    }

    private fun handleDeepLink(json: JSONObject, _campaignId: String, _widgetImageId: String?) {
        try {
            val value = json.optString("value").takeIf { it.isNotBlank() }

            if (value != null) {
                if (value.contains("://")) {
                    // URI-style deep link → fire Intent so the OS routes it
                    // through the client Activity's intent-filter / onNewIntent()
                    openUrl(value)
                } else {
                    // Plain screen name → use the navigateToScreen callback
                    navigateToScreen(value)
                }
            }

        } catch (e: Exception) {
            Log.e("DeepLinkException", e.message.toString())
        }
    }

    private fun List<WidgetImage>.turnToPair(): List<Pair<WidgetImage, WidgetImage>> {
        if (this.isEmpty()) {
            return emptyList()
        }
        val widgetImagePairs: List<Pair<WidgetImage, WidgetImage>> = this
            .sortedBy { it.order }
            .windowed(2, 2, partialWindows = false) { (first, second) ->
                first to second
            }

        return widgetImagePairs
    }


    internal fun isValidUrl(url: String?): Boolean {
        if (url.isNullOrEmpty()) return false
        // Standard http / https web URL  →  open in browser
        if (Patterns.WEB_URL.matcher(url).matches()) return true
        // Any other URI scheme (e.g. myapp://, appstorys://, app://) is a
        // custom-scheme deep link.  Returning true sends it through openUrl()
        // which fires Intent.ACTION_VIEW, letting the OS route it to the
        // client app's matching intent-filter and deliver it via onNewIntent().
        // Plain screen-name strings (e.g. "HomeScreen") contain no "://" and
        // therefore return false, continuing to reach navigateToScreen() as before.
        if (url.contains("://")) return true
        return false
    }

    internal fun openUrl(url: String) {
        try {
            val uri = url.toUri()
            // Fire a standard ACTION_VIEW Intent for ALL URIs (http, https,
            // and custom schemes like myapp://PayScreen).
            // For custom schemes the OS routes the Intent to the client app's
            // Activity via its intent-filter, delivering it through
            // onNewIntent() (singleTop) or a fresh onCreate().
            val intent = Intent(Intent.ACTION_VIEW, uri)
            intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            context.startActivity(intent)
        } catch (e: Exception) {
            Log.i("Click", "Link has $e")
        }
    }

    @JvmStatic
    fun getInstance() = this
}

