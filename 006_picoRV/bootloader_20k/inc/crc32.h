#ifndef _CRC32_H_
#define _CRC32_H_

#include <stdbool.h>
#include <stdint.h>

typedef enum {
    CRC32_DATA_IN_BYTE,
    CRC32_DATA_IN_HALF_WORD,
    CRC32_DATA_IN_WORD
} crc32_data_in_width_t;

void crc32_init(crc32_data_in_width_t data_in_width); /* uint32_t polynomial */
void crc32_reset(crc32_data_in_width_t data_in_width);
void crc32_push(uint32_t data);
uint32_t crc32_get();

#endif /* _CRC32_H_ */