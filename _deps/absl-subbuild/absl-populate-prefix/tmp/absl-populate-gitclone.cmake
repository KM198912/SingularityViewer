
if(NOT "/Users/devil/singularity/_deps/absl-subbuild/absl-populate-prefix/src/absl-populate-stamp/absl-populate-gitinfo.txt" IS_NEWER_THAN "/Users/devil/singularity/_deps/absl-subbuild/absl-populate-prefix/src/absl-populate-stamp/absl-populate-gitclone-lastrun.txt")
  message(STATUS "Avoiding repeated git clone, stamp file is up to date: '/Users/devil/singularity/_deps/absl-subbuild/absl-populate-prefix/src/absl-populate-stamp/absl-populate-gitclone-lastrun.txt'")
  return()
endif()

execute_process(
  COMMAND ${CMAKE_COMMAND} -E remove_directory "/Users/devil/singularity/_deps/absl-src"
  RESULT_VARIABLE error_code
  )
if(error_code)
  message(FATAL_ERROR "Failed to remove directory: '/Users/devil/singularity/_deps/absl-src'")
endif()

# try the clone 3 times in case there is an odd git clone issue
set(error_code 1)
set(number_of_tries 0)
while(error_code AND number_of_tries LESS 3)
  execute_process(
    COMMAND "/usr/bin/git"  clone  "https://github.com/abseil/abseil-cpp.git" "absl-src"
    WORKING_DIRECTORY "/Users/devil/singularity/_deps"
    RESULT_VARIABLE error_code
    )
  math(EXPR number_of_tries "${number_of_tries} + 1")
endwhile()
if(number_of_tries GREATER 1)
  message(STATUS "Had to git clone more than once:
          ${number_of_tries} times.")
endif()
if(error_code)
  message(FATAL_ERROR "Failed to clone repository: 'https://github.com/abseil/abseil-cpp.git'")
endif()

execute_process(
  COMMAND "/usr/bin/git"  checkout ab3552a18964e7063c8324f45b3896a6a20b08a8 --
  WORKING_DIRECTORY "/Users/devil/singularity/_deps/absl-src"
  RESULT_VARIABLE error_code
  )
if(error_code)
  message(FATAL_ERROR "Failed to checkout tag: 'ab3552a18964e7063c8324f45b3896a6a20b08a8'")
endif()

execute_process(
  COMMAND "/usr/bin/git"  submodule update --recursive --init 
  WORKING_DIRECTORY "/Users/devil/singularity/_deps/absl-src"
  RESULT_VARIABLE error_code
  )
if(error_code)
  message(FATAL_ERROR "Failed to update submodules in: '/Users/devil/singularity/_deps/absl-src'")
endif()

# Complete success, update the script-last-run stamp file:
#
execute_process(
  COMMAND ${CMAKE_COMMAND} -E copy
    "/Users/devil/singularity/_deps/absl-subbuild/absl-populate-prefix/src/absl-populate-stamp/absl-populate-gitinfo.txt"
    "/Users/devil/singularity/_deps/absl-subbuild/absl-populate-prefix/src/absl-populate-stamp/absl-populate-gitclone-lastrun.txt"
  RESULT_VARIABLE error_code
  )
if(error_code)
  message(FATAL_ERROR "Failed to copy script-last-run stamp file: '/Users/devil/singularity/_deps/absl-subbuild/absl-populate-prefix/src/absl-populate-stamp/absl-populate-gitclone-lastrun.txt'")
endif()

