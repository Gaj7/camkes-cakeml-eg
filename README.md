CakeML CAmkES components, working once again!

To build:
```sh
mkdir camkes-cakeml-eg
cd camkes-cakeml-eg
repo init -u https://github.com/gaj7/camkes-cakeml-eg-manifest.git
repo sync
mkdir build
cd build
../griddle --CAMKES_APP=camkes-cakeml-eg --SIMULATION=ON
ninja
```

In addition to the regular sel4/camkes build requirements, this assumes you have the 64-bit architecture targeting CakeML compiler in you path under the name "cake64".

This will build a simulation x86_64 image. Run it with `./simulate`.

Alternatively, you can build an image for the odroid:
```sh
../griddle --CAMKES_APP=camkes-cakeml-eg --PLATFORM=exynos5422 --SIMULATION=OFF
ninja
```

This requires the 32-bit targetting CakeML compiler, named "cake32", on the system path.
