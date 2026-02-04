# based on init.janet from pyrmont's markable
(import ./spork/build-rules :as br)
(import ./spork/cc :as cc)
(import ./spork/declare-cc :as declare)

(def- seps {:windows `\` :mingw `\` :cygwin `\`})
(def- osw (os/which))
(def- s (get seps osw "/"))

(def- windows? (index-of osw [:cygwin :windows]))

(defn build
  [manifest &]
  (def configs (get-in manifest [:info :natives]))
  (def rules @{})
  (with-dyns [cc/*rules* rules
              declare/*build-root* "_build"]
    (declare/declare-project :name "fake project")
    (os/mkdir "_build")
    (os/mkdir "_build/release")
    (os/mkdir "_build/release/static")
    (each config configs
      (declare/declare-native
        :name (get config :name)
        :source (get config :files)
        :cflags (get config :cflags)))
    (br/build-run rules "build")))

(defn install
  [manifest &]
  # native modules
  (def natives (get-in manifest [:info :natives]))
  (each nat natives
    (def prefix (get nat :prefix))
    (if prefix (bundle/add-directory manifest prefix))
    (each ext [".a" ".meta.janet" ".so"]
      (def ext1 (if (and windows? (= ".so" ext))
                  ".dll"
                  ext))
      (def filename (string (get nat :name) ext1))
      (def src (string "_build" s "release" s filename))
      (def dest (string (if prefix (string prefix s)) filename))
      (bundle/add-file manifest src dest))))

