cmake_minimum_version(VERSION 3.7.2)

project(componentHello C)

include(CakeMLHelper.cmake)

declare_cakeml_component(Hello
    CML_SOURCES src/hello.cml
    C_SOURCES src/main.c
)

DeclareCAmkESRootserver(root.camkes)
