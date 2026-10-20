include(cmake/LibFuzzer.cmake)
include(CMakeDependentOption)
include(CheckCXXCompilerFlag)


include(CheckCXXSourceCompiles)


macro(slickc_supports_sanitizers)
  # Emscripten doesn't support sanitizers
  if(EMSCRIPTEN)
    set(SUPPORTS_UBSAN OFF)
    set(SUPPORTS_ASAN OFF)
  elseif((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND NOT WIN32)

    message(STATUS "Sanity checking UndefinedBehaviorSanitizer, it should be supported on this platform")
    set(TEST_PROGRAM "int main() { return 0; }")

    # Check if UndefinedBehaviorSanitizer works at link time
    set(CMAKE_REQUIRED_FLAGS "-fsanitize=undefined")
    set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=undefined")
    check_cxx_source_compiles("${TEST_PROGRAM}" HAS_UBSAN_LINK_SUPPORT)

    if(HAS_UBSAN_LINK_SUPPORT)
      message(STATUS "UndefinedBehaviorSanitizer is supported at both compile and link time.")
      set(SUPPORTS_UBSAN ON)
    else()
      message(WARNING "UndefinedBehaviorSanitizer is NOT supported at link time.")
      set(SUPPORTS_UBSAN OFF)
    endif()
  else()
    set(SUPPORTS_UBSAN OFF)
  endif()

  if((CMAKE_CXX_COMPILER_ID MATCHES ".*Clang.*" OR CMAKE_CXX_COMPILER_ID MATCHES ".*GNU.*") AND WIN32)
    set(SUPPORTS_ASAN OFF)
  else()
    if (NOT WIN32)
      message(STATUS "Sanity checking AddressSanitizer, it should be supported on this platform")
      set(TEST_PROGRAM "int main() { return 0; }")

      # Check if AddressSanitizer works at link time
      set(CMAKE_REQUIRED_FLAGS "-fsanitize=address")
      set(CMAKE_REQUIRED_LINK_OPTIONS "-fsanitize=address")
      check_cxx_source_compiles("${TEST_PROGRAM}" HAS_ASAN_LINK_SUPPORT)

      if(HAS_ASAN_LINK_SUPPORT)
        message(STATUS "AddressSanitizer is supported at both compile and link time.")
        set(SUPPORTS_ASAN ON)
      else()
        message(WARNING "AddressSanitizer is NOT supported at link time.")
        set(SUPPORTS_ASAN OFF)
      endif()
    else()
      set(SUPPORTS_ASAN ON)
    endif()
  endif()
endmacro()

macro(slickc_setup_options)
  option(slickc_ENABLE_HARDENING "Enable hardening" ON)
  option(slickc_ENABLE_COVERAGE "Enable coverage reporting" OFF)
  cmake_dependent_option(
    slickc_ENABLE_GLOBAL_HARDENING
    "Attempt to push hardening options to built dependencies"
    ON
    slickc_ENABLE_HARDENING
    OFF)

  slickc_supports_sanitizers()

  if(NOT PROJECT_IS_TOP_LEVEL OR slickc_PACKAGING_MAINTAINER_MODE)
    option(slickc_ENABLE_IPO "Enable IPO/LTO" OFF)
    option(slickc_WARNINGS_AS_ERRORS "Treat Warnings As Errors" OFF)
    option(slickc_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" OFF)
    option(slickc_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(slickc_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" OFF)
    option(slickc_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(slickc_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(slickc_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(slickc_ENABLE_CLANG_TIDY "Enable clang-tidy" OFF)
    option(slickc_ENABLE_CPPCHECK "Enable cpp-check analysis" OFF)
    option(slickc_ENABLE_PCH "Enable precompiled headers" OFF)
    option(slickc_ENABLE_CACHE "Enable ccache" OFF)
  else()
    option(slickc_ENABLE_IPO "Enable IPO/LTO" ON)
    option(slickc_WARNINGS_AS_ERRORS "Treat Warnings As Errors" ON)
    option(slickc_ENABLE_SANITIZER_ADDRESS "Enable address sanitizer" ${SUPPORTS_ASAN})
    option(slickc_ENABLE_SANITIZER_LEAK "Enable leak sanitizer" OFF)
    option(slickc_ENABLE_SANITIZER_UNDEFINED "Enable undefined sanitizer" ${SUPPORTS_UBSAN})
    option(slickc_ENABLE_SANITIZER_THREAD "Enable thread sanitizer" OFF)
    option(slickc_ENABLE_SANITIZER_MEMORY "Enable memory sanitizer" OFF)
    option(slickc_ENABLE_UNITY_BUILD "Enable unity builds" OFF)
    option(slickc_ENABLE_CLANG_TIDY "Enable clang-tidy" ON)
    option(slickc_ENABLE_CPPCHECK "Enable cpp-check analysis" ON)
    option(slickc_ENABLE_PCH "Enable precompiled headers" OFF)
    option(slickc_ENABLE_CACHE "Enable ccache" ON)
  endif()

  if(NOT PROJECT_IS_TOP_LEVEL)
    mark_as_advanced(
      slickc_ENABLE_IPO
      slickc_WARNINGS_AS_ERRORS
      slickc_ENABLE_SANITIZER_ADDRESS
      slickc_ENABLE_SANITIZER_LEAK
      slickc_ENABLE_SANITIZER_UNDEFINED
      slickc_ENABLE_SANITIZER_THREAD
      slickc_ENABLE_SANITIZER_MEMORY
      slickc_ENABLE_UNITY_BUILD
      slickc_ENABLE_CLANG_TIDY
      slickc_ENABLE_CPPCHECK
      slickc_ENABLE_COVERAGE
      slickc_ENABLE_PCH
      slickc_ENABLE_CACHE)
  endif()

  slickc_check_libfuzzer_support(LIBFUZZER_SUPPORTED)
  if(LIBFUZZER_SUPPORTED AND (slickc_ENABLE_SANITIZER_ADDRESS OR slickc_ENABLE_SANITIZER_THREAD OR slickc_ENABLE_SANITIZER_UNDEFINED))
    set(DEFAULT_FUZZER ON)
  else()
    set(DEFAULT_FUZZER OFF)
  endif()

  option(slickc_BUILD_FUZZ_TESTS "Enable fuzz testing executable" ${DEFAULT_FUZZER})

endmacro()

macro(slickc_global_options)
  if(slickc_ENABLE_IPO)
    include(cmake/InterproceduralOptimization.cmake)
    slickc_enable_ipo()
  endif()

  slickc_supports_sanitizers()

  if(slickc_ENABLE_HARDENING AND slickc_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR slickc_ENABLE_SANITIZER_UNDEFINED
       OR slickc_ENABLE_SANITIZER_ADDRESS
       OR slickc_ENABLE_SANITIZER_THREAD
       OR slickc_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    message("${slickc_ENABLE_HARDENING} ${ENABLE_UBSAN_MINIMAL_RUNTIME} ${slickc_ENABLE_SANITIZER_UNDEFINED}")
    slickc_enable_hardening(slickc_options ON ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()
endmacro()

macro(slickc_local_options)
  if(PROJECT_IS_TOP_LEVEL)
    include(cmake/StandardProjectSettings.cmake)
  endif()

  add_library(slickc_warnings INTERFACE)
  add_library(slickc_options INTERFACE)

  include(cmake/CompilerWarnings.cmake)
  slickc_set_project_warnings(
    slickc_warnings
    ${slickc_WARNINGS_AS_ERRORS}
    ""
    ""
    ""
    "")

  include(cmake/Linker.cmake)
  # Must configure each target with linker options, we're avoiding setting it globally for now

  if(NOT EMSCRIPTEN)
    include(cmake/Sanitizers.cmake)
    slickc_enable_sanitizers(
      slickc_options
      ${slickc_ENABLE_SANITIZER_ADDRESS}
      ${slickc_ENABLE_SANITIZER_LEAK}
      ${slickc_ENABLE_SANITIZER_UNDEFINED}
      ${slickc_ENABLE_SANITIZER_THREAD}
      ${slickc_ENABLE_SANITIZER_MEMORY})
  endif()

  set_target_properties(slickc_options PROPERTIES UNITY_BUILD ${slickc_ENABLE_UNITY_BUILD})

  if(slickc_ENABLE_PCH)
    target_precompile_headers(
      slickc_options
      INTERFACE
      <vector>
      <string>
      <utility>)
  endif()

  if(slickc_ENABLE_CACHE)
    include(cmake/Cache.cmake)
    slickc_enable_cache()
  endif()

  include(cmake/StaticAnalyzers.cmake)
  if(slickc_ENABLE_CLANG_TIDY)
    slickc_enable_clang_tidy(slickc_options ${slickc_WARNINGS_AS_ERRORS})
  endif()

  if(slickc_ENABLE_CPPCHECK)
    slickc_enable_cppcheck(${slickc_WARNINGS_AS_ERRORS} "" # override cppcheck options
    )
  endif()

  if(slickc_ENABLE_COVERAGE)
    include(cmake/Tests.cmake)
    slickc_enable_coverage(slickc_options)
  endif()

  if(slickc_WARNINGS_AS_ERRORS)
    check_cxx_compiler_flag("-Wl,--fatal-warnings" LINKER_FATAL_WARNINGS)
    if(LINKER_FATAL_WARNINGS)
      # This is not working consistently, so disabling for now
      # target_link_options(slickc_options INTERFACE -Wl,--fatal-warnings)
    endif()
  endif()

  if(slickc_ENABLE_HARDENING AND NOT slickc_ENABLE_GLOBAL_HARDENING)
    include(cmake/Hardening.cmake)
    if(NOT SUPPORTS_UBSAN 
       OR slickc_ENABLE_SANITIZER_UNDEFINED
       OR slickc_ENABLE_SANITIZER_ADDRESS
       OR slickc_ENABLE_SANITIZER_THREAD
       OR slickc_ENABLE_SANITIZER_LEAK)
      set(ENABLE_UBSAN_MINIMAL_RUNTIME FALSE)
    else()
      set(ENABLE_UBSAN_MINIMAL_RUNTIME TRUE)
    endif()
    slickc_enable_hardening(slickc_options OFF ${ENABLE_UBSAN_MINIMAL_RUNTIME})
  endif()

endmacro()
