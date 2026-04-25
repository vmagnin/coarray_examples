# A Buddhabrot computed with co_sum() and saved in a PPM file

For the moment, this repository contains only one example (but you may also be interested by [exploring_coarrays](https://github.com/vmagnin/exploring_coarrays)).

`ppm_coarray_buddhabrot.f90` is a CLI program drawing a [Buddhabrot](https://en.wikipedia.org/wiki/Buddhabrot) in a [portable pixmap binary format (PPM)](https://en.wikipedia.org/wiki/Netpbm#File_formats) file, a very basic uncompressed image file format. Each Fortran _image_ is computing its own Buddhabrot, and they are finally summed using the `co_sum()` _collective subroutine._ The process is therefore very similar to what is done in astrophotography.


## Compiling and executing

### GFortran>=16.0

Starting from version 16, GFortran supports natively coarrays using shared memory mulithreading on single node machines:
```bash
$ gfortran -Ofast -march=native -mtune=native -fcoarray=lib ppm_coarray_buddhabrot.f90 -lcaf_shmem && ./a.out
```

You can force the number of images (8 for example) with:
```bash
$ export GFORTRAN_NUM_IMAGES=8
```

The `-lcaf_shmem` is necessary until a `-fcoarray=shared` option is added in a later GFortran release.

### GFortran<16

You needed to install [OpenCoarrays](http://www.opencoarrays.org/) and type that command (8 images here):

```bash
$ caf -Ofast -march=native -mtune=native ppm_coarray_buddhabrot.f90 && cafrun -n 8 ./a.out
```

### Intel ifx

```bash
$ ifx -Ofast -coarray ppm_coarray_buddhabrot.f90 && ./a.out
```
The number of images can be set with the option `-coarray-num-images=8`.

### Flang

Flang 22.1 offers an experimental support for coarrays with the option `-fcoarray`.


## TODO

- The loop computing `z(k)` could be stopped by `exit` when we escape the computing window containing the whole Mandelbrot set.
- We could use the symmetry of the Buddhabrot to improve computing.
- We could add colours instead of grey levels.

## License

Distributed under the MIT license.

## References

* Curcic, Milan. [Modern Fortran - Building efficient parallel applications](https://learning.oreilly.com/library/view/-/9781617295287/?ar), Manning Publications, 1st edition, novembre 2020, ISBN 978-1-61729-528-7.
* Metcalf, Michael, John Ker Reid, et Malcolm Cohen. *[Modern Fortran Explained: Incorporating Fortran 2018.](https://oxford.universitypressscholarship.com/view/10.1093/oso/9780198811893.001.0001/oso-9780198811893)* Numerical Mathematics and Scientific Computation. Oxford (England): Oxford University Press, 2018, ISBN 978-0-19-185002-8.
* Thomas Koenig, [coarray-tutorial](https://github.com/tkoenig1/coarray-tutorial/blob/main/tutorial.md).
* Ondrej CERTIK's code (MIT license) for PPM format: https://github.com/certik/fortran-utils/blob/master/src/ppm.f90
