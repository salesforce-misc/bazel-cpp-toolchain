#include <iostream>
#include <string>

int main() {
   auto expected_version = EXPECTED_CPP_VERSION;
   auto actual_version = __cplusplus;

   if (actual_version != expected_version) {
      std::cerr << "This test file was compiled with a different C++ version than speficied via the Bazel toolchain feature. This is probably caused by a bug in the toolchain." << std::endl;
      std::cerr << "Expected value of __cplusplus: " << expected_version << std::endl;
      std::cerr << "Actual value of __cplusplus: " << actual_version << std::endl;
      return 1;
   }
   return 0;
}
