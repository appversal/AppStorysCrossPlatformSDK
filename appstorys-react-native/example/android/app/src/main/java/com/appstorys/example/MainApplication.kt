package com.appstorys.example

import android.app.Application
import com.appstorysreactnative.AppStorysPackage
import com.appstorys.example.BuildConfig
import com.facebook.react.ReactApplication
import com.facebook.react.ReactNativeHost
import com.facebook.react.ReactPackage
import com.facebook.react.shell.MainReactPackage
import com.facebook.soloader.SoLoader
import com.th3rdwave.safeareacontext.SafeAreaContextPackage
import com.airbnb.android.react.lottie.LottiePackage
import com.rnfs.RNFSPackage
import fr.greweb.reactnativeviewshot.RNViewShotPackage
import com.brentvatne.react.ReactVideoPackage

class MainApplication : Application(), ReactApplication {

    override val reactNativeHost: ReactNativeHost = object : ReactNativeHost(this) {
        // Keep Metro/dev support always on for the example app to avoid asset-bundle fallback.
        override fun getUseDeveloperSupport(): Boolean = true

        override fun getPackages(): List<ReactPackage> = listOf(
            MainReactPackage(),
            AppStorysPackage(),
            SafeAreaContextPackage(),
            LottiePackage(),
            RNFSPackage(),
            RNViewShotPackage(),
            ReactVideoPackage()
        )

        override fun getJSMainModuleName(): String = "index"
    }


    override fun onCreate() {
        super.onCreate()
        SoLoader.init(this, false)
    }
}
