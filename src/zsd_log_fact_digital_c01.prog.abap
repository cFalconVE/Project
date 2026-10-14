*&---------------------------------------------------------------------*
*&  Include           ZSD_LOG_FACT_DIGITAL_C01
*&---------------------------------------------------------------------*

CLASS lcl_log_fact_dig DEFINITION.
  PUBLIC SECTION.
    DATA: gt_output TYPE TABLE OF tt_log.

    DATA:
      gr_table     TYPE REF TO cl_salv_table,
      gr_functions TYPE REF TO cl_salv_functions,
      gr_columns   TYPE REF TO cl_salv_columns_table,
      gr_column    TYPE REF TO cl_salv_column_table,
      gr_agg       TYPE REF TO cl_salv_aggregations,
      gr_sorts     TYPE REF TO cl_salv_sorts,
      lo_header    TYPE REF TO cl_salv_form_layout_grid,
      lo_h_label   TYPE REF TO cl_salv_form_label,
      lo_h_flow    TYPE REF TO cl_salv_form_layout_flow.
    METHODS:
      init_process.
  PRIVATE SECTION.
    METHODS:
      get_data,
      build_catalog IMPORTING i_field   TYPE lvc_fname
                              i_len     TYPE lvc_outlen
                              i_l       TYPE scrtext_l   "texto largo
                              i_m       TYPE scrtext_m    "Texto Medio
                              i_s       TYPE scrtext_s
                              i_display TYPE actsg,    "Texto corto
      display_data.

ENDCLASS.

