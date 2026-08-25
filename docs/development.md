# TLS developer guide

This package adapts TLS to `AsyncStream`. It does not own an event loop and it
does not introduce a separate scheduler. Reads, writes, handshake progress,
and shutdown all use the CPS runtime supplied by the underlying stream.

## Source layout

| Path | Responsibility |
| --- | --- |
| `cps/tls/client` | Client context, hostname verification, ALPN, async stream |
| `cps/tls/server` | Server context, certificates, ALPN selection, accepted streams |
| `cps/tls/fingerprint` | Browser-oriented TLS and HTTP/2 profile data |
| `cps/tls/boringssl` | Native BoringSSL declarations used by fingerprinting |
| `cps/tls/boringssl_compat` | Stable wrappers around BoringSSL-only operations |

## Data flow

OpenSSL or BoringSSL consumes encrypted bytes from the underlying stream and
produces plaintext for callers. A write moves in the opposite direction. When
the TLS engine reports `WANT_READ` or `WANT_WRITE`, the operation yields through
the stream rather than spinning.

The portable build uses OpenSSL. BoringSSL enables QUIC hooks, GREASE, extension
ordering, ALPS, and the remaining fingerprint controls. Keep conditional code
at the native boundary so the stream API behaves the same in both builds.

## Invariants

- The TLS stream owns its native `SSL` object; the context owns `SSL_CTX`.
- Closing a stream releases the native object once and then closes according to
  the caller-selected underlying-stream policy.
- Certificate and hostname verification stay enabled unless the caller opts out
  explicitly.
- Native buffers remain valid for the duration required by the TLS call.
- TLS errors retain the native error detail needed to diagnose the failure.

## Extending the package

Keep raw native declarations narrow. Put portability logic in a wrapper and
document whether a method is OpenSSL-compatible, BoringSSL-only, or a no-op on
the portable path. A new fingerprint setting must describe what can actually be
reproduced by each backend.

Every exported callable needs a `##` comment. For native bindings, name the
library operation and why the package exposes it. For stream operations,
document ownership, handshake state, and error behavior.

## Validation

```sh
nimble checkDocs
nimble test
```

Run downstream HTTP/2, HTTP/3, and IRC integration tests after changing ALPN,
verification, shutdown, or native-library selection.
