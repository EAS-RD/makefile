## *****************************************************************************
## **                                                                         **
## **                     Copyright 2018 (c) Tuxin                            **
## **   Licensed under the Apache License, Version 2.0 (the "License");       **
## **   you may not use this file except in compliance with the License.      **
## **   You may obtain a copy of the License at                               **                                                   
## **       http://www.apache.org/licenses/LICENSE-2.0                        **
## **                                                                         **
## **   Unless required by applicable law or agreed to in writing, software   **
## **   distributed under the License is distributed on an "AS IS" BASIS,     **
## **   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or       **
## **   implied.                                                              **
## **   See the License for the specific language governing permissions and   **
## **   limitations under the License.                                        **
## **                                                                         **
## *****************************************************************************
## *****************************************************************************
## @file        Makefile
## @brief       Generic project build file.
##
##              This makefile can generate a binary by automatically detecting
##              the files of a project, provided that it respects a pre-defined
##              directory architecture.
##
## @author      Tuxin (JPB)
## @version     1.4.7
## @since       Created 04/25/2018 (JPB)
## @since       Modified 10/15/2018 (JPB) - Add 'dependencies' rule.
## @since       Modified 10/19/2018 (JPB) - The version number and the type
##                                          (shared or static) of the libraries
##                                          can be specified in the dependency
##                                          variables.
## @since       Modified 10/26/2018 (JPB) - Fixed libraries inclusions.
## @since       Modified 11/02/2018 (JPB) - Fixed include directory management
## @since       Modified 12/14/2018 (JPB) - Generate symbolic link for test bin.
## @since       Modified 02/04/2019 (JPB) - Use externally defined compiler var.
## @since       Modified 05/09/2019 (JPB) - We can specify that a dependency
##                                          can only have header files.
## @since       Modified 07/26/2019 (JPB) - Fixed text search in variables.
## @since       Modified 10/18/2019 (JPB) - Fixed transmission of environment
##                                          variables (among others, BOARD_TYPE)
##                                          to the compiler.
##                                        - Adds gcov options.
## @since       Modified 11/05/2019 (JPB) - Adds CppUTest options for memory
##                                          leaks detection.
## @since       Modified 09/01/2020 (JPB) - Fixes ar parameters for static lib
## @since       Modified 10/15/2020 (JPB) - Fixes VERSION define
## @since       Modified 06/02/2021 (JPB) - Fixes ar parameters for external SDK 
##
## @date        June 2nd, 2021
##
## *****************************************************************************
.DEFAULT_GOAL = without_target
.PHONY: mrproper clean create_distribution without_target dependencies \
        clear_tarball finalize display_config help create_directories

## \def COLOR
## \brief Sets the escape command to display messages in color.
##
COLOR ?= "\\033[42m"

## \def END_COLOR
## \brief Sets the escape command to complete the colorization.
##
END_COLOR ?= "\\033[0m"

## \mainpage Generic Makefile
##
## \section intro_sec Introduction
## This Makefile compiles the C / C ++ sources of a project that respects a
## specific folders architecture. It adapts according to the binary to be
## generated through the different variables available.
##
## \section architecture_sec Folder architecture
## This architecture must match the one shown below. Only the directories used
## by this makefile are indicated in this diagram.
## <pre>
## Workspace
##     :
##     :-------- Project 1
##     :            :-------- build
##     :            :          :
##     :            :          :-------- Debug_<arch>
##     :            :          :
##     :            :          :-------- Release_<arch>
##     :            :          :
##     :            :          :-------- Test_<arch>
##     :            :
##     :            :-------- include
##     :            :
##     :            :-------- log
##     :            :
##     :            :-------- package
##     :            :            :
##     :            :            :-------- deb
##     :            :            :
##     :            :            :-------- rpm
##     :            :            :
##     :            :            :-------- tar
##     :            :            :
##     :            :            :-------- ...
##     :            :            :
##     :            :            :-------- zip
##     :            :
##     :            :
##     :            :-------- src
##     :            :
##     :            :-------- test
##     :
##     :
##     :-------- Project 2
##     :
##     :
##     :
##     :-------- Project n
## </pre>
## \subsection dir_content Directories contents
##
## * Workspace ($WORKSPACE_DIR) : Root of workspace containing all associated
## projects.
## * Project x ($PROJECT_DIR) : Roots of projects.
## * build ($BIN_DIR) : Root directory containing the generated binaries. These
## binaries are sorted by build configuration and by hardware architecture type.
## * build/$CONFIG_$TARGET_ARCH ($OBJ_DIR) : Binary specific to the build
## configuration.
## * include ($INC_DIR) : Directory for public header files to be deployed with
## the project binary (usually for a library project)
## * log ($LOG_DIR) : Directory intended to receive the files generated by the
## build and control tools.
## * package ($PACKAGE_DIR) : Root directory of subdirectories intended to
## receive the delivery packages.
## * src ($SRC_DIR) : Root directory of the source files. This directory can
## contain sub-directories.
## * test ($TEST_DIR) : Root directory of the unit testing source files.
##
## \subsection use Use Makefile
## In principle, the only variables to modify to adapt this Makefile to your
## project are those of the 'Project Variables' section. This section includes
## PROJECT_NAME, DEPENDENCIES, TEST_DEPENDENCIES, LIB_DIR, TEST_LIB_DIR, and
## BINARY_TYPE.
## Then some variables in the 'Build variables' section can be defined by your
## development environment. These are CONFIG, TARGET_ARCH, OS_TYPE, MAJ_VERSION,
## MIN_VERSION, BUILD_VERSION, and PRE_DEFINED. It is best to use a file
## containing the version number (vers-number.txt). In this case, the version
## variables are automatically updated with this file.
## For example, using Eclipse CDT as IDE, we can, for a configuration intended
## for a Linux PC environment, define the following variables:
## * CONFIG = Debug
## * TARGET_ARCH = x86_64
## * OS_TYPE = Linux64
## The simple modification of these variables will allow you to change the build
## configuration.
##
## \subsection rules Makefile rules
## Existing rules can be listed by typing 'make help' or simply 'make'.
## * all             Builds project
## * dependencies    Creates a file to configure the LD_LIBRARY_PATH variable.
## * display_config  Display current configuration variables
## * clear_tarball   Clear all packages
## * clean           Delete object files
## * mrproper        Clear all generated files
## * help            This help message

