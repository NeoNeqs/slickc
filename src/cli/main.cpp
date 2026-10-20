#include <CLI/CLI.hpp>
#include <fmt/base.h>
#include <fmt/format.h>
#include <spdlog/spdlog.h>

#include <cstdlib>
#include <exception>
#include <string>
#include <vector>

// This file will be generated automatically when you run the CMake
// configuration step. It creates a namespace called `slickc`. You can modify
// the source template at `configured_files/config.hpp.in`.
#include <internal_use_only/config.hpp>

// NOLINTNEXTLINE(bugprone-exception-escape)
int main(int argc, const char **argv)
{
  try {
    CLI::App app{ fmt::format("{} - the slick language compiler (version {})",
      slickc::cmake::project_name,
      slickc::cmake::project_version) };

    std::vector<std::string> input_files;
    app.add_option("files", input_files, "Source files to compile");

    bool show_version = false;
    app.add_flag("--version", show_version, "Show version information");

    CLI11_PARSE(app, argc, argv);

    if (show_version) {
      fmt::print("{}\n", slickc::cmake::project_version);
      return EXIT_SUCCESS;
    }

    if (input_files.empty()) {
      fmt::print(stderr, "error: no input files\n");
      return EXIT_FAILURE;
    }

    // TODO: run the actual compiler pipeline on input_files
    spdlog::info("compiling {} file(s) - not implemented yet", input_files.size());
    return EXIT_SUCCESS;

  } catch (const std::exception &e) {
    spdlog::error("Unhandled exception in main: {}", e.what());
    return EXIT_FAILURE;
  }
}
