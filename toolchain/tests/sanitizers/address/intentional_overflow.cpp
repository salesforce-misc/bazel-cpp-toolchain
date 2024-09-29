// Intentionally overflowing test to ensure we get stack traces
// Based on https://github.com/google/sanitizers/wiki/AddressSanitizerExampleStackOutOfBounds
// However, the overflow is moved to a second function to verify stack traces with ASAN
__attribute__((optnone)) int overflow(int argc) {
   int stack_array[100];
   stack_array[1] = 0;
   return stack_array[argc + 100]; // BOOM
}

__attribute__((optnone)) int main(int argc, [[maybe_unused]] char** argv) {
   return overflow(argc);
}
