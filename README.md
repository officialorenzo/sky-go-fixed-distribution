# Sky Go Fixed

Launcher di compatibilità non ufficiale per usare Sky Go Italia su macOS 26 quando l’app ufficiale va in crash all’avvio.

## download rapido

- [Scarica il DMG per Mac](https://github.com/officialorenzo/sky-go-fixed-distribution/releases/download/v1.3/Sky-Go-Fixed-Installer-macOS-26.dmg)
- [Scarica lo ZIP per Mac](https://github.com/officialorenzo/sky-go-fixed-distribution/releases/download/v1.3/Sky-Go-Fixed-Installer-macOS-26.zip)
- [Apri la release v1.3 e verifica gli hash](https://github.com/officialorenzo/sky-go-fixed-distribution/releases/tag/v1.3)

Il DMG è la procedura più semplice. Apri **Installa Sky Go Fixed** con clic destro → **Apri** e conferma l’avviso di macOS. Al termine l’app viene installata realmente in `/Applications/Sky Go Fixed.app` ed è avviabile da Finder, Launchpad e Dock.

## cosa corregge la versione 1.3

- il Dock riapre il launcher esterno e non il runtime Electron annidato;
- chiudendo il runtime, un nuovo clic sull’icona lo avvia nuovamente;
- il modulo keystore di Sky Go 26.2.3 viene adattato all’ABI del runtime compatibile;
- il runtime è aggiornato a Electron 41.10.3 x86_64;
- nel Dock compare una sola app con l’icona Sky Go Fixed.

## account e privacy

Ogni persona accede dalla schermata originale con il proprio account Sky. L’installer non contiene né trasferisce password, cookie, preferenze, registrazioni, download offline o dati personali.

L’installer scarica Sky Go 26.2.3 dal server ufficiale Sky ed Electron 41.10.3 dalla release ufficiale Electron. Verifica SHA-256, firma Developer ID e notarizzazione del pacchetto Sky prima di creare l’app.

## compatibilità

- macOS 26;
- Mac Intel e Apple Silicon;
- launcher universale `arm64 + x86_64`;
- Rosetta richiesta su Apple Silicon perché i componenti Sky restano Intel;
- connessione Internet necessaria durante l’installazione.

## versioni e impronte

- Sky Go Fixed **1.3**, build 6;
- installer **1.4**, build 7;
- Sky Go **26.2.3**;
- Electron **41.10.3** x86_64.

| file | dimensione | SHA-256 |
| --- | ---: | --- |
| `Sky-Go-Fixed-Installer-macOS-26.dmg` | 927.936 byte | `160a5b8c7f040e5b4ca5aad6f50a1865764e87a465d8eda4c18ea64395b3db78` |
| `Sky-Go-Fixed-Installer-macOS-26.zip` | 514.407 byte | `7109c5183eb264d193d077b0fde270cfcf5ac7b82f2e936f012d89046b3435e5` |

## sorgenti e build

Il repository contiene il launcher Swift, l’installer grafico, lo script di installazione e il piccolo adattatore di compatibilità. Non contiene l’app Sky Go, Electron, account o dati utente.

Per creare localmente DMG e ZIP:

```bash
bash ./script/build_distributable.sh
```

Gli artefatti vengono scritti in `outputs/`. L’installer scarica i componenti ufficiali solo quando viene eseguito dall’utente.

## limiti

Sky Go Fixed non è sviluppato né supportato da Sky Italia e non modifica abbonamenti, licenze, DRM, limiti dei dispositivi o contenuti disponibili. L’interfaccia Sky rimane codice Intel eseguito tramite Rosetta, quindi non può avere la fluidità di un’app nativa Apple Silicon. Un futuro aggiornamento di Sky o macOS potrebbe richiedere una nuova release.
