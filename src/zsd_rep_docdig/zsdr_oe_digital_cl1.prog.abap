*&---------------------------------------------------------------------*
*&  Include  zsdr_oe_digital_cl1
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
CLASS lcl_report_handler DEFINITION.
  PUBLIC SECTION.

    METHODS:
      constructor,

*      handle_double_click FOR EVENT  node_double_click OF cl_gui_alv_tree
*        IMPORTING
*          node_key sender,

      on_link_click FOR EVENT link_click OF cl_gui_alv_tree
        IMPORTING fieldname
                  node_key.

    CLASS-METHODS:
      build_hierarchy_header CHANGING c_p_hierarchy_header TYPE treev_hhdr,
      build_catalog,
      create_hierarchy,
      top_of_page,
      register_events,
      top_of_page_tree RETURNING VALUE(t_comment) TYPE slis_t_listheader,
      get_logo RETURNING VALUE(logo) TYPE sdydo_value.

  PRIVATE SECTION.
    METHODS:
      get_data.

ENDCLASS.

CLASS lcl_report_handler IMPLEMENTATION.

  METHOD constructor.
    get_data( ).

    IF gt_likp_oe[] IS INITIAL.
      MESSAGE i208(00) WITH text-m01.
    ELSE.
      CALL SCREEN 9000.
    ENDIF.
  ENDMETHOD.

  METHOD get_data.
    DATA: lv_status  TYPE icon_d,
          lv_paginas TYPE i.

    DATA: wa_likp_oe TYPE tt_likp_oe.

    SELECT y~*,
           x~*
      INTO TABLE @DATA(lt_base)
      FROM zsd_tb_json_stat AS x
      INNER JOIN zsd_likp_oe AS y
                ON x~bukrs EQ y~tplst AND
                    x~tdocumento EQ y~tdocumento AND
                    x~vbeln EQ y~vbeln_oe
      WHERE x~bukrs IN @so_tplst AND
            x~vbeln IN @so_tknum AND
            x~fechareci IN @so_erdat.

    SORT lt_base BY y-vbeln.

    LOOP AT lt_base ASSIGNING FIELD-SYMBOL(<ls_base>).
      AT NEW y-vbeln.
        ADD 1 TO lv_paginas.
      ENDAT.

      CASE <ls_base>-y-estado.
*        WHEN 'C' OR 'G' OR 'P'.
        WHEN 'E'.
          lv_status = '@0A@'.
        WHEN 'S'.
          lv_status = '@08@'.
        WHEN OTHERS.
          lv_status = '@09@'.
      ENDCASE.

      " Detalle
      APPEND VALUE #( vbeln_oe = <ls_base>-x-vbeln
                      vbeln = <ls_base>-y-vbeln
                      ncontrol = <ls_base>-x-ncontrol
                      pagina = <ls_base>-y-pag
                      estado = <ls_base>-y-estado
                      status = lv_status
                      femision  = <ls_base>-x-fechareci
                      hemision  = <ls_base>-y-hemision
                      url    = <ls_base>-x-url )
             TO gt_likp_oe_d.

      wa_likp_oe-tplst = <ls_base>-x-bukrs.
      wa_likp_oe-femision = <ls_base>-x-fechareci.
      wa_likp_oe-likp_oe = 1.

      COLLECT wa_likp_oe INTO gt_likp_oe.
      CLEAR wa_likp_oe.

      AT END OF y-vbeln.

        CASE <ls_base>-y-estado.
          WHEN 'E'.
            lv_status = '@0A@'.
          WHEN 'S'.
            lv_status = '@08@'.
          WHEN OTHERS.
            lv_status = '@09@'.
        ENDCASE.

        " Cabecera
        APPEND VALUE #( tplst = <ls_base>-x-bukrs
                        erdat = <ls_base>-x-fechareci
                        tdocumento = <ls_base>-x-tdocumento
                        vbeln = <ls_base>-y-vbeln
                        vbeln_oe = <ls_base>-x-vbeln
                        estado = <ls_base>-y-estado
                        status = lv_status
                        pag = lv_paginas )
                 TO gt_likp_oe_h.
        CLEAR lv_paginas.
      ENDAT.
    ENDLOOP.
  ENDMETHOD.

  METHOD  build_hierarchy_header.
    c_p_hierarchy_header-heading = 'Fecha'.
    c_p_hierarchy_header-tooltip = 'OE por Fecha' .
    c_p_hierarchy_header-width = 35.
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
    <ls_fcat>-fieldname = 'VBELN'.
    <ls_fcat>-coltext = 'Orden Entrega' .
    <ls_fcat>-outputlen = 17.
    <ls_fcat>-hotspot = 'X'.
    <ls_fcat>-convexit = 'ALPHA'.
    <ls_fcat>-just = 'C'.

    APPEND INITIAL LINE TO gt_fieldcat ASSIGNING <ls_fcat>.
    <ls_fcat>-fieldname = 'VBELN_OE'.
    <ls_fcat>-coltext = 'OE Digital'.
    <ls_fcat>-no_zero = 'X'.
    <ls_fcat>-outputlen = 15.
    <ls_fcat>-just = 'C'.
