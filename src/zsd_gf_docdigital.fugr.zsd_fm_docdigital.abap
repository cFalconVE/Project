*&---------------------------------------------------------------------*
*&  Funtion Module  zsd_fm_docdigital
*&---------------------------------------------------------------------*
*  FECHA DE CREACION: 03.02.2025
*  MODULO SAP     : SD
*  EMPRESA        : Corimon
*  AUTOR (NOMBRE) : Carlos Falcón
*  AUTOR (ID)     : 700-009
*  OBJECTO        : FUNCTION MODULE
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

FUNCTION ZSD_FM_DOCDIGITAL.
*"----------------------------------------------------------------------
*"*"Interfase local
*"  IMPORTING
*"     VALUE(IV_PROCESS) TYPE  C
*"     VALUE(IV_TKNUM) TYPE  TKNUM OPTIONAL
*"     VALUE(IV_TPLST) TYPE  TPLST
*"     VALUE(IS_DATOS_GC) TYPE  ZSD_ST_DATOS_GC OPTIONAL
*"  EXPORTING
*"     VALUE(EV_PROCESS_RESULT) TYPE  STRING
*"     VALUE(EV_TECHNICAL_MESSAGE) TYPE  STRING
*"  TABLES
*"      T_TKNUM TYPE  STANDARD TABLE
*"      T_FBSTA STRUCTURE  RSDSSELOPT OPTIONAL
*"      T_HEAD TYPE  STANDARD TABLE
*"      T_ITEMS TYPE  STANDARD TABLE
*"      T_OE_HEAD TYPE  STANDARD TABLE
*"      T_OE_ITEMS TYPE  STANDARD TABLE
*"      ET_MESSAGE TYPE  STANDARD TABLE
*"----------------------------------------------------------------------
***************************************************
*
* GC - Guía de Carga
* OE - Ordenes de Entrega
* LR - Deolución de Materiales
*
***************************************************
  DATA(lo_doc_digital) = NEW zcl_sd_doc_digital( ).

  DATA lv_json TYPE string.
  DATA: lt_head  TYPE STANDARD TABLE OF zv_cds_sd_gc,
        lt_items TYPE STANDARD TABLE OF zv_cds_gcp,
        lt_df    TYPE STANDARD TABLE OF zview_doc_flujo.

  DATA: lt_gc_head  TYPE STANDARD TABLE OF zv_cds_sd_gc,
        lt_gc_items TYPE STANDARD TABLE OF zv_cds_gcp.

  DATA: lt_oe_head  TYPE STANDARD TABLE OF zview_entrega_oe,
        lt_oe_items TYPE STANDARD TABLE OF zview_entp_oe.

  DATA: lt_gck TYPE STANDARD TABLE OF zsd_tb_gck,
        lt_gcp TYPE STANDARD TABLE OF zsd_tb_gcp.

  DATA: lt_results TYPE TABLE OF zsd_st_dd_results.

  DATA: lv_fecpro LIKE sy-datum.

  CASE iv_process.
    WHEN 'LR'. "Genera Ordenes de Entrega Devolución de Materiales

      IF lo_doc_digital->check_date(
       EXPORTING
         iv_bukrs  = iv_tplst
       IMPORTING
         ev_fecpro = lv_fecpro ) EQ abap_false.

        ev_process_result = zcl_sd_doc_digital=>wr_not_head_trans.
        ev_technical_message = zcl_sd_doc_digital=>technical_message.
        et_message[] = zcl_sd_doc_digital=>lt_message.
        EXIT.
      ENDIF.

      IF lo_doc_digital->get_transp_oe(
           EXPORTING
             iv_tplst  = iv_tplst
             it_tknum  = t_tknum[]
             iv_orddev = iv_process
           IMPORTING
             et_head  = lt_oe_head[]
             et_items = lt_oe_items[] ) EQ abap_false.

        ev_process_result = zcl_sd_doc_digital=>wr_not_head_trans.
        ev_technical_message = zcl_sd_doc_digital=>technical_message.
        et_message[] = zcl_sd_doc_digital=>lt_message.
        EXIT.
      ENDIF.

      IF lo_doc_digital->check_pend_oe(
       EXPORTING
         it_table = lt_oe_head ) EQ abap_false.
        ev_process_result = zcl_sd_doc_digital=>wr_transportista.
        ev_technical_message = zcl_sd_doc_digital=>technical_message.
        et_message[] = zcl_sd_doc_digital=>lt_message.
        EXIT.
      ENDIF.

      " Asignar Transportista
      IF lo_doc_digital->val_transp_oe(
        EXPORTING
          it_table = lt_oe_head ) EQ abap_false.
        ev_process_result = zcl_sd_doc_digital=>wr_transportista.
        ev_technical_message = zcl_sd_doc_digital=>technical_message.
        et_message[] = zcl_sd_doc_digital=>lt_message.
        EXIT.
      ENDIF.

      IF lo_doc_digital->send_oe(
              EXPORTING
                iv_document = iv_process
                it_head     = lt_oe_head[]
                it_items    = lt_oe_items[]
              IMPORTING
                et_head     = t_oe_head[]
                et_items    = t_oe_items[] ) EQ abap_false.

        ev_technical_message = zcl_sd_doc_digital=>technical_message.
        ev_process_result = zcl_sd_doc_digital=>er_create_json.
        et_message[] = zcl_sd_doc_digital=>lt_message.
        EXIT.
      ENDIF.

      IF lo_doc_digital->create_json_oe(
          EXPORTING
            iv_document = iv_process
            iv_fecdoc   = lv_fecpro
            it_head     = t_oe_head[]
            it_items    = t_oe_items[]
          IMPORTING
            ev_json     = lv_json ) EQ abap_false.

        ev_technical_message = zcl_sd_doc_digital=>technical_message.
        ev_process_result = zcl_sd_doc_digital=>er_create_json.
        et_message[] = zcl_sd_doc_digital=>lt_message.
        EXIT.

      ENDIF.

      ev_process_result = zcl_sd_doc_digital=>ok_send_oe.
      et_message[] = zcl_sd_doc_digital=>lt_message.

    WHEN 'GC' OR 'GD'. "Genera la Guía de Carga

      IF lo_doc_digital->check_gc(
         EXPORTING
           iv_tplst  = iv_tplst
           it_tknum  = t_tknum[] ) EQ abap_false.

        ev_process_result = zcl_sd_doc_digital=>wr_not_head_trans.
        ev_technical_message = zcl_sd_doc_digital=>technical_message.
        et_message[] = zcl_sd_doc_digital=>lt_message.
        EXIT.
      ENDIF.

      IF lo_doc_digital->get_gc_enc(
         EXPORTING
           iv_tplst  = iv_tplst
           it_tknum  = t_tknum[]
           iv_proccess = iv_process
           is_dat_gc    = is_datos_gc
         IMPORTING
           et_table  = lt_head[] ) EQ abap_false.

        ev_process_result = zcl_sd_doc_digital=>wr_not_head_trans.
        ev_technical_message = zcl_sd_doc_digital=>technical_message.
        et_message[] = zcl_sd_doc_digital=>lt_message.
        EXIT.
      ENDIF.

      IF lo_doc_digital->get_gc_items(
         EXPORTING
           it_tknum  = t_tknum[]
           iv_proccess = iv_process
         IMPORTING
           et_table  = lt_items[] ) EQ abap_false.

        ev_process_result = zcl_sd_doc_digital=>wr_not_exit_mer.
        ev_technical_message = zcl_sd_doc_digital=>technical_message.
        et_message[] = zcl_sd_doc_digital=>lt_message.
        EXIT.
      ENDIF.

      ev_process_result = zcl_sd_doc_digital=>ok_trans.

      IF lo_doc_digital->get_destino(
        EXPORTING
          it_table = lt_items
        CHANGING
          et_table = lt_head ) EQ abap_false.
        ev_process_result = zcl_sd_doc_digital=>wr_not_exit_dest.
        ev_technical_message = zcl_sd_doc_digital=>technical_message.
        et_message[] = zcl_sd_doc_digital=>lt_message.
        EXIT.
      ENDIF.

      IF lo_doc_digital->check_transporte(
        EXPORTING
          it_table = lt_head ) EQ abap_false.
        ev_process_result = zcl_sd_doc_digital=>wr_transportista.
        ev_technical_message = zcl_sd_doc_digital=>technical_message.
        et_message[] = zcl_sd_doc_digital=>lt_message.
        EXIT.
      ENDIF.

      IF lo_doc_digital->set_group_gc(
        EXPORTING
          iv_document = iv_process
          it_head     = lt_head[]
          it_items    = lt_items[]
        IMPORTING
          et_head     = lt_gc_head[]
          et_items    = lt_gc_items[]
          et_gck      = lt_gck[]
          et_gcp      = lt_gcp[] ) EQ abap_false.

        ev_technical_message = zcl_sd_doc_digital=>technical_message.
        ev_process_result = zcl_sd_doc_digital=>er_create_json.
        et_message[] = zcl_sd_doc_digital=>lt_message.
        EXIT.
      ENDIF.

      t_head[] = lt_gc_head[].
      t_items[] = lt_gc_items[].

