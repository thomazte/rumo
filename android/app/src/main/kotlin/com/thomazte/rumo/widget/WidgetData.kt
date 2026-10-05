package com.thomazte.rumo.widget

import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
import androidx.compose.ui.graphics.Color
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.glance.appwidget.state.updateAppWidgetState
import androidx.glance.color.ColorProvider
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

/** Mesmas chaves que lib/platform/home_widgets.dart escreve. */
object WidgetKeys {
    const val DATA = "rumo_widget"
    const val PENDING = "rumo_widget_pending"
}

data class WidgetTask(
    val id: String,
    val title: String,
    /** yyyy-MM-dd; compara como texto. */
    val date: String,
    val minutes: Int?,
    val priority: Int,
    val projectName: String?,
    val projectColor: String?,
)

/**
 * O que o app mandou para os widgets. As contas de "hoje" são feitas aqui,
 * na hora de desenhar, para o widget virar o dia sozinho.
 */
class WidgetSnapshot(private val tasks: List<WidgetTask>, private val doneDates: List<String>, private val hidden: Set<String>) {
    val today: String = dayString(Calendar.getInstance())

    val pendingToday: List<WidgetTask> = tasks.filter { it.date <= today && it.id !in hidden }

    val doneToday: Int = doneDates.count { it == today } + tasks.count { it.id in hidden }

    val total: Int get() = pendingToday.size + doneToday

    val progress: Float get() = if (total == 0) 0f else doneToday.toFloat() / total

    /** A próxima com horário ainda hoje; senão a mais urgente. */
    fun next(): WidgetTask? {
        val now = Calendar.getInstance()
        val nowMinutes = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        return pendingToday.firstOrNull { it.date == today && it.minutes != null && it.minutes >= nowMinutes }
            ?: pendingToday.firstOrNull { it.priority == 3 }
            ?: pendingToday.firstOrNull()
    }

    companion object {
        fun dayString(c: Calendar): String = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(c.time)

        fun read(prefs: SharedPreferences): WidgetSnapshot {
            val hidden = prefs.getString(WidgetKeys.PENDING, null)
                ?.split(',')?.filter { it.isNotBlank() }?.toSet() ?: emptySet()
            val raw = prefs.getString(WidgetKeys.DATA, null) ?: return WidgetSnapshot(emptyList(), emptyList(), hidden)
            return try {
                val json = JSONObject(raw)
                val list = json.getJSONArray("tasks")
                val tasks = (0 until list.length()).map { i ->
                    val t = list.getJSONObject(i)
                    WidgetTask(
                        id = t.getString("id"),
                        title = t.getString("t"),
                        date = t.getString("d"),
                        minutes = if (t.has("m")) t.getInt("m") else null,
                        priority = t.optInt("p", 0),
                        projectName = t.optString("pn").ifEmpty { null },
                        projectColor = t.optString("pc").ifEmpty { null },
                    )
                }
                val done = json.getJSONArray("done")
                WidgetSnapshot(tasks, (0 until done.length()).map { done.getString(it) }, hidden)
            } catch (e: Exception) {
                WidgetSnapshot(emptyList(), emptyList(), hidden)
            }
        }

        /** Esconde a tarefa na hora, antes do app confirmar em segundo plano. */
        fun markPendingDone(prefs: SharedPreferences, id: String) {
            val current = prefs.getString(WidgetKeys.PENDING, null)
                ?.split(',')?.filter { it.isNotBlank() }?.toMutableSet() ?: mutableSetOf()
            current.add(id)
            prefs.edit().putString(WidgetKeys.PENDING, current.joinToString(",")).commit()
        }
    }
}

fun formatMinutes(m: Int): String = String.format(Locale.US, "%02d:%02d", m / 60, m % 60)

fun isNight(context: Context): Boolean =
    (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES

/** Paleta do app (lib/ui/theme.dart), em claro e escuro. */
object RumoColors {
    val surface = ColorProvider(day = Color(0xFFFFFFFF), night = Color(0xFF151A24))
    val surface2 = ColorProvider(day = Color(0xFFF2F4F8), night = Color(0xFF1C2230))
    val ink = ColorProvider(day = Color(0xFF141925), night = Color(0xFFE9EDF5))
    val muted = ColorProvider(day = Color(0xFF677085), night = Color(0xFF8D96AA))
    val accent = ColorProvider(day = Color(0xFF2D5BE3), night = Color(0xFF7090FF))
    val onAccent = ColorProvider(day = Color(0xFFFFFFFF), night = Color(0xFF0B0E14))
    val high = ColorProvider(day = Color(0xFFE2484D), night = Color(0xFFFF6B6E))
    val medium = ColorProvider(day = Color(0xFFE08A0B), night = Color(0xFFF5A524))
    val low = ColorProvider(day = Color(0xFF2F9467), night = Color(0xFF3DBE86))
    val none = ColorProvider(day = Color(0xFFAEB5C4), night = Color(0xFF4C5568))

    fun priority(p: Int) = when (p) {
        3 -> high
        2 -> medium
        1 -> low
        else -> none
    }

    fun project(key: String?) = when (key) {
        "orange" -> ColorProvider(day = Color(0xFFD97A2B), night = Color(0xFFF09A50))
        "green" -> ColorProvider(day = Color(0xFF2F9467), night = Color(0xFF3DBE86))
        "violet" -> ColorProvider(day = Color(0xFF8A57E8), night = Color(0xFFA983FF))
        else -> ColorProvider(day = Color(0xFF2D5BE3), night = Color(0xFF7090FF))
    }

    // Cores fixas para o anel desenhado em bitmap.
    fun accentArgb(night: Boolean) = if (night) 0xFF7090FF.toInt() else 0xFF2D5BE3.toInt()
    fun trackArgb(night: Boolean) = if (night) 0xFF273042.toInt() else 0xFFE3E7EF.toInt()
}

/** Redesenha todos os widgets do Rumo que estiverem na tela. */
suspend fun refreshAllWidgets(context: Context) {
    val manager = GlanceAppWidgetManager(context)
    for (widget in listOf(TodayWidget(), NextWidget(), ProgressWidget(), AddWidget())) {
        for (id in manager.getGlanceIds(widget.javaClass)) {
            updateAppWidgetState(context, HomeWidgetGlanceStateDefinition(), id) { it }
            widget.update(context, id)
        }
    }
}
