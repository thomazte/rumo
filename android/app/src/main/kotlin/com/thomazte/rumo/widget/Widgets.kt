package com.thomazte.rumo.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.appWidgetBackground
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.lazy.LazyColumn
import androidx.glance.appwidget.lazy.items
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.height
import androidx.glance.layout.padding
import androidx.glance.layout.size
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import com.thomazte.rumo.R
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

private val cardModifier
    get() = GlanceModifier.fillMaxSize().appWidgetBackground().cornerRadius(24.dp).background(RumoColors.surface)

@Composable
private fun snapshot(): WidgetSnapshot = WidgetSnapshot.read(currentState<HomeWidgetGlanceState>().preferences)

// ---------- Hoje ----------

class TodayWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()
    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { Content(context, snapshot()) }
    }

    @Composable
    private fun Content(context: Context, s: WidgetSnapshot) {
        Column(modifier = cardModifier.padding(horizontal = 12.dp, vertical = 12.dp)) {
            Row(
                modifier = GlanceModifier.fillMaxWidth().padding(start = 4.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Row(
                    modifier = GlanceModifier.defaultWeight().clickable(openApp(context, "open?tab=today")),
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    Image(ImageProvider(R.drawable.widget_logo), contentDescription = null, modifier = GlanceModifier.size(22.dp))
                    Spacer(GlanceModifier.width(8.dp))
                    Text("Hoje", style = TextStyle(color = RumoColors.ink, fontSize = 15.sp, fontWeight = FontWeight.Bold))
                    Spacer(GlanceModifier.width(8.dp))
                    Text(
                        when (val left = s.pendingToday.size) {
                            0 -> "Tudo feito"
                            1 -> "1 restante"
                            else -> "$left restantes"
                        },
                        style = TextStyle(color = RumoColors.muted, fontSize = 12.sp, fontWeight = FontWeight.Medium),
                    )
                }
                PlusButton(openApp(context, "capture"))
            }
            Spacer(GlanceModifier.height(4.dp))
            if (s.pendingToday.isEmpty()) {
                Text(
                    "Nada pendente para hoje.",
                    modifier = GlanceModifier.padding(start = 4.dp, top = 8.dp),
                    style = TextStyle(color = RumoColors.muted, fontSize = 13.sp),
                )
            } else {
                LazyColumn {
                    items(s.pendingToday, itemId = { it.id.hashCode().toLong() }) { t ->
                        Row(modifier = GlanceModifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                            CheckCircle(t.priority, toggleTask(t.id))
                            Text(
                                t.title,
                                maxLines = 1,
                                modifier = GlanceModifier.defaultWeight().padding(vertical = 6.dp).clickable(openTask(context, t.id)),
                                style = TextStyle(color = RumoColors.ink, fontSize = 14.sp, fontWeight = FontWeight.Medium),
                            )
                            when {
                                t.date < s.today -> Text(
                                    "atrasada",
                                    modifier = GlanceModifier.padding(start = 6.dp, end = 4.dp),
                                    style = TextStyle(color = RumoColors.high, fontSize = 11.sp, fontWeight = FontWeight.Bold),
                                )
                                t.minutes != null -> Text(
                                    formatMinutes(t.minutes),
                                    modifier = GlanceModifier.padding(start = 6.dp, end = 4.dp),
                                    style = TextStyle(color = RumoColors.muted, fontSize = 12.sp),
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

class TodayWidgetReceiver : HomeWidgetGlanceWidgetReceiver<TodayWidget>() {
    override val glanceAppWidget = TodayWidget()
}

// ---------- A seguir ----------

class NextWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { Content(context, snapshot()) }
    }

    @Composable
    private fun Content(context: Context, s: WidgetSnapshot) {
        val next = s.next()
        Column(
            modifier = cardModifier.padding(14.dp)
                .clickable(if (next == null) openApp(context, "open?tab=today") else openTask(context, next.id)),
        ) {
            Label("A seguir")
            Spacer(GlanceModifier.defaultWeight())
            if (next == null) {
                Text("Nada pendente", style = TextStyle(color = RumoColors.ink, fontSize = 15.sp, fontWeight = FontWeight.Bold))
            } else {
                val late = next.date < s.today
                val big = when {
                    late -> "Atrasada"
                    next.minutes != null -> formatMinutes(next.minutes)
                    else -> "Hoje"
                }
                Text(
                    big,
                    style = TextStyle(
                        color = if (late) RumoColors.high else RumoColors.accent,
                        fontSize = if (next.minutes != null && !late) 30.sp else 24.sp,
                        fontWeight = FontWeight.Bold,
                    ),
                )
                Spacer(GlanceModifier.height(4.dp))
                Text(next.title, maxLines = 2, style = TextStyle(color = RumoColors.ink, fontSize = 14.sp, fontWeight = FontWeight.Bold))
                Spacer(GlanceModifier.height(6.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    if (next.projectName != null) {
                        Box(GlanceModifier.size(8.dp).cornerRadius(3.dp).background(RumoColors.project(next.projectColor))) {}
                        Spacer(GlanceModifier.width(6.dp))
                    }
                    Text(next.projectName ?: "Sem projeto", style = TextStyle(color = RumoColors.muted, fontSize = 12.sp))
                }
            }
        }
    }
}

class NextWidgetReceiver : HomeWidgetGlanceWidgetReceiver<NextWidget>() {
    override val glanceAppWidget = NextWidget()
}

// ---------- Progresso ----------

class ProgressWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { Content(context, snapshot()) }
    }

    @Composable
    private fun Content(context: Context, s: WidgetSnapshot) {
        Column(
            modifier = cardModifier.padding(12.dp).clickable(openApp(context, "open?tab=today")),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Box(contentAlignment = Alignment.Center) {
                Image(
                    ImageProvider(ringBitmap(context, 76, 8f, s.progress)),
                    contentDescription = "${s.doneToday} de ${s.total} concluídas",
                    modifier = GlanceModifier.size(76.dp),
                )
                Text(
                    "${(s.progress * 100).toInt()}%",
                    style = TextStyle(color = RumoColors.ink, fontSize = 16.sp, fontWeight = FontWeight.Bold),
                )
            }
            Spacer(GlanceModifier.height(8.dp))
            Text("${s.doneToday} de ${s.total} hoje", style = TextStyle(color = RumoColors.ink, fontSize = 13.sp, fontWeight = FontWeight.Medium))
            Text(
                if (s.pendingToday.isEmpty()) "Dia completo" else "${s.pendingToday.size} para terminar",
                style = TextStyle(color = RumoColors.muted, fontSize = 11.5.sp),
            )
        }
    }
}

class ProgressWidgetReceiver : HomeWidgetGlanceWidgetReceiver<ProgressWidget>() {
    override val glanceAppWidget = ProgressWidget()
}

// ---------- Adicionar ----------

class AddWidget : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { Content(context) }
    }

    @Composable
    private fun Content(context: Context) {
        Row(
            modifier = GlanceModifier.fillMaxSize().appWidgetBackground().cornerRadius(28.dp)
                .background(RumoColors.surface).padding(horizontal = 10.dp).clickable(openApp(context, "capture")),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            PlusButton(openApp(context, "capture"), size = 32.dp)
            Spacer(GlanceModifier.width(12.dp))
            Text(
                "Adicionar tarefa",
                modifier = GlanceModifier.defaultWeight(),
                style = TextStyle(color = RumoColors.ink, fontSize = 15.sp, fontWeight = FontWeight.Bold),
            )
            Text("#projeto !alta", style = TextStyle(color = RumoColors.muted, fontSize = 11.sp))
            Spacer(GlanceModifier.width(6.dp))
        }
    }
}

class AddWidgetReceiver : HomeWidgetGlanceWidgetReceiver<AddWidget>() {
    override val glanceAppWidget = AddWidget()
}
