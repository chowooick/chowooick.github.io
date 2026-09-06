---
layout: post
title: "Twelve things about Nakama and Godot that no document tells you"
date: 2026-09-06 20:00:00 +0900
categories: [nakama, godot]
---

I spent a day wiring Godot 4.7.2 to a self-hosted Nakama 3.40 server. Every item
below cost real time to find and takes one paragraph to explain. All of them were
measured against a running server, not read somewhere.

## 1. The `godot-4` branch of nakama-godot does not exist

`AGENTS.md` in my repo said "use the Godot 4 branch". There is no such branch.
`git ls-remote --heads https://github.com/heroiclabs/nakama-godot.git` returns
exactly three: `godot-3`, `master`, `small-performance-improvement`. Godot 4
support lives on `master`.

## 2. The release tag is two years older than the code

The latest tag, `v3.4.0`, is from 2024-03-19. `master` HEAD
(`7549fea8cb4d62a319028946de01a2993440c2d6`) is from 2026-08-11. If you pin the
tag because tags feel safer, you get a two-year-old SDK and conclude the project
is abandoned. Pin the commit.

On Godot 4.7.2 that commit runs with **zero patch lines**. Auth, RPC, socket,
stream presence — all of it, unmodified.

## 3. A Go plugin with the wrong version fails silently

This is the worst one. If your plugin's Go version or `nakama-common` version
does not match the server image, Nakama does not error. It logs
`Go runtime modules loaded` and registers **zero** RPCs. Every call then 404s and
you go hunting in your own code.

The tell is the RPC count in the startup log line. The fix is to build inside
`heroiclabs/nakama-pluginbuilder:<exact server tag>` and never with a local
toolchain.

Also: `nakama-common` is not versioned in lockstep with the server. Nakama
v3.40.0 pins `nakama-common v1.47.0`. "Same minor as the server" is not a rule
that exists.

## 4. The pluginbuilder image's entrypoint is `go`, not a shell

So `docker run … pluginbuilder sh -ec '…'` arrives as `go sh -ec '…'` and dies.
Pass `--entrypoint sh`.

## 5. Stream subjects must be UUIDs; use the label instead

`StreamUserJoin(mode, subject, subcontext, label, …)` parses `subject` and
`subcontext` with `uuid.FromString`. A channel id like `"colony-01"` is rejected.
Put the channel id in the **label**. The stream key is
`mode + subject + subcontext + label` taken together, so a label-keyed stream is
just as isolated.

## 6. Presence `status` never reaches the client

You can write a status when you join a stream, and the server can read it back
with `StreamUserList`. It will not appear on the wire. In Nakama v3.40.0,
`server/tracker.go:928` (joins) and `:971` (leaves) build the outgoing presence as

```go
pWire := &rtapi.UserPresence{UserId, SessionId, Username, Persistence}
if p.Stream.Mode == StreamModeStatus {
    pWire.Status = …
}
```

with the comment *"Status field is only populated for status stream presences."*
Measured: a join event on a custom mode arrives with no `status` key at all,
while the built-in `status_presence_event` on the same socket carries one.

If you want a display name on a presence event, the only wire fields you get are
`user_id`, `session_id`, `username`, `persistence`. Resolve the name from
`user_id` through the users API instead.

## 7. A socket that joins a stream learns nothing about who is already there

It receives its own join event and that is all. The player who arrived first sees
the second one arrive; the second one never hears about the first. If you want a
roster, the join RPC has to return it. Nothing pushes it to you.

## 8. Error codes collapse over the socket

Over HTTP you get the gRPC code you raised — `3`, `8`, `9`, `16`. Over a
WebSocket rpc envelope, Nakama rewrites every runtime error to
`7 RUNTIME_FUNCTION_EXCEPTION`. Only the message survives.

So the client must branch on the **message identifier**, not the code. Use
snake_case identifiers (`channel_full`, `insufficient_stock`) and treat them as
part of your contract.

## 9. HTTP RPCs have no session id

`RUNTIME_CTX_SESSION_ID` is only populated for calls that arrive over a socket.
This is actually useful: it is a structural way to require a live socket for a
mutating RPC. It also means "connect a socket, then call over HTTP" cannot tell
the server *which* socket you meant.

## 10. `RegisterEventSessionEnd` runs after presence cleanup

Nakama removes a dead session's stream presences before your hook fires. There is
nothing for the hook to clean up. A test that kills a socket and expects the count
to drop within two seconds passes with an empty hook body. Do not add presence
deletion there.

## 11. The default session token lives 60 seconds

Fine for a smoke test, invisible in development, and exactly long enough to break
a 60-second countdown screen: the token expires the moment the user submits. Raise
`session.token_expiry_sec`, or refresh when the remaining lifetime drops below a
margin you keep in config.

## 12. `string_to_array('', ',')::uuid[]` is a Postgres error

Not an empty array — an error. If you build an `ANY(...)` filter from a comma-joined
id list (which you will, because the plugin has no array driver), short-circuit on
the empty set before the query.

---

## Two Godot ones while I am here

**`user://` is derived from the project name.** Every instance on one machine
shares it, so every instance authenticates as the same device — the same account.
To run two clients as two players locally, give each a different `HOME`.

**Headless does not render 3D.** `--headless` uses the dummy driver. If you need a
render from a script, run windowed and draw into a fixed-size `SubViewport` — the
main viewport texture follows the actual window framebuffer, which on a Retina
display is not the resolution you asked for.

And a small one: Godot 4.4+ writes a `.gd.uid` companion file next to every
script. They are generated, they are not noise, and they belong in your commits.
