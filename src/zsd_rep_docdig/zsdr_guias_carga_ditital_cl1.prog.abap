*&---------------------------------------------------------------------*
*&  Include           ZSDR_GUIAS_CARGA_DITITAL_CL1
*&---------------------------------------------------------------------*

CLASS lcl_report_handler DEFINITION.
  PUBLIC SECTION.


    METHODS:
      init,
      get_data,

      handle_double_click FOR EVENT  node_double_click OF cl_gui_alv_tree
        IMPORTING
          node_key sender,

      on_link_click FOR EVENT link_click OF cl_gui_alv_tree
        IMPORTING fieldname
                  node_key,

      handle_item_click
                  FOR EVENT item_keypress OF cl_gui_alv_tree
        IMPORTING node_key fieldname,

      handle_button_click FOR EVENT button_click OF cl_gui_alv_tree
        IMPORTING
          node_key
          fieldname.

    CLASS-METHODS:
      build_hierarchy_header    CHANGING c_p_hierarchy_header TYPE treev_hhdr,
      build_catalog,
      get_document_detail IMPORTING i_tknum TYPE vttk-tknum,
      create_hierarchy,
      top_of_page,
      register_events,
      refresh_data,
      create_object,
      top_of_page_tree RETURNING VALUE(t_comment) TYPE slis_t_listheader,
      get_logo RETURNING VALUE(logo) TYPE sdydo_value.

  PRIVATE SECTION.



ENDCLASS.


CLASS lcl_report_handler IMPLEMENTATION.
  METHOD init.
    get_data( ).

    IF gt_guias[] IS INITIAL.
      MESSAGE i208(00) WITH text-m01.
    ELSE.
      CALL SCREEN 9000.
    ENDIF.
  ENDMETHOD.

  METHOD get_data.
    DATA: lv_status   TYPE icon_d,
          lv_status_d TYPE icon_d,
          lv_paginas  TYPE i.
    DATA: ls_style TYPE lvc_s_styl,
          lt_style TYPE lvc_t_styl.
    DATA: wa_guias TYPE tt_guias.

    CLEAR:  gt_guias_d[], gt_guias_h[], gt_doc_detail[], gt_guias[].

    SELECT
           y~*,
           x~*
      INTO TABLE @DATA(lt_base)
      FROM zsd_tb_gck AS x
      INNER JOIN zsd_tb_gcp AS y ON x~tknum EQ y~tknum_c
      WHERE x~tplst IN @so_tplst
        AND x~tknum IN @so_tknum
        AND x~erdat IN @so_erdat.

    SORT lt_base BY y-tknum_c.

    IF lt_base[] IS NOT INITIAL.
      SELECT tknum, vbeln
           INTO TABLE @DATA(lt_entregas)
           FROM vttp
        FOR ALL ENTRIES IN @lt_base
           WHERE tknum EQ @lt_base-y-tknum.

      IF lt_entregas[] IS NOT INITIAL.
        SELECT x~*, y~tdocumento, y~aedat AS fec_procesado, y~aezet AS hora_procesado
          INTO TABLE @DATA(lt_ord_entrega)
          FROM zsd_likp_oe AS x
          LEFT OUTER JOIN zsd_recep_desp AS y ON x~vbeln_oe EQ y~vbeln
            FOR ALL ENTRIES IN @lt_entregas
          WHERE x~vbeln EQ @lt_entregas-vbeln.

