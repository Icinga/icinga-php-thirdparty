# Third-Party Licenses

This package bundles third-party components used by Icinga Web.
Each bundled component remains available under its upstream license.

This file highlights bundled components and shipped assets under licenses other
than MIT.

## License Summary

| License           | Component                                                     | License Files / Notes                                                                                                     |
|-------------------|---------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------|
| Apache-2.0        | [wikimedia/less.php](https://github.com/wikimedia/less.php)   | [`vendor/wikimedia/less.php/LICENSE`](vendor/wikimedia/less.php/LICENSE)                                                  |
| Apache-2.0        | [zircote/swagger-php](https://github.com/zircote/swagger-php) | [`vendor/zircote/swagger-php/LICENSE`](vendor/zircote/swagger-php/LICENSE)                                                |
| BSD-3-Clause      | [icinga/zf1](https://github.com/Icinga/zf1)                   | [`vendor/icinga/zf1/LICENSE.txt`](vendor/icinga/zf1/LICENSE.txt)                                                          |
| BSD-3-Clause      | [jfcherng/php-diff](https://github.com/jfcherng/php-diff)     | [`vendor/jfcherng/php-diff/LICENSE`](vendor/jfcherng/php-diff/LICENSE)                                                    |
| BSD-3-Clause      | [tedivm/jshrink](https://github.com/tedious/JShrink)          | [`vendor/tedivm/jshrink/LICENSE`](vendor/tedivm/jshrink/LICENSE)                                                          |
| ISC               | [d3.js](https://d3js.org/)                                    | [`asset/js/mbostock/LICENSE`](asset/js/mbostock/LICENSE); shipped as [`asset/js/mbostock/d3.js`](asset/js/mbostock/d3.js) |
| LGPL-2.1          | [dompdf/dompdf](https://github.com/dompdf/dompdf)             | [`vendor/dompdf/dompdf/LICENSE.LGPL`](vendor/dompdf/dompdf/LICENSE.LGPL)                                                  |
| LGPL-2.1-or-later | [ezyang/htmlpurifier](https://github.com/ezyang/htmlpurifier) | [`vendor/ezyang/htmlpurifier/LICENSE`](vendor/ezyang/htmlpurifier/LICENSE)                                                |
| LGPL-3.0-or-later | [dompdf/php-svg-lib](https://github.com/dompdf/php-svg-lib)   | [`vendor/dompdf/php-svg-lib/LICENSE`](vendor/dompdf/php-svg-lib/LICENSE); bundled through the `dompdf/dompdf` dependency  |

## Notes

- This file lists top-level bundled components and additional shipped assets.
- Components under MIT are not listed individually here.
- Indirect dependencies are not listed one by one, but licenses they add to the
  shipped source tree are still reflected here when relevant. For example,
  `dompdf/dompdf` brings in a bundled `LGPL-3.0-or-later` dependency, so that
  license is included above.
