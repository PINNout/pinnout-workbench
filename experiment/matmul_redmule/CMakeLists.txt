# Generated from experiment/templates/CMakeLists.txt.in by compile.sh.
set(TEST_NAME matmul_redmule)

file(GLOB_RECURSE TEST_SRCS "src/*.c")

add_executable(${TEST_NAME} ${TEST_SRCS})

target_include_directories(${TEST_NAME} PUBLIC
  include                                          # matmul_redmule.h, matmul_redmule_data.h
  ${CMAKE_CURRENT_LIST_DIR}/../templates           # compare.h
  ${CMAKE_SOURCE_DIR}/kernels/common               # kernels_compare_utils.h
  ${CMAKE_SOURCE_DIR}/targets/${TARGET_PLATFORM}/include/utils
)

target_compile_options(${TEST_NAME} PRIVATE -O2)
target_link_libraries(${TEST_NAME} PUBLIC runtime hal)
