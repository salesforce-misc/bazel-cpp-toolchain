#ifndef CONFIG_WINDOWS
#include <chrono>
#include <thread>
// Uninitialized global
int global;
__attribute__((optnone)) int main() {
   // Creates race as access to global is not synchronized
   // Note: We perform updates for 500ms, because thread sanitizer has an intentional
   // trade-off between performance and some false negatives (see https://github.com/google/sanitizers/issues/1576).
   // If a single update is done by each thread, we'll see a few instances where the race is not detected. By doing many
   // updates, we reduce the false negative likelihood significantly
   const auto start = std::chrono::steady_clock::now();
   std::thread t1([&] {do {++global;} while (std::chrono::steady_clock::now() - start < std::chrono::milliseconds{500}); });
   std::thread t2([&] {do {--global;} while (std::chrono::steady_clock::now() - start < std::chrono::milliseconds{500}); });
   t1.join();
   t2.join();
   return 0;
}
#else
int main() {
}
#endif
