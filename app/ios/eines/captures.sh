#!/usr/bin/env bash
# Captures de l'App Store en el simulador (Codemagic o qualsevol Mac).
#
#   ios/eines/captures.sh "iPhone 17 Pro Max|iPhone 16 Pro Max" iphone
#   ios/eines/captures.sh "iPad Pro 13-inch"                     ipad
#
# 1r argument: noms de simulador acceptats (expressió regular; el primer que hi haja).
# 2n argument: subcarpeta de captures/ on deixar-les.
# Cal: SUPABASE_URL, SUPABASE_KEY, CAPTURES_EMAIL i CAPTURES_PASSWORD (vegeu docs/CODEMAGIC.md).
# S'executa des de app/.
set -euo pipefail

PATRO="$1"
SORTIDA="captures/$2"
BUNDLE="com.mamlabsfera.observatoriPerlhorta"
# L'horta de Benimaclet, la mateixa vista que les captures d'Android
LAT=39.4330
LON=-0.3668

UDID=$(xcrun simctl list devices available -j | python3 -c "
import json, re, sys
dispositius = [d for r, ds in json.load(sys.stdin)['devices'].items() if 'iOS' in r for d in ds]
for p in sys.argv[1].split('|'):
    for d in dispositius:
        if re.fullmatch(re.escape(p) + r'( \(.*\))?', d['name']):
            print(d['udid']); sys.exit()
sys.exit('Cap simulador coincideix amb: ' + sys.argv[1])
" "$PATRO")
echo "Simulador: $UDID"

xcrun simctl boot "$UDID" 2>/dev/null || true
xcrun simctl bootstatus "$UDID" -b
# Barra d'estat neta, com en les captures d'Apple
xcrun simctl status_bar "$UDID" override --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
xcrun simctl location "$UDID" set "$LAT,$LON"
# El permís d'ubicació, donat abans: així no ix el diàleg
xcrun simctl privacy "$UDID" grant location "$BUNDLE" || true

mkdir -p "$SORTIDA"
SIMULADOR_UDID="$UDID" CAPTURES_DIR="$SORTIDA" flutter drive \
  -d "$UDID" \
  --driver=test_driver/captures.dart \
  --target=integration_test/captures_test.dart \
  --dart-define=SUPABASE_URL="$SUPABASE_URL" \
  --dart-define=SUPABASE_KEY="$SUPABASE_KEY" \
  --dart-define=CAPTURES_EMAIL="$CAPTURES_EMAIL" \
  --dart-define=CAPTURES_PASSWORD="$CAPTURES_PASSWORD"

ls -l "$SORTIDA"
