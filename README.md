# Sky Go Fixed

Una versione di compatibilità per usare Sky Go su macOS 26 quando l'app ufficiale non si avvia correttamente.

## download rapido

- [Scarica il DMG per Mac](https://github.com/officialorenzo/sky-go-fixed-distribution/releases/download/v1.2/Sky-Go-Fixed-Installer-macOS-26.dmg)
- [Scarica lo ZIP per Mac](https://github.com/officialorenzo/sky-go-fixed-distribution/releases/download/v1.2/Sky-Go-Fixed-Installer-macOS-26.zip)
- [Apri la release v1.2 e verifica gli hash](https://github.com/officialorenzo/sky-go-fixed-distribution/releases/tag/v1.2)

Il DMG è la procedura più semplice. Se macOS mostra un avviso, usa clic destro → **Apri**. Prima dell'installazione confronta il file con lo SHA-256 pubblicato nella release.

## che cos'è

Sky Go Fixed è un launcher non ufficiale per macOS. Mantiene l'interfaccia e i servizi originali di Sky Go, ma usa un ambiente di avvio compatibile per evitare il crash che può verificarsi durante l'apertura dell'app su macOS 26.

Non è un'applicazione sviluppata o supportata da Sky Italia.

## versione verificata

La versione **1.2** è la versione dell'app Sky Go Fixed. L'installer che la installa è alla versione **1.3**: sono due numeri diversi perché l'installer è il programma che prepara e installa l'app.

## come si usa

Per installare la release v1.2:

1. scarica il DMG oppure lo ZIP;
2. apri l'installer con clic destro → **Apri**;
3. conferma l'avviso di macOS;
4. lascia terminare l'installazione;
5. avvia **Sky Go Fixed** dalla cartella Applicazioni.

L'app finale viene installata in `/Applications/Sky Go Fixed.app` e si apre come una normale applicazione.

## account e privacy

Ogni persona accede con il proprio account Sky. L'installer non contiene né trasferisce password, cookie, preferenze, registrazioni, download offline o dati personali di altri utenti.

## compatibilità

- macOS 26;
- Mac Intel e Apple Silicon;
- launcher universale `arm64 + x86_64`;
- Rosetta può essere richiesta da macOS al primo avvio su Apple Silicon;
- connessione Internet necessaria durante l'installazione.

## dati tecnici

- app: Sky Go Fixed **1.2**, build 3;
- installer: **1.3**, build 4;
- componenti Sky: Sky Go **26.2.3**;
- runtime compatibile: Electron **41.3.0** x86_64;
- formato DMG: 926.272 byte;
- formato ZIP: 513.022 byte.

### impronte SHA-256

| file | SHA-256 |
| --- | --- |
| `Sky-Go-Fixed-Installer-macOS-26.dmg` | `94accddb3a328908ae010c6bc49c40996b9e491055d0797136ae2446ebe3afe2` |
| `Sky-Go-Fixed-Installer-macOS-26.zip` | `6866a4cd1b5fa0aed41c7569a46eb205be59eceb8d853625b7c8db751bce3cf7` |

## sicurezza e trasparenza

L'installer scarica i componenti dai server ufficiali Sky ed Electron e ne controlla l'integrità prima di creare l'app. Il file scaricato va sempre confrontato con il relativo SHA-256 indicato nella release.

Al primo avvio macOS può richiedere **clic destro → Apri** perché questa è una distribuzione non ufficiale e non firmata con un certificato Apple Developer ID.

## limiti

Sky Go Fixed non modifica abbonamenti, licenze, DRM, limiti dei dispositivi o contenuti disponibili. Un aggiornamento futuro di Sky o macOS potrebbe richiedere una nuova release.

I file di installazione sono disponibili nella [release Sky Go Fixed 1.2](https://github.com/officialorenzo/sky-go-fixed-distribution/releases/tag/v1.2).
