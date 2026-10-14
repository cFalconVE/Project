*&---------------------------------------------------------------------*
*&  Include           ZSD_LOG_FACT_DIGITAL_T01
*&---------------------------------------------------------------------*
TABLES: zsd_tb_oe_log.

TYPES: BEGIN OF tt_log.
         INCLUDE STRUCTURE zsd_tb_oe_log.
         TYPES: status_t TYPE ddtext,
       END OF tt_log.

SELECTION-SCREEN: BEGIN OF BLOCK b01 WITH FRAME TITLE text-001.
SELECT-OPTIONS: so_bukrs FOR zsd_tb_oe_log-sociedad OBLIGATORY NO INTERVALS NO-EXTENSION,
                so_fecha FOR zsd_tb_oe_log-fecha OBLIGATORY,
                so_tdoc FOR zsd_tb_oe_log-tdocumento,
                so_vbeln FOR zsd_tb_oe_log-ndocumento.
SELECTION-SCREEN: SKIP.

SELECT-OPTIONS: so_stat FOR zsd_tb_oe_log-status.

SELECTION-SCREEN: END OF BLOCK b01.
