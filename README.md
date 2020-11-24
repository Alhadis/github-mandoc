GitHub Mandoc
=============

[![CI Status](https://github.com/Alhadis/github-mandoc/workflows/Run%20tests/badge.svg)](https://github.com/Alhadis/github-mandoc/actions)

Filter to optimise [`mandoc(1)`][1]'s HTML output for display on GitHub.
Its output is heavily tailored to the site's aggressive sanitisation rules,
which permit [only a subset of HTML][2].

This gem will (eventually) form part of a proposed addition to bring rendered man pages to GitHub.
See [`github/markup#1196`][3] for a slightly-more detailed explanation.

<!-- Referenced links -->
[1]: https://man.openbsd.org/mandoc
[2]: https://github.com/jch/html-pipeline/blob/5d76e286fffbbd14d65fbba152c0c3caab0a55f6/lib/html/pipeline/sanitization_filter.rb#L40-L88
[3]: https://github.com/github/markup/pull/1196#issuecomment-732911618
