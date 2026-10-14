*&---------------------------------------------------------------------*
*&  Include  zsdr_oe_digital_s01
*&---------------------------------------------------------------------*
*&  Fecha:      10.09.2025
*&  Autor:      700-009 : CFALCON
*&  ServiDesk:  REQ-C1049 Caso: 55601
*&  Transporte: DR3K980133
*&  Titulo:     Reporte Ordenes de entrega FD
*----------------------------------------------------------------------*
*    Bitacora de actualización
*----------------------------------------------------------------------*
*&   Fecha       Caso   User    Orden      Descripción
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
SELECTION-SCREEN: BEGIN OF BLOCK b01 WITH FRAME TITLE text-001.
SELECT-OPTIONS:   so_tplst  FOR zsd_likp_oe-tplst OBLIGATORY NO-EXTENSION NO INTERVALS,
                  so_tknum  FOR zsd_likp_oe-vbeln,
                  so_erdat  FOR zsd_likp_oe-erdat OBLIGATORY.
SELECTION-SCREEN: END OF BLOCK b01.

AT SELECTION-SCREEN.
  PERFORM validate_init_entry.

INITIALIZATION.
  PERFORM init_data.
