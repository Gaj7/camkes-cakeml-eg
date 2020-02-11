# Config variables
find_program(cake64 cake64)
find_program(cake32 cake32)
set(cake_flags "--stack_size=10 --heap_size=10" CACHE STRING "Arguments passed to the CakeML compiler")
string(REGEX REPLACE "[ \t\r\n]+" ";" cakeflag_list "${cake_flags}")

# Compile a list of CakeML source files. Creates a build target for library ${name}
# Args: name - name of the resulting library
#       SOURCES - CakeML source files, in order (they'll be concatenated together)
#       ENTRY_NAME - Name of assembly symbol denoting start of the CakeML code. Defaults to "run" (CAmkES component entry point)
function(build_cake name)
    cmake_parse_arguments(
        PARSE_ARGV
        1
        PARSED_ARGS
        ""
        "SOURCES"
        "ENTRY_NAME"
    )
    if(NOT "${PARSED_ARGS_UNPARSED_ARGUMENTS}" STREQUAL "")
        message(FATAL_ERROR "Unknown arguments to build_cake ${PARSED_ARGS_UNPARSED_ARGUMENTS}")
    endif()
    if("${PARSED_ARGS_SOURCES}" STREQUAL "")
        message(FATAL_ERROR "Must provide at least one CakeML source file to build_cake")
    endif()
    if("${PARSED_ARGS_ENTRY_NAME}" STREQUAL "")
        set(PARSED_ARGS_ENTRY_NAME "run")
    endif()

    if("${KernelSel4Arch}" STREQUAL "aarch32" OR "${KernelSel4Arch}" STREQUAL "arm_hyp")
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

    cat("${name}.cml" ${PARSED_ARGS_SOURCES})
    set(abs_bin_prefix "${CMAKE_BINARY_DIR}/${name}")
    add_custom_command(
        OUTPUT ${abs_bin_prefix}.cake.S
        COMMAND ${cake} ${cakeflag_list} < ${abs_bin_prefix}.cml > ${abs_bin_prefix}.cake.S
        COMMAND sed -i "s/cdecl(main)/cdecl(${PARSED_ARGS_ENTRY_NAME})/g" ${abs_bin_prefix}.cake.S
        DEPENDS ${abs_bin_prefix}.cml
        VERBATIM
    )
    add_library(${name} STATIC "${abs_bin_prefix}.cake.S")
endfunction()

# Builds a CAmkES component from CakeML and C sourse files.
# Args: name - name of the component
#       CML_SOURCES - CakeML source files, in order (they'll be concatenated together)
#       C_SOURCES - C source files
#       LIBS - Libraries to link. Defaults to "camkescakeml"
#       ENTRY_NAME - Name of assembly symbol denoting start of the CakeML code. Defaults to "run" (CAmkES component entry point)
function(cakeml_component name)
    cmake_parse_arguments(
        PARSE_ARGV
        1
        PARSED_ARGS
        ""
        "CML_SOURCES;C_SOURCES;LIBS"
        "ENTRY_NAME"
    )
    if(NOT "${PARSED_ARGS_UNPARSED_ARGUMENTS}" STREQUAL "")
        message(FATAL_ERROR "Unknown arguments to cakeml_component ${PARSED_ARGS_UNPARSED_ARGUMENTS}")
    endif()
    if("${PARSED_ARGS_LIBS}" STREQUAL "")
        set(PARSED_ARGS_LIBS "camkescakeml")
    endif()

    build_cake("${name}.cake" SOURCES "${PARSED_ARGS_CML_SOURCES}" ENTRY_NAME "${PARSED_ARGS_ENTRY_NAME}")
    DeclareCAmkESComponent(${name}
        SOURCES "${PARSED_ARGS_C_SOURCES}"
        LIBS "${PARSED_ARGS_LIBS}" "${name}.cake"
    )
endfunction()

# Concatenates files with unix "cat" program
function(cat name file)
    set(abs_name "${CMAKE_BINARY_DIR}/${name}")
    foreach(filepath ${file} ${ARGN})
        list(APPEND abs_files "${CMAKE_CURRENT_SOURCE_DIR}/${filepath}")
    endforeach(filepath)

    add_custom_command(
        OUTPUT ${abs_name}
        COMMAND cat ${abs_files} > ${abs_name}
        DEPENDS ${abs_files}
    )
endfunction()
