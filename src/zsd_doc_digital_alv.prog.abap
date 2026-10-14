*&---------------------------------------------------------------------*
*&  Include  zsd_doc_digital_alv
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&  Include  zsd_rep_gc_dig_alv
*&---------------------------------------------------------------------*
*  FECHA DE CREACION: 23.04.2025
*  MODULO SAP     : SD
*  EMPRESA        : Corimon
*  AUTOR (NOMBRE) : Carlos Falcón
*  AUTOR (ID)     : 700-009
*  OBJECTO        : INCLUDE
*  ORDEN          : DR3K978052
*  Solicitud      : REQ-55601
*&---------------------------------------------------------------------*
*   Descripción
*   Reporte para Guía de Carga digital
*
*&---------------------------------------------------------------------*
*    Bitacora de actualización
*----------------------------------------------------------------------*
* Fecha       Caso    User    Orden       Descripción
*
*
*&---------------------------------------------------------------------*
*###############################################################
* LOCAL CLASSES
*###############################################################
*§1. Define a (local) class for event handling

CLASS lcl_tree_event_receiver DEFINITION.

  PUBLIC SECTION.
*§2. Define an event handler method for each event you want to react to.
    METHODS handle_node_double_click
      FOR EVENT node_double_click OF cl_gui_alv_tree
      IMPORTING node_key sender.
* 'sender' is an implicit event parameter that is provided by
* ABAP Objects runtime system. It contains a reference to the
* object that fired the event. You may directly use it to
* call methods of this instance.

ENDCLASS.
******************************************************************
CLASS lcl_tree_event_receiver IMPLEMENTATION.
*§3. Implement your event handler methods.

  METHOD handle_node_double_click.
    data: lt_children type lvc_t_nkey.
*first check if the node is a leaf, i.e. can not be expanded

    call method sender->get_children
              exporting i_node_key = node_key
              importing et_children = lt_children.

    if not lt_children is initial.

        CALL METHOD sender->expand_node
                  EXPORTING  i_node_key = node_key
                             i_level_count = 2.
    endif.

  ENDMETHOD.

ENDCLASS.
*##################################################################

*START-OF-SELECTION.
*
*END-OF-SELECTION.
*
*  CALL SCREEN 100.

*&---------------------------------------------------------------------*
*&      Module  PBO  OUTPUT
*&---------------------------------------------------------------------*
*       process before output
*----------------------------------------------------------------------*
MODULE pbo OUTPUT.

  SET PF-STATUS 'MAIN100'.
  SET TITLEBAR 'MAINTITLE'.

  IF g_alv_tree IS INITIAL.
    PERFORM init_tree.

    CALL METHOD cl_gui_cfw=>flush
            EXCEPTIONS cntl_system_error = 1
                       cntl_error        = 2.
    IF sy-subrc NE 0.
      CALL FUNCTION 'POPUP_TO_INFORM'
           EXPORTING
                titel = 'Automation Queue failure'(801)
                txt1  = 'Internal error:'(802)
                txt2  = 'A method in the automation queue'(803)
                txt3  = 'caused a failure.'(804).
    ENDIF.
  ENDIF.

ENDMODULE.                             " PBO  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  PAI  INPUT
*&---------------------------------------------------------------------*
*       process after input
*----------------------------------------------------------------------*
MODULE pai INPUT.
  save_ok = ok_code.
  CLEAR ok_code.

  CASE save_ok.
    WHEN 'EXIT' OR 'BACK' OR 'CANC'.
      PERFORM exit_program.

    WHEN OTHERS.
* §5. Call dispatch to process toolbar functions
* Toolbar events are registered in constructur method of
* CL_ALV_TREE_BASE as application events. So the dispatch call
* is a must if you want to use the standard toolbar.
      CALL METHOD cl_gui_cfw=>dispatch.

  ENDCASE.

  CALL METHOD cl_gui_cfw=>flush.
ENDMODULE.                             " PAI  INPUT

*&---------------------------------------------------------------------*
*&      Form  init_tree
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM init_tree.
* create container for alv-tree
  DATA: l_tree_container_name(30) TYPE c.

  l_tree_container_name = 'CCONTAINER1'.

  CREATE OBJECT g_custom_container
      EXPORTING
            container_name = l_tree_container_name
      EXCEPTIONS
            cntl_error                  = 1
            cntl_system_error           = 2
            create_error                = 3
            lifetime_error              = 4
            lifetime_dynpro_dynpro_link = 5.
  IF sy-subrc <> 0.
    MESSAGE x208(00) WITH 'ERROR'(100).
  ENDIF.

