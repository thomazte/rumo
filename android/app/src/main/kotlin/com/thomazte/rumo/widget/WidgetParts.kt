package com.thomazte.rumo.widget

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.RectF
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.Action
import androidx.glance.action.ActionParameters
import androidx.glance.action.actionParametersOf
import androidx.glance.action.clickable
import androidx.glance.appwidget.action.ActionCallback
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.appwidget.cornerRadius
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.size
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider
import com.thomazte.rumo.MainActivity
import es.antonborri.home_widget.HomeWidgetBackgroundIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.actionStartActivity

// Endereços que o app entende (lib/platform/home_widgets.dart).
fun openApp(context: Context, path: String = "open"): Action =
    actionStartActivity<MainActivity>(context, Uri.parse("rumo://$path"))

fun openTask(context: Context, id: String): Action = openApp(context, "task?id=${Uri.encode(id)}")

val TaskIdKey = ActionParameters.Key<String>("taskId")

fun toggleTask(id: String): Action = actionRunCallback<ToggleTaskAction>(actionParametersOf(TaskIdKey to id))

/** Conclui pelo widget: esconde na hora e pede ao app para salvar em segundo plano. */
class ToggleTaskAction : ActionCallback {
    override suspend fun onAction(context: Context, glanceId: GlanceId, parameters: ActionParameters) {
        val id = parameters[TaskIdKey] ?: return
        WidgetSnapshot.markPendingDone(HomeWidgetPlugin.getData(context), id)
        refreshAllWidgets(context)
        HomeWidgetBackgroundIntent.getBroadcast(context, Uri.parse("rumo://toggle?id=${Uri.encode(id)}")).send()
    }
}

/** O círculo de concluir, na cor da prioridade. */
@Composable
fun CheckCircle(priority: Int, onClick: Action, size: Dp = 20.dp) {
    Box(
        modifier = GlanceModifier.size(size + 12.dp).clickable(onClick),
        contentAlignment = Alignment.Center,
    ) {
        Box(
            modifier = GlanceModifier.size(size).cornerRadius(size / 2).background(RumoColors.priority(priority)),
            contentAlignment = Alignment.Center,
        ) {
            Box(modifier = GlanceModifier.size(size - 4.dp).cornerRadius((size - 4.dp) / 2).background(RumoColors.surface)) {}
        }
    }
}

@Composable
fun PlusButton(onClick: Action, size: Dp = 30.dp) {
    Box(
        modifier = GlanceModifier.size(size).cornerRadius(size / 2).background(RumoColors.accent).clickable(onClick),
        contentAlignment = Alignment.Center,
    ) {
        Text("+", style = TextStyle(color = RumoColors.onAccent, fontSize = 20.sp, fontWeight = FontWeight.Bold))
    }
}

@Composable
fun Label(text: String, color: ColorProvider = RumoColors.muted) {
    Text(text.uppercase(), style = TextStyle(color = color, fontSize = 10.5.sp, fontWeight = FontWeight.Bold))
}

/** Anel de progresso desenhado em bitmap (Glance não desenha arcos). */
fun ringBitmap(context: Context, sizeDp: Int, strokeDp: Float, progress: Float): Bitmap {
    val night = isNight(context)
    val density = context.resources.displayMetrics.density
    val px = (sizeDp * density).toInt()
    val bitmap = Bitmap.createBitmap(px, px, Bitmap.Config.ARGB_8888)
    val canvas = Canvas(bitmap)
    val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeWidth = strokeDp * density
        strokeCap = Paint.Cap.ROUND
    }
    val inset = paint.strokeWidth / 2
    val rect = RectF(inset, inset, px - inset, px - inset)
    paint.color = RumoColors.trackArgb(night)
    canvas.drawOval(rect, paint)
    if (progress > 0f) {
        paint.color = RumoColors.accentArgb(night)
        canvas.drawArc(rect, -90f, 360f * progress.coerceAtMost(1f), false, paint)
    }
    return bitmap
}