*    <ls_fcat>-hotspot = 'X'.
*    <ls_fcat>-convexit = 'ALPHA'.

    APPEND INITIAL LINE TO gt_fieldcat ASSIGNING <ls_fcat>.
    <ls_fcat>-fieldname = 'PAGINA' .
    <ls_fcat>-coltext = 'Num. Pag' .
    <ls_fcat>-no_zero = 'X'.
    <ls_fcat>-outputlen = 12.
    <ls_fcat>-just = 'C'.

    APPEND INITIAL LINE TO gt_fieldcat ASSIGNING <ls_fcat>.
    <ls_fcat>-fieldname = 'STATUS' .
    <ls_fcat>-coltext = 'Status' .
    <ls_fcat>-icon = 'X'.
    <ls_fcat>-outputlen = 10.
    <ls_fcat>-just = 'C'.

    APPEND INITIAL LINE TO gt_fieldcat ASSIGNING <ls_fcat>.
    <ls_fcat>-fieldname = 'FEMISION' .
    <ls_fcat>-coltext = 'Fecha' .
    <ls_fcat>-outputlen = 13.
    <ls_fcat>-ref_table = 'BKPF'.
    <ls_fcat>-ref_field = 'BUDAT'.

    APPEND INITIAL LINE TO gt_fieldcat ASSIGNING <ls_fcat>.
    <ls_fcat>-fieldname = 'HEMISION'.
    <ls_fcat>-coltext = 'Hora'.
    <ls_fcat>-outputlen = 8.
    <ls_fcat>-no_zero = 'X'.

    APPEND INITIAL LINE TO gt_fieldcat ASSIGNING <ls_fcat>.
    <ls_fcat>-fieldname = 'URL' .
    <ls_fcat>-coltext = 'URL o link' .
    <ls_fcat>-outputlen = 150.
    <ls_fcat>-hotspot = 'X'.

  ENDMETHOD.

  METHOD create_hierarchy.
    DATA: lv_node_text TYPE lvc_value.
    DATA: lv_estatus_h TYPE icon_d.
    DATA: ls_node      TYPE lvc_s_layn.
    DATA: wa_tree_output LIKE LINE OF gt_tree_output,
          it_item_layout TYPE lvc_t_layi,
          wa_item_layout TYPE lvc_s_layi.
    DATA: lv_nro_likp_oe TYPE i.