* create tree control
  CREATE OBJECT g_alv_tree
    EXPORTING
        parent              = g_custom_container
        node_selection_mode = cl_gui_column_tree=>node_sel_mode_single
        item_selection      = 'X'
        no_html_header      = 'X'
        no_toolbar          = ''
    EXCEPTIONS
        cntl_error                   = 1
        cntl_system_error            = 2
        create_error                 = 3
        lifetime_error               = 4
        illegal_node_selection_mode  = 5
        failed                       = 6
        illegal_column_name          = 7.
  IF sy-subrc <> 0.
    MESSAGE x208(00) WITH 'ERROR'.     "#EC NOTEXT
  ENDIF.

  DATA l_hierarchy_header TYPE treev_hhdr.
  PERFORM build_hierarchy_header CHANGING l_hierarchy_header.

* Hide columns and sum up values initially using the fieldcatalog
  PERFORM build_fieldcatalog.

* IMPORTANT: Table 'gt_sflight' must be empty. Do not change this table
* (even after this method call). You can change data of your table
* by calling methods of CL_GUI_ALV_TREE.
* Furthermore, the output table 'gt_outtab' must be global and can
* only be used for one ALV Tree Control.
  CALL METHOD g_alv_tree->set_table_for_first_display
     EXPORTING
               is_hierarchy_header  = l_hierarchy_header
     CHANGING
               it_fieldcatalog      = gt_fieldcatalog
               it_outtab            = gt_sflight. "table must be empty !

  PERFORM create_hierarchy.

  PERFORM register_events.
* Update calculations which were initially defined by field DO_SUM
* of the fieldcatalog. (see build_fieldcatalog).
  CALL METHOD g_alv_tree->update_calculations.

* Send data to frontend.
  CALL METHOD g_alv_tree->frontend_update.

ENDFORM.                               " init_tree
*&---------------------------------------------------------------------*
*&      Form  build_hierarchy_header
*&---------------------------------------------------------------------*
*       build hierarchy-header-information
*----------------------------------------------------------------------*
*      -->P_L_HIERARCHY_HEADER  strucxture for hierarchy-header
*----------------------------------------------------------------------*
FORM build_hierarchy_header CHANGING
                               p_hierarchy_header TYPE treev_hhdr.

  p_hierarchy_header-heading = 'Totals/Month/Carrier/Date'(300).
  p_hierarchy_header-tooltip = 'Flights in a month'(400).
  p_hierarchy_header-width = 35.
  p_hierarchy_header-width_pix = ''.

ENDFORM.                               " build_hierarchy_header
*&---------------------------------------------------------------------*
*&      Form  exit_program
*&---------------------------------------------------------------------*
*       free object and leave program
*----------------------------------------------------------------------*
FORM exit_program.

  CALL METHOD g_custom_container->free.
  LEAVE PROGRAM.

ENDFORM.                               " exit_program
*--------------------------------------------------------------------
FORM build_fieldcatalog.
  DATA: ls_fieldcatalog TYPE lvc_s_fcat.

* The following function module generates a fieldcatalog according
* to a given structure.
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
       EXPORTING
            i_structure_name = 'SFLIGHT'
       CHANGING
            ct_fieldcat      = gt_fieldcatalog.

* Now change the fieldcatalog to hide fields and to determine
* some initial calculations for chosen fields.
  LOOP AT gt_fieldcatalog INTO ls_fieldcatalog.
    CASE ls_fieldcatalog-fieldname.
* hide columns which are already displayed in our tree
      WHEN 'CARRID' OR 'FLDATE'.
        ls_fieldcatalog-no_out = 'X'.
* Do some initial calculations:
* ALV Tree uses the field 'do_sum' to declare that a function
* for the corresponding column shall be calculated.
* Use 'h_ftype' to set the function type (MAX, MIN, SUM, AVG).
      WHEN 'PRICE'.
        ls_fieldcatalog-do_sum = 'X'.
        ls_fieldcatalog-h_ftype = 'MAX'.
      WHEN 'SEATSMAX'.
        ls_fieldcatalog-do_sum = 'X'.
        ls_fieldcatalog-h_ftype = 'SUM'.
      WHEN 'SEATSOCC'.
        ls_fieldcatalog-do_sum = 'X'.
        ls_fieldcatalog-h_ftype = 'AVG'.
    ENDCASE.
    MODIFY gt_fieldcatalog FROM ls_fieldcatalog.
  ENDLOOP.