*      IF sy-uname EQ '700-009'.
*        cl_demo_output=>display( t_head[] ).
*        cl_demo_output=>display( t_items[] ).
*      ENDIF.

      IF lo_doc_digital->create_json_gc(
        EXPORTING
          iv_document = iv_process
          it_head     = t_head[]
          it_items    = t_items[] ) EQ abap_false.

        ev_technical_message = zcl_sd_doc_digital=>technical_message.
        et_message[] = zcl_sd_doc_digital=>lt_message.
        ev_process_result = zcl_sd_doc_digital=>er_create_json.
        EXIT.

      ENDIF.

*      cl_demo_output=>display( lv_json ).

*      "Envío OK
      et_message[] = zcl_sd_doc_digital=>lt_message.
      ev_process_result = zcl_sd_doc_digital=>ok_send_gc.
*
    WHEN 'OE'. "Genera la Orden de Entrega

      IF lo_doc_digital->check_date(
       EXPORTING
         iv_bukrs  = iv_tplst
       IMPORTING
         ev_fecpro = lv_fecpro ) EQ abap_false.

        ev_process_result = zcl_sd_doc_digital=>wr_not_head_trans.
        ev_technical_message = zcl_sd_doc_digital=>technical_message.
        et_message[] = zcl_sd_doc_digital=>lt_message.
        EXIT.
      ENDIF.

      IF lo_doc_digital->get_transp_oe(
           EXPORTING
             iv_tplst  = iv_tplst
             it_tknum  = t_tknum[]
           IMPORTING
             et_head  = lt_oe_head[]
             et_items = lt_oe_items[] ) EQ abap_false.

        ev_process_result = zcl_sd_doc_digital=>wr_not_head_trans.
        ev_technical_message = zcl_sd_doc_digital=>technical_message.
        et_message[] = zcl_sd_doc_digital=>lt_message.
        EXIT.
      ENDIF.

      IF lo_doc_digital->check_pend_oe(
       EXPORTING
         it_table = lt_oe_head ) EQ abap_false.
        ev_process_result = zcl_sd_doc_digital=>wr_transportista.
        ev_technical_message = zcl_sd_doc_digital=>technical_message.
        et_message[] = zcl_sd_doc_digital=>lt_message.
        EXIT.
      ENDIF.

      IF lo_doc_digital->val_transp_oe(
        EXPORTING
          it_table = lt_oe_head ) EQ abap_false.
        ev_process_result = zcl_sd_doc_digital=>wr_transportista.
        ev_technical_message = zcl_sd_doc_digital=>technical_message.
        et_message[] = zcl_sd_doc_digital=>lt_message.
        EXIT.
      ENDIF.

