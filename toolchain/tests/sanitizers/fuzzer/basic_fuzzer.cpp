#include <cstddef>
#include <cstdint>
#include <cstdlib>
extern "C" int LLVMFuzzerTestOneInput([[maybe_unused]] const uint8_t* data, [[maybe_unused]] size_t size) {
#ifdef FUZZING_BUILD_MODE_UNSAFE_FOR_PRODUCTION
   abort();
#else
   return data[size + 1];
#endif
}
