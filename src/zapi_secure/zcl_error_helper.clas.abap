*&---------------------------------------------------------------------*
*& Report  zcl_error_helper
*&
*&---------------------------------------------------------------------*
*  FECHA DE CREACION: 03.02.2025
*  MODULO SAP     : SD
*  EMPRESA        : Corimon
*  AUTOR (NOMBRE) : Carlos Falcón
*  AUTOR (ID)     : 700-009
*  OBJECTO        : CLASS
*  ORDEN          : DR3K976
*  Solicitud      : REQ-1354
*&---------------------------------------------------------------------*
*   Descripción
*   Documentos Digitales
*
*&---------------------------------------------------------------------*
*    Bitacora de actualización
*----------------------------------------------------------------------*
* Fecha       Caso    User    Orden       Descripció7n
*
*
*&---------------------------------------------------------------------*

CLASS zcl_error_helper DEFINITION
  PUBLIC CREATE PUBLIC .

  PUBLIC SECTION.

    CLASS-METHODS:
      raise_with_audit_log
        IMPORTING
          !iv_text    TYPE string
          !iv_context TYPE string OPTIONAL
        RAISING
          zcx_app_error.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_error_helper IMPLEMENTATION.
  METHOD raise_with_audit_log.

    " Registrar en tabla ZERR_LOG
    DATA(ls_log) = VALUE zerr_app_log(
      mandt   = sy-mandt
      erdat   = sy-datum
      erzet   = sy-uzeit
      erusr   = sy-uname
      tcode   = sy-tcode
      context = iv_context
      message = iv_text ).

    INSERT zerr_app_log FROM ls_log.

    " Lanzar excepción
    RAISE EXCEPTION TYPE zcx_app_error
      EXPORTING
        iv_text    = iv_text
        iv_context = iv_context.
  ENDMETHOD.

ENDCLASS.