* vbelv, posnv, vbeln, posnn
        SELECT x~vbelv,  x~vbeln, y~aedat AS fec_procesado, y~aezet AS hora_procesado
          INTO TABLE @DATA(lt_flujo)
          FROM vbfa AS x
          LEFT OUTER JOIN zsd_recep_desp AS y ON x~vbeln EQ y~vbeln
          FOR ALL ENTRIES IN @lt_entregas
          WHERE x~vbelv EQ @lt_entregas-vbeln
            AND x~vbtyp_n EQ 'M'
            AND x~vbtyp_v EQ 'J'.
      ENDIF.
    ENDIF.

    LOOP AT lt_base ASSIGNING FIELD-SYMBOL(<ls_base>).
      CLEAR: lv_status_d, lv_status.

      AT NEW y-tknum_c.
        ADD 1 TO lv_paginas.
      ENDAT.

      CASE <ls_base>-y-estado.
        WHEN 'C' OR 'G' OR 'P'.
          lv_status = '@09@'.
        WHEN 'E'.
          lv_status = '@0A@'.
        WHEN 'S'.
          lv_status = '@08@'.
      ENDCASE.
      " Detalle

      CASE <ls_base>-x-env_desp.
        WHEN 'S'.
          lv_status_d = '@08@'.
        WHEN 'E'.
          lv_status_d = '@0A@'.
        WHEN OTHERS.
          lv_status_d = '@09@'.
      ENDCASE.


      APPEND VALUE #( tknum_c = <ls_base>-x-tknum
                      tknum = <ls_base>-y-tknum
                      pagina = <ls_base>-y-pagina
                      estado = <ls_base>-y-estado
                      status = lv_status
                      aedat  = <ls_base>-y-aedat
                      aezet  = <ls_base>-y-aezet
                      env_desp = lv_status_d
                      fec_desp = <ls_base>-x-fec_desp
                      hora_desp = <ls_base>-x-hora_desp
                      fec_exit = <ls_base>-x-fec_exit
                      hora_exit = <ls_base>-x-hora_exit
                      fec_fin = <ls_base>-x-fec_fin
                      hora_fin = <ls_base>-x-hora_fin
                      url    = <ls_base>-y-url )
                      TO gt_guias_d.

      wa_guias-erdat = <ls_base>-x-erdat.
      wa_guias-tplst = <ls_base>-x-tplst.
      wa_guias-guias = 1.
      COLLECT wa_guias INTO gt_guias.
      CLEAR wa_guias.

      AT END OF y-tknum_c.

        CASE <ls_base>-x-estado.
          WHEN 'C' OR 'G' OR 'P'.
            lv_status = '@09@'.
          WHEN 'E'.
            lv_status = '@0A@'.
          WHEN 'S'.
            lv_status = '@08@'.
        ENDCASE.

        " Cabecera
        APPEND VALUE #( tplst = <ls_base>-x-tplst
                         erdat = <ls_base>-x-erdat
                         tknum = <ls_base>-x-tknum
                         estado = <ls_base>-x-estado
                         status = lv_status
                         pagina = lv_paginas )
                         TO gt_guias_h.
        CLEAR lv_paginas.
      ENDAT.
    ENDLOOP.

    LOOP AT lt_entregas ASSIGNING FIELD-SYMBOL(<ls_entregas>).
      IF line_exists( lt_flujo[ vbelv = <ls_entregas>-vbeln ] ).
        LOOP AT lt_flujo ASSIGNING FIELD-SYMBOL(<ls_flujo>)
              WHERE vbelv EQ <ls_entregas>-vbeln.
          APPEND INITIAL LINE TO gt_doc_detail ASSIGNING FIELD-SYMBOL(<ls_doc_detail>).
          <ls_doc_detail>-tknum = <ls_entregas>-tknum.
          <ls_doc_detail>-vbeln = <ls_entregas>-vbeln.
          "Ord. Entr. FD
          TRY.
              <ls_doc_detail>-vbeln_oe = lt_ord_entrega[ x-vbeln = <ls_entregas>-vbeln ]-x-vbeln_oe.
              <ls_doc_detail>-fec_procesado = lt_ord_entrega[ x-vbeln = <ls_entregas>-vbeln ]-fec_procesado.
              <ls_doc_detail>-hora_procesado = lt_ord_entrega[ x-vbeln = <ls_entregas>-vbeln ]-hora_procesado.
            CATCH cx_sy_itab_line_not_found.
          ENDTRY.
          <ls_doc_detail>-vbeln_fac = <ls_flujo>-vbeln.
          <ls_doc_detail>-fec_procesado_fc = <ls_flujo>-fec_procesado.
          <ls_doc_detail>-hora_procesado_fc = <ls_flujo>-hora_procesado.
        ENDLOOP.
      ELSE.
        APPEND INITIAL LINE TO gt_doc_detail ASSIGNING <ls_doc_detail>.
        <ls_doc_detail>-tknum = <ls_entregas>-tknum.
        <ls_doc_detail>-vbeln = <ls_entregas>-vbeln.

        TRY.
            <ls_doc_detail>-vbeln_oe = lt_ord_entrega[ x-vbeln = <ls_entregas>-vbeln ]-x-vbeln_oe.

            <ls_doc_detail>-fec_procesado = lt_ord_entrega[ x-vbeln = <ls_entregas>-vbeln ]-fec_procesado.
            <ls_doc_detail>-hora_procesado = lt_ord_entrega[ x-vbeln = <ls_entregas>-vbeln ]-hora_procesado.
          CATCH cx_sy_itab_line_not_found.
        ENDTRY.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.
  METHOD  build_hierarchy_header.
    c_p_hierarchy_header-heading = 'Fecha'.
    c_p_hierarchy_header-tooltip = 'Guias por Fecha' .
    c_p_hierarchy_header-width = 37.
    c_p_hierarchy_header-width_pix = ''.
  ENDMETHOD.

  METHOD build_catalog.
    APPEND INITIAL LINE TO gt_fieldcat ASSIGNING FIELD-SYMBOL(<ls_fcat>).
    <ls_fcat>-fieldname = 'PAGINAS' .
    <ls_fcat>-coltext = 'Nro. Documentos' .
    <ls_fcat>-no_zero = 'X'.
    <ls_fcat>-outputlen = 20.
    <ls_fcat>-just = 'C'.

    APPEND INITIAL LINE TO gt_fieldcat ASSIGNING <ls_fcat>.
    <ls_fcat>-fieldname = 'TKNUM' .
    <ls_fcat>-coltext = 'Nro.Transporte' .
    <ls_fcat>-outputlen = 20.
    <ls_fcat>-hotspot = 'X'.
    <ls_fcat>-convexit = 'ALPHA'.

    APPEND INITIAL LINE TO gt_fieldcat ASSIGNING <ls_fcat>.
    <ls_fcat>-fieldname = 'PAGINA' .
    <ls_fcat>-coltext = 'Num. Pag' .
    <ls_fcat>-no_zero = 'X'.
    <ls_fcat>-outputlen = 15.
    <ls_fcat>-just = 'C'.

    APPEND INITIAL LINE TO gt_fieldcat ASSIGNING <ls_fcat>.
    <ls_fcat>-fieldname = 'STATUS' .
    <ls_fcat>-coltext = 'Status' .
    <ls_fcat>-icon = 'X'.
    <ls_fcat>-outputlen = 10.
    <ls_fcat>-just = 'C'.

    APPEND INITIAL LINE TO gt_fieldcat ASSIGNING <ls_fcat>.
    <ls_fcat>-fieldname = 'AEDAT' .
    <ls_fcat>-coltext = 'Fecha' .
    <ls_fcat>-outputlen = 16.
    <ls_fcat>-ref_table = 'BKPF'.
    <ls_fcat>-ref_field = 'BUDAT'.

    APPEND INITIAL LINE TO gt_fieldcat ASSIGNING <ls_fcat>.
    <ls_fcat>-fieldname = 'AEZET' .
    <ls_fcat>-coltext = 'Hora' .
    <ls_fcat>-outputlen = 10.
    <ls_fcat>-no_zero = 'X'.

