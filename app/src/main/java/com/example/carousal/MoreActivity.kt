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


class MoreActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_more)

        // Handle deep link on cold start
        handleDeepLinkIntent(intent)

        // Observe the navigateToScreen callback flow
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
                    Log.d("MoreActivity", "Deep link received: $screenName")
                    // This Activity already IS the Cashbook screen — no further routing needed
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
                        // Navigate to TestActivity (XML Home)
                        "xmlhome" -> {
                            startActivity(Intent(this@MoreActivity, TestActivity::class.java))
                        }
                        // Navigate to Compose-based MainActivity
                        "payscreen", "homescreen", "testscreen" -> {
                            val intent = Intent(this@MoreActivity, MainActivity::class.java)
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
            "Cashbook Tab",
            emptyList()
        )
    }
}