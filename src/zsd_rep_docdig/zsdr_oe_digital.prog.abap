*&---------------------------------------------------------------------*
*& Report  zsdr_oe_digital
*&---------------------------------------------------------------------*
*&  Fecha:      10.09.2025
*&  Autor:      700-009 : CFALCON
*&  ServiDesk:  REQ-C1049 Caso: 55601
*&  Transporte: DR3K980133
*&  Titulo:     Reporte Ordenes de entrega FD
*----------------------------------------------------------------------*
*    Bitacora de actualización
*----------------------------------------------------------------------*
*&   Fecha       Caso   User   Orden      Descripción
*&---------------------------------------------------------------------*
*& 12.02.2026    577   700-009 DR3K981194 Solicitud de Inhabilitación
*&                                        de opción de impresión de Hoja
*&                                        de ruta en Despacho
*&---------------------------------------------------------------------*
REPORT zsdr_oe_digital.

INCLUDE zsdr_oe_digital_t01.
INCLUDE zsdr_oe_digital_s01.
INCLUDE zsdr_oe_digital_cl1.
INCLUDE zsdr_oe_digital_m01.
INCLUDE zsdr_oe_digital_f01.

START-OF-SELECTION.
  DATA: go_ref TYPE REF TO lcl_report_handler.
* monitorea el uso del programa
    CALL FUNCTION 'Z_MONITOREAR_PROGRAMA'
      EXPORTING
        programa = sy-cprog
        usuario  = sy-uname
        fecha    = sy-datum
        hora     = sy-uzeit.

  go_ref = NEW #( ).
