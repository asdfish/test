define GET_SOURCE_FILES
$(patsubst src/%.$(1),$\
	build/%.$(1).o,$\
	$(shell find src -name '*.$(1)' -type f))
endef

CC ?= cc
CXX ?= c++

CFLAGS ?= -O2 -march=native -pipe
CXXFLAGS ?= $(CFLAGS)

COMMONFLAGS := -Wall -Wextra -Wpedantic $\
							 -Iinclude

C_STANDARD := -std=c99
CXX_STANDARD := -std=c++98

OBJECT_FILES := $(call GET_SOURCE_FILES,c) $\
								$(call GET_SOURCE_FILES,cpp)

PROCESS_HEADER_FILES := yes
define GET_PROCESSED_HEADER_FILES
$(if ${PROCESS_HEADER_FILES},$\
	$(subst .$(1),$\
		$(if $(findstring clang,${CC}${CXX}),$\
			.$(1).pch,$\
			.$(1).gch),$\
		$(shell find include -name '*.$(1)' -type f)))
endef

PROCESSED_HEADER_FILES := $(call GET_PROCESSED_HEADER_FILES,h) $\
													$(call GET_PROCESSED_HEADER_FILES,hpp)

TEST_REQUIREMENTS := ${PROCESSED_HEADER_FILES} ${OBJECT_FILES}

define C_COMPILE
${CC} -c $1 ${C_STANDARD} ${CFLAGS} ${COMMONFLAGS} -o $2

endef
define CXX_COMPILE
${CXX} -c $1 ${CXX_STANDARD} ${CXXFLAGS} ${COMMONFLAGS} -o $2

endef

define REMOVE
$(if $(wildcard $(1)),$\
	rm -rf $(1))

endef
define REMOVE_LIST
$(foreach ITEM,$\
	$(1),$\
	$(call REMOVE,${ITEM}))
endef

define RESET_DIRECTORY
$(call REMOVE,$(1))
mkdir $1

endef
define RESET_DIRECTORIES
$(foreach DIRECTORY,$\
	$(1),$\
	$(call RESET_DIRECTORY,${DIRECTORY}))
endef

all: test

build/%.c.o: src/%.c
	$(call C_COMPILE,$<,$@)
build/%.cpp.o: src/%.cpp
	$(call CXX_COMPILE,$<,$@)

%.h.gch: %.h
	$(call C_COMPILE,$<,$@)
%.h.pch: %.h
	$(call C_COMPILE,$<,$@)
%.hpp.gch: %.h
	$(call CXX_COMPILE,$<,$@)
%.hpp.pch: %.h
	$(call CXX_COMPILE,$<,$@)

test: ${TEST_REQUIREMENTS}
	${CXX} ${OBJECT_FILES} ${CXX_STANDARD} ${CXXFLAGS} ${COMMONFLAGS} -o $@

clean:
	$(call REMOVE_LIST,${TEST_REQUIREMENTS})
	$(call REMOVE,test)
	$(call RESET_DIRECTORIES,include src)
	echo '#include <stdio.h>' >> src/main.c
	echo 'int main(void) {' >> src/main.c
	echo '  printf("Hello world.\n");' >> src/main.c
	echo '  return 0;' >> src/main.c
	echo '}' >> src/main.c

.PHONY: all clean
