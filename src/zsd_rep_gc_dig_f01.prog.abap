*&---------------------------------------------------------------------*
*&  Include  zsd_rep_gc_dig_f01
*&---------------------------------------------------------------------*
*  FECHA DE CREACION: 27.03.2025
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
*&      Module  M_STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE m_status_0100 OUTPUT.

  SET PF-STATUS 'STS_INI_100'.
  SET TITLEBAR 'TIT_INI_100'.

  IF gr_alv_tree IS INITIAL.
    PERFORM init_tree.

    CALL METHOD cl_gui_cfw=>flush
      EXCEPTIONS
        cntl_system_error = 1
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

ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  M_USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE m_user_command_0100 INPUT.
  CASE ok_code.
    WHEN 'BACK'.
      CLEAR ok_code.
      CALL METHOD gr_alv_tree->free.
      LEAVE TO CURRENT TRANSACTION.

    WHEN 'CANC'.
      CLEAR ok_code.
      CALL METHOD gr_alv_tree->free.
      LEAVE TO CURRENT TRANSACTION.

    WHEN OTHERS.
      CALL METHOD cl_gui_cfw=>dispatch.

  ENDCASE.

  CLEAR: ok_code,
         sy-ucomm.

  CALL METHOD cl_gui_cfw=>flush.

ENDMODULE.

FORM create_tree.
* Step 1 - get ref. obj_tree

*  TRY.
*      CALL METHOD cl_salv_tree=>factory
*        IMPORTING
*          r_salv_tree = gr_tree   " ALV: Tree Model
*        CHANGING
*          t_table     = gt_gcd.
*    CATCH cx_salv_error.    "
*  ENDTRY.

  PERFORM build_header.

  PERFORM select_data.

  IF sy-subrc NE 0.
    MESSAGE i208(00) WITH 'No hay registro en:' pa_tplst.
    EXIT.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  build_header
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_header .

*... § 2.1 build the hierarchy header
  DATA: lr_settings TYPE REF TO cl_salv_tree_settings.
  DATA: lv_title TYPE salv_de_tree_text.

  lr_settings = gr_tree->get_tree_settings( ).
  lr_settings->set_hierarchy_header( text-050 ).
  lr_settings->set_hierarchy_tooltip( text-300 ).
  lr_settings->set_hierarchy_size( 30 ).

  lv_title = sy-title.
  lr_settings->set_header( lv_title ).

ENDFORM.                    " build_header

FORM set_tree.
  DATA: lo_nodes TYPE REF TO cl_salv_nodes,
        lo_node  TYPE REF TO cl_salv_node.

  DATA: lv_text      TYPE lvc_value,
        lv_lgart_key TYPE salv_de_node_key,
        lv_mes_key   TYPE salv_de_node_key.

*Step 2 - Header Setting
  go_settings = gr_tree->get_tree_settings( ).

  go_settings->set_header( 'Guía de Carga Digital' ).
  go_settings->set_hierarchy_header( 'Registros' ).
  go_settings->set_hierarchy_tooltip( 'Guías digital generadas' ).
  go_settings->set_hierarchy_size( 30 ).

* Step 3 - Read the nodes
  lo_nodes = gr_tree->get_nodes( ).

* Step 4 - Data to ALV Tree
  DATA: lv_padre   TYPE lvc_value,
        lv_child   TYPE lvc_value,
        lv_i       TYPE i,
        lv_cont(1) TYPE c.

  REFRESH gt_gcd.

  break 700-009.
  PERFORM select_data.

  LOOP AT gt_gcd ASSIGNING FIELD-SYMBOL(<ls_gcd>). " INTO DATA(ls_gcd).

    ON CHANGE OF <ls_gcd>-lgart.
      CONCATENATE 'Año' <ls_gcd>-lgart
             INTO lv_text SEPARATED BY space.

      TRY.
          lo_node = lo_nodes->add_node(
                       related_node = space
                       text         = lv_text
                       relationship = if_salv_c_node_relation=>parent
                       expander     = abap_true
                       folder       = abap_true ).
        CATCH cx_salv_msg.
      ENDTRY.

      lv_lgart_key = lo_node->get_key( ).
    ENDON.

    ON CHANGE OF <ls_gcd>-mes.
      CONCATENATE 'Mes' <ls_gcd>-mes
              INTO lv_text SEPARATED BY space.

      TRY.
          lo_node = lo_nodes->add_node(
                       related_node = lv_lgart_key
                       text = lv_text
*                       data_row = ls_gcd
                       relationship = if_salv_c_node_relation=>last_child "cl_gui_column_tree=>relat_first_child
                       expander     = abap_true
                       folder       = abap_true ).
        CATCH cx_salv_msg.
      ENDTRY.

      lv_mes_key = lo_node->get_key( ).
    ENDON.

    CONCATENATE 'Transporte' <ls_gcd>-tknumk
                INTO lv_text SEPARATED BY space.
    TRY.
        lo_node = lo_nodes->add_node(
                     related_node = lv_mes_key
                     text = lv_text
                     data_row = <ls_gcd>
                     relationship = if_salv_c_node_relation=>last_child
                     "cl_gui_column_tree=>relat_first_child
                     ).
      CATCH cx_salv_msg.
    ENDTRY.

  ENDLOOP.

  lo_nodes->expand_all( ).
