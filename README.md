# CPS TLS

Async TLS client and server streams for the CPS runtime. This package wraps
OpenSSL/BoringSSL without introducing a second async abstraction: a TLS
connection is still an `AsyncStream`, so buffered I/O, IRC, HTTP, and custom
protocols can use it exactly like a TCP stream.

## Features

- Non-blocking client and server handshakes
- TLS 1.2 minimum with TLS 1.3 support
- SNI and operating-system CA verification
- ALPN negotiation for HTTP/2 and HTTP/1.1
- Server certificate and private-key loading
- Chrome and Firefox TLS/HTTP2 fingerprint profiles
- Reactor-thread handoff when used from the MT runtime
- Optional BoringSSL support for GREASE, extension permutation, ALPS, and
  certificate-compression advertisement

## Requirements

- Nim 2.0 or newer
- [cps-runtime](https://github.com/gabearro/cps-runtime)
- OpenSSL 3 on macOS or the platform OpenSSL libraries on Linux

## Install

```sh
nimble install https://github.com/gabearro/cps-tls@#v1.0.2
```

## TLS client

```nim
import cps
import cps/io
import cps/tls/client

proc fetch(): CpsVoidFuture {.cps.} =
  let tcp = await tcpConnect("example.com", 443)
  let tls = newTlsStream(tcp, "example.com", @["http/1.1"])
  await tls.tlsConnect()

  await tls.AsyncStream.write(
    "GET / HTTP/1.1\r\nHost: example.com\r\nConnection: close\r\n\r\n"
  )

  let response = await tls.AsyncStream.read(4096)
  echo response
  tls.AsyncStream.close()

runCps(fetch())
```

`TlsStream` implements the same read, write, and close operations as every
other CPS stream. `alpnProto` contains the negotiated protocol after the
handshake.

## TLS server

```nim
import cps
import cps/io
import cps/tls/server

proc serveOne(): CpsVoidFuture {.cps.} =
  let listener = tcpListen("127.0.0.1", 8443)
  let tlsContext = newTlsServerContext(
    "cert.pem",
    "key.pem",
    @["http/1.1"]
  )

  let tcp = await listener.accept()
  let tls = await tlsContext.tlsAccept(tcp)
  await tls.AsyncStream.write("hello over TLS\n")
  tls.AsyncStream.close()

  listener.close()
  tlsContext.closeTlsServerContext()

runCps(serveOne())
```

## Browser fingerprint profiles

```nim
import cps
import cps/io
import cps/tls/client
import cps/tls/fingerprint

proc connectLikeChrome(): CpsVoidFuture {.cps.} =
  let tcp = await tcpConnect("example.com", 443)
  let profile = chromeProfile() # firefoxProfile() is also available
  let tls = newTlsStream(tcp, "example.com", fp = profile.tls)
  await tls.tlsConnect()
  tls.AsyncStream.close()

runCps(connectLikeChrome())
```

OpenSSL applies the portable parts of a profile. Build with BoringSSL when the
GREASE, extension-order, and ALPS details need to match the profile as closely
as possible.

## BoringSSL build

```sh
bash scripts/build_boringssl.sh
nim c -r -d:useBoringSSL your_program.nim
```

The script builds into `deps/boringssl/`. That directory is intentionally not
committed.

## Development

Read the [TLS developer guide](docs/development.md) before changing public
APIs, ownership, protocol state, or execution behavior.

```sh
nimble install -d -y
nimble checkDocs
nimble docs
nimble test
nimble testMms
```

The library supports ARC, ORC, and AtomicARC. `nimble testMms` runs the
same supported surface under all three memory managers.

`nimble docs` writes the generated API reference to
[`docs/api/theindex.html`](docs/api/theindex.html).

The default test suite validates the fingerprint model without requiring a
network connection. Client/server integration is exercised by the downstream
HTTP and IRC packages.

## License

MIT