* BOM 16072026
    APPEND INITIAL LINE TO gt_fieldcat ASSIGNING <ls_fcat>.
    <ls_fcat>-fieldname = 'ENV_DESP' .
    <ls_fcat>-coltext = 'St.Envio Doc.' .
    <ls_fcat>-icon = 'X'.
    <ls_fcat>-outputlen = 10.
    <ls_fcat>-just = 'C'.

    APPEND INITIAL LINE TO gt_fieldcat ASSIGNING <ls_fcat>.
    <ls_fcat>-fieldname = 'FEC_DESP' .
    <ls_fcat>-coltext = 'Fecha Envio' .
    <ls_fcat>-outputlen = 16.
    <ls_fcat>-ref_table = 'BKPF'.
    <ls_fcat>-ref_field = 'BUDAT'.

    APPEND INITIAL LINE TO gt_fieldcat ASSIGNING <ls_fcat>.
    <ls_fcat>-fieldname = 'HORA_DESP' .
    <ls_fcat>-coltext = 'Hora Envio' .
    <ls_fcat>-outputlen = 10.
    <ls_fcat>-no_zero = 'X'.

    APPEND INITIAL LINE TO gt_fieldcat ASSIGNING <ls_fcat>.
    <ls_fcat>-fieldname = 'FEC_EXIT' .
    <ls_fcat>-coltext = 'Fecha Ini.Transp.' .
    <ls_fcat>-outputlen = 16.
    <ls_fcat>-ref_table = 'BKPF'.
    <ls_fcat>-ref_field = 'BUDAT'.

    APPEND INITIAL LINE TO gt_fieldcat ASSIGNING <ls_fcat>.
    <ls_fcat>-fieldname = 'HORA_EXIT' .
    <ls_fcat>-coltext = 'Hora Ini.Transp.' .
    <ls_fcat>-outputlen = 10.
    <ls_fcat>-no_zero = 'X'.

    APPEND INITIAL LINE TO gt_fieldcat ASSIGNING <ls_fcat>.
    <ls_fcat>-fieldname = 'FEC_FIN' .
    <ls_fcat>-coltext = 'Fecha FinTransp.' .
    <ls_fcat>-outputlen = 16.
    <ls_fcat>-ref_table = 'BKPF'.
    <ls_fcat>-ref_field = 'BUDAT'.

    APPEND INITIAL LINE TO gt_fieldcat ASSIGNING <ls_fcat>.
    <ls_fcat>-fieldname = 'HORA_FIN' .
    <ls_fcat>-coltext = 'Hora FinTransp.' .
    <ls_fcat>-outputlen = 10.
    <ls_fcat>-no_zero = 'X'.

