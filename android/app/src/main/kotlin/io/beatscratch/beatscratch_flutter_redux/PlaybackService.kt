package io.beatscratch.beatscratch_flutter_redux


import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.annotation.RequiresApi
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationCompat.PRIORITY_DEFAULT
import io.beatscratch.beatscratch_flutter_redux.BeatScratchPlugin.Companion.currentSection


class PlaybackService : Service() {

  companion object {
    private const val SERVICE_ID = 101

    object Action {
      const val MAIN_ACTION = "main"
      const val STARTFOREGROUND_ACTION = "startService"
      const val STOPFOREGROUND_ACTION = "stopService"
      const val PLAY_ACTION = "play"
      const val PAUSE_ACTION = "pause"
      const val STOP_ACTION = "stop"
      const val REWIND_ACTION = "rewind"
    }

    var instance: PlaybackService? = null
      private set
  }

  internal lateinit var playbackThread: PlaybackThread private set
  val isStopped get() = playbackThread.stopped

  override fun onCreate() {
    super.onCreate()
    instance = this
    playbackThread = PlaybackThread()
    playbackThread.start()
//    AndroidMidi.ONBOARD_DRIVER.start()
    MidiDevices.refreshInstruments()
  }

  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    when (intent?.action) {
      Action.STARTFOREGROUND_ACTION -> {
        logI("Received Start Foreground Intent ")
        showNotification()
      }
      Action.PLAY_ACTION            -> {
        logI("Clicked Play")
        playbackThread.stopped = false
        synchronized(PlaybackThread) {
          (PlaybackThread as java.lang.Object).notify()
        }
        showNotification()
      }
      Action.REWIND_ACTION          -> {
        logI("Clicked Rewind")
        BeatClockScoreConsumer.tickPosition = 0
      }
      Action.PAUSE_ACTION           -> {
        logI("Clicked Pause")
        playbackThread.stopped = true
        showNotification()
      }
      Action.STOP_ACTION            -> {
        logI("Clicked Stop")
        playbackThread.stopped = true
        BeatClockScoreConsumer.tickPosition = 0
//        BeatClockPaletteConsumer.viewModel?.playbackTick = 0
        BeatClockScoreConsumer.clearActiveAttacks()
        AndroidMidi.flushSendStream()
        AndroidMidi.sendImmediately(byteArrayOf(123.toByte()))// All notes off
        AndroidMidi.sendImmediately(byteArrayOf(0xFF.toByte()))// Midi reset
        showNotification()
      }
      Action.STOPFOREGROUND_ACTION  -> {
        logI("Received Stop Foreground Intent")
        stopForeground(true)
        stopSelf()
//        BeatClockPaletteConsumer.viewModel?.activity?.finish()
//        doAsync {
//          Thread.sleep(1000L)
//          val pid = android.os.Process.myPid()
//          android.os.Process.killProcess(pid)
//          exitProcess(0)
//        }
      }
    }
    return START_STICKY
  }

  override fun onDestroy() {
    super.onDestroy()
    logI("In onDestroy")
    playbackThread.terminated = true
//    AudioTrackCache.releaseAll()
    AndroidMidi.sendImmediately(byteArrayOf(0xFF.toByte()))// Midi reset
//    AndroidMidi.ONBOARD_DRIVER.stop()
  }

  override fun onBind(intent: Intent): IBinder? {
    // Used only in case of bound services.
    return null
  }

  fun showNotification() {
    val pendingIntent = Intent(this, MainActivity::class.java).let {
      //it.action = Action.MAIN_ACTION
      //it.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
      PendingIntent.getActivity(this, 0, it, 0)
    }

    fun pendingIntent(action: String) = PendingIntent.getService(
      this, 0,
      Intent(this, PlaybackService::class.java).also {
        it.action = action
      }, 0)

//    val icon = BitmapFactory.decodeResource(resources, R.drawable.beatscratch_icon)

    val channelId =
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        createNotificationChannel()
      } else {
        // If earlier version channel ID is not used
        // https://developer.android.com/reference/android/support/v4/app/NotificationCompat.Builder.html#NotificationCompat.Builder(android.content.Context)
        ""
      }

    val sectionName = currentSection?.name ?: "Section ${currentSection?.id?.substring(0..5)}"
    val builder = NotificationCompat.Builder(this, channelId)
      .setSmallIcon(R.drawable.beatscratch_icon_inset_slight_transparent_keys)
      .setContentTitle("Score Name")
      .setTicker("Score Name")
      .setPriority(PRIORITY_DEFAULT)
      .setVibrate(null)
      .setSound(null)
      .setContentText(sectionName)
      //.setPriority()
//      .setL
//      .setLargeIcon(Bitmap.createScaledBitmap(icon, 128, 128, false))
      .setContentIntent(pendingIntent)
      .setOngoing(true)
      .apply {
        if(isStopped) {
          addAction(R.drawable.play_notification, "Play", pendingIntent(Action.PLAY_ACTION))
        } else {
          addAction(R.drawable.previous_notification, "Skip back", pendingIntent(Action.REWIND_ACTION))
        }
      }
      .addAction(R.drawable.stop_notification, "Stop", pendingIntent(Action.STOP_ACTION))
      .addAction(R.drawable.close_notification, "Exit", pendingIntent(Action.STOPFOREGROUND_ACTION))
      .setStyle(androidx.media.app.NotificationCompat.MediaStyle().setShowActionsInCompactView(0, 1)
        .setShowCancelButton(true)
        .setCancelButtonIntent(pendingIntent(Action.STOPFOREGROUND_ACTION)))
//      .setStyle(
//        NotificationCompat.MediaStyle()
//          .setShowActionsInCompactView(0, 1)
////          .setShowCancelButton(true)
////          .setCancelButtonIntent(pendingIntent(Action.STOPFOREGROUND_ACTION))
//      )
//    builder.setStyle(NotificationCompat.MediaStyle(builder))
    val notification = builder.build();
    startForeground(SERVICE_ID, notification)

  }

  @RequiresApi(Build.VERSION_CODES.O)
  private fun createNotificationChannel(): String {
    val channelId = "audio_playback"
    val channelName = "MIDI and Hardware Audio"
    val chan = NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_DEFAULT)
    chan.setSound(null, null)
    chan.enableVibration(false)
    //chan.lightColor = Color.BLUE
    //chan.importance = NotificationManager.IMPORTANCE_NONE
    //chan.lockscreenVisibility = Notification.VISIBILITY_PRIVATE
    val service = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    service.createNotificationChannel(chan)
    return channelId
  }
}