#-------------------------------------------------------------------------------
## \addtogroup Makefile
## \{

## \addtogroup Project_Variables Project Variables
## \{
## \brief These variables must be declared in this file according to the
##  project.

## \def PROJECT_NAME
## \brief Defines the project name. This name must match the name of the
##  project's parent directory in the workspace.
##
PROJECT_NAME := makefile

## \def DEPENDENCIES
## \brief Sets the name of libraries whose binary depends.
##  These libraries must be in a path of the LD_LIBRARY_PATH variable, in the
##  system default directories, or in workspace. Library names must be
##  separated by at least one space. The version of the library can be
##  specified by adding it after the name followed by ':'. If the link is
##  static, the library name must be enclosed by '[..].
##  If the dependency concerns only header files, its name must be preceded by
##  the '@' character.
##  Here are some examples allowed: mylib:1.2.0 thelib:1 [staticlib]
##  [commonlib:2.1] @header_only
##
DEPENDENCIES := @common

## \def TEST_DEPENDENCIES
## \brief Sets the name of libraries whose unit testing depends.
##  These libraries must be in a path of the LD_LIBRARY_PATH variable, in the
##  system default directories, or in workspace. The same rules as the variable
##  'DEPENDENCIES' apply for the name of the libraries indicated.
##
TEST_DEPENDENCIES :=

## \def LIB_DIR
## \brief Defines directory of system libraries. This variable can be set before
##  calling 'make'
##
LIB_DIR ?= /usr/local/lib

## \def TEST_LIB_DIR
## \brief Defines the library directory required for unit testing. This variable
##  can be set before calling 'make'
##
TEST_LIB_DIR ?=

## \def BINARY_TYPE
## \brief Defines the type of binary generated. Authorized values are
##  'exe' (by default), 'lib', or 'shared'
##
BINARY_TYPE ?= shared

## @}
##
#-------------------------------------------------------------------------------
## \addtogroup Build_Variables Build variables
## \{
## \brief These variables can be redefined before the execution of 'make'

## \def CONFIG
## \brief Defines build configuration. Authorized values are
##  'Release' (by default), 'Debug', or 'Test'.
##
CONFIG ?= Release

ifeq (${CONFIG},Test)
  BINARY_TYPE := exe
endif

## \def PRE_DEFINED
## \brief Stores predefined variables. These variables are passed to the
##  preprocessor.
##
PRE_DEFINED = -DVERSION=\"$(VERSION)\" -DREVISION=$(REV_NUMBER)

# BOARD_TYPE is used to define the electronic card used.
ifneq ($(BOARD_TYPE),)
  PRE_DEFINED += -DBOARD_TYPE=$(BOARD_TYPE)
endif 
 
ifeq ($(CONFIG),Debug)
  PRE_DEFINED += -D_DEBUG
endif

ifeq ($(CONFIG),Release)
  PRE_DEFINED += -DNDEBUG
endif

ifeq (${CONFIG},Test)
  PRE_DEFINED += -DTEST_COMPILATION
endif

## \def TARGET_ARCH
## \brief Defines target architecture. Authorized values are 'x86',
##  'x86_64' (by default), 'arm', 'armhf'
##
TARGET_ARCH ?= x86_64

## \def OS_TYPE
## \brief Defines target Operating System. Authorized values are
##  'Linux' (by default), 'Linux64', 'Win32', 'Win64'
##
OS_TYPE ?= Linux

## \def MAJ_VERSION
## \brief Defines the major version of the binary. The default value is '1'.
##
MAJ_VERSION ?= 1

## \def MIN_VERSION
## \brief Defines the minor version of the binary. The default value is '0'.
##
MIN_VERSION ?= 0

## \def BUILD_VERSION
## \brief Defines the build version of the binary. The default value is '0'.
##
BUILD_VERSION ?= 0

## @}
##
#-------------------------------------------------------------------------------

## \addtogroup Private_Variables
## \{
## \brief These variables 

## \def REV_NUMBER_FILE
## \brief Sets the filename containing the revision number. This filename
##  is 'rev-number.txt' by default
##
REV_NUMBER_FILE = $(PROJECT_DIR)/rev-number.txt