*  Step 5 - Display the tree
*  go_tree->display( ).

ENDFORM.

FORM select_data. "CHANGING p_gc TYPE zsd_tb_gck.
  DATA lv_text TYPE lvc_value.

  break 700-009.

*  SELECT *
*    FROM  zview_gc( p_tplst = @pa_tplst )
*    INTO TABLE @gt_outtab
*      UP TO @pa_filas ROWS.
*    ORDER BY  .

  SELECT p~aedat, k~tknum, p~tknum AS nroentrega, p~pagina, p~estado, p~url
    FROM zsd_tb_gck AS k
         INNER JOIN zsd_tb_gcp AS p
           ON k~tknum = p~tknum_c
    INTO TABLE @DATA(lt_gc_merge) UP TO @pa_filas ROWS.

  CHECK sy-subrc EQ 0.

*gt_gc_merge
*  IF sy-subrc EQ 0.

**  LOOP AT gt_gc_merge INTO DATA(wa_gcd).
**
**    DATA(ls_item) = VALUE ty_gcd( aedat = wa_gcd-aedat
**                                  tknumk = wa_gcd-tknumk
**                                  tknump = wa_gcd-tknum
**                                  pagina = wa_gcd-pagina
**                                  estado = wa_gcd-estado
**                                  url    = wa_gcd-url ).
**
**    ls_item-lgart = wa_gcd-aedat(4).
**    ls_item-mes = wa_gcd-aedat+4(2).
**
**    APPEND ls_item TO gt_gcd.
**  ENDLOOP.

  SORT lt_gc_merge BY aedat+0(6).

**  SORT gt_gcd BY lgart mes tknumk pagina ASCENDING.

*****  PERFORM supply_data USING lt_gc_merge.

*  SORT gt_outtab BY fechaenvio ASCENDING.
*  ENDIF.

*  SELECT p~aedat, k~tknum, p~tknum AS nroentrega, p~pagina, p~estado, p~url
*      FROM zsd_tb_gck AS k
*             INNER JOIN zsd_tb_gcp AS p
*               ON k~tknum = p~tknum_c
*      INTO TABLE @gt_gcd.

*  SELECT *
*  FROM zsd_tb_gck
*  INTO TABLE @DATA(lt_gc).


*  IF sy-subrc = 0.
*    LOOP AT gt_gcd INTO DATA(ls_gcd).
*      CONCATENATE 'Fecha' ls_gcd-aedat
*             INTO lv_text SEPARATED BY space.
*
*      go_node = go_nodes->add_node( related_node = ' '
*                                    text = lv_text
*                                    data_row = ls_gcd
*                                    relationship = ' ' ).
*
*      DATA(lv_order_key) = go_node->get_key( ).
*
*      go_node = go_nodes->add_node( related_node = lv_order_key
*                                    data_row = ls_gcd
*                                    relationship = '' ).
*
*
*
*    ENDLOOP.
*  ENDIF.

ENDFORM.

FORM do_alv_tree.