CLASS lcl_log_fact_dig IMPLEMENTATION.
  METHOD init_process.
    get_data( ).

    IF gt_output[] IS NOT INITIAL.
      display_data( ).
    ELSE.
      MESSAGE i208(00) WITH text-m01.
    ENDIF.
  ENDMETHOD.

  METHOD get_data.
    DATA: ir_documento TYPE RANGE OF vbeln.

    SELECT ddtext, domvalue_l
      INTO TABLE @DATA(lt_status)
      FROM dd07t
      WHERE domname = 'ZSTATUS'.

    SELECT *
      INTO TABLE @gt_output
      FROM zsd_tb_oe_log
      WHERE sociedad IN @so_bukrs
      AND tdocumento IN @so_tdoc
      AND ndocumento IN @so_vbeln
      AND fecha IN @so_fecha
      AND status IN @so_stat.

    IF gt_output[] IS NOT INITIAL.
      LOOP AT gt_output ASSIGNING FIELD-SYMBOL(<fs_output>).
        APPEND VALUE #( sign = 'I' option = 'EQ' low = <fs_output>-ndocumento high = space )
            TO ir_documento.
      ENDLOOP.


      SELECT *
        INTO TABLE @DATA(lt_control)
        FROM zsd_tb_json_stat
        WHERE bukrs IN @so_bukrs
          AND vbeln IN @ir_documento.
    ENDIF.

    LOOP AT gt_output ASSIGNING  <fs_output>.
      READ TABLE lt_status ASSIGNING FIELD-SYMBOL(<fs_status>)
            WITH KEY domvalue_l = <fs_output>-status.
      IF sy-subrc EQ 0.
        <fs_output>-status_t = <fs_status>-ddtext.
      ENDIF.

      IF <fs_output>-status EQ '0'.
        READ TABLE lt_control ASSIGNING FIELD-SYMBOL(<ls_control>)
                WITH KEY tdocumento = <fs_output>-tdocumento
                         vbeln = <fs_output>-ndocumento.
        IF sy-subrc EQ 0.
          <fs_output>-ncontrol = <ls_control>-ncontrol.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD display_data.
    TRY.
        cl_salv_table=>factory( IMPORTING r_salv_table = gr_table
                                 CHANGING t_table = gt_output ).
      CATCH cx_salv_msg.
    ENDTRY.

    gr_functions = gr_table->get_functions( ).
    gr_functions->set_all( abap_true ).

    CREATE OBJECT lo_header.

    SELECT SINGLE butxt
      INTO @DATA(lv_butxt)
      FROM t001
      WHERE bukrs IN @so_bukrs.

    lo_h_label = lo_header->create_label( row = 1 column = 1 ).
    lo_h_label->set_text( 'LOG FACTURACIÓN DIGITAL' ) .

    lo_h_flow  = lo_header->create_flow( row = 2  column = 1 ).
    lo_h_flow->create_text( text = lv_butxt ) .

    DATA(lv_emision) = | FECHA DE EMISIÓN: | & |{ sy-datum DATE = USER }| &
                       | HORA DE EMISIÓN: | &  |{ sy-uzeit(2) }| & |:| & |{ sy-uzeit+2(2) }|
                       & |:| & |{ sy-uzeit+4(2) }|.
    lo_h_flow  = lo_header->create_flow( row = 3  column = 1 ).
    lo_h_flow->create_text( text = lv_emision ).

    gr_table->set_top_of_list( lo_header ).
    gr_table->set_top_of_list_print( lo_header ).

    TRY.
        build_catalog( EXPORTING i_field = 'MANDT' i_len = 4
                                   i_l = '' i_m = '' i_s = '' i_display = space ).
        build_catalog( EXPORTING i_field = 'SOCIEDAD' i_len = 10
                                 i_l = 'Sociedad' i_m = 'Sociedad' i_s = 'Soc.' i_display = 'X' ).
        build_catalog( EXPORTING i_field = 'TDOCUMENTO' i_len = 10
                                 i_l = 'Tipo de Documento' i_m = 'TpoDoc' i_s = 'TDoc' i_display = 'X' ).
        build_catalog( EXPORTING i_field = 'NDOCUMENTO' i_len = 10
                                 i_l = 'Ord. Entr.' i_m = 'Ord. Entr.' i_s = 'Ord. Entr.' i_display = 'X' ).
        build_catalog( EXPORTING i_field = 'PAGINA' i_len = 6
                                 i_l = 'Nr. Pag.' i_m = 'Nr. Pag.' i_s = 'Nr. Pag.' i_display = 'X' ).
        build_catalog( EXPORTING i_field = 'FECHA' i_len = 10
                                 i_l = 'Fecha' i_m = 'Fecha' i_s = 'Fecha' i_display = 'X' ).
        build_catalog( EXPORTING i_field = 'MENSAJE' i_len = 50
                                 i_l = 'Mensaje' i_m = 'Mensaje' i_s = 'Mensaje' i_display = 'X' ).
        build_catalog( EXPORTING i_field = 'NCONTROL' i_len = 12
                                 i_l = 'No.Control' i_m = 'No.Control' i_s = 'Control' i_display = 'X' ).
        build_catalog( EXPORTING i_field = 'STATUS' i_len = 12
                                 i_l = 'Status' i_m = 'Status' i_s = 'Status' i_display = ' ' ).
        build_catalog( EXPORTING i_field = 'STATUS_T' i_len = 12
                                 i_l = 'Status' i_m = 'Status' i_s = 'St.' i_display = 'X' ).
        build_catalog( EXPORTING i_field = 'URL' i_len = 20
                                 i_l = 'URL Recibido' i_m = 'URL Recibido' i_s = 'URL' i_display = 'X' ).
        build_catalog( EXPORTING i_field = 'UNAME' i_len = 12
                                 i_l = 'Usuario' i_m = 'Usuario' i_s = 'Usuario' i_display = 'X' ).
        build_catalog( EXPORTING i_field = 'ERDAT' i_len = 10
                                 i_l = 'Fecha Creación' i_m = 'Fecha' i_s = 'Fecha' i_display = 'X' ).
        build_catalog( EXPORTING i_field = 'ERZET' i_len = 10
                                 i_l = 'Hora Creación' i_m = 'Hora' i_s = 'Hora' i_display = 'X' ).
      CATCH cx_salv_not_found.
    ENDTRY.

    gr_table->display( ).
  ENDMETHOD.

  METHOD build_catalog.
    CASE i_display.

      WHEN 'X'.
        gr_columns = gr_table->get_columns( ).
        gr_column ?= gr_columns->get_column( i_field ).
        gr_column->set_long_text( i_l ).
        gr_column->set_medium_text( i_m ).
        gr_column->set_short_text( i_s ).
        gr_column->set_output_length( i_len ).
      WHEN space.
        gr_columns = gr_table->get_columns( ).
        gr_column ?= gr_columns->get_column( i_field ).
        gr_column->set_visible( ' ' ).
    ENDCASE.


  ENDMETHOD.
ENDCLASS.
