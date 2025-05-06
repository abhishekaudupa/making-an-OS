#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

int main(int argc, char **argv) {

    uint64_t segDesc = 0;
    uint64_t dummy;

    uint32_t limit, base;
    uint8_t access, flags;

    printf("Enter segment base address: ");
    scanf("%x", &base);
    dummy = base;
    segDesc |= (((dummy & 0xFFFFFF) << 16) | ((dummy & 0xFF000000) << 32));

    printf("Enter limit: ");
    scanf("%x", &limit);
    dummy = limit;
    segDesc |= (dummy & 0xFFFF) | ((dummy >> 16) << 48);

    printf("4k granularity? 0/1: ");
    scanf("%lu", &dummy);
    if(dummy)
	flags = 0x8;

    printf("Mode:\n");
    printf("  16-bit -> 0\n");
    printf("  32-bit -> 1\n");
    printf("  64-bit -> 2\n");
    printf("   Choice: ");
    scanf("%lu", &dummy);
    switch(dummy) {
	case 0:
	    break;
	case 1:
	    flags |= (1 << 2);
	    break;
	case 2:
	    flags |= (1 << 1);
	    break;
    }

    dummy = flags;
    segDesc |= (dummy << 52);

    printf("Privilege Level: ");
    scanf("%lu", &dummy);
    access = dummy << 5;

    printf("Is System Segment? 0/1: ");
    scanf("%lu", &dummy);
    if(!dummy) {
	access |= 1 << 4;

	printf("Is Code Segment? 0/1: ");
	scanf("%lu", &dummy);
	if(dummy) {
	    access |= 1 << 3;

	    printf("Is Conforming? 0/1: ");
	    scanf("%lu", &dummy);
	    if(dummy)
		access |= 1 << 2;

	    printf("Is Readable? 0/1: ");
	    scanf("%lu", &dummy);
	    if(dummy)
		access |= 1 << 1;

	} else {
	    printf("Does Segment Grow Down? 0/1: ");
	    scanf("%lu", &dummy);
	    if(dummy)
		access |= 1 << 2;

	    printf("Is Writable? 0/1: ");
	    scanf("%lu", &dummy);
	    if(dummy)
		access |= 1 << 1;
	}
    }
    dummy = access;
    segDesc |= dummy << 40;

    printf("Segment Descriptor = 0x%lx\n", segDesc);
}
