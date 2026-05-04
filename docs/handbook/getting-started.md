# Getting Started

This page explains how to set up, install, run, and verify the `telnet-sentinel` project.

## Prerequisites

- **Dart SDK**: ^3.11.5 (as specified in `pubspec.yaml`)

## Installation

Download dependencies:

```bash
dart pub get
```

## Running the Application

Run the CLI tool using `dart run`:

```bash
dart run bin/telnet_sentinel.dart [arguments]
```

## Development Commands

### Static Analysis

Check for linting issues and common errors:

```bash
dart analyze
```

### Formatting

Ensure code follows the standard style:

```bash
dart format .
```

### Testing

Run the test suite:

```bash
dart test
```

## Building

Compile to a native executable:

```bash
dart compile exe bin/telnet_sentinel.dart -o telnet_sentinel
```
