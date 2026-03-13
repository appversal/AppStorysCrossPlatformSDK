package com.example.carousal

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import android.view.ViewGroup
import android.widget.Button
import androidx.activity.ComponentActivity
import androidx.lifecycle.lifecycleScope
import com.appversal.appstorys.ui.xml.BottomSheetView
import com.appversal.appstorys.ui.xml.OverlayLayoutView
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch


class TestActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_home)

        findViewById<OverlayLayoutView>(R.id.overlay_layout)?.setActivity(this)

        findViewById<Button>(R.id.open_bottom_sheet).setOnClickListener {
//            findViewById<BottomSheetView>(R.id.bottom_sheet_view).open()
        }
        findViewById<Button>(R.id.open_more_screen).setOnClickListener {
            startActivity(Intent(this, MoreActivity::class.java))
        }

        // Handle deep link on cold start
        handleDeepLinkIntent(intent)

        // Observe the navigateToScreen callback flow
        // (for plain screen names that don't go through Intent)
        observeNavigationFlow()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleDeepLinkIntent(intent)
    }

    private fun handleDeepLinkIntent(intent: Intent?) {
        if (intent?.action == Intent.ACTION_VIEW) {
            val uri: Uri? = intent.data
            if (uri != null) {
                val screenName = uri.host?.lowercase()
                if (!screenName.isNullOrEmpty()) {
                    Log.d("TestActivity", "Deep link received: $screenName")
                    // This Activity already IS the XML Home — no further routing needed
                    // If you need to handle other screens, route them here
                }
            }
        }
    }

    private fun observeNavigationFlow() {
        val app = applicationContext as App
        lifecycleScope.launch {
            app.screenNameNavigation.collect { screenName ->
                if (screenName.isNotEmpty()) {
                    when (screenName.lowercase()) {
                        // Navigate to MoreActivity (Cashbook)
                        "cashbook" -> {
                            startActivity(Intent(this@TestActivity, MoreActivity::class.java))
                        }
                        // Navigate to Compose-based MainActivity
                        "payscreen", "homescreen", "testscreen" -> {
                            val intent = Intent(this@TestActivity, MainActivity::class.java)
                            intent.putExtra("screen_name", screenName)
                            startActivity(intent)
                        }
                    }
                    app.resetNavigation()
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        App.appStorys.getScreenCampaigns(
            "Home Screen Kotlin XML",
            emptyList()
        )
        lifecycleScope.launch {
            App.appStorys.setUserProperties(mapOf("hello" to "world"))
        }
    }
}