# Br.asm

A [bf](https://en.wikipedia.org/wiki/Brainfuck) interpreter written in x86-64 assembly for linux.
Cheeky little afternoon project today, not at all portable, not at all performant.

## Build

Build with `make`.

## Usage

Pipe your program to stdin, specify vm memory in kB as a commandline argument (default: 40, currently not implemented):

```
cat src/hello_world.b | brasm 64
```

Currently doesn't support input (`,`), since we use the stdin stream for inputting the program.

If I feel like it/have time, I'll add those missing features tomorrow.
