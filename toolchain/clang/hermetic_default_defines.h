#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wbuiltin-macro-redefined"

#undef __DATE__
#undef __TIMESTAMP__
#undef __TIME__

#define __DATE__ "redacted"
#define __TIMESTAMP__ "redacted"
#define __TIME__ "redacted"

#pragma clang diagnostic pop
