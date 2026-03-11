#!/bin/bash
# Run this once from your project root to download the real fonts
# Usage: bash assets/fonts/DOWNLOAD_FONTS.sh

DIR="assets/fonts"
echo "Downloading Bebas Neue..."
curl -L "https://github.com/dharmatype/Bebas-Neue/raw/master/fonts/BebasNeue(2018)ByDharmaType.zip" -o /tmp/bebas.zip
unzip -p /tmp/bebas.zip "*.ttf" | head -c 999999 > "$DIR/BebasNeue-Regular.ttf" 2>/dev/null || \
  curl -L "https://fonts.gstatic.com/s/bebasneue/v14/JTUSjIg69CK48gW7PXoo9WdhyyTh89ZNpQ.ttf" -o "$DIR/BebasNeue-Regular.ttf"

echo "Downloading DM Mono..."
curl -L "https://fonts.gstatic.com/s/dmmono/v14/aFTR7PB1QTsUX8KYthyorYataIf4VllXuA.ttf" -o "$DIR/DMMono-Regular.ttf"
curl -L "https://fonts.gstatic.com/s/dmmono/v14/aFTU7PB1QTsUX8KYth-QAa6JYKzkXw.ttf" -o "$DIR/DMMono-Medium.ttf"
curl -L "https://fonts.gstatic.com/s/dmmono/v14/aFTV7PB1QTsUX8KYthCGd9aMiZJN.ttf" -o "$DIR/DMMono-Italic.ttf"

echo "✅ Fonts downloaded. Run: flutter pub get"
