# Regras extras do R8 para o build de release (o Flutter carrega este arquivo sozinho).

# shared_preferences_android 2.5+ fala com o Dart por JNI (pacote `jni`), que procura classes
# e métodos pelo nome original. Se o R8 renomear ou remover algum deles, o app quebra ao abrir
# (NoSuchMethodError / ClassNotFoundException). O pacote `jni` só protege as próprias classes;
# esta lista cobre as classes do Kotlin e do plugin citadas no código Dart dos dois pacotes.
-keep class kotlin.Unit { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.coroutines.Continuation { *; }
-keep class kotlin.coroutines.intrinsics.** { *; }
-keep class kotlin.enums.EnumEntries { *; }
-keep class kotlin.jvm.internal.DefaultConstructorMarker { *; }
-keep class io.flutter.plugins.sharedpreferences.** { *; }
