package app.zeromiles

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class PartnerWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.partner_widget).apply {
                val pending = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                )
                setOnClickPendingIntent(R.id.widget_root, pending)

                val name = widgetData.getString("widget_name", "Partner") ?: "Partner"
                val mood = widgetData.getString("widget_mood", "") ?: ""
                val scene = widgetData.getString("widget_scene", "") ?: ""
                setTextViewText(R.id.widget_name, name)
                setTextViewText(R.id.widget_mood, mood)
                setTextViewText(R.id.widget_scene, scene)
                setViewVisibility(
                    R.id.widget_mood,
                    if (mood.isEmpty()) View.GONE else View.VISIBLE,
                )
                setInt(
                    R.id.widget_root,
                    "setBackgroundResource",
                    when (scene) {
                        "Dawn" -> R.drawable.partner_widget_bg_dawn
                        "Dusk" -> R.drawable.partner_widget_bg_dusk
                        "Night" -> R.drawable.partner_widget_bg_night
                        else -> R.drawable.partner_widget_bg_day
                    },
                )

                val imagePath = widgetData.getString("widget_avatar", null)
                if (!imagePath.isNullOrEmpty()) {
                    val bitmap = BitmapFactory.decodeFile(imagePath)
                    if (bitmap != null) {
                        setImageViewBitmap(R.id.widget_avatar, bitmap)
                        setViewVisibility(R.id.widget_avatar, View.VISIBLE)
                    } else {
                        setViewVisibility(R.id.widget_avatar, View.GONE)
                    }
                } else {
                    setViewVisibility(R.id.widget_avatar, View.GONE)
                }
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
