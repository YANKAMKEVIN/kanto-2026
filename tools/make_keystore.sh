#!/usr/bin/env bash
# Crée, une seule fois, la clé de signature release de Pokemake (J34). À lancer par Kevin.
#
# Usage : tools/make_keystore.sh [chemin.jks]
#   chemin : où garder le keystore, HORS du dépôt (défaut : ~/.pokemake/pokemake-release.jks)
#   Le mot de passe est lu dans GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD (jamais en argument : il
#   resterait dans l'historique du shell). L'alias est GODOT_ANDROID_KEYSTORE_RELEASE_USER
#   (défaut : pokemake).
#
# La même clé signe toutes les versions à venir : si elle est perdue, plus aucune mise à jour
# par-dessus n'est possible sur les téléphones des proches (il faudrait désinstaller, et la
# sauvegarde part avec). Sauvegarder le fichier et le mot de passe dans un gestionnaire de mots de
# passe. Détail : docs/tech/release.md
set -euo pipefail

KEYSTORE="${1:-$HOME/.pokemake/pokemake-release.jks}"
ALIAS="${GODOT_ANDROID_KEYSTORE_RELEASE_USER:-pokemake}"
: "${GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD:?définis GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD (au moins 6 caractères) avant de lancer ce script}"
[ "${#GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD}" -ge 6 ] || { echo "Mot de passe trop court (6 caractères au moins)" >&2; exit 1; }
[ ! -e "$KEYSTORE" ] || { echo "Le keystore existe déjà : $KEYSTORE (on ne l'écrase jamais)" >&2; exit 1; }

REPO="$(cd "$(dirname "$0")/.." && pwd)"
case "$(mkdir -p "$(dirname "$KEYSTORE")" && cd "$(dirname "$KEYSTORE")" && pwd)" in
	"$REPO"*) echo "Garde le keystore hors du dépôt ($REPO)" >&2; exit 1 ;;
esac

KEYTOOL="${KEYTOOL:-keytool}"
if ! command -v "$KEYTOOL" >/dev/null; then
	KEYTOOL="/Users/kevinyankam/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool"
fi

"$KEYTOOL" -genkeypair -v \
	-keystore "$KEYSTORE" -storetype PKCS12 \
	-alias "$ALIAS" -keyalg RSA -keysize 4096 -validity 10950 \
	-dname "CN=Pokemake, OU=Kevin, O=Pokemake, C=FR" \
	-storepass:env GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD \
	-keypass:env GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD >/dev/null
chmod 600 "$KEYSTORE"

echo "Keystore créé : $KEYSTORE (alias $ALIAS, RSA 4096, valable 30 ans)"
# « keytool -list -v » plante en locale française (bug de format du JDK) : on le lance en anglais.
"$KEYTOOL" -J-Duser.language=en -list -v -keystore "$KEYSTORE" -alias "$ALIAS" \
	-storepass:env GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD 2>/dev/null \
	| grep -E "SHA256:" | sed 's/^[[:space:]]*/  Empreinte /' || true
cat <<EOF

À mettre dans ~/.zshrc (ou un fichier chargé par le shell, jamais dans le dépôt) :
  export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$KEYSTORE"
  export GODOT_ANDROID_KEYSTORE_RELEASE_USER="$ALIAS"
  export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="…"
Puis : tools/build_rc.sh
EOF
