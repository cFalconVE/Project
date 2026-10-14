*&---------------------------------------------------------------------*
*&  Include  zsd_rep_gc_dig_top
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
*&---------------------------------------------------------------------*
CONSTANTS: gc_red_status    TYPE icon_d VALUE '@0A@', "Error
           gc_yellow_status TYPE icon_d VALUE '@09@', "Warning
           gc_green_status  TYPE icon_d VALUE '@08@'. "OK

CONSTANTS: gc_tree_container_name TYPE char30 VALUE 'TREE_CONTROL',
           gc_true                TYPE abap_bool VALUE 'X',
           BEGIN OF gc_s_display,
             tree       TYPE i VALUE 1,
             fullscreen TYPE i VALUE 2,
           END   OF gc_s_display.

TABLES: zsd_tb_gck, zsd_tb_gcp.

TYPES: BEGIN OF g_type_s_test,
         amount  TYPE i,
         repid   TYPE syrepid,
         display TYPE i,
         dynamic TYPE sap_bool,
       END OF g_type_s_test.

DATA: gs_test TYPE g_type_s_test.

DATA: gr_alv_tree  TYPE REF TO cl_gui_alv_tree,
      gr_container TYPE REF TO cl_gui_custom_container.
*      go_tree_control     TYPE REF TO cl_item_tree_control.

DATA: gt_fieldcatalog TYPE TABLE OF lvc_s_fcat,
      ok_code         LIKE sy-ucomm,
      save_ok         LIKE sy-ucomm.
*      ,
*      gv_max          TYPE i VALUE 255.
*      gt_alv           TYPE TABLE OF zst_alv_tree.

DATA: wa_hierarchy_header TYPE treev_hhdr,
      wa_variant          TYPE disvariant.
*      wa_alv              TYPE zst_alv_tree.

DATA: gr_tree     TYPE REF TO cl_salv_tree,
      go_nodes    TYPE REF TO cl_salv_nodes,
      go_node     TYPE REF TO cl_salv_node,
      go_settings TYPE REF TO cl_salv_tree_settings.

*DATA(go_rep_alv) = NEW lcl_tree_event_receiver( ).

TYPES: BEGIN OF ty_gcd,
         lgart  TYPE lgart,
         mes(2) TYPE c,
         aedat  TYPE aedat,
         tknumk TYPE tknum,
         tknump TYPE tknum,
         pagina TYPE zpagina,
         estado TYPE zsd_dd_status,
         url    TYPE zurl,
       END OF ty_gcd,

       BEGIN OF ty_gc_merge,
         aedat      TYPE aedat,
         tknumk     TYPE tknum,
         nroentrega TYPE tknum,
         pagina     TYPE zpagina,
         estado     TYPE zsd_dd_status,
         url        TYPE zurl,
       END OF ty_gc_merge.

*p~aedat, k~tknum, p~tknum as nroentrega, p~pagina, p~estado, p~url

DATA: gt_gck      TYPE TABLE OF zsd_tb_gck,
      gs_gck      TYPE zsd_tb_gck,
      gt_gcp      TYPE TABLE OF zsd_tb_gcp,
      gs_gcp      TYPE zsd_tb_gcp,
      gt_gcd      TYPE TABLE OF ty_gcd,
      ls_gc_out   TYPE ty_gc_merge,
      gt_gc_out   TYPE TABLE OF ty_gc_merge,
      gt_gc_merge TYPE TABLE OF ty_gc_merge,
      gt_outtab   TYPE STANDARD TABLE OF zview_gc.
