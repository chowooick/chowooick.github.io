---
layout: post
title: "The constraint I wrote to protect the schedule became the quality ceiling"
date: 2026-09-06 22:00:00 +0900
categories: [agents, art]
---

I needed three comic panels for the game's store page. Solo developer, no artist,
nineteen weeks to launch. So I wrote the ticket defensively:

> Godot built-in primitives (`BoxMesh`, `SphereMesh`, `CapsuleMesh`,
> `CylinderMesh`, `PlaneMesh`, `TorusMesh`) plus `StandardMaterial3D` flat colours
> only. **No external 3D assets, model files or textures.**

The reasoning was sound. The real risk in 3D for a one-person team is not
rendering — it is the hours that disappear into modelling. Primitives cannot
consume a week.

The agent did exactly what I asked. The jokes landed: a settler falling in 0.38g
with "EST. IMPACT 00:06.4" above him and "RESPONDER ETA 4 MIN" off to the side; a
briefing diagram whose arrows form a circular reference on slide 4 of 61; a launch
banner where the year has been patched over twice with tape.

The verdict from the person who has to ship it: *"Looks like an amateur drew it in
MS Paint. Redo it at top-1% professional quality."*

He was right.

## What I had actually forbidden

Looking at the render with that sentence in mind, the diagnosis was not subtle.
Capsule-plus-sphere reads as capsule-plus-sphere. Three lights and no post
gives you flat shading and hard black shadows. One flat colour per object means
nothing in the frame tells you what anything is made of.

**Quality in a 3D still does not come from geometry.** It comes from lighting,
materials, post-processing, and composition. I had banned all four and left the
one that matters least.

The agent could not have done better inside that ticket. It was not an execution
failure. It was a specification failure, and I wrote the specification.

## The rewrite

I split the ban into two halves that I had wrongly glued together:

- **Shape**: anything generated in code. Primitives, CSG, `ArrayMesh`,
  `SurfaceTool`. Bevels, panel lines, asymmetric silhouettes.
- **Files**: still no imported models, textures or fonts — licensing and
  consistency, and this is the half that actually protects the schedule.
- **Lighting, materials, post-processing**: no limits at all. Key/fill/rim,
  soft shadows, roughness variation, fresnel, ACES tonemapping, bloom, SSAO,
  atmospheric fog.

Generated geometry costs no licence, stays consistent, and ports into the game
unchanged. Imported assets were never the thing making the picture good.

## The second half of the fix

The first ticket rendered once and stopped. That was the other ceiling.

The rewrite requires a **self-evaluation loop, minimum four passes**: render, open
the PNG with the read tool, score it against an explicit checklist, fix, render
again. Log the score each round.

The checklist is written to be answerable by looking:

- Are the shadows soft? Hard shadows are an amateur signal.
- Is the inside of a shadow black, or tinted with sky colour?
- Does roughness differ between objects, so metal and dusty plastic read apart?
- Do the primitives still read as primitives?
- Is the subject stuck dead centre?
- Is there foreground, midground, background?

An agent that can look at its own output can iterate on it. Mine had never been
asked to look.

## The general shape of the mistake

Every constraint I write to protect one axis silently caps another. "Primitives
only" protected the schedule and capped the art. "No autoloads" protected a spike
from over-engineering and later forced re-authentication on every scene change.
"No local Go toolchain" protected build reproducibility and made unit tests that
need a database impossible.

None of those were wrong when written. They became wrong when the situation moved
and the sentence stayed.

So the rule is not "write fewer constraints". It is: when output is mediocre in a
specific way, **read your own constraints before blaming the execution.** The
ceiling is usually something you built.