* The fieldcatalog is provided in form 'init_tree' using method
* set_table_for_first_display.
ENDFORM.                               " build_fieldcatalog
*-----------------------------------------------------------------------
FORM register_events.
*§4. Event registration: tell ALV Tree which events shall be passed
*    from frontend to backend.
  DATA: lt_events TYPE cntl_simple_events,
        l_event TYPE cntl_simple_event,
        l_event_receiver TYPE REF TO lcl_tree_event_receiver.

*§4a. Frontend registration(i):  get already registered tree events.
*................................................................
* The following four tree events registers ALV Tree in the constructor
* method itself.
*    - cl_gui_column_tree=>eventid_expand_no_children
* (needed to load data to frontend when a user expands a node)
*    - cl_gui_column_tree=>eventid_header_context_men_req
* (needed for header context menu)
*    - cl_gui_column_tree=>eventid_header_click
* (allows selection of columns (only when item selection activated))
*   - cl_gui_column_tree=>eventid_item_keypress
* (needed for F1-Help (only when item selection activated))
*
* Nevertheless you have to provide their IDs again if you register
* additional events with SET_REGISTERED_EVENTS (see below).
* To do so, call first method  GET_REGISTERED_EVENTS (this way,
* all already registered events remain registered, even your own):
call method g_alv_tree->get_registered_events
      importing events = lt_events.
* (If you do not these events will be deregistered!!!).
* You do not have to register events of the toolbar again.

*§4b. Frontend registration(ii): add additional event ids
  l_event-eventid = cl_gui_column_tree=>eventid_node_double_click.
  APPEND l_event TO lt_events.

*§4c. Frontend registration(iii):provide new event table to alv tree
  CALL METHOD g_alv_tree->set_registered_events
    EXPORTING
      events = lt_events
    EXCEPTIONS
      cntl_error                = 1
      cntl_system_error         = 2
      illegal_event_combination = 3.
  IF sy-subrc <> 0.
    MESSAGE x208(00) WITH 'ERROR'.     "#EC NOTEXT
  ENDIF.
*--------------------
*§4d. Register events on backend (ABAP Objects event handling)
  CREATE OBJECT l_event_receiver.
  SET HANDLER l_event_receiver->handle_node_double_click FOR g_alv_tree.

ENDFORM.                               " register_events
*&---------------------------------------------------------------------*
*&      Form  create_hierarchy
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM create_hierarchy.
* See BCALV_TREE_01 for more comments on building the hierarchy
  DATA: ls_sflight TYPE sflight,
        lt_sflight TYPE sflight OCCURS 0,
        l_yyyymm(6) TYPE c,            "year and month of sflight-fldate
        l_yyyymm_last(6) TYPE c,
        l_carrid LIKE sflight-carrid,
        l_carrid_last LIKE sflight-carrid.

  DATA: l_month_key TYPE lvc_nkey,
        l_carrid_key TYPE lvc_nkey,
        l_last_key TYPE lvc_nkey,
        l_top_key TYPE lvc_nkey.

* Select data
  SELECT * FROM sflight INTO TABLE lt_sflight up to g_max rows.
* sort table according to conceived hierarchy
  SORT lt_sflight BY fldate+0(6) carrid fldate+6(2).

* Define one top node. In this way it is possible to calculate
* values for the whole hierarchy.
  CALL METHOD g_alv_tree->add_node
    EXPORTING
          i_relat_node_key = ''
          i_relationship   = cl_gui_column_tree=>relat_last_child
          i_node_text      = text-050
       IMPORTING
          e_new_node_key = l_top_key.

  LOOP AT lt_sflight INTO ls_sflight.
    l_yyyymm = ls_sflight-fldate+0(6).
    l_carrid = ls_sflight-carrid.

    IF l_yyyymm <> l_yyyymm_last.      "on change of l_yyyymm
      l_yyyymm_last = l_yyyymm.