*    APPEND INITIAL LINE TO gt_fieldcat ASSIGNING <ls_fcat>.
*    <ls_fcat>-fieldname = 'FLUJO' .
*    <ls_fcat>-coltext = 'Detalle' .
*    <ls_fcat>-just = 'C'.
**    <ls_fcat>-icon = 'X'.
*    <ls_fcat>-hotspot = 'X'.
**    <ls_fcat>-style = cl_gui_alv_grid=>mc_style_button.
*    <ls_fcat>-outputlen = 8.
* EOM 16072026

*    APPEND INITIAL LINE TO gt_fieldcat ASSIGNING <ls_fcat>.
*    <ls_fcat>-fieldname = 'VBELN_OE' .
*    <ls_fcat>-coltext = 'Ord. Entr.' .
*    <ls_fcat>-outputlen = 20.
*    <ls_fcat>-no_zero = 'X'.
*    <ls_fcat>-convexit = 'ALPHA'.

    APPEND INITIAL LINE TO gt_fieldcat ASSIGNING <ls_fcat>.
    <ls_fcat>-fieldname = 'URL' .
    <ls_fcat>-coltext = 'URL o link' .
    <ls_fcat>-outputlen = 150.
    <ls_fcat>-hotspot = 'X'.

  ENDMETHOD.

  METHOD create_hierarchy.
    DATA: l_node_text TYPE lvc_value.
    DATA: lv_estatus_h TYPE icon_d.
    DATA: ls_node           TYPE lvc_s_layn.
    DATA: wa_tree_output LIKE LINE OF gt_tree_output,
          it_item_layout TYPE lvc_t_layi,
          wa_item_layout TYPE lvc_s_layi.
    DATA: lv_nro_guias TYPE i.
    DATA: ir_tknum TYPE RANGE OF vttk-tknum.
    DATA:  lt_doc_detail TYPE TABLE OF  tt_doc_detail.

    CALL METHOD o_tree->add_node
      EXPORTING
        i_relat_node_key = ''
        i_relationship   = cl_gui_column_tree=>relat_last_child
        i_node_text      = text-t02
      IMPORTING
        e_new_node_key   = l_top_key.

    SORT gt_doc_detail BY tknum vbeln ASCENDING.
    SORT gt_guias BY erdat DESCENDING .
    SORT gt_guias_h BY erdat DESCENDING tknum DESCENDING.
    SORT gt_guias_d BY tknum pagina ASCENDING.

    LOOP AT gt_guias ASSIGNING FIELD-SYMBOL(<ls_guias>).
      "1er nivel
      CLEAR wa_tree_output.
      WRITE <ls_guias>-erdat TO l_node_text  DD/MM/YYYY.
      wa_tree_output-paginas = <ls_guias>-guias .

      LOOP AT gt_guias_h ASSIGNING FIELD-SYMBOL(<ls_guias_h>)
          WHERE tplst EQ <ls_guias>-tplst
            AND erdat EQ <ls_guias>-erdat
            AND estado NE 'S'.

        lv_estatus_h = '@09@'.
        EXIT.
      ENDLOOP.
      IF sy-subrc NE 0.
        lv_estatus_h = '@08@'.
      ENDIF.

      CLEAR it_item_layout[].
      wa_item_layout-t_image = lv_estatus_h.
      wa_item_layout-fieldname = o_tree->c_hierarchy_column_name.
      wa_item_layout-style = cl_gui_column_tree=>style_intensifd_critical.
      APPEND wa_item_layout TO it_item_layout.
      CLEAR wa_item_layout.

      CALL METHOD o_tree->add_node
        EXPORTING
          i_relat_node_key = l_top_key
          i_relationship   = cl_gui_column_tree=>relat_last_child
          i_node_text      = l_node_text
          is_outtab_line   = wa_tree_output
          is_node_layout   = ls_node
          it_item_layout   = it_item_layout
        IMPORTING
          e_new_node_key   = l_node_key.

      LOOP AT gt_guias_h ASSIGNING <ls_guias_h>
          WHERE tplst EQ <ls_guias>-tplst
            AND erdat EQ <ls_guias>-erdat.
        "2do nivel
        CLEAR l_node_text.
        CLEAR wa_tree_output.
        l_node_text = <ls_guias_h>-tknum.

        CLEAR it_item_layout[].
        wa_item_layout-t_image = <ls_guias_h>-status.
        wa_item_layout-fieldname = o_tree->c_hierarchy_column_name.
        wa_item_layout-style = cl_gui_column_tree=>style_intensifd_critical.
        APPEND wa_item_layout TO it_item_layout.
        CLEAR wa_item_layout.

        CLEAR it_item_layout[].
        wa_item_layout-t_image = icon_te_receipts.
        wa_item_layout-fieldname = 'FLUJO'.
        wa_item_layout-class     = cl_gui_column_tree=>item_class_button.
        wa_item_layout-style = cl_gui_column_tree=>style_intensifd_critical.
        APPEND wa_item_layout TO it_item_layout.
        CLEAR wa_item_layout.

        LOOP AT gt_guias_d ASSIGNING FIELD-SYMBOL(<ls_detail>)
            WHERE tknum_c EQ <ls_guias_h>-tknum.
          lv_nro_guias = lv_nro_guias + 1.
        ENDLOOP.

        wa_tree_output-aedat = <ls_guias_h>-erdat.
        wa_tree_output-pagina  = lv_nro_guias.


        CLEAR lv_nro_guias.

        CALL METHOD o_tree->add_node
          EXPORTING
            i_relat_node_key = l_node_key
            i_relationship   = cl_gui_column_tree=>relat_last_child
            i_node_text      = l_node_text
            is_outtab_line   = wa_tree_output
            is_node_layout   = ls_node
            it_item_layout   = it_item_layout
          IMPORTING
            e_new_node_key   = l_node2_key.

        CLEAR ir_tknum[].
        LOOP AT gt_guias_d ASSIGNING <ls_detail>
            WHERE tknum_c EQ <ls_guias_h>-tknum.
          " 3er nivel
          CLEAR l_node_text.
          CLEAR wa_tree_output.
          MOVE-CORRESPONDING <ls_detail> TO wa_tree_output.

          APPEND VALUE #( sign = 'I' option = 'EQ' low = <ls_detail>-tknum ) TO ir_tknum.

          l_node_text = <ls_detail>-tknum.

          CALL METHOD o_tree->add_node
            EXPORTING
              i_relat_node_key = l_node2_key
              i_relationship   = cl_gui_column_tree=>relat_last_child
              i_node_text      = l_node_text
              is_outtab_line   = wa_tree_output
            IMPORTING
              e_new_node_key   = l_node_line.
        ENDLOOP.

        IF line_exists( gt_doc_detail[ tknum = <ls_guias_h>-tknum ] ) AND ir_tknum[] IS NOT INITIAL.

          l_node_text = 'Entregas'.

          CLEAR wa_tree_output.
          CLEAR it_item_layout[].
          wa_item_layout-t_image = icon_delivery.
          wa_item_layout-fieldname = o_tree->c_hierarchy_column_name.
          wa_item_layout-style = cl_gui_column_tree=>style_intensifd_critical.
          APPEND wa_item_layout TO it_item_layout.
          CLEAR wa_item_layout.


          CALL METHOD o_tree->add_node
            EXPORTING
              i_relat_node_key = l_node2_key
              i_relationship   = cl_gui_column_tree=>relat_last_child
              i_node_text      = l_node_text
              is_outtab_line   = wa_tree_output
              is_node_layout   = ls_node
              it_item_layout   = it_item_layout
            IMPORTING
              e_new_node_key   = l_node3_key.

          CLEAR lt_doc_detail[].
          lt_doc_detail = VALUE #( FOR wa IN gt_doc_detail WHERE ( tknum IN ir_tknum )
                          ( CORRESPONDING #( wa ) ) ).
          SORT lt_doc_detail BY vbeln.

          LOOP AT lt_doc_detail ASSIGNING FIELD-SYMBOL(<ls_doc_detail>).
            AT NEW vbeln.
              CLEAR wa_tree_output.
              l_node_text = <ls_doc_detail>-vbeln.
              wa_tree_output-vbeln_oe = <ls_doc_detail>-vbeln_oe.
*              wa_tree_output-fec_fin = <ls_doc_detail>-fec_procesado.
*              wa_tree_output-hora_fin = <ls_doc_detail>-hora_procesado.


              CALL METHOD o_tree->add_node
                EXPORTING
                  i_relat_node_key = l_node3_key
                  i_relationship   = cl_gui_column_tree=>relat_last_child
                  i_node_text      = l_node_text
                  is_outtab_line   = wa_tree_output
                  is_node_layout   = ls_node
                IMPORTING
                  e_new_node_key   = l_node4_key.
            ENDAT.

            IF <ls_doc_detail>-vbeln_fac IS NOT INITIAL.
              CLEAR wa_tree_output.
              wa_tree_output-fec_fin = <ls_doc_detail>-fec_procesado_fc.
              wa_tree_output-hora_fin = <ls_doc_detail>-hora_procesado_fc.
              l_node_text = <ls_doc_detail>-vbeln_fac.

              CLEAR it_item_layout[].
              wa_item_layout-t_image = icon_otf_document.
              wa_item_layout-fieldname = o_tree->c_hierarchy_column_name.
              wa_item_layout-style = cl_gui_column_tree=>style_intensifd_critical.
              APPEND wa_item_layout TO it_item_layout.
              CLEAR wa_item_layout.

              CALL METHOD o_tree->add_node
                EXPORTING
                  i_relat_node_key = l_node4_key
                  i_relationship   = cl_gui_column_tree=>relat_last_child
                  i_node_text      = l_node_text
                  is_outtab_line   = wa_tree_output
                  is_node_layout   = ls_node
                  it_item_layout   = it_item_layout
                IMPORTING
                  e_new_node_key   = l_node5_key.

            ELSEIF <ls_doc_detail>-vbeln_oe IS NOT INITIAL.
              CLEAR wa_tree_output.
              wa_tree_output-fec_fin = <ls_doc_detail>-fec_procesado.
              wa_tree_output-hora_fin = <ls_doc_detail>-hora_procesado.
              l_node_text = <ls_doc_detail>-vbeln_oe.

              CLEAR it_item_layout[].
              wa_item_layout-t_image = icon_order.
              wa_item_layout-fieldname = o_tree->c_hierarchy_column_name.
              wa_item_layout-style = cl_gui_column_tree=>style_intensifd_critical.
              APPEND wa_item_layout TO it_item_layout.
              CLEAR wa_item_layout.

              CALL METHOD o_tree->add_node
                EXPORTING
                  i_relat_node_key = l_node4_key
                  i_relationship   = cl_gui_column_tree=>relat_last_child
                  i_node_text      = l_node_text
                  is_outtab_line   = wa_tree_output
                  is_node_layout   = ls_node
                  it_item_layout   = it_item_layout
                IMPORTING
                  e_new_node_key   = l_node5_key.
            ENDIF.

          ENDLOOP.

        ENDIF.
      ENDLOOP.


    ENDLOOP.
  ENDMETHOD.
  METHOD top_of_page_tree .
    DATA: ls_line TYPE slis_listheader.

    SELECT SINGLE  y~butxt
      INTO @DATA(lv_filial)
      FROM ttds AS x
      INNER JOIN t001 AS y ON x~bukrs EQ y~bukrs
      WHERE x~tplst IN @so_tplst.

*    SELECT SINGLE bezei
*         INTO @DATA(lv_bezei)
*         FROM ttdst
*         WHERE spras EQ @sy-langu
*           AND tplst IN @so_tplst.

    ls_line-typ = 'H'.
    ls_line-info = 'Reporte Guias de Carga Digital'.
    APPEND ls_line TO t_comment.
    CLEAR ls_line.

    ls_line-typ = 'S'.
    ls_line-info = lv_filial.
    APPEND ls_line TO t_comment.
    CLEAR ls_line.

    ls_line-typ = 'S'.
    DATA(lv_emision) = | Fecha: | & |{ so_erdat-low DATE = USER }| &
                          | - | & |{ so_erdat-high DATE = USER }|.

    ls_line-info = lv_emision.
    APPEND ls_line TO t_comment.
    CLEAR ls_line.

    APPEND INITIAL LINE TO t_comment.
    APPEND INITIAL LINE TO t_comment.
  ENDMETHOD.

  METHOD  top_of_page.

    DATA: g_text           TYPE sdydo_text_element.

    SELECT SINGLE bezei
      INTO @DATA(lv_bezei)
      FROM ttdst
      WHERE spras EQ @sy-langu
        AND tplst IN @so_tplst.

    g_text   = 'Reporte Guias de Carga Digital'.
    CALL METHOD o_document->add_text
      EXPORTING
        text         = g_text
        sap_emphasis = cl_dd_area=>heading.

    CALL METHOD o_document->add_gap
      EXPORTING
        width = 20.

    CALL METHOD o_document->new_line.
    CALL METHOD o_document->add_text
      EXPORTING
        text = ' '.
    CALL METHOD o_document->new_line.

    CLEAR g_text.
    g_text = lv_bezei.
    CALL METHOD o_document->add_text
      EXPORTING
        text      = g_text
        sap_style = cl_dd_area=>strong.


    CALL METHOD o_document->new_line.

    g_text = 'Fecha:'.
    CALL METHOD o_document->add_text
      EXPORTING
        text      = g_text
        sap_style = cl_dd_area=>strong.


    DATA(lv_emision) = |{ so_erdat-low DATE = USER }| &
                       | - | & |{ so_erdat-high DATE = USER }|.

    g_text = lv_emision.
    CALL METHOD o_document->add_text
      EXPORTING
        text = g_text.

    CALL METHOD o_document->add_gap
      EXPORTING
        width = 10.


    o_document->display_document( parent = o_top ).
  ENDMETHOD.

  METHOD on_link_click.

    DATA: wa_tree_output LIKE LINE OF gt_tree_output.
    CALL METHOD o_tree->get_outtab_line
      EXPORTING
        i_node_key     = node_key
      IMPORTING
        e_outtab_line  = wa_tree_output
      EXCEPTIONS
        node_not_found = 1
        OTHERS         = 2.

    CASE fieldname.
      WHEN 'TKNUM'.
        SET PARAMETER ID 'TNR' FIELD wa_tree_output-tknum_c.
        CALL TRANSACTION 'VT03N' AND SKIP FIRST SCREEN.

      WHEN 'URL'.
        CALL FUNCTION 'CALL_BROWSER'
          EXPORTING
            url                    = wa_tree_output-url
          EXCEPTIONS
            frontend_not_supported = 1
            frontend_error         = 2
            prog_not_found         = 3
            no_batch               = 4
            unspecified_error      = 5
            OTHERS                 = 6.

    ENDCASE.

  ENDMETHOD.
  METHOD register_events.
    DATA: lt_events        TYPE cntl_simple_events,
          l_event          TYPE cntl_simple_event,
          ls_event         LIKE LINE OF lt_events,
          l_event_receiver TYPE REF TO lcl_report_handler.

    CALL METHOD o_tree->get_registered_events
      IMPORTING
        events = lt_events.

    ls_event-eventid = cl_gui_column_tree=>eventid_link_click.
    APPEND ls_event TO lt_events.
    ls_event-eventid = cl_gui_column_tree=>eventid_node_double_click.
    APPEND ls_event TO lt_events.
    ls_event-eventid = cl_gui_column_tree=>eventid_button_click.
    APPEND ls_event TO lt_events.
    ls_event-eventid = cl_gui_column_tree=>eventid_item_keypress.
    APPEND ls_event TO lt_events.

    CALL METHOD o_tree->set_registered_events
      EXPORTING
        events                    = lt_events
      EXCEPTIONS
        cntl_error                = 1
        cntl_system_error         = 2
        illegal_event_combination = 3.

    l_event_receiver = NEW #( ).
    SET HANDLER l_event_receiver->handle_item_click FOR o_tree.
    SET HANDLER l_event_receiver->handle_double_click FOR o_tree.
    SET HANDLER l_event_receiver->on_link_click FOR o_tree.
    SET HANDLER l_event_receiver->handle_button_click FOR o_tree.
  ENDMETHOD.
  METHOD  get_logo.
    SELECT SINGLE  y~objkey
      INTO @DATA(lv_logo)
      FROM ttds AS x
      INNER JOIN zfi_retxml05 AS y ON x~bukrs EQ y~bukrs
      WHERE x~tplst IN @so_tplst.

    IF sy-subrc EQ 0.
      logo = lv_logo.
    ENDIF.
  ENDMETHOD.
  METHOD handle_item_click.
  ENDMETHOD.
  METHOD handle_button_click.
    DATA: lv_node TYPE lvc_nkey.
    break 700-006.
    lv_node = node_key + 1.
    DATA: wa_tree_output LIKE LINE OF gt_tree_output.
    CALL METHOD o_tree->get_outtab_line
      EXPORTING
        i_node_key     = lv_node
      IMPORTING
        e_outtab_line  = wa_tree_output
      EXCEPTIONS
        node_not_found = 1
        OTHERS         = 2.

    CASE fieldname.
      WHEN 'FLUJO'.
        get_document_detail( wa_tree_output-tknum ).
    ENDCASE.

  ENDMETHOD.

  METHOD handle_double_click.
  ENDMETHOD.

  METHOD get_document_detail.
    CONSTANTS: gc_true TYPE sap_bool VALUE 'X'.

    DATA:   gr_table_a  TYPE REF TO cl_salv_table.
    DATA: lt_doc_detail TYPE TABLE OF tt_doc_detail.
    DATA: lv_first TYPE c.
    DATA:       lo_salv_sorts  TYPE REF TO cl_salv_sorts.
    DATA: lr_columns TYPE REF TO cl_salv_columns.
    DATA: lr_column TYPE REF TO cl_salv_column.

    SELECT vbeln
      INTO TABLE @DATA(lt_entregas)
      FROM vttp
      WHERE tknum EQ @i_tknum.

    IF lt_entregas[] IS NOT INITIAL.
      SELECT *
        INTO TABLE @DATA(lt_ord_entrega)
        FROM zsd_likp_oe
          FOR ALL ENTRIES IN @lt_entregas
        WHERE vbeln EQ @lt_entregas-vbeln.

      SELECT vbelv, vbeln
        INTO TABLE @DATA(lt_flujo)
        FROM vbfa
        FOR ALL ENTRIES IN @lt_entregas
        WHERE vbelv EQ @lt_entregas-vbeln
          AND vbtyp_n EQ 'M'
          AND vbtyp_v EQ 'J'.

      LOOP AT lt_entregas ASSIGNING FIELD-SYMBOL(<ls_entregas>).
        LOOP AT lt_flujo ASSIGNING FIELD-SYMBOL(<ls_flujo>)
              WHERE vbelv EQ <ls_entregas>-vbeln.
          APPEND INITIAL LINE TO lt_doc_detail ASSIGNING FIELD-SYMBOL(<ls_doc_detail>).
          <ls_doc_detail>-vbeln = <ls_entregas>-vbeln.
          "Ord. Entr. FD
          TRY.
              <ls_doc_detail>-vbeln_oe = lt_ord_entrega[ vbeln = <ls_entregas>-vbeln ]-vbeln_oe.
            CATCH cx_sy_itab_line_not_found.
          ENDTRY.
          <ls_doc_detail>-vbeln_fac = <ls_flujo>-vbeln.
        ENDLOOP.

      ENDLOOP.

      IF lt_doc_detail[] IS NOT INITIAL.

        TRY.
            cl_salv_table=>factory(
              EXPORTING
                list_display = gc_true
              IMPORTING
                r_salv_table = gr_table_a
              CHANGING
                t_table      = lt_doc_detail ).
          CATCH cx_salv_msg.                            "#EC NO_HANDLER
        ENDTRY.


        lr_columns = gr_table_a->get_columns( ).
        lr_columns->set_optimize( gc_true ).

        lo_salv_sorts = gr_table_a->get_sorts( ).
        TRY.
            lo_salv_sorts->add_sort(
              columnname = 'VBELN'
              sequence   = if_salv_c_sort=>sort_up
              subtotal   = abap_false
            ).
          CATCH cx_salv_msg.
            " Handle exception
        ENDTRY.

        gr_table_a->set_screen_popup(
          start_column = 1
          end_column   = 50
          start_line   = 1
          end_line     = 10 ).

        gr_table_a->display( ).
      ELSE.
        MESSAGE i208(00) WITH 'No se encontro flujo de documento'.
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD refresh_data.

    IF o_tree IS BOUND.
      CALL METHOD o_tree->delete_all_nodes.

      create_hierarchy( ).

      CALL METHOD o_tree->frontend_update.
      CALL METHOD cl_gui_cfw=>flush.
    ENDIF.
  ENDMETHOD.

  METHOD create_object.
    DATA: lv_logo TYPE sdydo_value.
    DATA: it_list_comm TYPE slis_t_listheader.

    IF o_tree IS NOT BOUND.
      CREATE OBJECT o_container
        EXPORTING
          side                        = cl_gui_docking_container=>dock_at_left
          extension                   = 2000
        EXCEPTIONS
          cntl_error                  = 1
          cntl_system_error           = 2
          create_error                = 3
          lifetime_error              = 4
          lifetime_dynpro_dynpro_link = 5
          OTHERS                      = 6.

      CREATE OBJECT o_tree
        EXPORTING
          parent                      = o_container
          node_selection_mode         = cl_gui_column_tree=>node_sel_mode_single
          item_selection              = 'X'
          no_toolbar                  = ' '
          no_html_header              = ' '
        EXCEPTIONS
          cntl_error                  = 1
          cntl_system_error           = 2
          create_error                = 3
          lifetime_error              = 4
          illegal_node_selection_mode = 5
          failed                      = 6
          illegal_column_name         = 7
          OTHERS                      = 8.

      lcl_report_handler=>build_hierarchy_header(
             CHANGING c_p_hierarchy_header = gs_tree_header ).

      it_list_comm = lcl_report_handler=>top_of_page_tree( ).

      lcl_report_handler=>build_catalog( ).

      lv_logo = lcl_report_handler=>get_logo( ).

      CALL METHOD o_tree->set_table_for_first_display
        EXPORTING
          is_hierarchy_header = gs_tree_header
          it_list_commentary  = it_list_comm
          i_logo              = lv_logo
        CHANGING
          it_fieldcatalog     = gt_fieldcat
          it_outtab           = gt_tree_output.

      lcl_report_handler=>create_hierarchy( ).

      lcl_report_handler=>register_events( ).



      CALL METHOD o_tree->frontend_update.

      CALL METHOD cl_gui_cfw=>flush
        EXCEPTIONS
          cntl_system_error = 1
          cntl_error        = 2.
    ENDIF.

  ENDMETHOD.
ENDCLASS.
