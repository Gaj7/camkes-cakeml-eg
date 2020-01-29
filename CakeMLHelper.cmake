# Config variables
find_program(cake cake)
set(cake_flags "--stack_size=50 --heap_size=50" CACHE STRING "Arguments passed to the CakeML compiler")
string(REGEX REPLACE "[ \t\r\n]+" ";" cakeflag_list "${cake_flags}")

# Similar to DeclareCAmkESComponent, but also handles concrete CakeML source files
# Input:
#   First argument - name of the component
#   CML_SOURCES - CakeML source files, in order (they'll be concatenated together)
#   C_SOURCES - C source files
#   CML_ENTRY - Name of assembly symbol denoting start of the CakeML code. Defaults to "cml_entry"
# TODO: Support more DeclareCAmkESComponent arguments
function(declare_cakeml_component name)
    cmake_parse_arguments(
        PARSE_ARGV
        1
        PARSED_ARGS
        ""
        "CML_ENTRY_NAME"
        "CML_SOURCES;C_SOURCES"
    )
    if(NOT "${PARSED_ARGS_UNPARSED_ARGUMENTS}" STREQUAL "")
        message(FATAL_ERROR "Unknown arguments to declare_cakeml_component ${PARSED_ARGS_UNPARSED_ARGUMENTS}")
    endif()
    if("${PARSED_ARGS_CML_SOURCES}" STREQUAL "")
        message(FATAL_ERROR "Must provide at least one CakeML source file to declare_cakeml_component")
    endif()
    if("${PARSED_ARGS_CML_ENTRY_NAME}" STREQUAL "")
        set(PARSED_ARGS_CML_ENTRY_NAME "cml_entry")
    endif()

    cat(${name}.cml ${PARSED_ARGS_CML_SOURCES})
    add_custom_command(
        OUTPUT ${name}.cake.S
        COMMAND ${cake} ${cakeflag_list} < ${name}.cml > ${name}.cake.S
        COMMAND sed -i "s/cdecl(main)/cdecl(${PARSED_ARGS_CML_ENTRY_NAME})/g" ${name}.cake.S
        DEPENDS ${name}.cml
        VERBATIM
    )
    DeclareCAmkESComponent(${name}
        SOURCES ${PARSED_ARGS_C_SOURCES} ${name}.cake.S
        LIBS camkescakeml
    )
endfunction(declare_cakeml_component)

# Concatenates files with unix "cat" program
# Assumes filepaths are relative
function(cat name file)
    foreach(filepath ${file} ${ARGN})
        list(APPEND relative_files "${CMAKE_CURRENT_SOURCE_DIR}/${filepath}")
    endforeach(filepath)

    add_custom_command(
        OUTPUT ${name}
        COMMAND cat ${relative_files} > ${name}
        DEPENDS ${relative_files}
    )
    set_source_files_properties(${name} PROPERTIES GENERATED TRUE)
endfunction(cat)
