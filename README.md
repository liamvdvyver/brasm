# Br.asm

A [bf](https://en.wikipedia.org/wiki/Brainfuck) interpreter written in x86-64 assembly for linux.
Cheeky little afternoon project ~~today~~ over two days, not at all portable, not at all performant.

## Build

Build with `make`.

## Usage

Takes source as command line argument, uses stdin as input stream, for example:

```
./brasm example/hello_world.b
```

VM has 4kB of memory. If I get around to it I'll make this dynamically resizable.
