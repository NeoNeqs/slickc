macro(slickc_configure_linker project_name)
  set(slickc_USER_LINKER_OPTION
    "DEFAULT"
      CACHE STRING "Linker to be used")
    set(slickc_USER_LINKER_OPTION_VALUES "DEFAULT" "SYSTEM" "LLD" "GOLD" "BFD" "MOLD" "SOLD" "APPLE_CLASSIC" "MSVC")
  set_property(CACHE slickc_USER_LINKER_OPTION PROPERTY STRINGS ${slickc_USER_LINKER_OPTION_VALUES})
  list(
    FIND
    slickc_USER_LINKER_OPTION_VALUES
    ${slickc_USER_LINKER_OPTION}
    slickc_USER_LINKER_OPTION_INDEX)

  if(${slickc_USER_LINKER_OPTION_INDEX} EQUAL -1)
    message(
      STATUS
        "Using custom linker: '${slickc_USER_LINKER_OPTION}', explicitly supported entries are ${slickc_USER_LINKER_OPTION_VALUES}")
  endif()

  set_target_properties(${project_name} PROPERTIES LINKER_TYPE "${slickc_USER_LINKER_OPTION}")
endmacro()