## \def VERS_NUMBER_FILE
## \brief Sets the filename containing the version number. This filename
##  is 'vers-number.txt' by default. It contains the version number in the
##  form x.y.z where x is the major version, y the minor version and z the
##  build version.
##
VERS_NUMBER_FILE = $(PROJECT_DIR)/vers-number.txt

## \def TEST_LIB
## \brief Sets the name of the unit test library.
##
TEST_LIB = CppUTest

## @}
##
#-------------------------------------------------------------------------------
## \addtogroup Automatic_Variables Automatic variables
## \{
## \brief These variables can be redefined during the execution of 'make'

## \def VERSION
## \brief Defines the version in the format x.y.z
##
VERSION = $(MAJ_VERSION).$(MIN_VERSION).$(BUILD_VERSION)

# -----------------------------------
# SETS PREFIX AND EXTENSION OF BINARY
# -----------------------------------
## \def BINARY_PREFIX
## \brief Sets the prefix of the binary file according to the configuration.
##
BINARY_PREFIX =

## \def BINARY_EXT
## \brief Sets the extension of the binary file according to the configuration.
##
BINARY_EXT =

# Definitions of specific prefix and extensions for each OS type.
ifeq ($(findstring Win,${OS_TYPE}), Win)
  LIB_PREFIX = 
  LIB_EXT = lib
  SHARED_EXT = dll
  EXE_EXT = exe
else
  LIB_PREFIX = lib
  LIB_EXT = a
  SHARED_EXT = so
  EXE_EXT = 
endif

# Creates prefix and extension for the binary file
ifeq (${BINARY_TYPE}, exe)
  BINARY_EXT = $(if $(EXE_EXT),.$(EXE_EXT),)
else
  ifeq (${BINARY_TYPE}, shared)
    BINARY_EXT = $(if $(SHARED_EXT),.$(SHARED_EXT),)
  else
    BINARY_EXT = $(if $(LIB_EXT),.$(LIB_EXT),)
  endif
  BINARY_PREFIX = $(LIB_PREFIX)
endif

# ---------------------------
# SETS PROJECT SUBDIRECTORIES
# ---------------------------
## \def BIN_DIR_NAME
## \brief Sets directory name where binary files are stored
##
BIN_DIR_NAME := build
## \def SRC_DIR_NAME
## \brief Sets directory name where source files are stored
##
SRC_DIR_NAME := src
## \def INC_DIR_NAME
## \brief Sets directory name where header files are stored
##
INC_DIR_NAME := include
## \def LOG_DIR_NAME
## \brief Sets directory name where log files are stored
##
LOG_DIR_NAME := log
## \def TEST_DIR_NAME
## \brief Sets directory name where testing source files are stored
##
TEST_DIR_NAME := test

## \def TEST_RC_DIR_NAME
## \brief Sets directory name where testing ressources files are stored
##
TEST_RC_DIR_NAME := rc

## \def PROJECT_DIR
## \brief Reads actual directory corresponding to project name
##
PROJECT_DIR := ${PWD}

## \def WORKSPACE_DIR
## \brief Defines Workspace directory
##
WORKSPACE_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)

## \def SRC_DIR
## \brief Defines the parent directory of sources
##
SRC_DIR := ${SRC_DIR_NAME}

## \def SRC_SUBDIR
## \brief Defines the sub-directories of sources
##
SRC_SUBDIR := $(shell cd $(PROJECT_DIR)/$(SRC_DIR) && ls -d */ 2>/dev/null)

## \def INC_DIR
## \brief Defines directory for header files to be deployed with
##  the project binary.
##
INC_DIR := ${INC_DIR_NAME}

## \def TEST_INC_DIR
## \brief Defines directory for header files required for unit testing
##
TEST_INC_DIR := ${INC_DIR_NAME}

## \def TEST_DIR
## \brief Defines the parent directory of unit testing sources
##
TEST_DIR:= $(TEST_DIR_NAME)

## \def BIN_DIR
## \brief Defines the parent directory of binaries
##
BIN_DIR := ${BIN_DIR_NAME}

## \def OBJ_DIR
## \brief Defines directory where the object files will be stored during compilation.
##
OBJ_DIR := $(BIN_DIR)/$(CONFIG)_$(TARGET_ARCH)

## \def LOG_DIR
## \brief Defines directory where the report files will be stored.
##
LOG_DIR := ${LOG_DIR_NAME}

# ----------------------------------
# READS REVISION AND VERSION NUMBERS
# ----------------------------------
## \def REV_NUMBER
## \brief Contains the revision number. This number is read from REV_NUMBER_FILE.
##
REV_NUMBER := $(shell cat $(REV_NUMBER_FILE))

## \def VERS_NUMBER
## \brief Contains the version number. This number is read from VERS_NUMBER_FILE.
##
ifneq ("$(wildcard $(VERS_NUMBER_FILE))","")
  VERS_NUMBER := $(shell cat $(VERS_NUMBER_FILE))
  DUMMY_VAR := $(subst ., ,$(VERS_NUMBER))

  MAJ_VERSION := $(word 1, $(DUMMY_VAR))
  MIN_VERSION := $(word 2, $(DUMMY_VAR))
  BUILD_VERSION := $(word 3, $(DUMMY_VAR))
endif

