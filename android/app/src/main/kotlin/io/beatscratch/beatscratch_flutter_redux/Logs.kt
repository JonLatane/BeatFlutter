package io.beatscratch.beatscratch_flutter_redux

import android.util.Log

fun Any.logE(msg: String, tr: Throwable) {
  Log.e(javaClass.simpleName, msg, tr)
}
fun Any.logI(msg: String) {
  Log.i(javaClass.simpleName, msg)
}
fun Any.logV(msg: String) {
  Log.v(javaClass.simpleName, msg)
}
fun Any.logW(msg: String) {
  Log.w(javaClass.simpleName, msg)
}
fun Any.logW(msg: String, tr: Throwable) {
  Log.w(javaClass.simpleName, msg, tr)
}