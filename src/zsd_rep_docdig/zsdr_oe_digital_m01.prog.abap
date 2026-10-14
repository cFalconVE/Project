*&---------------------------------------------------------------------*
*&  Include  zsdr_oe_digital_m01
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
*&---------------------------------------------------------------------*
*&      Module  STATUS_9000  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_9000 OUTPUT.
  SET PF-STATUS 'SG_9000'.
  SET TITLEBAR 'TG_9000'.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_9000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_9000 INPUT.
  CASE gv_ucomm.
    WHEN '&BACK' OR '&CANC'.
      SET SCREEN 0.
      LEAVE SCREEN.
    WHEN '&EXIT'.
      LEAVE PROGRAM.
  ENDCASE.

  CALL METHOD cl_gui_cfw=>flush.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  CREATE_OBJECT  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE create_object OUTPUT.
  DATA: lv_logo TYPE sdydo_value.
  DATA: it_list_comm TYPE slis_t_listheader.

  IF go_tree IS NOT BOUND.
    CREATE OBJECT go_container
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

    CREATE OBJECT go_tree
      EXPORTING
        parent                      = go_container
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

    CALL METHOD go_tree->set_table_for_first_display
      EXPORTING
        is_hierarchy_header = gs_tree_header
        it_list_commentary  = it_list_comm
        i_logo              = lv_logo
      CHANGING
        it_fieldcatalog     = gt_fieldcat
        it_outtab           = gt_tree_output.

    lcl_report_handler=>create_hierarchy( ).

    lcl_report_handler=>register_events( ).

    CALL METHOD go_tree->frontend_update.

    CALL METHOD cl_gui_cfw=>flush
      EXCEPTIONS
        cntl_system_error = 1
        cntl_error        = 2.
  ENDIF.

ENDMODULE.
