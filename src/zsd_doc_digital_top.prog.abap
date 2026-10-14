*&---------------------------------------------------------------------*
*&  Include  zsd_doc_digital_top
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

CONSTANTS: gc_red_status    TYPE icon_d VALUE '@0A@', "Error
           gc_yellow_status TYPE icon_d VALUE '@09@', "Warning
           gc_green_status  TYPE icon_d VALUE '@08@'. "OK

TABLES: vttk,     "CABECERA DE TRANSPORTE
        zsd_tb_json_stat.
*        likp.     "CABECERA NOTA DE ENTREGA
*
*TYPES: BEGIN OF ty_fecha,
*         sign   TYPE /bcv/fnd_sign_range,
*         option TYPE /bcv/fnd_option,
*         low    TYPE sy-datum,
*         high   TYPE sy-datum,
*       END OF ty_fecha.

*       TYPES: rng_typ type RANGE OF

TYPES: BEGIN OF ty_dat_gc,
         ord_dev     TYPE string,
         ord_equi    TYPE string,
         precintos   TYPE string,
         not_cred    TYPE string,
         despachador TYPE string,
       END OF ty_dat_gc.


DATA gv_process_type(3) TYPE c.

*DATA: gr_fbsta TYPE TABLE OF ty_fbsta.

DATA gt_results TYPE TABLE OF zsd_st_dd_results.

DATA: gt_gc_enc TYPE TABLE OF zsd_st_gc_enc,
      gt_gc_det TYPE TABLE OF zsd_st_gc_det.
