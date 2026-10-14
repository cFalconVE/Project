*&---------------------------------------------------------------------*
*& Report  zsd_doc_util
*&---------------------------------------------------------------------*
*  FECHA DE CREACION: 23.09.2025
*  MODULO SAP     : SD
*  EMPRESA        : Corimon
*  AUTOR (NOMBRE) : Carlos Falcón
*  AUTOR (ID)     : 700-009
*  OBJECTO        : PROGRAM
*  ORDEN          : DR3K979429
*  Solicitud      : REQ-55601
*&---------------------------------------------------------------------*
*   Descripción
*   Utility Documentos Digitales
*
*&---------------------------------------------------------------------*
*    Bitacora de actualización
*----------------------------------------------------------------------*
* Fecha       Caso    User    Orden       Descripción
*
*
*&---------------------------------------------------------------------*
REPORT zsd_doc_util.

INCLUDE:
    zsd_doc_util_cl.

START-OF-SELECTION.

  TRY.
      DATA(lo_upd) = NEW lcl_dd_util( ).
    CATCH cx_abap_invalid_value.
  ENDTRY.

  IF lo_upd IS BOUND.
    MESSAGE i208(00) WITH 'Se actualizaron las fechas.'.
  ELSE.
    MESSAGE i208(00) WITH 'No actualizaron las fechas.'.
  ENDIF.

END-OF-SELECTION.
