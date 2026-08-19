# M2 Fred hero story and touch-first instructions

Updated: 2026-08-18

## Purpose

Fred no longer enters a level without context. Choosing **Begin Fred's Story**
opens two short, required, touch-friendly screens before Level 1. The first
explains Fred's purpose; the second teaches the complete App Build 1 control
and survival loop without referring to a keyboard.

## The Moonpetal Promise

Every little frog dreams of a safe, glowing marsh where the Moonpetal shines.
Wild currents, hungry predators and scattered bugs have broken the lily paths.
Fred promises to cross all 100 levels, protect the smaller frogs and carry hope
home. His hero loop is expressed in child-friendly language:

> Gather bugs. Outsmart danger. Bring courage home.

The story's central promise is to become **the frog hero in every little frog's
dreams**. This gives the leap, dive, munch, boost, survival and progression
mechanics one coherent reason without changing deterministic gameplay or save
data.

## How to Be a Marsh Hero

The instruction screen teaches six touch-first concepts:

- touch and drag through the marsh to steer Fred;
- Munch when a bug is close enough for Fred's tongue;
- Leap between lily pads and over danger;
- Boost for a short burst while watching energy;
- Dive and Surface to travel through both water layers;
- avoid predators and whirlpools, beginning each fresh adventure with three
  lives while every tenth level can add a fairy life.

The mission summary connects those actions to the current level loop: munch
three bugs, reach the Moonpetal, earn coins and customize Fred. Buttons meet the
existing large touch-target contract and remain separated from one another.

## Deterministic and save boundary

Story and instruction screens are explicit non-gameplay presentation states.
Opening or leaving them cannot begin the countdown, advance a fixed tick,
consume a life, award coins, write a checkpoint or change cosmetics. No story
or instruction state is persisted in `fred_save` v1. Starting play still uses
the existing five-second level countdown and three-life fresh-run contract.

## Evidence

The focused Godot suite injects real `InputEventScreenTouch` contacts through
title, story, instructions and Level 1. It also checks child-sized safe-area
buttons, exact story/instruction content, Home behavior, no keyboard wording,
no stale contacts and no gameplay/save mutation. Full matrix, visible desktop
review, Android revision identity and exact owner handoff are recorded in
`APP_BUILD_1_TEST_REPORT.md` after execution.

This local evidence does not claim physical Android/iPad acceptance, Apple
Game Center activation, signing, TestFlight, store submission or release.
