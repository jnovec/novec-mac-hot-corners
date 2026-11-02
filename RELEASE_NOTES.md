# NOVEC Mac Hot Corners 0.2.0 — Nové grafické rozhraní

Druhé veřejné vydání přináší nativní grafické nastavení všech čtyř aktivních rohů macOS.

## Novinky ve verzi 0.2

- Přehledné okno ve SwiftUI s mapou rohů a čtyřmi samostatnými kartami nastavení.
- Pro každý roh lze vybrat Mission Control, zobrazení oken nebo plochy, Screenshot, systémové diktování (Fn + D), Enter, vlastní klávesovou zkratku, příkaz v Terminálu či spuštění aplikace. Roh lze také vypnout.
- Klávesové zkratky lze zadat například jako `cmd+shift+5`, `ctrl+up` nebo `fn+d`.
- Výběr aplikace probíhá pomocí systémového dialogu macOS.
- Nastavení se ukládá lokálně, platí ihned a zůstává zachováno po restartu.
- Ikona v liště nabídek otevírá nastavení, automatické spouštění po přihlášení běží na pozadí.
- Nastavitelná prodleva aktivace, dvousekundová ochrana proti opakování a nejvýše jedno spuštění při každém najetí do rohu.

## Instalace

Stáhni **NOVEC-Hot-Corners-v0.2.0-macOS-universal.zip**, rozbal celý archiv a otevři **install.command**. Instalátor zazálohuje předchozí verzi a nevyžaduje n8n. V **Nastavení systému → Soukromí a zabezpečení → Zpřístupnění** aplikaci povol. Příkazy v Terminálu se spouštějí pod tvým uživatelským účtem a mohou vyžadovat schválení Automatizace.

## Podpis a ověření

Univerzální aplikace pro Apple Silicon a Intel je sestavována a automaticky testována pomocí GitHub Actions. Má *ad-hoc* podpis, nikoliv podpis Apple Developer ID či notarizaci. macOS může vyžadovat **Přesto otevřít**; po výměně aplikace může být nutné znovu povolit Zpřístupnění. CI ověřuje kompilaci, vlastní testy, obě architektury a podpis. Chování GUI je potřeba vyzkoušet také přímo na Macu.

Výchozí nastavení zůstává: Mission Control vlevo nahoře, diktování vpravo nahoře, Screenshot vlevo dole a Enter vpravo dole. Funkce fyzické klávesy mikrofonu F5 se nemění.