## \def C_SOURCES
## \brief Defines the list of c source files.
##
C_SOURCES := $(shell ls ${SRC_DIR}/*.c 2>/dev/null)
 C_SOURCES += $(shell ls ${SRC_DIR}/*/*.c 2>/dev/null)
 
## \def CXX_SOURCES
## \brief Defines the list of c++ source files.
##
CXX_SOURCES := $(shell ls ${SRC_DIR}/*.cpp 2>/dev/null)
 CXX_SOURCES += $(shell ls ${SRC_DIR}/*/*.cpp 2>/dev/null)
 
## \def C_TEST_SOURCES
## \brief Defines the list of unit tests c source files.
##
C_TEST_SOURCES :=

## \def CXX_TEST_SOURCES
## \brief Defines the list of unit tests c++ source files.
##
CXX_TEST_SOURCES :=

# add Unit testing source files in Test config
ifeq (${CONFIG}, Test)
  C_TEST_SOURCES += $(shell ls ${TEST_DIR}/*.c 2>/dev/null)
  CXX_TEST_SOURCES += $(shell ls ${TEST_DIR}/*.cpp 2>/dev/null)
endif

## \def SOURCES
## \brief Defines the list of c and c++ source files.
##
SOURCES = $(C_SOURCES) $(CXX_SOURCES) $(C_TEST_SOURCES) $(CXX_TEST_SOURCES)

# ---------------------------------------
# FIND OBJECT AND CREATE DEPENDENCY FILES
# ---------------------------------------
## \def OBJ_LIST
## \brief Defines the list of object files.
##
OBJ_LIST := $(patsubst %.c, %.o, $(filter %.c, $(SOURCES)))
 OBJ_LIST += $(patsubst %.cpp, %.o, $(filter %.cpp, $(SOURCES)))

# Modifies target directory of object files
 OBJECTS_TMP := $(subst $(SRC_DIR), $(OBJ_DIR)/$(SRC_DIR), $(OBJ_LIST))
## \def OBJECTS
## \brief Defines the list of object files.
##
OBJECTS = $(patsubst $(TEST_DIR)%, $(OBJ_DIR)/$(TEST_DIR)%, $(OBJECTS_TMP))
 
# Defines the list of dependency files from the list of object files. However the
# dependency files will be placed in the directory of the sources, it is therefore
# necessary to replace the name of the directory, which is done for the variable
# DEP_FILES.
# DEP_LIST = $(OBJECTS:.o=.d)

## \def DEP_FILES
## \brief Establish the list of dependency files from the list of object files.
##
DEP_FILES := $(OBJECTS:.o=.d)

# -----------------
# TOOLS DEFINITIONS
# -----------------
## \def LOCAL_ARCH
## \brief Stores host architecture 
##
LOCAL_ARCH := $(shell arch)

## \def ARM_FAMILY
## \brief Stores the ARM family.
##
##  The main values allowed are : cortex-a8, cortex-a9, ...
##
ARM_FAMILY := cortex-a8

# Sets prefix for specific compilator
ifneq (${TARGET_ARCH}, ${LOCAL_ARCH})
  ifeq (${TARGET_ARCH}, arm)
    CROSS_COMPILE ?= arm-linux-gnueabi-
  endif
  ifeq (${TARGET_ARCH}, armhf)
    CROSS_COMPILE ?= arm-linux-gnueabihf-
  endif
  ifeq (${TARGET_ARCH}, win32)
    CROSS_COMPILE ?= i686-w64-mingw32-
  endif
  ifeq (${TARGET_ARCH}, win64)
    CROSS_COMPILE ?= x86_64-w64-mingw32-
  endif
endif

# If it's default variables, we redefine them
ifeq ($(origin CC),default)
## \def AR
## \brief Stores archiver command
##
AR = $(CROSS_COMPILE)ar -rcs

## \def AS
## \brief Stores assembler command
##
AS = "$(CROSS_COMPILE)as "

## \def CC
## \brief Stores C compilator executable
##
CC = "$(CROSS_COMPILE)gcc"

## \def CPP
## \brief Stores C compilator executable for preprocess only
##
CPP = "$(CROSS_COMPILE)gcc -E"

## \def CXX
## \brief Stores C++ compilator executable
##
CXX = "$(CROSS_COMPILE)g++"

## \def GDB
## \brief Stores archiver command
##
GDB = "$(CROSS_COMPILE)gdb"

## \def LD
## \brief Stores linker command
##
LD = "$(CROSS_COMPILE)ld "

## \def NM
## \brief Stores xxx command
##
NM = "$(CROSS_COMPILE)nm"

## \def STRIP
## \brief Stores xxx command
##
STRIP = "$(CROSS_COMPILE)strip"

## \def OBJCOPY
## \brief Stores xxx command
##
OBJCOPY = "$(CROSS_COMPILE)objcopy"

## \def OBJDUMP
## \brief Stores xxx command
##
OBJDUMP = "$(CROSS_COMPILE)objdump"

## \def RANLIB
## \brief Stores xxx command
##
RANLIB = "$(CROSS_COMPILE)ranlib"
else
AR += "-rcs"
endif

## \def RM
## \brief Stores remove command
##
RM = rm -f

## \def ARM_FLAGS
## \brief Stores specific ARM flags for compilation and linking.
##
ARM_FLAGS = -mcpu=$(ARM_FAMILY) -mthumb

## \def COMMON_FLAGS
## \brief Defines the C and C++ common flags (compilation and linking)
##
COMMON_FLAGS = -fmessage-length=0 -fsigned-char -ffunction-sections -fdata-sections -Wall -Wextra

## \def COMPIL_FLAGS
## \brief Defines the C and C++ common compilation flags
##
COMPIL_FLAGS = $(COMMON_FLAGS) -ansi -pedantic
ifeq (${CONFIG}, Test)
  COMPIL_FLAGS += -fprofile-arcs -ftest-coverage
endif

## \def CFLAGS
## \brief Defines the C compilation flags
##
CFLAGS ?= $(COMPIL_FLAGS)
 CFLAGS += -std=gnu11 $(PRE_DEFINED) 

## \def CXXFLAGS
## \brief Defines the C++ compilation flags
##
CXXFLAGS ?= $(COMPIL_FLAGS)
 CXXFLAGS += -std=gnu++11 $(PRE_DEFINED) 
 
## \def LDFLAGS
## \brief Defines the linker flags
##
LDFLAGS ?= $(COMMON_FLAGS) -Xlinker --gc-sections -Wl,-Map,"$(LOG_DIR)/$(PROJECT_NAME)$(TYPE_SUFFIX)-$(VERSION).map"
ifeq (${CONFIG}, Test)
  CFLAGS +=-fprofile-arcs -ftest-coverage 
  CFLAGS += -include CppUTest/MemoryLeakDetectorMallocMacros.h
  CXXFLAGS +=-fprofile-arcs -ftest-coverage
  CXXFLAGS += -include CppUTest/MemoryLeakDetectorNewMacros.h
  LDFLAGS += -fprofile-arcs
endif

## \def DEP_LIB_PATH
## \brief Variable used to define the contents of LD_LIBRARY_PATH ('dependencies' rule)
##
DEP_LIB_PATH:=

ifneq ($(LIB_DIR),)
  $(foreach lib_dir,$(LIB_DIR),$(eval LDFLAGS+=-L$(lib_dir)))
  $(foreach lib_dir,$(LIB_DIR),$(eval DEP_LIB_PATH:=$(DEP_LIB_PATH):$(lib_dir)))
endif

ifneq ($(TEST_LIB_DIR),)
  $(foreach lib_dir,$(TEST_LIB_DIR),$(eval LDFLAGS+=-L$(lib_dir)))
  $(foreach lib_dir,$(LIB_DIR),$(eval DEP_LIB_PATH:=$(DEP_LIB_PATH):$(lib_dir)))
endif

ifneq ($(findstring pthread, $(DEPENDENCIES)),)
  COMMON_FLAGS += -pthread
endif
  
ifeq (${BINARY_TYPE},shared)
  CFLAGS += -fPIC
  CXXFLAGS += -fPIC
  LDFLAGS += -fPIC -shared
  ifeq ($(findstring Linux,${OS_TYPE}), Linux)
    LDFLAGS += -Wl,-soname,$(BINARY_NAME).$(SHARED_EXT).$(MAJ_VERSION)
  endif
endif

ifeq (${BINARY_TYPE},lib)
  CFLAGS += -fPIC
  CXXFLAGS += -fPIC
  LDFLAGS += -fPIC
endif

ifeq (${CONFIG}, Release)
  ifdef OPTIMIZE_FOR_SIZE
    CFLAGS += -Os
  else
    CFLAGS += -O3
  endif
  CXXFLAGS +=
  TYPE_SUFFIX := 
else
  CFLAGS += -ggdb -Og
  CXXFLAGS += -ggdb -Og
  TYPE_SUFFIX := _d
endif

ifeq (${TARGET_ARCH}, arm)
  COMMON_FLAGS += $(ARM_FLAGS)
endif
ifeq (${TARGET_ARCH}, armhf)
  COMMON_FLAGS += $(ARM_FLAGS)
endif
ifeq (${TARGET_ARCH}, win32)

endif
ifeq (${TARGET_ARCH}, win64)

endif

# Sets dependencies flags
# ------------------------------------------------------------------------------
# Take the Debug binary when Test config is active
ifeq ($(CONFIG), Test)
  DEP_CONFIG := Debug
else
  DEP_CONFIG := $(CONFIG)
endif

define display_message
	echo $(COLOR)$(1)$(END_COLOR);
endef

# find_headers function
# Search for headers in the specified workspace directory 
# -------------------------------------------------------
define find_headers
$(eval DEFAULT_DIR := $(WORKSPACE_DIR)/$(1));
$(if $(or $(wildcard $(DEFAULT_DIR)/*.h*), \
          $(wildcard $(DEFAULT_DIR)/*/*.h*)), \
              $(eval INCLUDE += -I$(DEFAULT_DIR)); \
              $(eval INCLUDE_DIR += $(DEFAULT_DIR)); \
              $(eval NOT_IN_WORKSPACE =),);
