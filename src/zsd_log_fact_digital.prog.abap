*&---------------------------------------------------------------------*
*& Report  ZSD_LOG_FACT_DIGITAL
*&
*&---------------------------------------------------------------------*
*& Fecha: 26.08.2025
*&
*&---------------------------------------------------------------------*
REPORT zsd_log_fact_digital.

INCLUDE zsd_log_fact_digital_t01.
INCLUDE zsd_log_fact_digital_c01.

START-OF-SELECTION.
  DATA: o_log TYPE REF TO lcl_log_fact_dig.

  o_log = NEW #( ).
  o_log->init_process( ).
