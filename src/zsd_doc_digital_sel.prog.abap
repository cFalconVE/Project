*&---------------------------------------------------------------------*
*&  Include  zsd_doc_digital_sel
*&---------------------------------------------------------------------*
*  FECHA DE CREACION: 03.02.2025
*  MODULO SAP     : SD
*  EMPRESA        : Corimon
*  AUTOR (NOMBRE) : Carlos Falcón
*  AUTOR (ID)     : 700-009
*  OBJECTO        : INCLUDE
*  ORDEN          : DR3K976964
*  Solicitud      : REQ-55601
*&---------------------------------------------------------------------*
*   Descripción
*   Documentos Digitales
*
*&---------------------------------------------------------------------*
*    Bitacora de actualización
*----------------------------------------------------------------------*
* Fecha       Caso    User    Orden       Descripción
*
*
*&---------------------------------------------------------------------*
*Selection Screen
SELECTION-SCREEN BEGIN OF BLOCK block_02 WITH FRAME TITLE text-b02.
*SELECT-OPTIONS: so_fecha FOR zsd_tb_json_stat-fechareci.
PARAMETERS: p_tplst TYPE vttk-tplst OBLIGATORY.
SELECT-OPTIONS: so_tknum FOR vttk-tknum OBLIGATORY.

SELECTION-SCREEN END OF BLOCK block_02.

SELECTION-SCREEN BEGIN OF BLOCK block_01 WITH FRAME TITLE text-b01.
SELECTION-SCREEN COMMENT /1(30) text-c01.
PARAMETERS:
  pr_gc TYPE xfeld RADIOBUTTON GROUP oper DEFAULT 'X', "01-Guía de Carga
*            pr_gd TYPE xfeld RADIOBUTTON GROUP oper,             "02-Guía de Devolución
  pr_oe TYPE xfeld RADIOBUTTON GROUP oper.            "02-Orden de Entrega
*            pr_dm TYPE xfeld RADIOBUTTON GROUP oper.             "03-Devolución de productos

SELECTION-SCREEN COMMENT /1(30) text-c02.
PARAMETERS:
*pr_gc TYPE xfeld RADIOBUTTON GROUP oper DEFAULT 'X', "01-Guía de Carga
  pr_gd TYPE xfeld RADIOBUTTON GROUP oper,             "02-Guía de Devolución
*            pr_oe TYPE xfeld RADIOBUTTON GROUP oper,             "02-Orden de Entrega
  pr_dm TYPE xfeld RADIOBUTTON GROUP oper.             "03-Devolución de productos

SELECTION-SCREEN COMMENT /1(30) text-c03.

PARAMETERS:
  pr_de TYPE xfeld RADIOBUTTON GROUP oper, "01-Guía de Despacho
  pr_or TYPE xfeld RADIOBUTTON GROUP oper.

SELECTION-SCREEN COMMENT /1(30) text-c04.
PARAMETERS:
  pr_rxp TYPE xfeld RADIOBUTTON GROUP oper,
  cb_dig AS CHECKBOX DEFAULT ' '.



SELECTION-SCREEN END OF BLOCK block_01.

SELECTION-SCREEN BEGIN OF BLOCK block_03 WITH FRAME TITLE text-b03.

PARAMETERS: pa_bktx1(20) TYPE c,
            pa_bktx2(20) TYPE c,
            pa_bktx3(20) TYPE c,
            pa_bktx4(20) TYPE c,
            pa_desp(50)  TYPE c.
SELECTION-SCREEN END OF BLOCK block_03.
