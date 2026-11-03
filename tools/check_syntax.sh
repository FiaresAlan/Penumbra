#!/bin/sh
# Confere a sintaxe de todos os .lua de src/ com o luau-analyze (não roda o jogo e não confere tipos do Roblox).
# Uso: baixe luau-windows.zip de https://github.com/luau-lang/luau/releases para tools/downloads/luau e rode este script.
A=tools/downloads/luau/luau-analyze.exe
fails=0
for f in $(find src -name "*.lua"); do
  out=$($A "$f" 2>&1 | grep -i "SyntaxError")
  if [ -n "$out" ]; then echo "$out"; fails=$((fails+1)); fi
done
echo "arquivos com erro de sintaxe: $fails"