*      ev_process_result = zcl_sd_doc_digital=>er_not_access_service.
*      EXIT.
*
*      IF lo_user_automation->check_user_exists( iv_user ) EQ abap_false.
*        ev_process_result = zcl_user_automation=>er_user_doesnot_exists.
*      ELSE.
*        IF lo_user_automation->unlock_user( iv_user ) EQ abap_true.
*          ev_process_result = zcl_user_automation=>ok_user_unlock.
*        ELSE.
*          ev_process_result = zcl_user_automation=>er_unlock_user.
*        ENDIF.
*      ENDIF.

*      t_oe_head[] = lt_oe_head[].
*      t_oe_items[] = lt_oe_items[].

      IF lo_doc_digital->send_oe(
              EXPORTING
                iv_document = iv_process
                it_head     = lt_oe_head[]
                it_items    = lt_oe_items[]
              IMPORTING
                et_head     = t_oe_head[]
                et_items    = t_oe_items[] ) EQ abap_false.

        ev_technical_message = zcl_sd_doc_digital=>technical_message.
        ev_process_result = zcl_sd_doc_digital=>er_create_json.
        et_message[] = zcl_sd_doc_digital=>lt_message.
        EXIT.
      ENDIF.

      IF lo_doc_digital->create_json_oe(
          EXPORTING
            iv_document = iv_process
            iv_fecdoc   = lv_fecpro
            it_head     = t_oe_head[]
            it_items    = t_oe_items[]
          IMPORTING
            ev_json     = lv_json ) EQ abap_false.

        ev_technical_message = zcl_sd_doc_digital=>technical_message.
        ev_process_result = zcl_sd_doc_digital=>er_create_json.
        et_message[] = zcl_sd_doc_digital=>lt_message.
        EXIT.

      ENDIF.

      ev_process_result = zcl_sd_doc_digital=>ok_send_oe.
      et_message[] = zcl_sd_doc_digital=>lt_message.

  ENDCASE.
* Termino

  ev_technical_message = zcl_sd_doc_digital=>technical_message.
  et_message[] = zcl_sd_doc_digital=>lt_message.
ENDFUNCTION.
