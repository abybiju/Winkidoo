package com.winkidoo.winkidoo

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class WinkidooWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val mgr = AppWidgetManager.getInstance(context)
        val ids = mgr.getAppWidgetIds(
            android.content.ComponentName(context, WinkidooWidgetProvider::class.java)
        )
        for (id in ids) updateWidget(context, mgr, id)
    }

    private fun updateWidget(
        context: Context,
        mgr: AppWidgetManager,
        widgetId: Int
    ) {
        val prefs = HomeWidgetPlugin.getData(context)
        val streak  = prefs.getInt("streak", 0)
        val pending = prefs.getInt("pending", 0)
        val prompt  = prefs.getString("prompt", "💝 Create a surprise today!") ?: ""

        val views = RemoteViews(context.packageName, R.layout.winkidoo_widget)
        views.setTextViewText(R.id.widget_streak,  "🔥 $streak")
        views.setTextViewText(R.id.widget_pending, "💌 $pending")
        views.setTextViewText(R.id.widget_prompt,  prompt)

        // Tap opens the vault
        val launchIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
        if (launchIntent != null) {
            launchIntent.data = android.net.Uri.parse("winkidoo://shell/vault")
            val pi = android.app.PendingIntent.getActivity(
                context, 0, launchIntent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or
                        android.app.PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_streak, pi)
            views.setOnClickPendingIntent(R.id.widget_pending, pi)
            views.setOnClickPendingIntent(R.id.widget_prompt, pi)
        }

        mgr.updateAppWidget(widgetId, views)
    }
}
