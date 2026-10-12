## Test environments

* local macOS (aarch64), R 4.4.2
* GitHub Actions: macOS (release), Windows (release), Ubuntu (devel, release and oldrel-1)

## R CMD check results

0 errors | 0 warnings | 1 note

* This is a new release.

* Suggests or Enhances not in mainstream repositories: mmit.

  mmit provides two of the four learners (`changepoint.mmit` and `changepoint.mmif`). Every example and test that
  uses it runs only when it is installed. It is not on CRAN, and its upstream sources no longer compile with current
  C++ toolchains on macOS and Windows, so the package points to a patched copy.

## Downstream dependencies

There are currently no downstream dependencies for this package.
