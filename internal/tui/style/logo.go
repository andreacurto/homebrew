package style

import (
	_ "embed"
	"strings"
)

// donkeyLogo è l'arte ANSI a colori del logo, generata da chafa dall'immagine
// sorgente. Vive come file incorporato così è disponibile offline nel binario.
//
//go:embed donkey.ansi
var donkeyLogo string

// DonkeyLogo ritorna il logo pronto da stampare (già colorato in ANSI).
func DonkeyLogo() string {
	return strings.Trim(donkeyLogo, "\n")
}