endef
# ----------------------------------------------------


# find_dependency function
# gcc flags generating for include files and libraries
# ----------------------------------------------------
define find_dependency
$(eval LIB_NAME := $(strip $(1)));     # Removes spaces
$(eval LIB_VERSION :=);
$(eval CUR_LIB_EXT := $(SHARED_EXT));  # Default extension
$(eval SUFFIX :=);
$(eval NOT_IN_WORKSPACE = 1);
$(eval LIB_SEARCH = 1);     # By default, we search library

# For static library, remove '[ ]'
$(if $(findstring [,$(LIB_NAME)),
    $(eval CUR_LIB_EXT := $(LIB_EXT)); \
    $(eval LIB_NAME := $(subst [,,$(LIB_NAME))); \
    $(eval LIB_NAME := $(subst ],,$(LIB_NAME))),
); 

# For specific version, remove ':'    
$(if $(findstring :,$(LIB_NAME)),
    $(eval LIB_NAME := $(subst :, ,$(LIB_NAME))); \
    $(eval LIB_VERSION := $(lastword $(LIB_NAME))); \
    $(eval LIB_NAME := $(firstword $(LIB_NAME))),
);

# For headers only, remove '@'    
$(if $(findstring @,$(LIB_NAME)),
    $(eval LIB_NAME := $(subst @,,$(LIB_NAME))); \
    $(eval LIB_SEARCH =),
);       

# Search directories for headers, in the workspace
$(call find_headers,$(LIB_NAME)/$(INC_DIR_NAME));
$(call find_headers,$(LIB_NAME)/$(SRC_DIR_NAME)/$(INC_DIR_NAME));
$(call find_headers,$(LIB_NAME)/$(SRC_DIR_NAME));

$(eval CUR_LIB_PATH = $(WORKSPACE_DIR)/$(LIB_NAME)/$(BIN_DIR_NAME)/$(DEP_CONFIG)_$(TARGET_ARCH));
$(eval CUR_LIB = $(LIB_PREFIX)$(LIB_NAME));

$(if $(wildcard $(CUR_LIB_PATH)/*), \
                $(eval SUFFIX = $(TYPE_SUFFIX)),);
$(if $(or $(wildcard $(CUR_LIB_PATH)/$(CUR_LIB)$(SUFFIX).$(LIB_EXT)*), \
          $(wildcard $(CUR_LIB_PATH)/$(CUR_LIB)$(SUFFIX).$(SHARED_EXT)*)
      ), \
      $(eval LDFLAGS += -L$(CUR_LIB_PATH) -l$(LIB_NAME)$(SUFFIX)); \
      $(eval DEP_LIB_PATH:=$(DEP_LIB_PATH):$(CUR_LIB_PATH)),);

# The library exists outside the workspace
$(if $(and $(NOT_IN_WORKSPACE),$(LIB_SEARCH)), \
                $(eval LDFLAGS += -l$(LIB_NAME)$(SUFFIX)));
endef
# ----------------------------------------------------

# Search all dependencies
$(foreach lib,$(DEPENDENCIES),$(call find_dependency,$(lib)))

# The include and src directories of the project are still
# in the search path of the headers.
$(eval INCLUDE += -I$(SRC_DIR) -I$(INC_DIR));

ifeq (${CONFIG}, Test)
  $(foreach lib,$(TEST_LIB),$(call find_dependency,$(lib)))
  $(foreach lib,$(TEST_DEPENDENCIES),$(call find_dependency,$(lib)))
endif
# ------------------------------------------------------------------------------
ifeq (${BINARY_TYPE},exe)
  BINARY_NAME = $(BINARY_PREFIX)$(PROJECT_NAME)$(TYPE_SUFFIX)-$(VERSION)
  BINARY_FILE = $(BINARY_NAME)$(BINARY_EXT)
  TARBALL_NAME = ${BINARY_NAME}_rev${REV_NUMBER}_${CONFIG}_${TARGET_ARCH}.tar.gz 
else
  BINARY_NAME = $(BINARY_PREFIX)$(PROJECT_NAME)$(TYPE_SUFFIX)
  BINARY_FILE = $(BINARY_NAME)$(BINARY_EXT).$(VERSION)
  TARBALL_NAME = ${BINARY_NAME}-$(VERSION)_rev${REV_NUMBER}_${CONFIG}_${TARGET_ARCH}.tar.gz 
endif
## @}
##
#-------------------------------------------------------------------------------
vpath %.h $(SRC_DIR) $(INC_DIR) $(TEST_DIR) $(INCLUDE_DIR)

without_target: help

all: $(REV_NUMBER_FILE) $(OBJ_DIR)/$(BINARY_FILE) finalize #= Builds project

# Objects link editing
$(OBJ_DIR)/$(BINARY_FILE) : $(OBJECTS)
	@echo "$(COLOR)--> Linking object files$(END_COLOR)"
ifeq (${BINARY_TYPE},lib)
	$(AR) $@ $^ 
else
	$(CXX) -o $@ $^ $(LDFLAGS) 
endif

# Dependencies File creation
# with rules "$(OBJ_DIR)%.o: <dependencies>"
$(OBJ_DIR)/$(SRC_DIR_NAME)/%.d: $(SRC_DIR)/%.c
	@echo "$(COLOR)--> Creates dependencies files (1) for $<$(END_COLOR)"
	$(CXX) -MM -MG $< | sed -e "s@^\(.*\)\.o:@\$(OBJ_DIR)/$(SRC_DIR_NAME)/\1.o:@" > $@

$(OBJ_DIR)/$(SRC_DIR_NAME)/%.d: $(SRC_DIR)/%.cpp
	@echo "$(COLOR)--> Creates dependencies files (2) for $<$(END_COLOR)"
	$(CXX) -MM -MG $< | sed -e "s@^\(.*\)\.o:@\$(OBJ_DIR)/$(SRC_DIR_NAME)/\1.o:@" > $@

$(OBJ_DIR)/$(TEST_DIR_NAME)/%.d: $(TEST_DIR)/%.c
	@echo "$(COLOR)--> Creates dependencies files (3) for $<$(END_COLOR)"
	$(CXX) -MM -MG $< | sed -e "s@^\(.*\)\.o:@\$(OBJ_DIR)/$(TEST_DIR_NAME)/\1.o:@" > $@

$(OBJ_DIR)/$(TEST_DIR_NAME)/%.d: $(TEST_DIR)/%.cpp
	@echo "$(COLOR)--> Creates dependencies files (4) for $<$(END_COLOR)"
	$(CXX) -MM -MG $< | sed -e "s@^\(.*\)\.o:@\$(OBJ_DIR)/$(TEST_DIR_NAME)/\1.o:@" > $@

# Sources compilation
$(OBJ_DIR)/$(SRC_DIR_NAME)/%.o: $(SRC_DIR)/%.c $(OBJ_DIR)/$(SRC_DIR_NAME)/%.d
	@echo "$(COLOR)--> Compiling C source file $<$(END_COLOR)"
	$(CC) $(CFLAGS) $(INCLUDE) -o $@ -c $<;

$(OBJ_DIR)/$(SRC_DIR_NAME)/%.o: $(SRC_DIR)/%.cpp $(OBJ_DIR)/$(SRC_DIR_NAME)/%.d
	@echo "$(COLOR)--> Compiling C++ source file $<$(END_COLOR)";
	$(CXX) $(CXXFLAGS) $(INCLUDE) -o $@ -c $<;

$(OBJ_DIR)/$(TEST_DIR_NAME)/%.o: $(TEST_DIR_NAME)/%.c $(OBJ_DIR)/$(TEST_DIR_NAME)/%.d
	@echo "$(COLOR)--> Compiling C source file $<$(END_COLOR)"
	$(CC) $(CFLAGS) $(INCLUDE) -o $@ -c $<;

$(OBJ_DIR)/$(TEST_DIR_NAME)/%.o: $(TEST_DIR_NAME)/%.cpp $(OBJ_DIR)/$(TEST_DIR_NAME)/%.d
	@echo "$(COLOR)--> Compiling C++ source file $<$(END_COLOR)";
	$(CXX) $(CXXFLAGS) $(INCLUDE) -o $@ -c $<;
			
finalize: clear_tarball
	@echo "$(COLOR)--> Symbolic links creation$(END_COLOR)"
	@ln -s -f -r $(OBJ_DIR)/$(BINARY_FILE) \
		$(OBJ_DIR)/$(BINARY_PREFIX)$(PROJECT_NAME)$(TYPE_SUFFIX)$(BINARY_EXT)
ifeq (${CONFIG}, Test)
	@echo "$(COLOR)--> Cppcheck report creation$(END_COLOR)"
	@mkdir -p $(PROJECT_DIR)/${LOG_DIR_NAME}
	@/usr/bin/cppcheck --xml-version=2 --enable=all ./${SRC_DIR_NAME}/ 2> ./${LOG_DIR_NAME}/${PROJECT_NAME}.xml
else
  ifeq (${BINARY_TYPE}, shared)
		@ln -s -f -r $(OBJ_DIR)/$(BINARY_FILE) \
		      $(OBJ_DIR)/$(BINARY_PREFIX)$(PROJECT_NAME)$(TYPE_SUFFIX)$(BINARY_EXT).${MAJ_VERSION}.${MIN_VERSION}
		@ln -s -f -r $(OBJ_DIR)/$(BINARY_FILE) \
		      $(OBJ_DIR)/$(BINARY_PREFIX)$(PROJECT_NAME)$(TYPE_SUFFIX)$(BINARY_EXT).${MAJ_VERSION}
  endif
	@echo "$(COLOR)--> Tarball creation$(END_COLOR)"
	@cd $(OBJ_DIR) && tar --exclude=*.o -zcf ../${TARBALL_NAME} $(BINARY_PREFIX)$(PROJECT_NAME)$(TYPE_SUFFIX)*
	@cd $(PROJECT_DIR)
endif

dependencies: #= Creates a file to configure the LD_LIBRARY_PATH variable.
	@echo "$(COLOR)--> Génération du fichier $(PROJECT_NAME).dep$(END_COLOR)"
	@echo "export LD_LIBRARY_PATH=$$\c" > $(PROJECT_DIR)/$(PROJECT_NAME).dep
	@echo "{LD_LIBRARY_PATH}$(DEP_LIB_PATH)" >> $(PROJECT_DIR)/$(PROJECT_NAME).dep

display_config: #= Display configuration variables
	@echo $(COLOR)Build Variables$(END_COLOR)
	@echo ---------------
	@echo "AR=$(AR)"
	@echo "AS=$(AS)"
	@echo "CC=$(CC)"
	@echo "CPP=$(CPP)"
	@echo "CXX=$(CXX)"
	@echo "LD=$(LD)"
	@echo "GDB=$(GDB)"
	@echo "STRIP=$(STRIP)"
	@echo
	@echo $(COLOR)Directories list$(END_COLOR)
	@echo ----------------
	@echo "* SRC_DIR=$(SRC_DIR)"
	@echo "* SRC_SUBDIR=$(SRC_SUBDIR)"
	@echo "* TEST_DIR=$(TEST_DIR)"
	@echo "* BIN_DIR=$(BIN_DIR)"
	@echo "* LIB_DIR=$(LIB_DIR)"
	@echo "* TEST_LIB_DIR=$(TEST_LIB_DIR)"
	@echo "* INC_DIR=$(INC_DIR)"
	@echo "* TEST_INC_DIR=$(TEST_INC_DIR)"
	@echo "* OBJ_DIR=$(OBJ_DIR)"
	@echo "* DEFAULT_LIB_DIR=$(DEFAULT_LIB_DIR)"
	@echo "* PROJECT_DIR=$(PROJECT_DIR)"
	@echo "* WORKSPACE_DIR=$(WORKSPACE_DIR)"
	@echo "* DEP_LIB_PATH=$(DEP_LIB_PATH)"
	@echo
	@echo $(COLOR)Build informations$(END_COLOR)
	@echo ------------------
	@echo "* CONFIG=$(CONFIG)"
	@echo "* TARGET_ARCH=$(TARGET_ARCH)"
	@echo "* OS_TYPE=$(OS_TYPE)"
	@echo "* CXX=$(CXX)"
	@echo "* CC=$(CC)"
	@echo "* LDFLAGS=$(LDFLAGS)"
	@echo "* CFLAGS=$(CFLAGS)"
	@echo "* CXXFLAGS=$(CXXFLAGS)"
	@echo "* PRE_DEFINED=$(PRE_DEFINED)"
	@echo
	@echo $(COLOR)Files informations$(END_COLOR)
	@echo ------------------
	@echo "* BINARY_TYPE=$(BINARY_TYPE)"
	@echo "* BINARY_FILE=$(BINARY_FILE)"
	@echo "* TARBALL_NAME=$(TARBALL_NAME)"
	@echo "* DEPENDENCIES=$(DEPENDENCIES)"
	@echo "* TEST_DEPENDENCIES=$(TEST_DEPENDENCIES)"
	@echo "* TEST_LIB=$(TEST_LIB)"
	@echo "* SOURCES=$(SOURCES)"
	@echo "* C_SOURCES=$(C_SOURCES)"
	@echo "* CXX_SOURCES=$(CXX_SOURCES)"
	@echo "* C_TEST_SOURCES=$(C_TEST_SOURCES)"
	@echo "* CXX_TEST_SOURCES=$(CXX_TEST_SOURCES)"
	@echo "* OBJ_LIST=$(OBJ_LIST)"
	@echo "* OBJECTS_TMP=$(OBJECTS_TMP)"
	@echo "* OBJECTS=$(OBJECTS)"
	@echo "* DEP_FILES=$(DEP_FILES)"
	@echo "* LOCAL_ARCH=$(LOCAL_ARCH)"
	@echo "* TYPE_SUFFIX=$(TYPE_SUFFIX)"
	@echo "* INCLUDE=$(INCLUDE)"
	@echo "* VERSION=$(MAJ_VERSION).$(MIN_VERSION).$(BUILD_VERSION)"
	@echo "* REV_NUMBER=$(REV_NUMBER)"

clear_tarball: #= Clear all packages
	@$(RM) -f $(TARBALL_NAME)
	
clean: #= Delete object files
	@$(RM) $(OBJECTS)
	@$(RM) $(SRC_DIR)/*.d
	
mrproper: clean clear_tarball #= Clear all generated files
	@$(RM) $(OBJ_DIR)/$(BINARY_PREFIX)$(PROJECT_NAME)$(TYPE_SUFFIX)*$(BINARY_EXT)
	@$(RM) $(LOG_DIR)/*.*

help: $(MAKEFILE_LIST) #= This help message
	@echo Available $< targets are :
	@grep -E '(^[a-zA-Z_-]+:.*?#=.*$$)' $< | awk 'BEGIN {FS = ":.*?#= "}; {printf "\033[32m- %-15s\033[0m %s\n", $$1, $$2}'
	@echo 

ifeq ($(MAKECMDGOALS),all)
  $(info $(COLOR)--> Creates missing directories$(END_COLOR))
  $(shell mkdir -p $(OBJ_DIR)/$(SRC_DIR_NAME))
  $(shell for i in ${SRC_SUBDIR} ; do mkdir -p $(OBJ_DIR)/$(SRC_DIR_NAME)/$$i ; done)
  $(shell mkdir -p $(OBJ_DIR)/$(TEST_DIR_NAME))
  $(shell mkdir -p $(LOG_DIR))

  # Copy test ressources into test directory
  $(shell cp -R $(TEST_DIR_NAME)/$(TEST_RC_DIR_NAME)/* $(OBJ_DIR)/)

  #  DUMMY_VAR := $(error erreur)
  # Includes dependencies
  -include $(DEP_FILES)
  # Includes revision number rules.
  include revnumber.mak
endif

##
## @}

##
## @}

