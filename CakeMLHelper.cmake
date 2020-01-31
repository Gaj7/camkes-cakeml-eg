# Config variables
find_program(cake64 cake64)
find_program(cake32 cake32)
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

    if("${KernelSel4Arch}" STREQUAL "aarch32")
        if("${cake32}" STREQUAL "cake32-NOTFOUND")
            message(FATAL_ERROR "Could not find a 32-bit targeting CakeML compiler. Please ensure cake32 is on the system path.")
        endif()
        set(cake ${cake32})
    elseif("${KernelSel4Arch}" STREQUAL "x86_64")
        if("${cake64}" STREQUAL "cake64-NOTFOUND")
            message(FATAL_ERROR "Could not find a 64-bit targeting CakeML compiler. Please ensure cake64 is on the system path.")
        endif()
        set(cake ${cake64})
    else()
        message(FATAL_ERROR "No CakeML compiler support for architecture ${KernelSel4Arch}")
    endif()

    cat(${name}.cml ${PARSED_ARGS_CML_SOURCES})
    set(abs_bin_prefix "${CMAKE_CURRENT_BINARY_DIR}/${name}")
    add_custom_command(
        OUTPUT ${abs_bin_prefix}.cake.S
        COMMAND ${cake} ${cakeflag_list} < ${abs_bin_prefix}.cml > ${abs_bin_prefix}.cake.S
        COMMAND sed -i "s/cdecl(main)/cdecl(${PARSED_ARGS_CML_ENTRY_NAME})/g" ${abs_bin_prefix}.cake.S
        DEPENDS ${abs_bin_prefix}.cml
        VERBATIM
    )
    DeclareCAmkESComponent(${name}
        SOURCES ${PARSED_ARGS_C_SOURCES} ${abs_bin_prefix}.cake.S
        LIBS camkescakeml
    )
endfunction(declare_cakeml_component)

# Concatenates files with unix "cat" program
# Assumes filepaths are relative
function(cat name file)
    set(abs_name "${CMAKE_CURRENT_BINARY_DIR}/${name}")
    foreach(filepath ${file} ${ARGN})
        list(APPEND abs_files "${CMAKE_CURRENT_LIST_DIR}/${filepath}")
    endforeach(filepath)

    add_custom_command(
        OUTPUT ${abs_name}
        COMMAND cat ${abs_Files} > ${abs_name}
        DEPENDS ${abs_files}
    )
    set_source_files_properties(${abs_name} PROPERTIES GENERATED TRUE)
endfunction(cat)