*  "Crea el objeto Container
*  CREATE OBJECT re_custom_container
*    EXPORTING
*      container_name              = gc_tree_container_name
*    EXCEPTIONS
*      cntl_error                  = 1
*      cntl_system_error           = 2
*      create_error                = 3
*      lifetime_error              = 4
*      lifetime_dynpro_dynpro_link = 5.
*
*  IF sy-subrc NE 0.
*    MESSAGE x208(00) WITH 'ERROR'.
*  ENDIF.
*
*  "Crea el ALV TREE
*  CREATE OBJECT re_alv_tree
*    EXPORTING
*      parent                      = re_custom_container
*      node_selection_mode         = cl_gui_column_tree=>node_sel_mode_multiple "selección filas
*      item_selection              = abap_true    "permite seleccionar columnas
*      no_html_header              = 'X'          "Cabecera
*      no_toolbar                  = ''
*    EXCEPTIONS
*      cntl_error                  = 1
*      cntl_system_error           = 2
*      create_error                = 3
*      lifetime_error              = 4
*      illegal_node_selection_mode = 5
*      failed                      = 6
*      illegal_column_name         = 7.
*
*  IF sy-subrc NE 0.
*    MESSAGE x208(00) WITH 'ERROR'.
*  ENDIF.
*
*  FIELD-SYMBOLS <fs_fieldcat_tree> TYPE lvc_s_fcat.
*
*  "Determina el catalogo del ALV tree
*  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
*    EXPORTING
*      i_structure_name       = 'ZST_ALV_TREE'  "estructura del ALV TREE
*    CHANGING
*      ct_fieldcat            = pgt_fieldcat_tree
*    EXCEPTIONS
*      inconsistent_interface = 1
*      program_error          = 2
*      OTHERS                 = 3.
*
*
*  "Ajuste de parámetros del catalogo
*  LOOP AT pgt_fieldcat_tree ASSIGNING <fs_fieldcat_tree>.
*
*    CASE <fs_fieldcat_tree>-fieldname.
*      WHEN 'CLIENTE'.
*        <fs_fieldcat_tree>-outputlen = '000020'.
*        <fs_fieldcat_tree>-no_zero   = 'X'.
*
*      WHEN 'OPERACION'.
*        <fs_fieldcat_tree>-outputlen = '000020'.
*        <fs_fieldcat_tree>-no_zero   = 'X'.
*        <fs_fieldcat_tree>-scrtext_l = text-002.  "Operación
*        <fs_fieldcat_tree>-scrtext_m = text-003.  "Nro Operación
*        <fs_fieldcat_tree>-scrtext_s = text-003.  "Nro Operación
*
*      WHEN 'ESTADO'.
*        <fs_fieldcat_tree>-outputlen = '000020'.
*        <fs_fieldcat_tree>-no_zero   = 'X'.
*
*      WHEN 'TIPO'.
*        <fs_fieldcat_tree>-outputlen = '000020'.
*        <fs_fieldcat_tree>-no_zero   = 'X'.
*
*      WHEN 'DESCRIP'.
*        <fs_fieldcat_tree>-outputlen = '000040'.
*        <fs_fieldcat_tree>-no_zero   = 'X'.
*
*      WHEN 'CLASE'.
*        <fs_fieldcat_tree>-outputlen = '000020'.
*        <fs_fieldcat_tree>-no_zero   = 'X'.
*
*      WHEN 'CANTIDAD'.
*        <fs_fieldcat_tree>-outputlen = '000020'.
*        <fs_fieldcat_tree>-no_zero   = 'X'.
*
*      WHEN OTHERS.
*        <fs_fieldcat_tree>-outputlen = '000020'.
*        <fs_fieldcat_tree>-scrtext_l = text-004.  "Cantidad
*        <fs_fieldcat_tree>-scrtext_m = text-004.  "Cantidad
*        <fs_fieldcat_tree>-scrtext_s = text-004.  "Cantidad
*        <fs_fieldcat_tree>-do_sum    = 'X'.
*        <fs_fieldcat_tree>-no_sum    = ''.
*    ENDCASE.
*
*  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  display_fullscreen
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM display_fullscreen .

*... §1 create an ALV tree
  TRY.
      cl_salv_tree=>factory(
        IMPORTING
          r_salv_tree = gr_tree
        CHANGING
          t_table      = gt_outtab ).
    CATCH cx_salv_no_new_data_allowed cx_salv_error.
      EXIT.
  ENDTRY.

  PERFORM create_tree.
break 700-009.
*... §3 Functions
*... §3.1 activate ALV generic Functions
*... §3.2 include own functions by setting own status
  gr_tree->set_screen_status(
    pfstatus      =  'SALV_STANDARD'
    report        =  gs_test-repid
    set_functions =  gr_tree->c_functions_all ).


*... set the columns technical
  DATA: lr_columns TYPE REF TO cl_salv_columns_tree.

  lr_columns = gr_tree->get_columns( ).
  lr_columns->set_optimize( gc_true ).

**** Luego lo verifico
****  PERFORM set_columns_technical USING lr_columns.

*... §4 display the table
  gr_tree->display( ).

ENDFORM.                    " display_fullscreen

*&--------------------------------------------------------------------*
*&      Form  display_grid
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
FORM display_tree.

  CALL SCREEN 100.

ENDFORM.                    "display_grid
*&---------------------------------------------------------------------*
*&      Form  supply_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_OUTTAB  text
*----------------------------------------------------------------------*
FORM supply_data USING pt_outtab TYPE STANDARD TABLE.

*... §2.3 supply the data to ALV, building the hierarchy

  DATA: ls_data TYPE ty_gc_merge.
  DATA: lv_lgart_key TYPE salv_de_node_key,
        lv_mes_key   TYPE salv_de_node_key.

  DATA: l_carrid_key TYPE lvc_nkey,
        l_connid_key TYPE lvc_nkey,
        l_last_key   TYPE lvc_nkey.


  LOOP AT pt_outtab INTO ls_data.

*    ON CHANGE OF ls_data-carrid.
*      PERFORM add_carrid_line USING    ls_data
*                                       ''
*                              CHANGING l_carrid_key.
*    ENDON.
*    ON CHANGE OF ls_data-connid.
*      PERFORM add_connid_line USING    ls_data
*                                       l_carrid_key
*                              CHANGING l_connid_key.
*    ENDON.
*    PERFORM add_complete_line USING  ls_data
*                                     l_connid_key
*                            CHANGING l_last_key.

  ENDLOOP.

ENDFORM.                    " supply_data
