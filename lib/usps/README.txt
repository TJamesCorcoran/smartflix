Installation
------------

1) from your project's db/migrate directory, ln to
       vendor/plugins/usps/db/migrate/FOO
   for each foo

2) run migrations


Use
---

top level calls:

  sf_packages = ... # magic!
  tempfile = UspsPermitImprint.generate_all_ps3600ez(sf_packages)
  system("lp #{tempfile}")

or

  heavyink_packages = ... # magic!
  tempfiles = UspsPermitImprint.generate_many_ps3605r_heavyink(heavyink_packages)
  system("lp #{tempfiles.join(' ')}")

There are lower level calls to generate just a single copy of a form,
or individual pages of a form.

Extending
---------

build_convert_str() is pretty nice - you feed it an array of data, and
an array of positions, and it will create a string that ImageMagick
can use to modify the template in place.

You need to supply X,Y coordinates.  These coordinates offset from the
top-left corner (thanks to the "-gravity NorthEast" flag).

If you open the empty PDF with gimp and import at a resolution of 72
pixels/inch, you can hover over the upper left hand corner of a target
and read the X,Y off the bottom of the Gimp edit screen.

If you get a postal form that is multiple pages, you'll want to
install pdftk, and then break the pdf apart like this:

		pdftk <filename>.pdf  burst


Bugs
----

* XXX has a seperate usps_utils plugin.  These should be merged.