* month nodes
      PERFORM add_month USING    l_yyyymm
                                      l_top_key
                             CHANGING l_month_key.
* clear l_carrid_last because this is a new month
      clear l_carrid_last.
    endif.
* Carrier nodes:
    if l_carrid <> l_carrid_last.      "on change of l_carrid
      l_carrid_last = l_carrid.
      PERFORM add_carrid_line USING    ls_sflight
                                       l_month_key
                              CHANGING l_carrid_key.
    ENDIF.
* Leaf:
    PERFORM add_complete_line USING  ls_sflight
                                     l_carrid_key
                            CHANGING l_last_key.
  ENDLOOP.

ENDFORM.                               " create_hierarchy

*&---------------------------------------------------------------------*
*&      Form  add_month
*&---------------------------------------------------------------------*
FORM add_month  USING     p_yyyymm TYPE c
                          p_relat_key TYPE lvc_nkey
                CHANGING  p_node_key TYPE lvc_nkey.

  DATA: l_node_text TYPE lvc_value,
        ls_sflight TYPE sflight,
        l_month(15) TYPE c.            "output string for month

* get month name for node text
  PERFORM get_month USING p_yyyymm
                    CHANGING l_month.
  l_node_text = l_month.

* add node
  CALL METHOD g_alv_tree->add_node
    EXPORTING
          i_relat_node_key = p_relat_key
          i_relationship   = cl_gui_column_tree=>relat_last_child
          i_node_text      = l_node_text
          is_outtab_line   = ls_sflight
       IMPORTING
          e_new_node_key = p_node_key.

ENDFORM.                               " add_month
*-----------------------------------------------------------------------
FORM add_carrid_line USING     ps_sflight TYPE sflight
                               p_relat_key TYPE lvc_nkey
                     CHANGING  p_node_key TYPE lvc_nkey.

  DATA: l_node_text TYPE lvc_value,
        ls_sflight TYPE sflight.

* add node
  l_node_text =  ps_sflight-carrid.
  CALL METHOD g_alv_tree->add_node
    EXPORTING
          i_relat_node_key = p_relat_key
          i_relationship   = cl_gui_column_tree=>relat_last_child
          i_node_text      = l_node_text
          is_outtab_line   = ls_sflight
       IMPORTING
          e_new_node_key = p_node_key.

ENDFORM.                               " add_carrid_line
*&---------------------------------------------------------------------*
*&      Form  add_complete_line
*&---------------------------------------------------------------------*
FORM add_complete_line USING   ps_sflight TYPE sflight
                               p_relat_key TYPE lvc_nkey
                     CHANGING  p_node_key TYPE lvc_nkey.

  DATA: l_node_text TYPE lvc_value.

  WRITE ps_sflight-fldate TO l_node_text MM/DD/YYYY.

  CALL METHOD g_alv_tree->add_node
    EXPORTING
          i_relat_node_key = p_relat_key
          i_relationship   = cl_gui_column_tree=>relat_last_child
          is_outtab_line   = ps_sflight
          i_node_text      = l_node_text
       IMPORTING
          e_new_node_key = p_node_key.

ENDFORM.                               " add_complete_line
*&---------------------------------------------------------------------*
*&      Form  GET_MONTH
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_YYYYMM  text
*      <--P_L_MONTH  text
*----------------------------------------------------------------------*
FORM get_month USING    p_yyyymm
               CHANGING p_month.

  DATA: l_monthdigits(2) TYPE c.

  l_monthdigits = p_yyyymm+4(2).
  CASE l_monthdigits.
    WHEN '01'.
      p_month = 'January'(701).
    WHEN '02'.
      p_month = 'February'(702).
    WHEN '03'.
      p_month = 'March'(703).
    WHEN '04'.
      p_month = 'April'(704).
    WHEN '05'.
      p_month = 'May'(705).
    WHEN '06'.
      p_month = 'June'(706).
    WHEN '07'.
      p_month = 'July'(707).
    WHEN '08'.
      p_month = 'August'(708).
    WHEN '09'.
      p_month = 'September'(709).
    WHEN '10'.
      p_month = 'October'(710).
    WHEN '11'.
      p_month = 'November'(711).
    WHEN '12'.
      p_month = 'December'(712).
  ENDCASE.
  CONCATENATE p_yyyymm+0(4) '->' p_month INTO p_month.

ENDFORM.
