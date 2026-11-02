# NOVEC Mac Hot Corners

**Čeština** | [English](README.en.md)

Nativní aplikace pro macOS, která umožňuje nastavit samostatnou akci pro každý ze čtyř aktivních rohů obrazovky. Verze **0.3.0** přidává automatické přizpůsobení jazyku macOS (čeština, angličtina, němčina) a zachovává grafické ovládání všech rohů.

![NOVEC Mac Hot Corners v0.2 – grafické nastavení všech čtyř aktivních rohů](docs/images/novec-hot-corners-gui-v0.2.webp)

*Ukázka nastavení ve verzi 0.2 — pro každý roh lze vybrat jinou akci.*

## Jazyky aplikace

Aplikace automaticky používá jazyk preferovaný v macOS: **češtinu, angličtinu nebo němčinu**. Pokud není žádný z těchto jazyků v jazykových preferencích dostupný, použije se angličtina. Jazyk lze samostatně nastavit pro NOVEC Hot Corners v **Nastavení systému → Obecné → Jazyk a oblast → Aplikace** (při změně aplikaci znovu spusť). Všechny překlady jsou součástí instalačního balíčku a fungují offline.

## Co aplikace umí

V nabídce **NOVEC Hot Corners → Nastavení aktivních rohů…** lze pro každý roh nezávisle zvolit:

- Mission Control, zobrazení oken aplikace nebo plochy (nativní funkce macOS).
- Spuštění nástroje Screenshot, systémového diktování pomocí **Fn + D** nebo stisknutí Enter.
- Vlastní klávesovou zkratku, například `cmd+shift+5`, `ctrl+up` nebo `fn+d`.
- Spuštění vlastního příkazu v Terminálu.
- Otevření nainstalované aplikace vybrané v dialogu.
- Vypnutí akce pro konkrétní roh.

Grafické rozhraní obsahuje mapu rohů, přepínače povolení a nastavitelnou prodlevu aktivace. Nastavení se ukládá lokálně, uplatní se ihned a zůstane zachováno po restartu. **Fyzická klávesa mikrofonu F5 na MacBooku se nemění.**

### Výchozí nastavení

| Roh obrazovky | Akce |
|---|---|
| Levý horní | Mission Control |
| Pravý horní | Diktování macOS (Fn + D) |
| Levý dolní | Screenshot |
| Pravý dolní | Enter |

## Instalace

1. Otevři [nejnovější vydání](https://github.com/jnovec/novec-mac-hot-corners/releases/latest).
2. Stáhni soubor **NOVEC-Hot-Corners-v0.3.0-macOS-universal.zip**. **Nestahuj** automaticky generovaný archiv „Source code“.
3. Rozbal **celý** ZIP a otevři soubor `install.command` vedle `NOVEC Hot Corners.app`.
4. V **Nastavení systému → Soukromí a zabezpečení → Zpřístupnění** aplikaci povol. Pro funkci diktování zapni také systémové diktování v nastavení Klávesnice.
5. Při prvním spuštění se otevře okno nastavení. Později ho otevřeš pomocí **ikony NOVEC v liště nabídek**.

Instalátor uloží zálohu předchozí verze, nainstaluje aplikaci do `~/Applications`, spustí ji a zaregistruje automatické spouštění po přihlášení. Není potřeba Docker, n8n ani administrátorské oprávnění.

**Zabezpečení a oprávnění:** Aplikace je podepsaná *ad-hoc*, nikoli certifikátem Apple Developer ID, a není notarizovaná. macOS proto může po kontrole balíčku vyžadovat ruční volbu **Přesto otevřít**. Po aktualizaci může být nutné znovu povolit Zpřístupnění. Vlastní příkaz v Terminálu se spouští s oprávněními přihlášeného uživatele a macOS může vyžadovat povolení Automatizace. Zadávej pouze příkazy, kterým důvěřuješ.

## Sestavení ze zdrojových kódů

```sh
xcrun swiftc -O Sources/*.swift -o novec-hot-corners
./novec-hot-corners --self-test
```

[GitHub Actions](https://github.com/jnovec/novec-mac-hot-corners/actions/workflows/build-release.yml) kompilují a testují verze pro Apple Silicon (`arm64`) i Intel (`x86_64`), vytvoří univerzální binární soubor, přidají lokální podpis a ke každému vydání s tagem `v*` publikují ZIP a kontrolní součet SHA-256.

## Technické informace

- Nativní nastavení ve SwiftUI a ikona v liště nabídek přes AppKit.
- Ukládání nastavení pomocí `UserDefaults`.
- Výchozí prodleva aktivace 350 ms, jedno spuštění při najetí do rohu a dvousekundová ochrana proti opakování.
- Podpora více monitorů pomocí `NSScreen`.
- Klávesové události prostřednictvím macOS Accessibility a `CGEvent`.
- Systémové funkce plochy a oken spravuje macOS Dock.
- Diagnostický log: `~/Library/Logs/NOVEC-HotCorners.log`.

Automatické testy ověřují sestavení, architektury, podpis a mapování rohů. Nedokážou však plně simulovat interakci s grafickým rozhraním ani schvalování oprávnění macOS. Tyto funkce je nutné prakticky ověřit na cílovém Macu.

Tento repozitář obsahuje pouze samostatnou aplikaci NOVEC Mac Hot Corners.
