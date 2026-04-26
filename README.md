# A Buddhabrot computed with co_sum() and saved in a PPM file

For the moment, this repository contains only one example (but you may also be interested by [exploring_coarrays](https://github.com/vmagnin/exploring_coarrays)).

`ppm_coarray_buddhabrot.f90` is a CLI program drawing a [Buddhabrot](https://en.wikipedia.org/wiki/Buddhabrot) in a [portable pixmap binary format (PPM)](https://en.wikipedia.org/wiki/Netpbm#File_formats) file, a very basic uncompressed image file format. Each Fortran _image_ is computing its own Buddhabrot, and they are finally summed using the `co_sum()` _collective subroutine._ The process is therefore very similar to what is done in astrophotography.


## The Buddhabrot

In the Buddhabrot, the intensity of a pixel is proportional to the number of times it was visited by the $z_n$ complex sequence defining the Mandelbrot set, considering only sequences starting from points not in the Mandelbrot set (and therefore diverging $z_n$ sequences).

Instead of partitioning the complex plane in several images, we have chose to simply use a Monte Carlo algorithm: each image is computing a lot of $z_n$ sequences using $c$ random complex values. At the end, all the results are summed using the `co_sum()` collective subroutine.

## Compiling and executing

### GFortran>=16.0

Starting from version 16, GFortran supports natively coarrays using shared memory mulithreading on single node machines:
```bash
$ gfortran -Ofast -fcoarray=lib ppm_coarray_buddhabrot.f90 -lcaf_shmem && ./a.out
```

The `-lcaf_shmem` is necessary until a `-fcoarray=shared` option is added in a later GFortran release.

You can force the number of images (8 for example) with:
```bash
$ export GFORTRAN_NUM_IMAGES=8
```

You can also add the `-march=native -mtune=native` options for further optimization.

### GFortran<16

You needed to install [OpenCoarrays](http://www.opencoarrays.org/) and type that command (8 images here):

```bash
$ caf -Ofast ppm_coarray_buddhabrot.f90 && cafrun -n 8 ./a.out
```

### Intel ifx

```bash
$ ifx -Ofast -coarray ppm_coarray_buddhabrot.f90 && ./a.out
```
The number of images can be set with the option `-coarray-num-images=8`.

### Flang

Flang 22.1 offers an experimental support for coarrays with the option `-fcoarray`.


## TODO

- The loop computing `z(k)` could be stopped by `exit` when we escape the computing window containing the whole Mandelbrot set. But the value of the counter should be memorized.
- We could use the symmetry of the Buddhabrot to improve computing.
- We could add colours instead of grey levels.

## License

Distributed under the MIT license.

## References

* Curcic, Milan. [Modern Fortran - Building efficient parallel applications](https://learning.oreilly.com/library/view/-/9781617295287/?ar), Manning Publications, 1st edition, novembre 2020, ISBN 978-1-61729-528-7.
* Metcalf, Michael, John Ker Reid, Malcolm Cohen and Reinhold Bader. *[Modern Fortran Explained: Incorporating Fortran 2023 (6th edn).](https://academic.oup.com/book/56095)* Numerical Mathematics and Scientific Computation. Oxford (England): Oxford University Press, 2023, ISBN 978-0-19-887657-1.
* Thomas Koenig, [coarray-tutorial](https://github.com/tkoenig1/coarray-tutorial/blob/main/tutorial.md).
* Ondrej CERTIK's code (MIT license) for PPM format: https://github.com/certik/fortran-utils/blob/master/src/ppm.f90
