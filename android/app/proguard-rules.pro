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

# Google Play Billing usa modelos serializados por reflexão. Sem esta regra
# a compra funciona em debug e falha no release.
-keep class com.android.vending.billing.** { *; }
-keep class com.google.android.gms.common.api.** { *; }
-keep class com.google.android.gms.auth.** { *; }

# Login com Google. O google_sign_in 7.x não usa mais a API antiga do GMS
# Auth: ele passa pelo Credential Manager (androidx.credentials) e pela
# biblioteca de identidade do Google. As regras acima não cobrem esse
# caminho, e o R8 só roda no release — exatamente onde o login some sem
# mensagem.
-keep class androidx.credentials.** { *; }
-keep class com.google.android.libraries.identity.googleid.** { *; }
-keep class com.google.android.gms.identitycredentials.** { *; }
-dontwarn androidx.credentials.**
-dontwarn com.google.android.libraries.identity.googleid.**
