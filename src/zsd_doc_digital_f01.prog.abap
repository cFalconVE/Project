*&---------------------------------------------------------------------*
*&  Include  zsd_doc_digital_f01
*&---------------------------------------------------------------------*
*  FECHA DE CREACION: 03.02.2025
*  MODULO SAP     : SD
*  EMPRESA        : Corimon
*  AUTOR (NOMBRE) : Carlos Falcón
*  AUTOR (ID)     : 700-009
*  OBJECTO        : INCLUDE
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
*& Display Alv List
*&-----------------------------------------------------------------
FORM display_alv.

  TRY.
      cl_salv_table=>factory(
       IMPORTING
         r_salv_table = DATA(lo_alv_table)
       CHANGING
         t_table      = gt_results ).
    CATCH cx_salv_msg INTO DATA(lx_salv_msg).
      WRITE  lx_salv_msg->get_text(  ).
  ENDTRY.

  lo_alv_table->get_selections( )->set_selection_mode( if_salv_c_selection_mode=>multiple ).
  lo_alv_table->display( ).

ENDFORM.

*&-----------------------------------------------------------------
*& Generar Documento Digital
*&-----------------------------------------------------------------
FORM gen_report USING pv_process_type TYPE c. "int2.

  TYPES:
    tyr_tknum TYPE RANGE OF vttk-tknum,

    BEGIN OF ty_guia,
      tplst  TYPE tplst,
      tknum  TYPE tknum,
      dig_sl TYPE abap_bool,
    END OF ty_guia,

    tt_guia TYPE ty_guia,

    BEGIN OF ty_desp,
      tplst  TYPE tplst,
      tknum  TYPE tknum, "tyr_tknum,
      dig_sl TYPE abap_bool,
    END OF ty_desp.

  DATA:
    lv_process_result    TYPE string,
    lv_technical_message TYPE string,
    lt_message           TYPE TABLE OF symsg,
    ls_guia              TYPE tt_guia.
*        lt_rsdsselopt        TYPE TABLE OF rsdsselopt.

  DATA:
    lt_gc_head  TYPE STANDARD TABLE OF zv_cds_sd_gc, " ZSD_ST_GC_ENC,
    lt_gc_items TYPE STANDARD TABLE OF zv_cds_gcp,
    lt_oe_head  TYPE STANDARD TABLE OF zview_entrega_oe,
    lt_oe_items TYPE STANDARD TABLE OF zview_entp_oe,
    ls_dat_gc   TYPE zsd_st_datos_gc.

*  FIELD-SYMBOLS: <fs> TYPE ANY TABLE.

  ls_dat_gc = VALUE #( ord_dev     = pa_bktx1
                       ord_equi    = pa_bktx2
                       precintos   = pa_bktx3
                       nota_cred   = pa_bktx4
                       despachador = pa_desp ).

  IF pv_process_type = 'DE' OR pv_process_type = 'OR'.
*    DATA ls_guia TYPE ty_guia.

    DATA(lo_desp) = NEW zcl_sd_doc_fd( ).

    ls_guia = VALUE #( tplst = p_tplst
                       tknum = so_tknum-low ).

    DATA(lv_orden) = COND char3( WHEN pv_process_type = 'DE'
                                THEN |GC| ELSE |GD| ).

    TRY.
        lo_desp->init(
          EXPORTING
            is_guia   = ls_guia
            iv_proccess  = lv_orden
            is_dat_gc = ls_dat_gc
            iv_mostrar = 'X' ).
      CATCH cx_abap_invalid_value.    "

    ENDTRY.
  ELSEIF pv_process_type = 'RXP'.
    DATA ls_rxp TYPE ty_desp.

    ls_rxp = VALUE #( tplst = p_tplst
                      tknum = so_tknum-low
                      dig_sl = COND abap_bool( WHEN cb_dig = abap_true
                                               THEN abap_true
                                               ELSE abap_false ) ).

    DATA(lo_rxp) = NEW zcl_sd_doc_fd( ).

    TRY.
        lo_rxp->init(
          EXPORTING
            is_desp      = ls_rxp
            iv_proccess  = pv_process_type
            is_dat_gc    = ls_dat_gc
            iv_mostrar   = 'X' ).
      CATCH cx_abap_invalid_value.    "

    ENDTRY.

  ELSE.

    CALL FUNCTION 'ZSD_FM_DOCDIGITAL'
      EXPORTING
        iv_process           = pv_process_type
        iv_tplst             = p_tplst
        is_datos_gc          = ls_dat_gc
      IMPORTING
        ev_process_result    = lv_process_result
        ev_technical_message = lv_technical_message
      TABLES
        t_tknum              = so_tknum[]
        t_head               = lt_gc_head
        t_items              = lt_gc_items
        t_oe_head            = lt_oe_head
        t_oe_items           = lt_oe_items
        et_message           = lt_message.

    READ TABLE lt_gc_head
          INTO DATA(ls_head)
         WITH KEY frkrl = abap_true.

    LOOP AT lt_message INTO DATA(ls_message).
      APPEND INITIAL LINE TO gt_results ASSIGNING FIELD-SYMBOL(<ls_results>).

      IF NOT ls_message-msgv1 IS INITIAL.
        <ls_results>-message = ls_message-msgv1.
      ENDIF.

      IF NOT ls_message-msgv2 IS INITIAL.
        CONCATENATE <ls_results>-message ls_message-msgv2
              INTO <ls_results>-message SEPARATED BY space.
      ENDIF.

      IF NOT ls_message-msgv3 IS INITIAL.
        CONCATENATE <ls_results>-message ls_message-msgv3
              INTO <ls_results>-message SEPARATED BY space.
      ENDIF.

      <ls_results>-proceso = pv_process_type.
*  <ls_results>-nrodocumento = ls_head-nrotrans.
      <ls_results>-nrodocumento = so_tknum-low.

      IF lv_process_result(2) EQ 'OK'.
*      IF NOT <ls_results>-message IS INITIAL.
*        <ls_results>-message = ls_message.
*      ELSE.
        IF <ls_results>-message IS INITIAL.
          <ls_results>-message = 'Procesado OK'.
        ENDIF.
        <ls_results>-status = gc_green_status.
      ELSEIF lv_process_result(2) EQ 'WR'.
*      IF NOT lv_message IS INITIAL.
*        <ls_results>-message = lv_message.
*      ELSE.
        IF <ls_results>-message IS INITIAL.
          <ls_results>-message = 'Proceso Warning'.
        ENDIF.
        <ls_results>-status = gc_yellow_status.
      ELSE.
*      IF NOT lv_message IS INITIAL.
*        <ls_results>-message = lv_message.
*      ELSE.
        IF <ls_results>-message IS INITIAL.
          <ls_results>-message = 'Procesado KO'.
        ENDIF.
        <ls_results>-status = gc_red_status.
      ENDIF.
    ENDLOOP.
  ENDIF.

ENDFORM.
