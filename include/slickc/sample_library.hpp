#ifndef SAMPLE_LIBRARY_HPP
#define SAMPLE_LIBRARY_HPP

#include <slickc/sample_library_export.hpp>

// The parameter name in the declaration must match the definition;
// cppcheck's funcArgNamesDifferent check fails the build otherwise
[[nodiscard]] SAMPLE_LIBRARY_EXPORT int factorial(int input) noexcept;

[[nodiscard]] constexpr int factorial_constexpr(int input) noexcept
{
  if (input == 0) { return 1; }

  return input * factorial_constexpr(input - 1);
}

#endif
