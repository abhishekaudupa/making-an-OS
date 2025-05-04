#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

void toBinary(uint16_t num, uint8_t bits) {
    printf("(");
    for(int i = 0; i < bits; ++i) {
	uint8_t pos = bits - 1 - i;
	uint16_t mask = (1U << pos);
	uint16_t post = (num & mask);
	if((pos+1) % 8 == 0)
	    printf(" ");
	printf("%d", post? 1: 0);
    }
    printf(")");
    printf("\n");
}

int main(int argc, char **argv) {
    if (argc < 2) {
	printf("Enter LBA\n");
	return 1;
    }

    uint16_t LBA = strtol(argv[1], NULL, 10);

#if 1
    uint16_t bpb_SecPerTrk = 63;
    uint16_t ebr_NumHeads = 16;

    uint16_t tempq = LBA / bpb_SecPerTrk;
    uint16_t tempr = LBA % bpb_SecPerTrk;

    uint16_t sec = tempr + 1;
    uint16_t head = tempq % ebr_NumHeads;
    uint16_t cyl = tempq / ebr_NumHeads;

    printf("C = 0x%x", cyl);
    toBinary(cyl, 10);
    printf("H = 0x%x", head);
    toBinary(head, 8);
    printf("S = 0x%x", sec);
    toBinary(sec, 6);

    uint8_t dh = head;
    uint8_t cl = sec;
    uint8_t ch = (cyl & 0xFF);
    cl |= ((cyl >> 2) & 0xC0);

    uint16_t cx = ((ch << 8) | cl);

    printf("dh = 0x%x", dh);
    toBinary(dh, 8);
    printf("cx = 0x%x", cx);
    toBinary(cx, 16);
#else
    toBinary(LBA, 8);
#endif
}

