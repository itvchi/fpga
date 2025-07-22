#ifndef _MACROS_H_
#define _MACROS_H_

#define SET_BIT(REG, BIT)     ((REG) |= (BIT))
#define CLEAR_BIT(REG, BIT)   ((REG) &= ~(BIT))
#define READ_BIT(REG, BIT)    ((REG) & (BIT))
#define MODIFY_REG(REG, CLEARMASK, SETMASK) \
    ((REG) = (((REG) & ~(CLEARMASK)) | (SETMASK)))

#endif /* _MACROS_H_ */