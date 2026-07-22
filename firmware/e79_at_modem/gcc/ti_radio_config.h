/*
 *  ======== ti_radio_config.h ========
 *  Configured RadioConfig module definitions
 *
 *  DO NOT EDIT - This file is generated for the CC1352P1F3RGZ
 *  by the SysConfig tool.
 *
 *  Radio Config module version : 1.20.0
 *  SmartRF Studio data version : 2.32.0
 */
#ifndef _TI_RADIO_CONFIG_H_
#define _TI_RADIO_CONFIG_H_

#include <ti/devices/DeviceFamily.h>
#include DeviceFamily_constructPath(driverlib/rf_mailbox.h)
#include DeviceFamily_constructPath(driverlib/rf_common_cmd.h)
#include DeviceFamily_constructPath(driverlib/rf_prop_cmd.h)
#include <ti/drivers/rf/RF.h>

/* SmartRF Studio version that the RF data is fetched from */
#define SMARTRF_STUDIO_VERSION "2.32.0"

// *********************************************************************************
//   RF Frontend configuration
// *********************************************************************************
// RF design based on: LAUNCHXL-CC1352P-4
#define LAUNCHXL_CC1352P_4

// High-Power Amplifier supported
#define SUPPORT_HIGH_PA

// RF frontend configuration
#define FRONTEND_SUB1G_DIFF_RF
#define FRONTEND_SUB1G_EXT_BIAS
#define FRONTEND_24G_DIFF_RF
#define FRONTEND_24G_EXT_BIAS

// Supported frequency bands
#define SUPPORT_FREQBAND_2400
#define SUPPORT_FREQBAND_433

// TX power table size definitions
#define TXPOWERTABLE_2400_PA5_SIZE 16 // 2400 MHz, 5 dBm
#define TXPOWERTABLE_2400_PA5_10_SIZE 21 // 2400 MHz, 5 + 10 dBm
#define TXPOWERTABLE_433_PA13_SIZE 20 // 433 MHz, 13 dBm

// TX power tables
extern RF_TxPowerTable_Entry txPowerTable_2400_pa5[]; // 2400 MHz, 5 dBm
extern RF_TxPowerTable_Entry txPowerTable_2400_pa5_10[]; // 2400 MHz, 5 + 10 dBm
extern RF_TxPowerTable_Entry txPowerTable_433_pa13[]; // 433 MHz, 13 dBm



//*********************************************************************************
//  RF Setting:   50 kbps, 25kHz Deviation, 2-GFSK, 78 kHz RX Bandwidth
//
//  PHY:          2gfsk50kbps433mhz
//  Setting file: setting_tc112.json
//*********************************************************************************

// PA table usage
#define TX_POWER_TABLE_SIZE TXPOWERTABLE_433_PA13_SIZE

#define txPowerTable txPowerTable_433_pa13

// TI-RTOS RF Mode object
extern RF_Mode RF_prop;

// RF Core API commands
extern rfc_CMD_PROP_RADIO_DIV_SETUP_PA_t RF_cmdPropRadioDivSetup;
extern rfc_CMD_FS_t RF_cmdFs;
extern rfc_CMD_PROP_TX_t RF_cmdPropTx;
extern rfc_CMD_PROP_RX_t RF_cmdPropRx;

// RF Core API overrides
extern uint32_t pOverrides[];

//*********************************************************************************
//  RF Setting:   SimpleLink Long Range, 5 kbps (20 ksps), 5 kHz Deviation, 2-GFSK, 34 kHz RX Bandwidth, FEC = 1:2, DSSS = 1:2
//
//  PHY:          slr5kbps2gfsk433mhz
//  Setting file: setting_tc440.json
//*********************************************************************************

// PA table usage
#define RF_PROP_TX_POWER_TABLE_SIZE_SL_LR TXPOWERTABLE_433_PA13_SIZE

#define PROP_RF_txPowerTable_sl_lr txPowerTable_433_pa13

// TI-RTOS RF Mode object
extern RF_Mode RF_prop_sl_lr;

// RF Core API commands
extern rfc_CMD_PROP_RADIO_DIV_SETUP_PA_t RF_cmdPropRadioDivSetup_sl_lr;
extern rfc_CMD_FS_t RF_cmdFs_sl_lr;
extern rfc_CMD_PROP_TX_t RF_cmdPropTx_sl_lr;
extern rfc_CMD_PROP_RX_t RF_cmdPropRx_sl_lr;

// RF Core API overrides
extern uint32_t pOverrides_sl_lr[];

//*********************************************************************************
//  RF Setting:   SimpleLink Long Range, 2.5 kbps (20 ksps), 5 kHz Deviation, 2-GFSK, 34 kHz RX Bandwidth, FEC = 1:2, DSSS = 1:4
//
//  PHY:          slr2500bps2gfsk433mhz
//  Setting file: setting_tc441.json
//*********************************************************************************

// PA table usage
#define RF_PROP_TX_POWER_TABLE_SIZE_SLR_2K5 TXPOWERTABLE_433_PA13_SIZE

#define PROP_RF_txPowerTable_slr_2k5 txPowerTable_433_pa13

// TI-RTOS RF Mode object
extern RF_Mode RF_prop_slr_2k5;

