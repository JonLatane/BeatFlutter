package io.beatscratch.beatscratch_flutter_redux

import android.content.Context
import android.content.SharedPreferences
import android.preference.PreferenceManager
import kotlin.reflect.KProperty

/*
 * Android Shared Preferences Delegate for Kotlin
 *
 * Usage:
 *
 * PrefDelegate.init(storageContext)
 * ...
 * var accessToken by stringPref(PREFS_ID, "access_token")
 * var appLaunchCount by intPref(PREFS_ID, "app_launch_count", 0)
 * var autoRefreshEnabled by booleanPref("auto_refresh enabled") // using Default Shared Preferences
 *
 */

abstract class PrefDelegate<T>(val prefName: String?, val prefKey: String) {
 private val context get()  = MainApplication.instance

	protected val prefs: SharedPreferences by lazy {
			if (prefName != null) context.getSharedPreferences(prefName, Context.MODE_PRIVATE)
			else PreferenceManager.getDefaultSharedPreferences(context)
	}

	abstract operator fun getValue(thisRef: Any?, property: KProperty<*>): T
	abstract operator fun setValue(thisRef: Any?, property: KProperty<*>, value: T)
}

fun stringPref(prefKey: String, defaultValue: String) = StringPrefDelegate(prefKey, defaultValue)
class StringPrefDelegate(prefKey: String, val defaultValue: String?) : PrefDelegate<String>(null, prefKey) {
	override fun getValue(thisRef: Any?, property: KProperty<*>) = prefs.getString(prefKey, defaultValue)!!
	override fun setValue(thisRef: Any?, property: KProperty<*>, value: String) = prefs.edit().putString(prefKey, value).apply()
}

fun intPref(prefKey: String, defaultValue: Int = 0) = IntPrefDelegate(null, prefKey, defaultValue)
fun intPref(prefName: String, prefKey: String, defaultValue: Int = 0) = IntPrefDelegate(prefName, prefKey, defaultValue)
class IntPrefDelegate(prefName: String?, prefKey: String, val defaultValue: Int) : PrefDelegate<Int>(prefName, prefKey) {
	override fun getValue(thisRef: Any?, property: KProperty<*>) = prefs.getInt(prefKey, defaultValue)
	override fun setValue(thisRef: Any?, property: KProperty<*>, value: Int) = prefs.edit().putInt(prefKey, value).apply()
}

fun floatPref(prefKey: String, defaultValue: Float = 0f) = FloatPrefDelegate(null, prefKey, defaultValue)
fun floatPref(prefName: String, prefKey: String, defaultValue: Float = 0f) = FloatPrefDelegate(prefName, prefKey, defaultValue)
class FloatPrefDelegate(prefName: String?, prefKey: String, val defaultValue: Float) : PrefDelegate<Float>(prefName, prefKey) {
	override fun getValue(thisRef: Any?, property: KProperty<*>) = prefs.getFloat(prefKey, defaultValue)
	override fun setValue(thisRef: Any?, property: KProperty<*>, value: Float) = prefs.edit().putFloat(prefKey, value).apply()
}

fun booleanPref(prefKey: String, defaultValue: Boolean = false) = BooleanPrefDelegate(null, prefKey, defaultValue)
fun booleanPref(prefName: String, prefKey: String, defaultValue: Boolean = false) = BooleanPrefDelegate(prefName, prefKey, defaultValue)
class BooleanPrefDelegate(prefName: String?, prefKey: String, val defaultValue: Boolean) : PrefDelegate<Boolean>(prefName, prefKey) {
	override fun getValue(thisRef: Any?, property: KProperty<*>) = prefs.getBoolean(prefKey, defaultValue)
	override fun setValue(thisRef: Any?, property: KProperty<*>, value: Boolean) = prefs.edit().putBoolean(prefKey, value).apply()
}

fun longPref(prefKey: String, defaultValue: Long = 0L) = LongPrefDelegate(null, prefKey, defaultValue)
fun longPref(prefName: String, prefKey: String, defaultValue: Long = 0L) = LongPrefDelegate(prefName, prefKey, defaultValue)
class LongPrefDelegate(prefName: String?, prefKey: String, val defaultValue: Long) : PrefDelegate<Long>(prefName, prefKey) {
	override fun getValue(thisRef: Any?, property: KProperty<*>) = prefs.getLong(prefKey, defaultValue)
	override fun setValue(thisRef: Any?, property: KProperty<*>, value: Long) = prefs.edit().putLong(prefKey, value).apply()
}


fun stringSetPref(prefKey: String, defaultValue: Set<String> = emptySet()) = StringSetPrefDelegate(null, prefKey, defaultValue)
fun stringSetPref(prefName: String, prefKey: String, defaultValue:  Set<String> = emptySet()) = StringSetPrefDelegate(prefName, prefKey, defaultValue)
class StringSetPrefDelegate(prefName: String?, prefKey: String, val defaultValue: Set<String>) : PrefDelegate<Set<String>>(prefName, prefKey) {
	override fun getValue(thisRef: Any?, property: KProperty<*>) = prefs.getStringSet(prefKey, defaultValue)?.toSet() ?: emptySet()
	override fun setValue(thisRef: Any?, property: KProperty<*>, value: Set<String>) = prefs.edit().putStringSet(prefKey, value).apply()
}

//fun stringSetPref(prefKey: String, defaultValue: Set<String> = HashSet<String>()) = StringSetPrefDelegate(null, prefKey, defaultValue)
//fun stringSetPref(prefName: String, prefKey: String, defaultValue: Set<String> = HashSet<String>()) = StringSetPrefDelegate(prefName, prefKey, defaultValue)
//class StringSetPrefDelegate(prefName: String?, prefKey: String, val defaultValue: Set<String>) : PrefDelegate<Set<String>>(prefName, prefKey) {
//	override fun getValue(thisRef: Any?, property: KProperty<*>): MutableSet<String> = prefs.getStringSet(prefKey, defaultValue)
//	override fun setValue(thisRef: Any?, property: KProperty<*>, value: Set<String>) = prefs.edit().putStringSet(prefKey, value).apply()
//}