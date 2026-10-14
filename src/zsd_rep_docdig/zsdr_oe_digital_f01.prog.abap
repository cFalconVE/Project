*&---------------------------------------------------------------------*
*&  Include  zsdr_oe_digital_f01
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
FORM init_data .
  DATA: lv_edate TYPE sy-datum.

  DATA(lv_datum) = sy-datum.

  CALL FUNCTION 'BKK_ADD_MONTH_TO_DATE'
    EXPORTING
      months  = '-3'
      olddate = lv_datum
    IMPORTING
      newdate = lv_edate.

  APPEND VALUE #( sign = 'I' option = 'EQ' low = lv_edate  high = sy-datum )
  TO so_erdat.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  VALIDATE_INIT_ENTRY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM validate_init_entry .
  DATA: lv_months TYPE komp-anz_monate.
  IF so_erdat[] IS NOT INITIAL.

    CALL FUNCTION 'MONTHS_BETWEEN_TWO_DATES_NEW'
      EXPORTING
        i_datum_bis = so_erdat-high
        i_datum_von = so_erdat-low
      IMPORTING
        e_monate    = lv_months.

    IF lv_months GT 3.
      MESSAGE e208(00) WITH text-m02.
    ENDIF.
  ENDIF.
ENDFORM.
