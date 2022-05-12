package etc

import (
	"bufio"
	"bytes"
	_ "embed"
	"mime"
	"strings"
)

//go:embed mime.types
var mimeTypeRaw []byte

func init() {
	loadMime(mimeTypeRaw)
}

func loadMime(data []byte) {
	scanner := bufio.NewScanner(bytes.NewBuffer(data))
	for scanner.Scan() {
		fields := strings.Fields(scanner.Text())
		if len(fields) <= 1 || fields[0][0] == '#' {
			continue
		}
		mimeType := fields[0]
		for _, ext := range fields[1:] {
			if ext[0] == '#' {
				break
			}
			_ = mime.AddExtensionType("."+ext, mimeType)
		}
	}
	if err := scanner.Err(); err != nil {
		panic(err)
	}
}
