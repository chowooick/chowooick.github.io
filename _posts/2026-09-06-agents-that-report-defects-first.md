---
layout: post
title: "Make the agent criticise the ticket before it writes any code"
date: 2026-09-06 21:00:00 +0900
categories: [agents, process]
---

I run AI coding agents one ticket each, in parallel, against a single repository.
Yesterday I added one line to the rules they all read:

> After reading the ticket, before touching any code, report up to three defects
> in the ticket (or "none"). Report and then start immediately. Do not wait for an
> answer.

Twelve tickets later, the agents had reported **twelve defects. Ten of them were
mine.** Not bugs in their code — holes in the specification I had written.

## What they caught

**A branch that does not exist.** I had written "use the Godot 4 branch of
nakama-godot" into the stack rules. There is no such branch. The agent would have
spent its budget looking for it.

**A version rule that cannot hold.** I wrote "`nakama-common` must be the same
minor as server 3.40". `nakama-common` is a `v1.x` line. The rule is not satisfiable.
The agent read the server's own `go.mod` and used `v1.47.0`.

**Two completion criteria that contradict each other.** One smoke test asserted
`^\[create\] error name_too_long$` with both anchors. A later ticket asked the same
line to be `[create] error code=3 message=name_too_long`. One line cannot be both.
The agent printed two lines and kept the old test unmodified — which is the right
call, because "the refactor did not break the previous ticket" is only provable if
the previous test is untouched.

**A prohibition that blocked the feature.** I banned autoloads in the client
tickets, carried over from a spike where it made sense. Three scenes later that
meant re-authenticating on every scene change. The agent flagged it, worked around
it for that ticket, and I lifted the ban in the next one.

**A completion criterion that is not implementable.** "Assert the presence event
carries the character name." Nakama strips the status field from the wire for
custom streams. The agent found the exact lines in the server source, measured it
against a live socket, and proposed three alternatives ranked by cost.

**A test-stack port hardcoded to one value**, which meant exactly one ticket could
run integration tests at a time. Two agents lost the port to each other and
reported it from both sides, with `docker ps` output naming the other's container.

## Why this works better than reviewing the ticket myself

I wrote those tickets. I had already read them. Reading them again would not have
surfaced any of this, because the defects were in my own assumptions.

The agent executing the ticket is the one with the incentive: a bad ticket costs
it three failed attempts and a stop. And it reads the ticket cold, with no memory
of why I wrote each line — which is exactly the perspective I cannot have.

I had originally solved this differently: a separate reviewer agent whose job was
to check tickets before issue. It did not work, for a structural reason. The
reviewer received *my* brief describing what to check. Anything I had missed was
missing from the brief too, so the reviewer missed it as well. It was not an
independent check; it was my blind spot with extra steps.

## The part that makes it cheap

**Report and continue. Do not wait.**

If the agent blocks on an answer, every defect becomes a round trip through me,
and the whole thing collapses back into the bottleneck I was trying to remove.
Reporting into the void and proceeding on its own best interpretation is worth far
more than a correct answer that arrives ten minutes later, because I can read the
report while it works and correct it mid-flight if it went the wrong way.

In twelve tickets I overrode the agent's own handling exactly twice.

## The rule I would keep if I could keep only one

Not "write tests first". Not "small tickets". This:

> Before you build the thing, tell me what is wrong with the request.

The agents were better at spotting my errors than I was at not making them.
