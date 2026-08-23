# Plugin classes and generated R classes are kept because marker icons
# are resolved reflectively (R.drawable::class.java.getField(name)).
-keep class com.golrang.map_kit.R$drawable {
    *;
}

-keep class com.golrang.map_kit.R {
    *;
}

-keep class com.golrang.map_kit.** {
    *;
}

# Neshan SDK talks to native code through JNI and resolves parts of itself
# reflectively; stripping or renaming these classes breaks markers,
# polylines and circles in minified release builds.
-keep class org.neshan.** {
    *;
}

-keep class com.carto.** {
    *;
}

-dontwarn org.neshan.**
-dontwarn com.carto.**