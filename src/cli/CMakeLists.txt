add_executable(slickc main.cpp)

target_link_libraries(
  slickc
  PRIVATE slickc::slickc_options
          slickc::slickc_warnings
          CLI11::CLI11
          fmt::fmt
          spdlog::spdlog)

slickc_configure_linker(slickc)

target_include_directories(slickc PRIVATE "${CMAKE_BINARY_DIR}/configured_files/include")

# Apply WASM-specific configuration (keeps the web playground pipeline alive)
if(EMSCRIPTEN)
  slickc_configure_wasm_target(slickc
    TITLE "slickc"
    DESCRIPTION "The slick language compiler"
  )
endif()
