*&---------------------------------------------------------------------*
*& Report  ZSDR_GUIAS_CARGA_DITITAL
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT zsdr_guias_carga_ditital.

INCLUDE zsdr_guias_carga_ditital_t01.
INCLUDE zsdr_guias_carga_ditital_cl1.

START-OF-SELECTION.
  DATA: o_ref TYPE REF TO lcl_report_handler.

  o_ref = NEW #( ).
  o_ref->init( ).

INCLUDE zsdr_guias_carga_ditital_m01.
INCLUDE zsdr_guias_carga_ditital_f01.
