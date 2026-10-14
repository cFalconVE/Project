*&---------------------------------------------------------------------*
*& Report  zcx_app_error
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
CLASS zcx_app_error DEFINITION
  PUBLIC
  INHERITING FROM cx_static_check
  CREATE PUBLIC .

  PUBLIC SECTION.

    DATA:
        mv_context TYPE string.

    METHODS:
      constructor
        IMPORTING
          !iv_text    TYPE string
          !iv_context TYPE string OPTIONAL.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcx_app_error IMPLEMENTATION.
  METHOD constructor ##ADT_SUPPRESS_GENERATION.

    super->constructor( textid = textid previous = previous ).

    mv_context = iv_context.

  ENDMETHOD.

ENDCLASS.
