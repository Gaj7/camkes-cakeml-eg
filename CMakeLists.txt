cmake_minimum_required(VERSION 3.7.2)

project(componentHello C)

include("${CMAKE_CURRENT_LIST_DIR}/CakeMLHelper.cmake")

simple_cakeml_component(Hello
    CML_SOURCES src/hello.cml
    C_SOURCES src/main.c
)

DeclareCAmkESRootserver(root.camkes)
