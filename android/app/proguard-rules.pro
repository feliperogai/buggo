# Regras do R8 para o build de release.
#
# O plugin Gradle do Flutter já injeta as regras do engine; o que sobra aqui
# são os plugins que usam reflexão e por isso não sobrevivem à minificação.

# image_picker / flutter_secure_storage acessam classes do AndroidX via
# reflexão em alguns caminhos de código.
-keep class androidx.lifecycle.DefaultLifecycleObserver

# Mantém os nomes de arquivo e linha nos stack traces enviados pelo Play
# Console; sem isso, o relatório de crash vem ilegível.
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# Google Play Billing e google_sign_in usam modelos serializados por reflexão.
# Sem estas regras a compra e o login funcionam em debug e falham no release.
-keep class com.android.vending.billing.** { *; }
-keep class com.google.android.gms.common.api.** { *; }
-keep class com.google.android.gms.auth.** { *; }
