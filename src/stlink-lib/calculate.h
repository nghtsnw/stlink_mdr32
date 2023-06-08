/*
 * File: calculate.h
 *
 * Calculation of sector numbers and pages
 */

#ifndef CALCULATE_H
#define CALCULATE_H

#include <stdint.h>

uint32_t calculate_F4_sectornum(uint32_t);
uint32_t calculate_F7_sectornum(uint32_t);
uint32_t calculate_H7_sectornum(stlink_t *, uint32_t, unsigned);
uint32_t calculate_L4_page(stlink_t *, uint32_t);

#endif // CALCULATE_H