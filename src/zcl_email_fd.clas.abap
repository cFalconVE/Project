*  FECHA DE CREACION: 16.09.2025
*  MODULO SAP     : SD
*  EMPRESA        : Corimon
*  AUTOR (NOMBRE) : Carlos Falcón
*  AUTOR (ID)     : 700-009
*  OBJECTO        : CLASS
*  ORDEN          :
*  Solicitud      : REQ-55601
*&---------------------------------------------------------------------*
*   Descripción
*   Envío de correos cuando de genera errores de documentos digitales
*   (Factura digital)
*&---------------------------------------------------------------------*
*    Bitacora de actualización
*----------------------------------------------------------------------*
* Fecha       Caso    User    Orden       Descripción
*
*
*&--------------------------------------------------------------------*
CLASS zcl_email_fd DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .

    DATA: mv_asunto TYPE so_obj_des READ-ONLY,
          ms_oe_log TYPE zsd_tb_oe_log READ-ONLY,
          mv_return TYPE abap_bool READ-ONLY.

*    DATA obj_msg TYPE REF TO lcl_email.

    METHODS constructor
      IMPORTING
                i_asunto TYPE so_obj_des
                i_oe_log TYPE zsd_tb_oe_log
      RAISING   cx_abap_invalid_value..

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_email_fd IMPLEMENTATION.

  METHOD constructor.

*    me->mv_asunto = 'Prueba de correo'.
*    me->ms_oe_log = VALUE zsd_tb_oe_log( sociedad = '1200'
*                                         tdocumento = 'NC'
*                                         ndocumento = '803000017'
*                                         pagina     =  1
*                                         mensaje    = 'Mensaje de error del Log'
*                                         uname      = sy-uname
*                                         erdat      = sy-datum
*                                         status     = '0'
*                                         erzet      = sy-uzeit ).

    me->mv_asunto = i_asunto.
    me->ms_oe_log = i_oe_log.

    TRY.
        DATA(ob_msg) = NEW lcl_email( i_asunto = mv_asunto
                                      i_oe_log = ms_oe_log ).
      CATCH cx_abap_invalid_value.
    ENDTRY.

    IF sy-subrc <> 0.
      RAISE EXCEPTION TYPE cx_abap_invalid_value.
*    ELSE.
*      me->mv_return = abap_true.
    ENDIF.

    ob_msg->send_msg_mail( ).

  ENDMETHOD.

  METHOD if_oo_adt_classrun~main.

    TRY.
        DATA(ob_msg) = NEW lcl_email( i_asunto = mv_asunto
                                      i_oe_log = ms_oe_log ).
      CATCH cx_abap_invalid_value.
        out->write( | Sociedad { ms_oe_log-sociedad } no existe | ).
*      CATCH cx_sy_itab_line_not_found.
*        out->write( | Carrier { c_carrier_id } does not exist | ).
    ENDTRY.

    IF ob_msg IS BOUND.
      out->write( data = ob_msg->lt_list_email[]
                  name = |Lista de correos, Sociedad: { mv_asunto }, DG: { ms_oe_log-tdocumento }| ).
      me->mv_return = abap_true.
    ELSE.
      out->write( data = 'No hay datos' ).
    ENDIF.

  ENDMETHOD.

ENDCLASS.
