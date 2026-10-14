*&---------------------------------------------------------------------*
*& Report  zsd_doc_digital
*&
*&---------------------------------------------------------------------*
*  FECHA DE CREACION: 03.02.2025
*  MODULO SAP     : SD
*  EMPRESA        : Corimon
*  AUTOR (NOMBRE) : Carlos Falcón
*  AUTOR (ID)     : 700-009
*  OBJECTO        : PROGRAM
*  ORDEN          : DR3K976964
*  Solicitud      : REQ-55601
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
REPORT zsd_doc_digital.

INCLUDE: zsd_doc_digital_top,
         zsd_doc_digital_sel,
         zsd_doc_digital_f01.

*INITIALIZATION.
**  DATA lso_fecha TYPE ty_fecha.
*
*  DATA(lso_fecha) = VALUE ty_fecha( sign = 'I'
*                                    option = 'BT'
*                                    low =  sy-datum - 7
*                                    high = sy-datum ).
*
*  APPEND lso_fecha TO so_fecha.

START-OF-SELECTION.

* monitorea el uso del programa
  CALL FUNCTION 'Z_MONITOREAR_PROGRAMA'
    EXPORTING
      programa = sy-cprog
      usuario  = sy-uname
      fecha    = sy-datum
      hora     = sy-uzeit.

  CASE abap_true.
    WHEN pr_gc. "Generar Guía de Carga
      gv_process_type = 'GC'.
    WHEN pr_gd. "Generar Guía de Carga
      gv_process_type = 'GD'.
    WHEN pr_oe. "Generar OE
      gv_process_type = 'OE'.
    WHEN pr_dm . "Generar devolución de materiales
      gv_process_type = 'LR'.
    WHEN pr_de.
      gv_process_type = 'DE'.
    WHEN pr_or.
      gv_process_type = 'OR'.
    WHEN pr_rxp.
      gv_process_type = 'RXP'.
    WHEN OTHERS.
  ENDCASE.

END-OF-SELECTION.

  PERFORM:
*  status_transporte,
           gen_report USING gv_process_type.

  IF NOT gt_results[] IS INITIAL."lines( gt_results ) > 0.
    PERFORM display_alv.
  ENDIF.