*    CALL METHOD go_tree->add_node
*      EXPORTING
*        i_relat_node_key = ''
*        i_relationship   = cl_gui_column_tree=>relat_last_child
*        i_node_text      = text-t02
*      IMPORTING
*        e_new_node_key   = l_top_key.

    SORT gt_likp_oe BY femision DESCENDING.
    SORT gt_likp_oe_h BY erdat DESCENDING vbeln ASCENDING.
    SORT gt_likp_oe_d BY vbeln pagina ASCENDING.

    LOOP AT gt_likp_oe ASSIGNING FIELD-SYMBOL(<ls_likp_oe>).
      "1er nivel
      CLEAR wa_tree_output.
      WRITE <ls_likp_oe>-femision TO lv_node_text  DD/MM/YYYY.
      wa_tree_output-paginas = <ls_likp_oe>-likp_oe.

      LOOP AT gt_likp_oe_h ASSIGNING FIELD-SYMBOL(<ls_likp_oe_h>)
          WHERE tplst EQ <ls_likp_oe>-tplst
            AND erdat EQ <ls_likp_oe>-femision
            AND estado NE 'S'.

        lv_estatus_h = '@09@'.
        EXIT.
      ENDLOOP.

      IF sy-subrc NE 0.
        lv_estatus_h = '@08@'.
      ENDIF.

      CLEAR it_item_layout[].

      wa_item_layout-t_image = lv_estatus_h.
      wa_item_layout-fieldname = go_tree->c_hierarchy_column_name.
      wa_item_layout-style = cl_gui_column_tree=>style_intensifd_critical.
      APPEND wa_item_layout TO it_item_layout.
      CLEAR wa_item_layout.

      CALL METHOD go_tree->add_node
        EXPORTING
          i_relat_node_key = '' "l_top_key
          i_relationship   = cl_gui_column_tree=>relat_last_child
          i_node_text      = lv_node_text
          is_outtab_line   = wa_tree_output
          is_node_layout   = ls_node
          it_item_layout   = it_item_layout
        IMPORTING
          e_new_node_key   = l_node_key.

      LOOP AT gt_likp_oe_h ASSIGNING <ls_likp_oe_h>
          WHERE tplst EQ <ls_likp_oe>-tplst
            AND erdat EQ <ls_likp_oe>-femision.
        "2do nivel
        CLEAR lv_node_text.
        CLEAR wa_tree_output.
        lv_node_text = <ls_likp_oe_h>-vbeln.

        CLEAR it_item_layout[].

        wa_item_layout-t_image = <ls_likp_oe_h>-status.
        wa_item_layout-fieldname = go_tree->c_hierarchy_column_name.
        wa_item_layout-style = cl_gui_column_tree=>style_intensifd_critical.
        APPEND wa_item_layout TO it_item_layout.

        CLEAR wa_item_layout.

        lv_nro_likp_oe = REDUCE i( INIT lv_sum = 0
                          FOR wa IN gt_likp_oe_d
                            WHERE ( vbeln EQ <ls_likp_oe_h>-vbeln )
                              NEXT lv_sum = lv_sum + 1 ).

        wa_tree_output-femision = <ls_likp_oe_h>-erdat.
        wa_tree_output-pagina  = lv_nro_likp_oe.

        CLEAR lv_nro_likp_oe.

        CALL METHOD go_tree->add_node
          EXPORTING
            i_relat_node_key = l_node_key
            i_relationship   = cl_gui_column_tree=>relat_last_child
            i_node_text      = lv_node_text
            is_outtab_line   = wa_tree_output
            is_node_layout   = ls_node
            it_item_layout   = it_item_layout
          IMPORTING
            e_new_node_key   = l_node2_key.

        LOOP AT gt_likp_oe_d ASSIGNING FIELD-SYMBOL(<ls_detail>)
            WHERE vbeln EQ <ls_likp_oe_h>-vbeln.
          " 3er nivel
          CLEAR lv_node_text.
          CLEAR wa_tree_output.
          MOVE-CORRESPONDING <ls_detail> TO wa_tree_output.

          lv_node_text = <ls_detail>-vbeln.

          CALL METHOD go_tree->add_node
            EXPORTING
              i_relat_node_key = l_node2_key
              i_relationship   = cl_gui_column_tree=>relat_last_child
              i_node_text      = lv_node_text
              is_outtab_line   = wa_tree_output
            IMPORTING
              e_new_node_key   = l_node_line.
        ENDLOOP.

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

    ls_line-typ = 'H'.
    ls_line-info = 'Reporte Ordenes de entrega Digital'.
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
  ENDMETHOD.

  METHOD  top_of_page.

    DATA: g_text           TYPE sdydo_text_element.

    SELECT SINGLE bezei
      INTO @DATA(lv_bezei)
      FROM ttdst
      WHERE spras EQ @sy-langu
        AND tplst IN @so_tplst.

    g_text   = 'Reporte Ordenes de entrega Digital'.
    CALL METHOD go_document->add_text
      EXPORTING
        text         = g_text
        sap_emphasis = cl_dd_area=>heading.

    CALL METHOD go_document->add_gap
      EXPORTING
        width = 20.

    CALL METHOD go_document->new_line.
    CALL METHOD go_document->add_text
      EXPORTING
        text = ' '.
    CALL METHOD go_document->new_line.

    CLEAR g_text.
    g_text = lv_bezei.
    CALL METHOD go_document->add_text
      EXPORTING
        text      = g_text
        sap_style = cl_dd_area=>strong.

    CALL METHOD go_document->new_line.

    g_text = 'Fecha:'.
    CALL METHOD go_document->add_text
      EXPORTING
        text      = g_text
        sap_style = cl_dd_area=>strong.

    DATA(lv_emision) = |{ so_erdat-low DATE = USER }| &
                       | - | & |{ so_erdat-high DATE = USER }|.

    g_text = lv_emision.
    CALL METHOD go_document->add_text
      EXPORTING
        text = g_text.

    CALL METHOD go_document->add_gap
      EXPORTING
        width = 10.

    go_document->display_document( parent = go_top ).
  ENDMETHOD.

  METHOD on_link_click.
    DATA: wa_tree_output LIKE LINE OF gt_tree_output.

    CALL METHOD go_tree->get_outtab_line
      EXPORTING
        i_node_key     = node_key
      IMPORTING
        e_outtab_line  = wa_tree_output
      EXCEPTIONS
        node_not_found = 1
        OTHERS         = 2.

    CASE fieldname.
      WHEN 'VBELN'.
        SET PARAMETER ID 'VL' FIELD wa_tree_output-vbeln.
        CALL TRANSACTION 'VL03N' AND SKIP FIRST SCREEN.
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

    CALL METHOD go_tree->get_registered_events
      IMPORTING
        events = lt_events.

    ls_event-eventid = cl_gui_column_tree=>eventid_link_click.
    APPEND ls_event TO lt_events.
*    ls_event-eventid = cl_gui_column_tree=>eventid_node_double_click.
*    APPEND ls_event TO lt_events.

    CALL METHOD go_tree->set_registered_events
      EXPORTING
        events                    = lt_events
      EXCEPTIONS
        cntl_error                = 1
        cntl_system_error         = 2
        illegal_event_combination = 3.

    l_event_receiver = NEW #( ).
*    SET HANDLER l_event_receiver->handle_double_click FOR o_tree.
    SET HANDLER l_event_receiver->on_link_click FOR go_tree.
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

*  METHOD handle_double_click.
*
*  ENDMETHOD.

ENDCLASS.
