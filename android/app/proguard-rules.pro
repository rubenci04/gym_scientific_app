# Evitar que R8/ProGuard rompa Hive y los Modelos
-keep class com.google.gson.** { *; }
-keep class sun.misc.Unsafe { *; }
-keep class com.google.crypto.tink.** { *; }

# Mantener tus modelos de datos (ajusta el paquete si es diferente)
-keep class io.flutter.plugins.** { *; }
-keep class com.example.gym_scientific_app.** { *; }

# Hive específico
-keep class org.apache.commons.logging.** { *; }
-dontwarn org.apache.commons.logging.**