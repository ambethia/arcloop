# Arcloop

Experiments with the GPU-accelerated rendering of animated vector art, with the intention of making games. Hand-drawn animations with many unique keyframes consume large amounts of texture memory when used as traditional sprite sheets. Also, tessellating vector shapes at runtime into triangle meshes is too slow for this purpose. I'm interested in creating a rendering engine that uploads bezier curve control and anchor points directly to the graphics hardware and using GPU shaders to draw smooth curves. Low-memory requirements and resolution independence should be another benefit of this technique. It remains to be seen how practical the performance can be once we start pushing lots of animations and vector data.

## SWFLUX

A tool written in [Haxe](http://haxe.org) to extract shape data and animation frames from a SWF file into a custom format optimized (eventually) for the rendering engine. The goal is to use software like [Animate CC](https://www.adobe.com/products/animate.html) (Flash) or [Toon Boom Harmony](https://www.toonboom.com/products/harmony) as authoring tools for vector-based game art.

The tool currently exports JSON, but I will eventually use a binary format, possibly [MessagePack](http://msgpack.org).

## WebGL Prototype

Proof of concept WebGL-based vector renderer. Eventually I will re-write the engine in C (or another compiled language) with OpenGL and SDL, but for now JavaScript provides faster iteration on ideas.

---

(c) 2016 Jason L Perry
