/// Each distribution fixes its language here, independently of macOS.
/// Keep the bundle development region and installer in the same language.
enum L10n {
    static let languageCode = "en"

    private static func text(_ english: String, _ french: String) -> String {
        languageCode == "fr" ? french : english
    }

    static let brightness = text("Brightness", "Luminosité")
    static let volume = text("Volume", "Volume")
    static let mute = text("Mute", "Couper le son")
    static let unmute = text("Unmute", "Rétablir le son")
    static let options = text("Options…", "Options…")
    static let quit = text("Quit", "Quitter")
    static let keyboardPermissionRequired = text(
        "Media-key permission required", "Autorisation des touches multimédias requise"
    )
    static let keyboardPermissionHelp = text(
        "Allow Evnia Control in Privacy & Security > Accessibility to use the sun and volume keys.",
        "Autorisez Evnia Control dans Confidentialité et sécurité > Accessibilité pour utiliser les touches de luminosité et de volume."
    )
    static let requestAccess = text("Request Access", "Autoriser l’accès")
    static let systemSettings = text("System Settings", "Réglages Système")
    static let useOptions = text(
        "Use Options… in Evnia Control.", "Utilisez Options… dans Evnia Control."
    )
    static let attenuation = text("Attenuation", "Atténuation")
    static let launchAtLogin = text(
        "Launch Evnia Control at login", "Lancer Evnia Control à l’ouverture de session"
    )
    static let optionsWindowTitle = text("Evnia Control Options", "Options Evnia Control")
    static let attenuationActive = text(
        "Audio attenuation is active via Core Audio.", "L’atténuation audio via Core Audio est active."
    )
    static let noAttenuation = text("0 dB: no attenuation.", "0 dB : aucune atténuation.")
    static let displayBrightness = text("Display brightness", "Luminosité de l’écran")
    static let displayVolume = text("Display volume", "Volume de l’écran")
    static let searchingForDisplay = text("Searching for the display…", "Recherche de l’écran…")
    static let connected = text("Connected", "Connecté")
    static let brightnessUnavailable = text(
        "Connected — brightness DDC unavailable", "Connecté — luminosité DDC indisponible"
    )
    static let volumeUnavailable = text(
        "Connected — volume DDC unavailable", "Connecté — volume DDC indisponible"
    )
    static let ddcEngineMissing = text(
        "The bundled DDC engine could not be found.", "Le moteur DDC intégré est introuvable."
    )
    static let displayNotFound = text(
        "No compatible Evnia display was detected.", "Aucun écran Evnia compatible n’a été détecté."
    )
    static let invalidDDCResponse = text("Invalid DDC response.", "Réponse DDC invalide.")
    static let ddcNotResponding = text(
        "The display was detected, but DDC/CI is not responding.",
        "L’écran a été détecté, mais DDC/CI ne répond pas."
    )
    static let ddcTimedOut = text(
        "The DDC request timed out. Disconnect and reconnect the display, then try again.",
        "La requête DDC a expiré. Débranchez puis rebranchez l’écran et réessayez."
    )
    static let ddcCommandFailed = text("The DDC command failed.", "La commande DDC a échoué.")
    static let noAudioOutput = text(
        "No default audio output is available.", "Aucune sortie audio par défaut n’est disponible."
    )

    static func percent(_ value: Int) -> String {
        text("\(value) percent", "\(value) pour cent")
    }

    static func audioStatus(_ message: String) -> String {
        text("Audio: \(message)", "Audio : \(message)")
    }
}
