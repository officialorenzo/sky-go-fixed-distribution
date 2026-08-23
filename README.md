# Sky Go Fixed

Launcher di compatibilità non ufficiale per usare Sky Go Italia su macOS 26 quando l’app ufficiale va in crash all’avvio.

## download rapido

- [Scarica il DMG per Mac](https://github.com/FollowTheNull/sky-go-fixed-distribution/releases/download/v1.3.1/Sky-Go-Fixed-Installer-macOS-26.dmg)
- [Scarica lo ZIP per Mac](https://github.com/FollowTheNull/sky-go-fixed-distribution/releases/download/v1.3.1/Sky-Go-Fixed-Installer-macOS-26.zip)
- [Apri la release v1.3.1 e verifica gli hash](https://github.com/FollowTheNull/sky-go-fixed-distribution/releases/tag/v1.3.1)

Il DMG è la procedura più semplice. L'installer non è ancora notarizzato da Apple, quindi al primo avvio macOS 26 può mostrare soltanto il pulsante **Fine** e bloccarne l'esecuzione.

1. Apri il DMG e prova ad avviare **Installa Sky Go Fixed**.
2. Se macOS mostra l'avviso di sicurezza, premi **Fine**.
3. Apri **Impostazioni di Sistema → Privacy e sicurezza**.
4. Scorri fino a **Sicurezza** e premi **Apri comunque** accanto a *Installa Sky Go Fixed*.
5. Autorizza con password o Touch ID, quindi conferma **Apri**.

L'eccezione viene salvata sul Mac. Al termine dell'installazione, **Sky Go Fixed** si trova realmente in `/Applications` ed è avviabile da Finder, Launchpad e Dock. Sui Mac aziendali gestiti, l'amministratore può impedire l'uso di **Apri comunque**.

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
- installer **1.4**, build 8;
- Sky Go **26.2.3**;
- Electron **41.10.3** x86_64.

| file | dimensione | SHA-256 |
| --- | ---: | --- |
| `Sky-Go-Fixed-Installer-macOS-26.dmg` | 928.238 byte | `7d9be8ac8f88f1eeed0fd54b8ffc9d1ac4fa43b6c62cb2237306d04d0b1994a0` |
| `Sky-Go-Fixed-Installer-macOS-26.zip` | 514.683 byte | `197365f2f2c9429fd27c64cf0599eb6e5a792f9b0d0a7aba19e95045e815e4da` |

## sorgenti e build

Il repository contiene il launcher Swift, l’installer grafico, lo script di installazione e il piccolo adattatore di compatibilità. Non contiene l’app Sky Go, Electron, account o dati utente.

Per creare localmente DMG e ZIP:

```bash
bash ./script/build_distributable.sh
```

Gli artefatti vengono scritti in `outputs/`. L’installer scarica i componenti ufficiali solo quando viene eseguito dall’utente.

## limiti

Sky Go Fixed non è sviluppato né supportato da Sky Italia e non modifica abbonamenti, licenze, DRM, limiti dei dispositivi o contenuti disponibili. L’interfaccia Sky rimane codice Intel eseguito tramite Rosetta, quindi non può avere la fluidità di un’app nativa Apple Silicon. Un futuro aggiornamento di Sky o macOS potrebbe richiedere una nuova release.