// RF Core API commands
extern rfc_CMD_PROP_RADIO_DIV_SETUP_PA_t RF_cmdPropRadioDivSetup_slr_2k5;
extern rfc_CMD_FS_t RF_cmdFs_slr_2k5;
extern rfc_CMD_PROP_TX_t RF_cmdPropTx_slr_2k5;
extern rfc_CMD_PROP_RX_t RF_cmdPropRx_slr_2k5;

// RF Core API overrides
extern uint32_t pOverrides_slr_2k5[];

//*********************************************************************************
//  RF Setting:   Narrowband, 4.8 kbps, 2 kHz Deviation, 2-GFSK, 10.1 kHz RX Bandwidth
//
//  PHY:          2gfsk48kpbs429mhz
//  Setting file: setting_tc596.json
//*********************************************************************************

// PA table usage
#define RF_PROP_TX_POWER_TABLE_SIZE_GFSK_4K8 TXPOWERTABLE_433_PA13_SIZE

#define PROP_RF_txPowerTable_gfsk_4k8 txPowerTable_433_pa13

// TI-RTOS RF Mode object
extern RF_Mode RF_prop_gfsk_4k8;

// RF Core API commands
extern rfc_CMD_PROP_RADIO_DIV_SETUP_PA_t RF_cmdPropRadioDivSetup_gfsk_4k8;
extern rfc_CMD_FS_t RF_cmdFs_gfsk_4k8;
extern rfc_CMD_PROP_TX_t RF_cmdPropTx_gfsk_4k8;
extern rfc_CMD_PROP_RX_t RF_cmdPropRx_gfsk_4k8;

// RF Core API overrides
extern uint32_t pOverrides_gfsk_4k8[];

//*********************************************************************************
//  RF Setting:   4.8 kbps, OOK, 34.1 kHz RX Bandwidth
//
//  PHY:          ook48kbps433mhz
//  Setting file: setting_tc599.json
//*********************************************************************************

// PA table usage
#define RF_PROP_TX_POWER_TABLE_SIZE_OOK_4K8 TXPOWERTABLE_433_PA13_SIZE

#define PROP_RF_txPowerTable_ook_4k8 txPowerTable_433_pa13

// TI-RTOS RF Mode object
extern RF_Mode RF_prop_ook_4k8;

// RF Core API commands
extern rfc_CMD_PROP_RADIO_DIV_SETUP_PA_t RF_cmdPropRadioDivSetup_ook_4k8;
extern rfc_CMD_FS_t RF_cmdFs_ook_4k8;
extern rfc_CMD_PROP_TX_t RF_cmdPropTx_ook_4k8;
extern rfc_CMD_PROP_RX_t RF_cmdPropRx_ook_4k8;

// RF Core API overrides
extern uint32_t pOverrides_ook_4k8[];

//*********************************************************************************
//  RF Setting:   200 kbps, 50 kHz Deviation, 2-GFSK, 273 kHz RX Bandwidth
//
//  PHY:          2gfsk200kbps433mhz
//  Setting file: setting_tc148.json
//*********************************************************************************

// PA table usage
#define RF_PROP_TX_POWER_TABLE_SIZE_GFSK_200 TXPOWERTABLE_433_PA13_SIZE

#define PROP_RF_txPowerTable_gfsk_200 txPowerTable_433_pa13

// TI-RTOS RF Mode object
extern RF_Mode RF_prop_gfsk_200;

// RF Core API commands
extern rfc_CMD_PROP_RADIO_DIV_SETUP_PA_t RF_cmdPropRadioDivSetup_gfsk_200;
extern rfc_CMD_FS_t RF_cmdFs_gfsk_200;
extern rfc_CMD_PROP_TX_t RF_cmdPropTx_gfsk_200;
extern rfc_CMD_PROP_RX_t RF_cmdPropRx_gfsk_200;

// RF Core API overrides
extern uint32_t pOverrides_gfsk_200[];

//*********************************************************************************
//  RF Setting:   IEEE 802.15.4, 50 kbps, 25kHz Deviation, 2-GFSK, 78 kHz RX Bandwidth
//
//  PHY:          2gfsk50kbps154g433mhz
//  Setting file: setting_tc112_154g.json
//*********************************************************************************

// PA table usage
#define RF_PROP_TX_POWER_TABLE_SIZE_IEEE154G_50 TXPOWERTABLE_433_PA13_SIZE

#define PROP_RF_txPowerTable_ieee154g_50 txPowerTable_433_pa13

// TI-RTOS RF Mode object
extern RF_Mode RF_prop_ieee154g_50;

// RF Core API commands
extern rfc_CMD_PROP_RADIO_DIV_SETUP_PA_t RF_cmdPropRadioDivSetup_ieee154g_50;
extern rfc_CMD_FS_t RF_cmdFs_ieee154g_50;
extern rfc_CMD_PROP_TX_ADV_t RF_cmdPropTxAdv_ieee154g_50;
extern rfc_CMD_PROP_RX_ADV_t RF_cmdPropRxAdv_ieee154g_50;

// RF Core API overrides
extern uint32_t pOverrides_ieee154g_50[];

#endif // _TI_RADIO_CONFIG_H_
