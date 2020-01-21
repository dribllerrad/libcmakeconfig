cmake_minimum_required(VERSION 3.15)



# Colorized Output Setup
if(NOT WIN32)
  string(ASCII 27 Esc)
  set(Reset 		"${Esc}[m")
  set(Bold  		"${Esc}[1m")
  set(Red         	"${Esc}[31m")
  set(Green       	"${Esc}[32m")
  set(Blue        	"${Esc}[34m")
  set(Cyan        	"${Esc}[36m")
  set(Magenta     	"${Esc}[35m")
  set(Yellow      	"${Esc}[33m")
  set(White       	"${Esc}[37m")
  set(BoldRed     	"${Esc}[1;31m")
  set(BoldGreen   	"${Esc}[1;32m")
  set(BoldBlue    	"${Esc}[1;34m")
  set(BoldCyan    	"${Esc}[1;36m")
  set(BoldMagenta 	"${Esc}[1;35m")
  set(BoldYellow  	"${Esc}[1;33m")
  set(BoldWhite   	"${Esc}[1;37m")
endif()



set(help_message 
"
${BoldMagenta}
CMake Library Configuration\n${Reset}
This CMake script generates a pre-configured CMakeList.txt and accompanying 
project files to generate a \"Modern\" CMake project that can easily 
be included in a super-project either by simply including the project
directory and calling add_subdirectory() or by fully installing the
project and calling find_package() from the super-project.

Place all privatly used source and header files in 
")

set(arg_error 
"
${BoldRed}ERROR:${Reset} 
${Red}Too few arguments were given.${Reset}
At least 1 argument must be given to specify the library name.
")

set(usage
"
${BoldCyan}USAGE:${Reset}
cmake -P libconfig.cmake <library name> [<library dependencies>]
")

set(argc ${CMAKE_ARGC})

# Get arguments passed to cmake -P libconfig.cmake
foreach(i RANGE 3 ${argc})
	set(arg_${i} ${CMAKE_ARGV${i}})
	string(REPLACE \\ / arg_${i} "${arg_${i}}") # for Windows path compatibility

endforeach()

# Check for too few arguments
if(${argc} LESS 4)
	message(${arg_error})
	message(${usage})
	return()
endif()


set(cmake_lists_text 
"
###############################################################################
###############################################################################
#[[
START OF FILE
CMakeLists.txt
Generated from libCMakeConfig.cmake
]]
###############################################################################
###############################################################################


cmake_minimum_required(VERSION 3.15 FATAL_ERROR)

set(PROJECT_NAME @libconfig_library_name@)

set(DEPENDENCY_LIST @libconfig_dependency_list@)
if(NOT \${DEPENDENCY_LIST} STREQUAL \"\")
	list(REMOVE_DUPLICATES \${DEPENDENCY_LIST})
	set(ALIAS_DEPENDENCY_LIST \${DEPENDENCY_LIST})
	list(LENGTH \${DEPENDENCY_LIST} NUMBER_OF_DEPENDENCIES)
endif()

if(NOT \${DEPENDENCY_LIST} STREQUAL \"\")
	list(TRANSFORM ALIAS_DEPENDENCY_LIST REPLACE \"([^;]+)\" \"\\\\1::\\\\1\")
endif() 

project(
    \${PROJECT_NAME}
    VERSION 0.1.0.0
    LANGUAGES CXX)

include(GNUInstallDirs)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY
    \"\${CMAKE_BINARY_DIR}/\${CMAKE_INSTALL_BINDIR}\")
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY
    \"\${CMAKE_BINARY_DIR}/\${CMAKE_INSTALL_LIBDIR}\")
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY
    \"\${CMAKE_BINARY_DIR}/\${CMAKE_INSTALL_LIBDIR}\")

set(CMAKE_EXPORT_PACKAGE_REGISTRY ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)
set(CMAKE_C_EXTENSIONS OFF)
set(CMAKE_CXX_EXTENSIONS OFF)

function(update_file path content)
    set(old_content \"\")
    if(EXISTS \"\${path}\")
        file(READ \"\${path}\" old_content)
    endif()
    if(NOT old_content STREQUAL content)
        file(WRITE \"\${path}\" \"\${content}\")
    endif()
endfunction(update_file)

function(update_deps_file)
    set(deps_file \"CMakeDeps.cmake\")
	set(deps \"\")
	math(EXPR num \"(\${ARGC}-1)\")
	foreach(i RANGE \${num})
		list(APPEND deps \${ARGV\${i}})
	endforeach()
    # Normalize the list so it's the same on every machine
    list(REMOVE_DUPLICATES deps)
    foreach(dep IN LISTS deps)
        file(RELATIVE_PATH rel_dep \${CMAKE_CURRENT_SOURCE_DIR} \${dep})
        list(APPEND rel_deps \${rel_dep})
    endforeach(dep)
    list(SORT rel_deps)
    # Update the deps file
    set(content \"# generated by make process\nset(sources \${rel_deps})\n\")
    update_file(\${deps_file} \"\${content}\")
    # Include the file so it's tracked as a generation dependency we don't
    # need the content.
    include(\${deps_file})
endfunction(update_deps_file)

# ##############################################################################
# Build steps
set(LIBRARY_TARGET_NAME \${PROJECT_NAME})

set(SOURCE_FILES_DIRECTORY \${CMAKE_CURRENT_SOURCE_DIR}/src)
set(INCLUDE_FILES_DIRECTORY_BUILD \${CMAKE_CURRENT_SOURCE_DIR}/include/\${LIBRARY_TARGET_NAME})
set(INCLUDE_FILES_DIRECTORY_INSTALL include/\${LIBRARY_TARGET_NAME})

file(GLOB_RECURSE \${LIBRARY_TARGET_NAME}_SRC LIST_DIRECTORIES false CONFIGURE_DEPENDS \${SOURCE_FILES_DIRECTORY}/*.cpp \${SOURCE_FILES_DIRECTORY}/*.hpp)
file(GLOB_RECURSE \${LIBRARY_TARGET_NAME}_BUILD_INTERFACE_HPP LIST_DIRECTORIES false CONFIGURE_DEPENDS \${INCLUDE_FILES_DIRECTORY_BUILD}/*.hpp)
file(GLOB_RECURSE \${LIBRARY_TARGET_NAME}_INSTALL_INTERFACE_HPP LIST_DIRECTORIES false RELATIVE \${CMAKE_CURRENT_SOURCE_DIR} CONFIGURE_DEPENDS \${INCLUDE_FILES_DIRECTORY_INSTALL}/*.hpp)

update_deps_file(\${\${LIBRARY_TARGET_NAME}_SRC} \${\${LIBRARY_TARGET_NAME}_BUILD_INTERFACE_HPP})

# Must use an empty string \"\" in add_library in order to use target_sources()
add_library(\${LIBRARY_TARGET_NAME} \"\")

target_sources(
	\${LIBRARY_TARGET_NAME}
		PRIVATE
			\${\${LIBRARY_TARGET_NAME}_SRC}
		PUBLIC
			\$<BUILD_INTERFACE:\${\${LIBRARY_TARGET_NAME}_BUILD_INTERFACE_HPP}>
        	\$<INSTALL_INTERFACE:\${\${LIBRARY_TARGET_NAME}_INSTALL_INTERFACE_HPP}>)

add_library(\${PROJECT_NAME}::\${LIBRARY_TARGET_NAME} ALIAS
            \${LIBRARY_TARGET_NAME})

if(NOT \${DEPENDENCY_LIST} STREQUAL \"\")
	if(\${PUBLIC_HEADERS})
		set(PUBLIC_PRIVATE PUBLIC)
	else()
		set(PUBLIC_PRIVATE PRIVATE)
	endif(\${PUBLIC_HEADERS})
	message(\"\n
**************************
PROJECT_DEPENDENCY was set
as \${PUBLIC_PRIVATE}
**************************\")

	target_link_libraries(\${LIBRARY_TARGET_NAME} PRIVATE \${ALIAS_DEPENDENCY_LIST})
	set(INHERITED_PUBLIC_INCLUDE_DIR \$<TARGET_PROPERTY:\${DEPENDENCY_LIST},INTERFACE_INCLUDE_DIRECTORIES>)
endif(NOT \${DEPENDENCY_LIST} STREQUAL \"\")

target_include_directories(\${LIBRARY_TARGET_NAME}
    PUBLIC
        #\${CMAKE_CURRENT_LIST_DIR}/include
		\${INHERITED_PUBLIC_INCLUDE_DIR}
        \$<INSTALL_INTERFACE:include>
        \$<BUILD_INTERFACE:\${CMAKE_CURRENT_LIST_DIR}/include>
    PRIVATE
        \${CMAKE_CURRENT_SOURCE_DIR}/src
)

# Strip the binaries in \"release\" build
set_target_properties(\${LIBRARY_TARGET_NAME} PROPERTIES LINK_FLAGS_RELEASE -s)
target_compile_features(\${PROJECT_NAME} PRIVATE cxx_std_17)


##############################################
# Installation config
set(INSTALL_CONFIGDIR \${CMAKE_INSTALL_LIBDIR}/cmake/\${LIBRARY_TARGET_NAME})

set_target_properties(
	\${LIBRARY_TARGET_NAME} 
		PROPERTIES
  			PUBLIC_HEADER 
				\${\${LIBRARY_TARGET_NAME}_BUILD_INTERFACE_HPP}
)


install(TARGETS \${LIBRARY_TARGET_NAME}
    EXPORT \${LIBRARY_TARGET_NAME}Targets
    LIBRARY 	DESTINATION \${CMAKE_INSTALL_LIBDIR} COMPONENT lib
    ARCHIVE 	DESTINATION \${CMAKE_INSTALL_LIBDIR} COMPONENT static_lib
	RUNTIME 	DESTINATION \${CMAKE_INSTALL_BINDIR} COMPONENT bin
	PUBLIC_HEADER DESTINATION \${CMAKE_INSTALL_INCLUDEDIR}/\${LIBRARY_TARGET_NAME} COMPONENT dev
)

install(DIRECTORY include/ DESTINATION \${CMAKE_INSTALL_INCLUDEDIR})

#Export the targets to a script
install(EXPORT \${LIBRARY_TARGET_NAME}Targets
  FILE
    \${LIBRARY_TARGET_NAME}Targets.cmake
  NAMESPACE
    \${LIBRARY_TARGET_NAME}::
  DESTINATION
    \${INSTALL_CONFIGDIR}
)

##############################################
#[[
Exporting from the build tree. Allows other projects in the build tree to use
the library target without calling FindPackage().
]]
export(
	TARGETS \${LIBRARY_TARGET_NAME} 
	FILE \${CMAKE_CURRENT_BINARY_DIR}/\${LIBRARY_TARGET_NAME}Targets.cmake
	NAMESPACE \${LIBRARY_TARGET_NAME}::
)

export(EXPORT \${LIBRARY_TARGET_NAME}Targets FILE \${CMAKE_CURRENT_BINARY_DIR}/\${LIBRARY_TARGET_NAME}Targets.cmake NAMESPACE \${LIBRARY_TARGET_NAME}::)

#Create a ConfigVersion.cmake file
include(CMakePackageConfigHelpers)
write_basic_package_version_file(
    \${CMAKE_CURRENT_BINARY_DIR}/\${LIBRARY_TARGET_NAME}ConfigVersion.cmake
    VERSION \${PROJECT_VERSION}
    COMPATIBILITY AnyNewerVersion
)

configure_package_config_file(\${CMAKE_CURRENT_SOURCE_DIR}/cmake/\${LIBRARY_TARGET_NAME}Config.cmake.in
    \${CMAKE_CURRENT_BINARY_DIR}/\${LIBRARY_TARGET_NAME}Config.cmake
    INSTALL_DESTINATION \${INSTALL_CONFIGDIR}
)

#Install the config, configversion and custom find modules
install(FILES
    \${CMAKE_CURRENT_BINARY_DIR}/\${LIBRARY_TARGET_NAME}Config.cmake
    \${CMAKE_CURRENT_BINARY_DIR}/\${LIBRARY_TARGET_NAME}ConfigVersion.cmake
    DESTINATION \${INSTALL_CONFIGDIR}
)


#Register package in user's package registry
export(PACKAGE \${LIBRARY_TARGET_NAME})

# uninstall target
if(NOT TARGET uninstall)
    configure_file(
        \"\${CMAKE_CURRENT_SOURCE_DIR}/cmake/cmake_uninstall.cmake.in\"
        \"\${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake\"
        IMMEDIATE @ONLY)

    add_custom_target(uninstall
        COMMAND \${CMAKE_COMMAND} -P \${CMAKE_CURRENT_BINARY_DIR}/cmake_uninstall.cmake)
endif(NOT TARGET uninstall)


# Colorized Output Setup
if(NOT WIN32)
  string(ASCII 27 Esc)
  set(Reset 		\"\${Esc}[m\")
  set(Bold  		\"\${Esc}[1m\")
  set(Red         	\"\${Esc}[31m\")
  set(Green       	\"\${Esc}[32m\")
  set(Blue        	\"\${Esc}[34m\")
  set(Cyan        	\"\${Esc}[36m\")
  set(Magenta     	\"\${Esc}[35m\")
  set(Yellow      	\"\${Esc}[33m\")
  set(White       	\"\${Esc}[37m\")
  set(BoldRed     	\"\${Esc}[1;31m\")
  set(BoldGreen   	\"\${Esc}[1;32m\")
  set(BoldBlue    	\"\${Esc}[1;34m\")
  set(BoldCyan    	\"\${Esc}[1;36m\")
  set(BoldMagenta 	\"\${Esc}[1;35m\")
  set(BoldYellow  	\"\${Esc}[1;33m\")
  set(BoldWhite   	\"\${Esc}[1;37m\")
endif()

if(\${DEPENDENCY_LIST} STREQUAL \"\")
	set(DEPENDENCY_MESSAGE \"None\")
else()
	set(DEPENDENCY_MESSAGE \${DEPENDENCY_LIST})
endif() 

# Final summary
message(\"\n\${BoldWhite}
*******************************************************************************
CMake configuration completed with the following values:
Library Name: \n\t\${BoldCyan}\${LIBRARY_TARGET_NAME}\${BoldWhite}
Alias for use with FindPackage(): \n\t\${BoldCyan}\${LIBRARY_TARGET_NAME}::\${LIBRARY_TARGET_NAME}\${BoldWhite}
Dependencies for \${LIBRARY_TARGET_NAME}: \n\t\${BoldCyan}\${DEPENDENCY_MESSAGE}\${BoldWhite}
*******************************************************************************
\${Reset}\"
)


###############################################################################
###############################################################################
#[[

END OF FILE

CMakeLists.txt
Generated from libCMakeConfig.cmake
]]
###############################################################################
###############################################################################
"
)



set(cmake_uninstall_in 
"
###############################################################################
###############################################################################
#[[

START OF FILE

cmake_uninstall.cmake.in
Generated from libCMakeConfig.cmake
]]
###############################################################################
###############################################################################


if(NOT EXISTS \"@CMAKE_BINARY_DIR@/install_manifest.txt\")
  message(FATAL_ERROR \"Cannot find install manifest: @CMAKE_BINARY_DIR@/install_manifest.txt\")
endif(NOT EXISTS \"@CMAKE_BINARY_DIR@/install_manifest.txt\")

file(READ \"@CMAKE_BINARY_DIR@/install_manifest.txt\" files)
string(REGEX REPLACE \"\\n\" \"\;\" files \"\${files}\")
foreach(file \${files})
  message(STATUS \"Uninstalling \$ENV{DESTDIR}\${file}\")
  if(IS_SYMLINK \"\$ENV{DESTDIR}\${file}\" OR EXISTS \"\$ENV{DESTDIR}\${file}\")
    exec_program(
      \"@CMAKE_COMMAND@\" ARGS \"-E remove \\\"\$ENV{DESTDIR}\${file}\\\"\"
      OUTPUT_VARIABLE rm_out
      RETURN_VALUE rm_retval
      )
    if(NOT \"\${rm_retval}\" STREQUAL 0)
      message(FATAL_ERROR \"Problem when removing \$ENV{DESTDIR}\${file}\")
    endif(NOT \"\${rm_retval}\" STREQUAL 0)
  else(IS_SYMLINK \"\$ENV{DESTDIR}\${file}\" OR EXISTS \"\$ENV{DESTDIR}\${file}\")
    message(STATUS \"File \$ENV{DESTDIR}\${file} does not exist.\")
  endif(IS_SYMLINK \"\$ENV{DESTDIR}\${file}\" OR EXISTS \"\$ENV{DESTDIR}\${file}\")
endforeach(file)


###############################################################################
###############################################################################
#[[

END OF FILE

cmake_uninstall.cmake.in
Generated from libCMakeConfig.cmake
]]
###############################################################################
###############################################################################
"
)



set(lib_config_cmake_in 
"
###############################################################################
###############################################################################
#[[

START OF FILE

<library_name>Cmake.in
Generated from libCMakeConfig.cmake
]]
###############################################################################
###############################################################################


@PACKAGE_INIT@

get_filename_component(CURRENT_DIR \${CMAKE_CURRENT_LIST_FILE} PATH)

include(CMakeFindDependencyMacro)

set(LIBRARY_TARGET_NAME @LIBRARY_TARGET_NAME@)
set(PROJECT_DEPENDENCY @PROJECT_DEPENDENCY@)

if(NOT \${PROJECT_DEPENDENCY} STREQUAL \"\")
	message(\"\n
		+++++++++++++++++++++++++++++++++++++++
		From \${LIBRARY_TARGET_NAME}Config.cmake
		Project is set to use dependency:
		\${PROJECT_DEPENDENCY} 
		+++++++++++++++++++++++++++++++++++++++\")
	#find_dependency(\${PROJECT_DEPENDENCY} REQUIRED)
	find_package(\${PROJECT_DEPENDENCY} REQUIRED)
endif(NOT \${PROJECT_DEPENDENCY} STREQUAL \"\")

if(NOT TARGET \${LIBRARY_TARGET_NAME} AND NOT \${\${LIBRARY_TARGET_NAME}_BINARY_DIR})
  include(\${CURRENT_DIR}/\${LIBRARY_TARGET_NAME}Targets.cmake)
endif()

check_required_components(\${LIBRARY_TARGET_NAME})


###############################################################################
###############################################################################
#[[

END OF FILE

${lib_name}.cmake.in
Generated from libCMakeConfig.cmake
]]
###############################################################################
###############################################################################
"
) ##################################
# End of set(lib_config_cmake_in "")


if(${argc} GREATER_EQUAL 4)
	
	if(${arg_3} STREQUAL "help")
		message(${help_message})
		message(${usage})
		return()
	endif()

	set(lib_name ${arg_3})
	message("${BoldWhite}Library name was set to ${BoldCyan}${lib_name}${Reset}")
	set(libconfig_library_name ${lib_name})

	if(${argc} GREATER_EQUAL 5)
		math(EXPR number_of_dependencies "(${argc} - 4)")
		set(libconfig_dependency_list "")
		message("${BoldYellow}Number of dependencies: ${number_of_dependencies}${Reset}")
		foreach(i RANGE 4 ${argc})
			math(EXPR dependency_index "(${i} - 3)")
			set(dep_${dependency_index} ${arg_${i}})
			list(APPEND libconfig_dependency_list ${dep_${dependency_index}})
		endforeach()
		foreach(i RANGE 1 ${number_of_dependencies})
			message(DEBUG "${BoldYellow}Dependency ${i}: ${dep_${i}}${Reset}")
		endforeach()
		message("${BoldMagenta}Dependency List:\n${libconfig_dependency_list}${Reset}")
	endif()

	file(MAKE_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/${lib_name})
	file(MAKE_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/${lib_name}/cmake)
	file(MAKE_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/${lib_name}/include)
	file(MAKE_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/${lib_name}/include/${lib_name})
	file(MAKE_DIRECTORY ${CMAKE_CURRENT_LIST_DIR}/${lib_name}/src)

	string(CONFIGURE ${cmake_lists_text} cmake_lists_text_formatted @ONLY)

	file(WRITE ${CMAKE_CURRENT_LIST_DIR}/${lib_name}/CMakeLists.txt ${cmake_lists_text_formatted})
	file(WRITE ${CMAKE_CURRENT_LIST_DIR}/${lib_name}/cmake/${lib_name}Config.cmake.in ${lib_config_cmake_in})
	file(WRITE ${CMAKE_CURRENT_LIST_DIR}/${lib_name}/cmake/cmake_uninstall.cmake.in ${cmake_uninstall_in})


endif()


message("${BoldGreen}END OF FILE\n${Cyan}Did not break...${Reset}\n")