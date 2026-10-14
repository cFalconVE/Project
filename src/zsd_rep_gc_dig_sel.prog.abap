*&---------------------------------------------------------------------*
*&  Include  zsd_rep_gc_dig_sel
*&---------------------------------------------------------------------*
*  FECHA DE CREACION: 27.03.2025
*  MODULO SAP     : SD
*  EMPRESA        : Corimon
*  AUTOR (NOMBRE) : Carlos Falcón
*  AUTOR (ID)     : 700-009
*  OBJECTO        : INCLUDE
*  ORDEN          : DR3K978052
*  Solicitud      : REQ-55601
*&---------------------------------------------------------------------*
*   Descripción
*   Reporte para Guía de Carga digital
*
*&---------------------------------------------------------------------*
*    Bitacora de actualización
*----------------------------------------------------------------------*
* Fecha       Caso    User    Orden       Descripción
*
*
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK sel WITH FRAME TITLE text-050.
PARAMETERS:
  pa_tplst TYPE zsd_tb_gck-tplst OBLIGATORY,
  pa_filas TYPE i DEFAULT 50.
SELECT-OPTIONS:
    so_date  FOR sy-datum,
    so_tplst FOR zsd_tb_gck-tplst OBLIGATORY NO-EXTENSION NO INTERVALS.
SELECTION-SCREEN END OF BLOCK sel.

SELECTION-SCREEN BEGIN OF BLOCK dsp WITH FRAME.
PARAMETERS:
  p_full RADIOBUTTON GROUP dsp,
  p_tree RADIOBUTTON GROUP dsp.
SELECTION-SCREEN END OF BLOCK dsp.
