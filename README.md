# Peblo AI Story Buddy

A Flutter-based interactive storytelling experience built for Peblo's AI Story Buddy & Quiz Component Challenge.

The application combines text-to-speech narration, a data-driven quiz engine, adaptive feedback, and playful animations to create an engaging educational experience for children.

## Features

- AI Buddy guided storytelling
- Flutter TTS narration
- Dynamic quiz rendering from JSON
- Smooth quiz reveal animations
- Wrong answer shake + haptic feedback
- Confetti success celebration
- Adaptive hint system
- Riverpod state management
- Lightweight architecture optimized for mid-range Android devices
- Error recovery and retry flows
- Local progress persistence

## Tech Stack

- Flutter
- Riverpod
- Flutter TTS
- Shared Preferences
- Confetti Package

## Architecture

Presentation Layer
→ Riverpod State Layer
→ Service Layer (TTS + Storage)
→ Data Models

The application follows a reactive state-driven architecture with clear separation of concerns and optimized rebuild patterns.
