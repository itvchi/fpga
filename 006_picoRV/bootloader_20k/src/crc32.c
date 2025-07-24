
#include "crc32.h"
#include "macros.h"

typedef struct {
    volatile uint32_t CONFIG;
    volatile uint32_t POLYNOMIAL;
    volatile uint32_t DATA_IN;
    volatile uint32_t CRC_DATA;  
} Crc32_TypeDef;

#define CRC32_BASE  0x80000500
#define CRC32        ((Crc32_TypeDef *) CRC32_BASE)

#define CRC32_CONFIG_RESET_BIT_Pos  (0U)
#define CRC32_CONFIG_RESET_BIT      (1 << CRC32_CONFIG_RESET_BIT_Pos)
#define CRC32_CONFIG_ENABLE_BIT_Pos (1U)
#define CRC32_CONFIG_ENABLE_BIT     (1 << CRC32_CONFIG_ENABLE_BIT_Pos)
#define CRC32_CONFIG_DATA_WIDTH_Pos (2U)
#define CRC32_CONFIG_DATA_WIDTH_Msk (0b11 << CRC32_CONFIG_DATA_WIDTH_Pos)

void crc32_init(crc32_data_in_width_t data_in_width) { /* uint32_t polynomial */

    SET_BIT(CRC32->CONFIG, CRC32_CONFIG_RESET_BIT); /* Reset */
    while (READ_BIT(CRC32->CONFIG, CRC32_CONFIG_RESET_BIT)); /* Wait until reset done */

    SET_BIT(CRC32->CONFIG, CRC32_CONFIG_ENABLE_BIT); /* Enable uart */
    MODIFY_REG(CRC32->CONFIG, CRC32_CONFIG_DATA_WIDTH_Msk, data_in_width << CRC32_CONFIG_DATA_WIDTH_Pos);
}

void crc32_reset(crc32_data_in_width_t data_in_width) {

    (void) data_in_width;
}

void crc32_push(uint32_t data) {

    CRC32->DATA_IN = data;
}

uint32_t crc32_get() {

    return CRC32->CRC_DATA;
}