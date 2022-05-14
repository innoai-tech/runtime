package main

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"io/ioutil"
	"log"
	"mime"
	"net/http"
	"os"
	"os/signal"
	"path"
	"runtime"
	"strings"
	"syscall"
	"time"

	"github.com/innoai-tech/runtime/pkg/appconfig"
	"github.com/innoai-tech/runtime/pkg/compress"
	"github.com/innoai-tech/runtime/pkg/version"
	"github.com/rs/cors"
	"github.com/spf13/cobra"
)

var serverOpt = &WebappServerOpt{}

var cmd = &cobra.Command{
	Version: version.FullVersion(),
	Run: func(cmd *cobra.Command, args []string) {
		if err := Serve(serverOpt); err != nil {
			panic(err)
		}
	},
}

func init() {
	cmd.Flags().StringVarP(&serverOpt.Port, "port", "p", os.Getenv("PORT"), "port")
	cmd.Flags().StringVarP(&serverOpt.AppRoot, "root", "", os.Getenv("APP_ROOT"), "app root")
	cmd.Flags().StringVarP(&serverOpt.AppConfig, "config", "c", os.Getenv("APP_CONFIG"), "app config")
	cmd.Flags().StringVarP(&serverOpt.AppEnv, "env", "e", os.Getenv("ENV"), "app env")
}

func main() {
	if err := cmd.Execute(); err != nil {
		panic(err)
	}
}

func Serve(opt *WebappServerOpt) error {
	if opt.Port == "" {
		opt.Port = "80"
	}

	srv := &http.Server{
		Addr:    ":" + opt.Port,
		Handler: compress.CompressHandlerLevel(WebappServer(opt), 6),
	}

	stopCh := make(chan os.Signal, 1)
	signal.Notify(stopCh, os.Interrupt, syscall.SIGTERM)

	go func() {
		log.Printf("webappserve on %s (%s/%s), %s\n", srv.Addr, runtime.GOOS, runtime.GOARCH, version.FullVersion())

		if err := srv.ListenAndServe(); err != nil {
			if err == http.ErrServerClosed {
				log.Println(err)
			} else {
				log.Fatalln(err)
			}
		}
	}()

	<-stopCh

	log.Printf("shutdowning in %s\n", 10*time.Second)

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	return srv.Shutdown(ctx)
}

type WebappServerOpt struct {
	AppConfig string
	AppEnv    string
	AppRoot   string
	Port      string
}

func WebappServer(opt *WebappServerOpt) http.Handler {
	indexHTML, err := ioutil.ReadFile(path.Join(opt.AppRoot, "./index.html"))
	if err != nil {
		indexHTML = []byte(fmt.Sprintf(`
<p>Please put your webapp static under</p>
<pre>
<code>
%s/
└── __built__/
	└── app.*.js
	└── chunk.*.png
└── index.html
</code>
</pre>
`, opt.AppRoot))
	}

	appConfig := appconfig.ParseAppConfig(opt.AppConfig)

	appConfig.LoadFromEnviron(os.Environ())

	indexHTML = bytes.ReplaceAll(indexHTML, []byte("__ENV__"), []byte(opt.AppEnv))
	indexHTML = bytes.ReplaceAll(indexHTML, []byte("__APP_CONFIG__"), []byte(appConfig.String()))

	cwd, _ := os.Getwd()
	root := path.Join(cwd, opt.AppRoot)

	if len(opt.AppRoot) > 0 && opt.AppRoot[0] == '/' {
		root = opt.AppRoot
	}

	return &webappServer{
		indexHTML:   indexHTML,
		fs:          http.Dir(root),
		corsHandler: cors.Default(),
		appConfig:   appConfig,
	}
}

type webappServer struct {
	appConfig   appconfig.AppConfig
	indexHTML   []byte
	corsHandler *cors.Cors
	fs          http.FileSystem
}

func (s *webappServer) responseFromIndexHTML(w http.ResponseWriter) {
	w.Header().Set("Content-Type", mime.TypeByExtension(".html"))

	w.Header().Set("X-Frame-Options", "sameorigin")
	w.Header().Set("X-Content-Type-Options", "nosniff")
	w.Header().Set("X-XSS-Protection", "1; mode=block")

	w.WriteHeader(http.StatusOK)
	if _, err := io.Copy(w, bytes.NewBuffer(s.indexHTML)); err != nil {
		writeErr(w, http.StatusNotFound, err)
	}
}

func (s *webappServer) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		w.WriteHeader(http.StatusNoContent)
		return
	}

	upath := r.URL.Path
	if !strings.HasPrefix(upath, "/") {
		upath = "/" + upath
		r.URL.Path = upath
	}

	p := path.Clean(upath)

	if p == "/" {
		s.responseFromIndexHTML(w)
		return
	}

	if _, err := s.fs.Open(p); err == nil {
		if p == "/favicon.ico" {
			expires(w.Header(), 24*time.Hour)
		} else if strings.HasPrefix(p, "/__built__/") {
			if p != "/__built__/config.json" {
				expires(w.Header(), 30*24*time.Hour)
			}
		}
		http.FileServer(s.fs).ServeHTTP(w, r)
		return
	}

	s.responseFromIndexHTML(w)
}

func expires(header http.Header, d time.Duration) {
	header.Set("Cache-Control", fmt.Sprintf("max-age=%d", d/time.Second))
}

func writeErr(w http.ResponseWriter, status int, err error) {
	w.WriteHeader(status)
	_, _ = w.Write([]byte(err.Error()))
}
